//
//  JournalView.swift
//  flourish-playground
//
//  Created by aliana yee on 8/4/25.
//

import SwiftUI
import PhotosUI

struct JournalEntry: Identifiable {
    let id = UUID()
    var title: String
    var entry: String
    var image: UIImage?
    var points: Int
    var date: Date
    var category: String
}

class JournalViewModel: ObservableObject {
    @Published var entries: [JournalEntry] = []
    @Published var categoryCounts: [Int] = [0,0,0,0,0]
}

struct RecordView: View {
    @ObservedObject var gardenVM: ThemedGardenViewModel
    @ObservedObject var journalVM: JournalViewModel

    @State private var titleText: String = ""
    @State private var entryText: String = "type your description here!"
    private var yellowBoxHeight: Int {
        var n = 250
        if selectedImage != nil { n += 170 }
        return n
    }
    @State private var selectedImage: UIImage?
    @State private var showPhotoPicker = false
    @State private var isSubmitting = false
    @State private var showPointsAwarded = false
    @State private var awardedPoints: Int = 0

    let lightYellow = Color(red: 255/255, green: 254/255, blue: 226/255)
    let lightGreen = Color(red: 203/255, green: 255/255, blue: 163/255)

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("record your impact")
                    .font(.poppinsBold())
                    .padding(.top)
                
                ZStack(alignment: .top) {
                    RoundedRectangle(cornerRadius: 30)
                        .fill(lightYellow)
                        .frame(width: 340, height: CGFloat(yellowBoxHeight))
                    
                    // full card container
                    VStack(alignment: .leading, spacing: 12) {
                        // entry fields
                        entryFields()
                        
                        // submit button
                        Button {
                            submitEntry()
                        } label: {
                            Text(isSubmitting ? "submitting..." : "submit")
                                .font(.poppins())
                                .frame(maxWidth: 300)
                                .padding()
                                .background(lightGreen)
                                .cornerRadius(20)
                                .frame(width: 300)
                        }
                        .disabled((titleText.isEmpty && entryText.isEmpty) || isSubmitting)
                        .padding(.horizontal, 25)
                    }
                    //.background(lightYellow)
                    .cornerRadius(30)
                    //.frame(width: 340)
                    .padding(.horizontal)
                }
                .frame(width:340)
                
                learnMore()
                
            }
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: Binding(
            get: { nil },
            set: { newItem in
                if let newItem {
                    Task {
                        if let data = try? await newItem.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data) {
                            selectedImage = uiImage
                        }
                    }
                }
            }
        ))
        .alert("points awarded!", isPresented: $showPointsAwarded) {
            Button("ok", role: .cancel) {}
        } message: {
            Text("you earned \(awardedPoints) points for your action!")
        }
        
    }

    private func submitEntry() {
        isSubmitting = true
        
        var category = ""
        
        GPTPointEvaluator.categorize(title: titleText, entry: entryText) { c in
            print("!!!!!!! \(c)")
            category = c
            if category == "recycling" { journalVM.categoryCounts[0] += 1 }
            if category == "gardening" { journalVM.categoryCounts[1] += 1 }
            if category == "reusing/repurposing" { journalVM.categoryCounts[2] += 1 }
            if category == "reducing waste" { journalVM.categoryCounts[3] += 1 }
            if category == "other" { journalVM.categoryCounts[4] += 1 }
        }
        
        print("****** \(category)")
        
        GPTPointEvaluator.evaluate(title: titleText, entry: entryText) { points in
            awardedPoints = points
            gardenVM.balance += points
            gardenVM.runningBal += points
            journalVM.entries.append(JournalEntry(
                title: titleText,
                entry: entryText,
                image: selectedImage,
                points: points,
                date: Date.now,
                category: category
                
            ))
            isSubmitting = false
            showPointsAwarded = true
            titleText = ""
            entryText = ""
            selectedImage = nil
            category = ""
        }
    }
    
    private func learnMore() -> some View {
        VStack {
            Text("learn more about what you can do to protect our environment!")
                .multilineTextAlignment(.leading)
                .padding()
                .font(Font.custom("Poppins-SemiBold", size: 15))
            
            HStack {
                Text("• go thrifting or avoid shopping at fast fashion brands\n• buy a water bottle so that you don't have to buy plastic ones\n• volunteer for a beach/park cleanup or an invasive plant removal\n• carpool, use public transport, or bike instead of driving\n• spread the word about apps like these to encourage others to become more environmentally friendly too!")
                    .multilineTextAlignment(.leading)
                    .padding()
                    .font(.poppins())
            }
            
            Link("want even more ideas?", destination: URL(string: "https://www.conservation.org/act/sustainable-living-tips")!)
                .multilineTextAlignment(.leading)
                .padding()
                .font(.poppins())
            
        }
        .background(lightYellow)
        .cornerRadius(20)
        .frame(width: 340)
        
    }
    
    private func entryFields() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("title", text: $titleText)
                .font(Font.custom("Poppins-SemiBold", size: 20))
                .padding(.horizontal, 25)
                .padding(.top, 10)
            
            // entry text editor
            TextEditor(text: $entryText)
                .foregroundColor(entryText == "type your description here!" ? .gray : .primary)
                .frame(minHeight: 100)
                .frame(width: 300)
                .padding(.horizontal, 25)
                .font(.poppins())
                .onAppear {
                    NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { (noti) in withAnimation { if entryText == "type your description here!" { entryText = "" } } } }
            
            // picture button
            Button {
                showPhotoPicker = true
            } label: {
                Text(selectedImage == nil ? "insert picture" : "change picture")
                    .font(.poppins())
                    .frame(maxWidth: 300)
                    .padding()
                    .background(lightGreen)
                    .cornerRadius(20)
                    .frame(width: 300)
            }
            .padding(.horizontal, 25)
            
            // optional image preview
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 150)
                    .cornerRadius(15)
                    .padding(.horizontal)
            }
        }
    }
}


class GPTPointEvaluator {
    static func evaluate(title: String, entry: String, completion: @escaping (Int) -> Void) {
        let prompt = "Give (only) a number between 5 and 20 for the eco-friendly action described in this journal entry, on a scale of if 5 is recycling, 10 is carpooling, 15 is thrifting, and 20 is volunteering and picking up trash or invasive plants: \(title): \(entry)"

        let requestData = [
            "model": "gpt-4",
            "messages": [
                ["role": "system", "content": prompt]
            ]
        ] as [String : Any]
       
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "API_KEY") as? String else {
            print("Missing API Key in Info.plist !!!!")
            return
        }
       
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            print("Invalid URL or missing API key")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestData)
        } catch {
            print("Failed to encode JSON")
            return
        }

        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, error == nil,
                  let response = try? JSONDecoder().decode(GPTResponse.self, from: data),
                  let content = response.choices.first?.message.content,
                  let number = Int(content.trimmingCharacters(in: .whitespacesAndNewlines))
            else {
                print("Failed to parse response: \(error!)")
                return
            }

            DispatchQueue.main.async {
                completion(number)
            }
        }.resume()
    }
    
    static func categorize(title: String, entry: String, completion: @escaping (String) -> Void) {
        let prompt = "please categorize this entry into one category of environmentally friendly actions (categories are: recycling, reusing/repurposing, reducing waste, gardening, or other). only return the category name in all lowercase letters exactly as given above. here is the entry: \(title): \(entry)"

        let requestData = [
            "model": "gpt-4",
            "messages": [
                ["role": "system", "content": prompt]
            ]
        ] as [String : Any]
       
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "API_KEY") as? String else {
            print("Missing API Key in Info.plist !!!!")
            return
        }
       
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            print("Invalid URL or missing API key")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestData)
        } catch {
            print("Failed to encode JSON")
            return
        }

        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, error == nil,
                  let response = try? JSONDecoder().decode(GPTResponse.self, from: data),
                  let content = response.choices.first?.message.content
            else {
                print("Failed to parse response: \(error!)")
                return
            }

            DispatchQueue.main.async {
                let str = String(content.trimmingCharacters(in: .whitespacesAndNewlines))
                completion(str)
            }
        }.resume()
    }
}

struct GPTResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            let content: String
        }
        let message: Message
    }

    let choices: [Choice]
}
