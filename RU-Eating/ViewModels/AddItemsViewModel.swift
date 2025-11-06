//
//  AddItemsViewModel.swift
//  RU Eating
//
//  Created by alex on 9/24/24.
//

import Foundation
import SwiftUI

@Observable class AddItemsViewModel {
    var meal: Category
    var searchText: String
    private(set) var fetched: Bool
    
    private(set) var rawItems: [Item]
    var items: [Item] {
        if (searchText.isEmpty) {
            return rawItems
        }
        else {
            return rawItems.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    init(meal: Category) {
        self.meal = meal
        
        self.searchText = ""
        self.fetched = false
        
        self.rawItems = [Item]()
    }
    
    func addItem(item: Item) {
        meal.items.append(item)
        Task {
            await item.fetchData()
        }
    }
    
    func updateItems(lastDiningHall: String) async {
        fetched = false
        rawItems = [Item]()
        for place in places {
            if !place.name.contains(lastDiningHall) { continue }
            for meal in meals {
                do {
                    let menu = try await place.fetchMenu(meal: meal, date: Date.now)
                    
                    for category in menu {
                        for item in category.items {
                            if !rawItems.contains(item) {
                                rawItems.append(item)
                            }
                        }
                    }
                } catch {
                    // do nothing
                }
            }
            break
        }
        fetched = true
    }
    
    func getHighlightedName(item: Item) -> AttributedString {
        var name = AttributedString(item.name)
        let lowercasedName = AttributedString(item.name.lowercased())
        
        for range in lowercasedName.characters.ranges(of: searchText.lowercased()) {
            name[range].foregroundColor = .accent
        }
        
        return name
    }
}
