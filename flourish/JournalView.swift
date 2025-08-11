//
//  Jour.swift
//  flourish-playground
//
//  Created by aliana yee on 8/4/25.
//


import SwiftUI

struct JournalView: View {
    @ObservedObject var journalVM: JournalViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // Title aligned with cards
                Text("journal")
                    .font(.poppinsBold())
                    .frame(width: 340, alignment: .leading)
                    .padding(.top)
                
                // No entries message
                if journalVM.entries.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("no entries yet!")
                            .font(.custom("Poppins-SemiBold", size: 25))
                        Text("go to the home page to add an entry to this journal!")
                            .font(.poppins())
                    }
                    .padding()
                    .frame(width: 340, alignment: .leading)
                    .background(Color(red: 255/255, green: 254/255, blue: 226/255))
                    .cornerRadius(30)
                }
                
                // Entries
                ForEach(journalVM.entries.reversed()) { entry in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(entry.title)
                            .font(.custom("Poppins-SemiBold", size: 25))
                        Text(entry.entry)
                            .font(.poppins())
                        
                        if let img = entry.image {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 150)
                                .cornerRadius(15)
                        }
                        
                        HStack {
                            Text("Points: \(entry.points)")
                                .font(.custom("Poppins-Regular", size: 10))
                                .foregroundColor(.gray)
                            Spacer()
                            Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.custom("Poppins-Regular", size: 10))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .frame(width: 340, alignment: .leading)
                    .background(Color(red: 255/255, green: 254/255, blue: 226/255))
                    .cornerRadius(30)
                }
            }
            .frame(maxWidth: .infinity) // Centers everything in ScrollView
            .padding(.bottom)
        }
    }
}

//struct JournalView: View {
//    @ObservedObject var journalVM: JournalViewModel
//
//    var body: some View {
//        ScrollView {
//            VStack(alignment: .leading, spacing: 20) {
//                Text("journal")
//                    .font(.poppinsBold())
//                    .padding(.top)
//                    .padding(.leading)
//                    .alignmentGuide(.leading, computeValue: {_ in 0} )
//                    .frame(width: 340, alignment: .leading)
//                
//                if journalVM.entries.count == 0 {
//                    VStack(alignment: .leading, spacing: 8) {
//                        Text("no entries yet!")
//                            .font(Font.custom("Poppins-SemiBold", size: 25))
//                            .frame(maxWidth: 340, alignment: .leading)
//                        Text("go to the home page to add an entry to this journal!")
//                            .font(.poppins())
//                            .frame(maxWidth: 340, alignment: .leading)
//                    }
//                    .frame(width: 340)
//                    .padding()
//                    .background(Color(red: 255/255, green: 254/255, blue: 226/255))
//                    .cornerRadius(30)
//                }
//                
//                ForEach(journalVM.entries.reversed()) { entry in
//                    VStack(alignment: .leading, spacing: 8) {
//                        Text(entry.title)
//                            .font(Font.custom("Poppins-SemiBold", size: 25))
//                            .frame(maxWidth: 340, alignment: .leading)
//                        Text(entry.entry)
//                            .font(.poppins())
//                            .frame(maxWidth: 340, alignment: .leading)
//                        if let img = entry.image {
//                            Image(uiImage: img)
//                                .resizable()
//                                .scaledToFit()
//                                .frame(height: 150)
//                                .cornerRadius(15)
//                        }
//                        HStack {
//                            Text("Points: \(entry.points)")
//                                .font(Font.custom("Poppins-Regular", size: 10))
//                                .foregroundColor(.gray)
//                                .frame(width: 340, alignment: .leading)
//                            Text("\(entry.date.formatted(date: .abbreviated, time: .omitted))")
//                                .font(Font.custom("Poppins-Regular", size: 10))
//                                .foregroundColor(.gray)
//                                .frame(width: 340, alignment: .trailing)
//                        }
//                    }
//                    .padding()
//                    .frame(width: 340)
//                    .background(Color(red: 255/255, green: 254/255, blue: 226/255))
//                    .cornerRadius(30)
//                }
//            }
//            .padding()
//        }
//    }
//}
