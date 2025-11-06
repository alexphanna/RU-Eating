//
//  CategoryViewModel.swift
//  RU Eating
//
//  Created by alex on 9/24/24.
//

import Foundation

@Observable class MenuViewModel {
    // core
    private(set) var place: Place
    var meal: String
    var date: Date
    
    // settings and filtering
    var isGrouped: Bool
    var sortBy: String
    var groupByCategory: Bool
    var sortOrder: String
    var nutrient: String
    var filter: String
    
    private(set) var rawMenu: [Category]
    private(set) var fetched: Bool
    
     var menu: [Category] {
        var menu: [Category] = [Category]()
        
        for category in rawMenu {
            let filteredCategory: Category = Category(name: category.name)
            
            switch filter {
            case "Favorites":
                filteredCategory.items.append(contentsOf: category.items.filter { $0.isFavorite })
                break
            case "Low Carbon Footprint":
                filteredCategory.items.append(contentsOf: category.items.filter { $0.carbonFootprint == 1 })
                break
            default:
                filteredCategory.items.append(contentsOf: category.items)
                break
            }
            
            if !filteredCategory.items.isEmpty {
                menu.append(filteredCategory)
            }
        }
        
        return menu
    }
    
    var isEditing: Bool = false
    
    var items: Category {
        let category: Category = Category(name: "All")
        
        for _category in menu {
            category.items.append(contentsOf: _category.items)
        }
        
        return category
    }
    
    private var dayName: String? {
        switch Calendar.current.dateComponents([.year, .month, .day], from: date) {
        case Calendar.current.dateComponents([.year, .month, .day], from: Calendar.current.date(byAdding: .day, value: -1, to: Date.now)!):
            return "Yesterday"
        case Calendar.current.dateComponents([.year, .month, .day], from: Date.now):
            return "Today"
        case Calendar.current.dateComponents([.year, .month, .day], from: Calendar.current.date(byAdding: .day, value: 1, to: Date.now)!):
            return "Tomorrow"
        default:
            return nil
        }
    }
    
    var randomItem: Item?
    
    var selection: [String] {
        return items.items.filter { $0.isSelected }.map { $0.name }
    }
    
    func resetSelection() {
        for item in items.items {
            item.isSelected = false
        }
    }
    
    init(place: Place) {
        self.place = place
        switch Calendar.current.component(.hour, from: Date.now) {
        case ..<11:
            self.meal = "Breakfast"
        case ..<17:
            self.meal = "Lunch"
        default:
            self.meal = "Dinner"
        }
        self.date = Date.now
        
        self.isGrouped = false
        self.sortBy = "Name"
        self.sortOrder = "Ascending"
        self.groupByCategory = true
        self.nutrient = "Calories"
        self.filter = "All Items"
        
        self.rawMenu = [Category]()
        self.fetched = false
    }
    
    func updateMenu() async {
        fetched = false
        rawMenu = [Category]()
        sortBy = "Name"
        filter = "All Items"
        randomItem = nil
        do {
            rawMenu = try await place.fetchMenu(meal: meal == "Takeout" ? "Knight+Room" : meal, date: date)
            if !items.items.isEmpty {
                randomItem = items.items.randomElement()!
            }
            for category in rawMenu {
                for item in category.items {
                    await item.fetchData()
                }
            }
        } catch {
            // do nothing
        }
        fetched = true
    }
}
