//
//  AnalyticsView.swift
//  flourish
//
//  Created by Alicia Yee on 8/11/25.
//

import Foundation
import SwiftUI
import Charts
import Firebase
import FirebaseFirestore
import FirebaseAuth

struct AnalyticsView: View {
    @ObservedObject var journalVM: JournalViewModel
    @ObservedObject var gardenVM: ThemedGardenViewModel
    
    var streakCount: Int {
        let sortedDates = journalVM.entries
            .map { Calendar.current.startOfDay(for: $0.date) }
            .sorted(by: >)
        
        guard let firstDay = sortedDates.first else { return 0 }
        
        var streak = 1
        var currentDay = firstDay
        
        for date in sortedDates.dropFirst() {
            if let diff = Calendar.current.dateComponents([.day], from: date, to: currentDay).day {
                if diff == 1 {
                    streak += 1
                    currentDay = date
                } else if diff > 1 {
                    break // streak ended
                }
            }
        }
        
        return streak
    }
    
    var categoryCounts: [CategoryData] {
        let dict = [ CategoryData(category: "recycling", count: journalVM.categoryCounts[0]),
                     CategoryData(category: "gardening", count: journalVM.categoryCounts[1]),
                     CategoryData(category: "reusing/repurposing", count: journalVM.categoryCounts[2]),
                     CategoryData(category: "reducing waste", count: journalVM.categoryCounts[3]),
                     CategoryData(category: "other", count: journalVM.categoryCounts[4]) ]
        return dict
    }
    
    @StateObject private var pointsUpdater = PointsUpdater()
    @State private var currentPoints: Int = 0
    @State private var userName: String = ""
    
    @State private var showingUsernameAlert = false
    @State private var newUsername = ""
    @State private var currentUserID: String? = nil
    
    @StateObject var viewModel = LeaderboardViewModel()
        
    var body: some View {
        VStack {
            
            Text("analytics")
                .font(.poppinsBold())
                .frame(width: 340, alignment: .leading)
                .padding(.top)
            
                // MARK: - Streak Bar
            VStack(alignment: .leading, spacing: 10) {
                Text("current streak")
                    .font(Font.custom("Poppins-SemiBold", size: 20))
                
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 20)
                    
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(red: 203/255, green: 255/255, blue: 163/255))
                        .frame(width: CGFloat(min(streakCount, 30)) / 30 * 300, height: 20)
                }
                
                Text("\(streakCount) days in a row!")
                    .font(.poppins())
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(width: 340, alignment: .leading)
            .background(Color(red: 255/255, green: 254/255, blue: 226/255))
            .cornerRadius(30)
            
            
            // MARK: - Pie Chart
            VStack(alignment: .leading, spacing: 10) {
                Text("category distribution")
                    .font(Font.custom("Poppins-SemiBold", size: 20))
                
                let cleanedData = categoryCounts.filter { !$0.category.isEmpty }
                if !journalVM.entries.isEmpty {
                    if #available(iOS 16.0, *) {
                        Chart(cleanedData) { data in
                            SectorMark(
                                angle: .value("Count", data.count),
                                innerRadius: .ratio(0.5),
                                angularInset: 1
                            )
                            .foregroundStyle(by: .value("Category", data.category))
                        }
                        .chartForegroundStyleScale([
                            "recycling": Color(red: 255/255, green: 194/255, blue: 248/255, opacity: 1),
                            "gardening": Color(red: 203/255, green: 255/255, blue: 163/255, opacity: 1),
                            "reusing/repurposing": Color(red: 234/255, green: 191/255, blue: 255/255, opacity: 1),
                            "reducing waste": Color(red: 243/255, green: 240/255, blue: 187/255, opacity: 1),
                            "other": Color(red: 187/255, green: 243/255, blue: 218/255, opacity: 1)
                        ])
                        .frame(height: 200)
                    } else {
                        Text("this pie chart analysis requires iOS 16+.")
                    }
                } else {
                    Text("you don't have any journal entries yet! use the journal to see your statistics.")
                }
            }
            .padding()
            .frame(width: 340, alignment: .leading)
            .background(Color(red: 255/255, green: 254/255, blue: 226/255))
            .cornerRadius(30)
            
            
            VStack(alignment: .leading) {
                HStack(alignment: .lastTextBaseline) {
                    Text("leaderboard")
                        .font(Font.custom("Poppins-SemiBold", size: 20))
                        .onAppear {
                            Task { currentPoints = try await pointsUpdater.addPoints(amount: gardenVM.runningBal, displayName: userName.isEmpty ? nil : userName) }
                        }
                        .padding(.trailing, 6)
                    
                    Button("change username") {
                        showingUsernameAlert = true
                    }
                    .font(.poppins())
                    .alert("change your username!", isPresented: $showingUsernameAlert) {
                        TextField("new username", text: $newUsername)
                        Button("save") {
                            Task {
                                do {
                                    try await pointsUpdater.updateDisplayName(newName: newUsername)
                                } catch {
                                    print("error updating username: \(error)")
                                }
                            }
                        }
                        Button("cancel", role: .cancel) { }
                    }
                }
                
                List(viewModel.entries) { entry in
                    HStack {
                        Text((entry.displayName ?? "anonymous flower") + (entry.id == currentUserID ? " (me)" : ""))
                            .font(.headline)
                        Spacer()
                        Text("\(entry.points) points")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .navigationTitle("leaderboard")
                .onAppear {
                    currentUserID = Auth.auth().currentUser?.uid
                    viewModel.startListeningForLeaderboard()
                }
            }
            .padding()
            .frame(width: 340, alignment: .leading)
            .background(Color(red: 255/255, green: 254/255, blue: 226/255))
            .cornerRadius(30)
            
        }
    }
}

struct CategoryData: Identifiable {
    let id = UUID()
    let category: String
    let count: Int
}

struct LeaderboardEntry: Identifiable, Codable {
    @DocumentID var id: String?
    var points: Int
    var displayName: String?
}

class PointsUpdater: ObservableObject {

    // Function to add points to the current anonymous user
    func addPoints(amount: Int, displayName: String?) async throws -> Int {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw PointsError.notAuthenticated
        }

        let db = Firestore.firestore()
        let userRef = db.collection("leaderboard").document(uid)

        do {
            var newPoints = 0
            try await db.runTransaction { transaction, _  in
                let userDocument: DocumentSnapshot?
                do {
                    userDocument = try transaction.getDocument(userRef)
                } catch {
                    print("Document for UID \(uid) not found, will create. Error: \(error.localizedDescription)")
                    userDocument = nil // document not found
                    return
                }

                newPoints = amount

                var dataToUpdate: [String: Any] = [
                    "points": newPoints
                ]

                if let name = displayName, !name.isEmpty {
                    dataToUpdate["displayName"] = name
                } else if userDocument!.exists && userDocument!.data()?["displayName"] == nil {
                    dataToUpdate["displayName"] = "flower \(uid.prefix(4))"
                }

                transaction.setData(dataToUpdate, forDocument: userRef, merge: true)
                return nil
            }
            print("Successfully updated points for \(uid). New points: \(newPoints)")
            return newPoints
        } catch {
            print("Error updating points: \(error.localizedDescription)")
            throw error
        }
    }
    
    func updateDisplayName(newName: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw PointsError.notAuthenticated
        }
        
        guard !newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("username cannot be empty!")
            return
        }
        
        let db = Firestore.firestore()
        let userRef = db.collection("leaderboard").document(uid)
        
        do {
            try await userRef.setData(["displayName": newName], merge: true)
            print("Successfully updated display name for \(uid) to \(newName)")
        } catch {
            print("Error updating display name: \(error.localizedDescription)")
            throw error
        }
    }

    enum PointsError: Error, LocalizedError {
        case notAuthenticated
        case firestoreError(Error)

        var errorDescription: String? {
            switch self {
            case .notAuthenticated:
                return "User is not authenticated. Please ensure anonymous sign-in is complete."
            case .firestoreError(let error):
                return "Firestore error: \(error.localizedDescription)"
            }
        }
    }
}

class LeaderboardViewModel: ObservableObject {
    @Published var entries: [LeaderboardEntry] = []
    private var listener: ListenerRegistration?

    init() {
        startListeningForLeaderboard()
    }

    func startListeningForLeaderboard() {
        listener?.remove()

        listener = Firestore.firestore().collection("leaderboard")
            .order(by: "points", descending: true)
            .limit(to: 10)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching leaderboard documents: \(error?.localizedDescription ?? "N/A")")
                    return
                }

                self.entries = documents.compactMap { queryDocumentSnapshot in
                    try? queryDocumentSnapshot.data(as: LeaderboardEntry.self)
                }
            }
    }

    deinit {
        listener?.remove()
    }
}
