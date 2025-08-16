//
//  ContentView.swift
//  flourish
//
//  Created by Alicia Yee on 8/3/25.
//

import SwiftUI
import Foundation
import AIProxy

enum biomeType: String, CaseIterable {
    case garden, rainforest, desert
}

protocol Flower: Identifiable {
    var iconName: String { get }
    var cost: Int { get }
}

extension GardenFlowerType: Flower {}
extension RainforestFlowerType: Flower {}
extension DesertFlowerType: Flower {}

enum GardenTheme: CaseIterable {
    case garden
    case rainforest
    case desert

    var name: String {
        switch self {
        case .garden: return "garden"
        case .rainforest: return "rainforest"
        case .desert: return "desert"
        }
    }

    var plotColor: Color {
        switch self {
        case .garden: return Color(red: 255/255, green: 194/255, blue: 248/255, opacity: 1) // light pink
        case .rainforest: return Color(red: 187/255, green: 243/255, blue: 218/255, opacity: 1) // darker yellow
        case .desert: return Color(red: 243/255, green: 240/255, blue: 187/255, opacity: 1) // light green
        }
    }

    var flowers: [any Flower] {
        switch self {
        case .garden: return GardenFlowerType.allCases
        case .rainforest: return RainforestFlowerType.allCases
        case .desert: return DesertFlowerType.allCases
        }
    }
}

enum GardenFlowerType: String, CaseIterable, Identifiable {
    case sunflower, rose, lavender, mushroom
    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .sunflower: return "sunflower"
        case .rose: return "rose"
        case .lavender: return "lavender"
        case .mushroom: return "mushroom"
        }
    }
    
    var cost: Int {
        switch self {
        case .sunflower: return 5
        case .rose: return 8
        case .lavender: return 10
        case .mushroom: return 14
        }
    }
}

enum RainforestFlowerType: String, CaseIterable, Identifiable {
    case ivy, orchid, lilypad, bromeliad
    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .ivy: return "ivy"
        case .orchid: return "orchid"
        case .lilypad: return "lilypad"
        case .bromeliad: return "bromeliad"
        }
    }

    var cost: Int {
        switch self {
        case .ivy: return 4
        case .orchid: return 6
        case .lilypad: return 5
        case .bromeliad: return 7
        }
    }
}

enum DesertFlowerType: String, CaseIterable, Identifiable {
    case cactus, aloevera, marigold, pricklypear
    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .cactus: return "cactus"
        case .aloevera: return "aloe vera"
        case .marigold: return "marigold"
        case .pricklypear: return "prickly pear"
        }
    }

    var cost: Int {
        switch self {
        case .cactus: return 4
        case .aloevera: return 5
        case .marigold: return 7
        case .pricklypear: return 6
        }
    }
}

struct GardenPlot: Identifiable {
    let id = UUID()
    var flower: (any Flower)?
}

class ThemedGardenViewModel: ObservableObject {
    @Published var currentThemeIndex: Int = 0
    @Published var plots: [GardenPlot] = Array(repeating: GardenPlot(flower: nil), count: 12)
    @Published var balance: Int = 20
    @Published var selectedFlower: (any Flower)? = nil
    @Published var showSelectPlot = false
    @Published var showGardenComplete = false
    @Published var runningBal: Int = 20

    var currentTheme: GardenTheme {
        GardenTheme.allCases[currentThemeIndex]
    }

    var flowers: [any Flower] {
        currentTheme.flowers
    }

    var plotColor: Color {
        currentTheme.plotColor
    }

    func purchase(flower: any Flower) {
        guard balance >= flower.cost else { return }
        balance -= flower.cost
        selectedFlower = flower
        showSelectPlot = true
    }

    func plant(at index: Int) {
        guard selectedFlower != nil, plots[index].flower == nil else { return }
        plots[index].flower = selectedFlower
        selectedFlower = nil
        showSelectPlot = false

        if plots.allSatisfy({ $0.flower != nil }) {
            showGardenComplete = true
        }
    }

    func advanceToNextGarden() {
        currentThemeIndex += 1
        if currentThemeIndex >= GardenTheme.allCases.count {
            currentThemeIndex = 0 // or show "all gardens complete"
        }
        plots = Array(repeating: GardenPlot(flower: nil), count: 12)
        showGardenComplete = false
    }
}


struct ThemedGardenView: View {
    @StateObject var viewModel: ThemedGardenViewModel
    
    let columns = Array(repeating: GridItem(.fixed(95), spacing: 5), count: 3)
    @State private var howItWorksAlert = false
    
    let lightYellow = Color(red: 255/255, green: 254/255, blue: 226/255, opacity: 1)
    let lightGreen = Color(red: 203/255, green: 255/255, blue: 163/255, opacity: 1)
    
    @State private var disableButtons = false
    @State private var showingBalAlert = false
    
    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("your \(viewModel.currentTheme.name)")
                    .padding(.bottom, 1)
                    .font(.poppinsBold())
                
                HStack(alignment: .lastTextBaseline) {
                    Button("how it works") {
                        howItWorksAlert = true
                    }
                    .alert("welcome to your garden!", isPresented: $howItWorksAlert) {
                        Button("got it!"){}
                    } message: {
                        Text("here, you can spend the points that you've earned by helping the environment. click one of the four plants below the grid to purchase that plant, then select a plot to plant it on! only one flower may be planted in each plot. fill in all 12 spaces to complete your garden!")
                    }
                    .font(.poppins())
                    .padding(.trailing, 25)
                    
                    Text("balance: \(viewModel.balance) points")
                        .font(.poppins())
                        .foregroundColor(.gray)
                        .frame(width: 200, height: 20, alignment: .topLeading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading) // push all to left edge
            .padding(.horizontal)
            
            theGarden()
            
            // flower buttons to purchase
            ZStack {
                RoundedRectangle(cornerRadius: 30)
                    .fill(lightGreen)
                    .frame(width: 340, height: 100)
                
                HStack {
                    ForEach(viewModel.flowers.indices, id: \.self) { i in
                        let flower = viewModel.flowers[i]
                        Button {
                            if (viewModel.balance < flower.cost) {
                                showingBalAlert = true
                            } else {
                                viewModel.purchase(flower: flower)
                            }
                        } label: {
                            VStack {
                                Image(flower.iconName)
                                    .resizable()
                                    .scaledToFit()
                                Text("\(flower.cost) ")
                                    .font(.poppins())
                            }
                            .frame(width: 70, height:80)
                            .background(lightYellow)
                            .cornerRadius(30)
                        }
                        .disabled(disableButtons)
                    }
                    .alert(isPresented: $showingBalAlert) {
                        Alert(title: Text("insufficient balance :("), message: Text("please log more environmentally beneficial tasks to get points and buy this plant."), dismissButton: .default(Text("ok")))
                    }
                }
            }
        }
        .alert("\(viewModel.currentTheme.name) complete!", isPresented: $viewModel.showGardenComplete) {
            Button("share your garden!") { exportGardenImage() }
            Button("ok", action: viewModel.advanceToNextGarden)
        } message: {
            Text("your garden is flourishing! it's time to explore a new biome...")
        }
        .font(.poppins())
        .padding()
    }
    
    func theGarden() -> some View {
        return ZStack {
            RoundedRectangle(cornerRadius: 30)
                .fill(lightYellow)
                .frame(width: 340, height: 480)
            
            LazyVGrid(columns: columns, spacing: 5) {
                ForEach(viewModel.plots.indices, id: \.self) { index in
                    ZStack {
                        RoundedRectangle(cornerRadius: 30)
                            .fill(viewModel.plotColor)
                            .frame(width: 95, height: 105)
                        if let flower = viewModel.plots[index].flower {
                            Image(flower.iconName)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: 340, maxHeight: 100)
                        } else if viewModel.selectedFlower != nil && viewModel.showSelectPlot {
                            Button {
                                print("planting")
                                viewModel.plant(at: index)
                            } label: {
                                Color.clear
                            }
                        }
                    }
                }
            }
        }
    }
    
    func exportGardenImage() {
        let renderer = ImageRenderer(content: theGarden())
        renderer.scale = UIScreen.main.scale // ensure correct resolution
        
        if let uiImage = renderer.uiImage {
            saveAndShare(image: uiImage)
        }
    }
    
    func saveAndShare(image: UIImage) {
        guard let data = image.pngData() else { return }
        
        let temporaryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("my\(viewModel.currentTheme.name).png")
        try? data.write(to: temporaryURL)
        
        let activityVC = UIActivityViewController(activityItems: [temporaryURL], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true, completion: nil)
        }
        
        viewModel.advanceToNextGarden()
    }
}
