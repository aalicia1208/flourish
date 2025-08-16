//
//  HomeView.swift
//  flourish-playground
//
//  Created by aliana yee on 8/4/25.
//


import SwiftUI

enum TabItem: Int {
    case recordImpact
    case garden
    case journal
    case analytics
}

struct HomeView: View {
    @StateObject var gardenVM = ThemedGardenViewModel()
    @StateObject var journalVM = JournalViewModel()

    @State private var selectedTab: TabItem = .recordImpact

    var body: some View {
        VStack() {
            ZStack {
                switch selectedTab {
                case .recordImpact:
                    RecordView(gardenVM: gardenVM, journalVM: journalVM)
                case .garden:
                    ThemedGardenView(viewModel: gardenVM)
                        .environmentObject(gardenVM)
                case .journal:
                    JournalView(journalVM: journalVM)
                case .analytics:
                    AnalyticsView(journalVM: journalVM, gardenVM: gardenVM)
                }
            }

            HStack(spacing: 30) {
                tabBarButton(icon: "house.fill", tab: .recordImpact)
                tabBarButton(icon: "camera.macro", tab: .garden)
                tabBarButton(icon: "book.fill", tab: .journal)
                tabBarButton(icon: "chart.bar.xaxis.ascending", tab: .analytics)
            }
            .frame(width: 340, height: 80)
            .cornerRadius(30)
            .background( Color(red: 255/255, green: 194/255, blue: 248/255) )
            .frame(width: 340, height: 70)
            .cornerRadius(30)
        }
    }

    private func tabBarButton(icon: String, tab: TabItem) -> some View {
        Button {
            selectedTab = tab
        } label: {
            Image(systemName: icon)
                .font(Font.custom("Poppins-Regular", size: 24))
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(selectedTab == tab
                              ? Color(red: 203/255, green: 255/255, blue: 163/255) // pastel green selected
                              : Color.clear)
                )
                .foregroundColor(.black)
        }
    }
}
