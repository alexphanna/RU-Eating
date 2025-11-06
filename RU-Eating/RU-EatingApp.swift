//
//  MenRUApp.swift
//  MenRU
//
//  Created by alex on 9/6/24.
//

import SwiftUI
import SwiftData

@main
struct MenRUApp: App {
    @Environment(\.requestReview) private var requestReview
    
    @AppStorage("numberOfUses") var numberOfUses: Int = 0
    @AppStorage("filterIngredients") var filterIngredients: Bool = false
    @AppStorage("restrictions") var restrictions: [String] = []
    @AppStorage("hideRestricted") var hideRestricted: Bool = false
    @AppStorage("favoriteItemsIDs") var favoriteItemsIDs: [String] = []
    @AppStorage("hideZeros") var hideZeros: Bool = false
    @AppStorage("hideNils") var hideNils: Bool = false
    @AppStorage("carbonFootprints") var carbonFootprints: Bool = true
    @AppStorage("extraPercents") var extraPercents: Bool = true
    @AppStorage("fdaDailyValues") var fdaDailyValues: Bool = false
    @AppStorage("lastDiningHall") var lastDiningHall: String = "Busch"
    @AppStorage("useHearts") var useHearts: Bool = false
    @AppStorage("itemDescriptions") var itemDescriptions: Bool = true
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    numberOfUses += 1
                    if numberOfUses % 10 == 0 {
                        requestReview()
                    }
                }
        }
    }
}
