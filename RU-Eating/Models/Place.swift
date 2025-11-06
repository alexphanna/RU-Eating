//
//  DiningHall.swift
//  MenRU
//
//  Created by alex on 9/9/24.
//

import Foundation
import SwiftSoup
import SwiftUI

class Place: Identifiable, Hashable {
    static func == (lhs: Place, rhs: Place) -> Bool {
        return lhs.name == rhs.name && lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(id)
    }
    
    var name: String
    var hours: [(String, String)]
    var id: Int
    var hasTakeout: Bool
    
    var isOpen: Bool {
        get {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm"
            
            let openDate = dateFormatter.date(from: hours[Int(Calendar.current.component(.weekday, from: Date())) - 1].0)!
            let nowDate = dateFormatter.date(from: dateFormatter.string(from: Date()))!
            let closedDate = dateFormatter.date(from: hours[Int(Calendar.current.component(.weekday, from: Date())) - 1].1)!
            
            return nowDate.timeIntervalSince(openDate) >= 0 && nowDate.timeIntervalSince(closedDate) <= 0
        }
    }
    
    var shortenName : String {
        switch name {
        case "Busch Dining Hall":
            return "Busch"
        case "Livingston Dining Commons":
            return "Livingston"
        case "Neilson Dining Hall":
            return "Neilson"
        default:
            return "The Atrium"
        }
    }
    
    static let defaultHours = [("09:30", "20:00"), ("07:00", "21:00"), ("07:00", "21:00"), ("07:00", "21:00"), ("07:00", "21:00"), ("07:00", "21:00"), ("07:00", "21:00"), ("09:30", "20:00")]
    
    @AppStorage("favoriteItemsIDs") var favoriteItemsIDs: [String] = []
    
    init(name: String, id: Int, hasTakeout: Bool, hours: [(String, String)] = defaultHours) {
        self.name = name
        self.hasTakeout = hasTakeout
        self.hours = hours
        self.id = id
    }
    
    func getURL(meal: String, date: Date) -> URL {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        
        return URL(string: "https://menuportal23.dining.rutgers.edu/foodpronet/pickmenu.aspx?locationNum=" + String(format: "%02d", id) + "&locationName=" + name.replacingOccurrences(of: " ", with: "+") + "&dtdate=" + dateFormatter.string(from: date) + "&activeMeal=" + meal + "&sName=Rutgers+University+Dining")!
    }
    
    func fetchMenu(meal: String, date: Date) async throws -> [Category] {
        var doc = try await fetchDoc(url: getURL(meal: meal, date: date))
        var elements = try! doc.select("div.menuBox h3, div.menuBox fieldset div.col-1 label, div.menuBox fieldset div.col-2 label, div.menuBox fieldset div.col-1 img[src*='green'], div.menuBox fieldset div.col-1 img[src*='orange'], div.menuBox fieldset div.col-1 img[src*='orange']").array()
        let breakfastCount = elements.count
        
        if meal == "Breakfast" {
            doc = try await fetchDoc(url: getURL(meal: "Lunch", date: date))
            elements.append(contentsOf: try! doc.select("div.menuBox h3, div.menuBox fieldset div.col-1 label, div.menuBox fieldset div.col-2 label, div.menuBox fieldset div.col-1 img[src*='green'], div.menuBox fieldset div.col-1 img[src*='orange'], div.menuBox fieldset div.col-1 img[src*='orange']").array())
        }
        
        var menu = [Category]()
        var lastCategory: Category? = nil
        var nonConstantIndex = 0
        var isBreakfast = false
        var i = 0
        while i < elements.count {
            let element = elements[i]
            
            if (element.tagName() == "h3") {
                var heading = String(try! element.text())
                // remove "-- " and " --" from headings and capitalize headings
                heading = String(heading[heading.index(after: heading.firstIndex(of: " ")!)..<heading.lastIndex(of: " ")!]).capitalized.replacingOccurrences(of: "/ ", with: " / ")
                if i >= breakfastCount {
                    if heading.contains("Breakfast") && !menu.contains(where: { $0.name == heading } ){
                        isBreakfast = true
                    }
                    else {
                        isBreakfast = false
                        i += 1
                        continue
                    }
                }
                lastCategory = Category(name: heading)
                if constantCategories.contains(heading.lowercased()) {
                    menu.append(lastCategory!)
                }
                else if heading.contains("Cook To Order") {
                    menu.insert(lastCategory!, at: 0)
                    nonConstantIndex += 1
                }
                else {
                    menu.insert(lastCategory!, at: nonConstantIndex)
                    nonConstantIndex += 1
                }
            }
            if (element.tagName() == "label") {
                if i >= breakfastCount && !isBreakfast {
                    i += 2 + (elements[i + 1].tagName() == "img" ? 1 : 0)
                    continue
                }
                if (menuContains(menu: menu, id: try! element.attr("for"))) {
                    i += 2 + (elements[i + 1].tagName() == "img" ? 1 : 0)
                    continue
                }
                
                // carbon footprint
                var carbonFootprint = 0
                if i + 2 < elements.count && elements[i + 1].tagName() == "img" {
                    carbonFootprint = parseCarbonFootprint(image: elements[i + 1])
                    i += 1
                }
                
                // servings
                let servings = try! elements[i + 1].text().split(separator: "\u{00A0}")
                let servingsNumber = parseServingsNumber(servings: servings)
                let servingsUnit = parseServingsUnit(servings: servings)
                
                // capitalize items
                let name = try! perfectName(name: element.text())
                let id = try! element.attr("for")
                let isFavorite = favoriteItemsIDs.contains(id)
                let item = Item(name: name, id: id, servingsNumber: servingsNumber, servingsUnit: servingsUnit, carbonFootprint: carbonFootprint, isFavorite: isFavorite)
                
                lastCategory!.items.append(item)
                
                i += 1
            }
            i += 1
        }
        
        return menu
    }
    
    // check if item is already on the menu
    func menuContains(menu: [Category], id: String) -> Bool {
        for category in menu {
            for item in category.items {
                if item.id == id {
                    return true
                }
            }
        }
        
        return false
    }
    
    // Converts carbon footprint image to number
    func parseCarbonFootprint(image: Element) -> Int {
        var carbonFootprint = 0
        
        switch try! image.attr("title") {
        case "Low carbon foot print":
            carbonFootprint = 1
            break
        case "Medium carbon foot print":
            carbonFootprint = 2
            break
        case "High carbon foot print":
            carbonFootprint = 3
            break
        default:
            carbonFootprint = 0
        }
        
        return carbonFootprint
    }
    
    func parseServingsNumber(servings: [String.SubSequence]) -> Float {
        var servingsNumber: Float = 0
        
        if !servings[0].contains("/") { // example: 1
            servingsNumber = Float(Int(servings[0])!)
        }
        else if servings[0].contains("/") && servings[0].contains(" ") { // example: 1 1/2
            let mixedFraction = String(servings[0]).split(separator: " ")
            let fraction = String(mixedFraction[1]).split(separator: "/")
            servingsNumber = (Float(fraction[0])! + Float(mixedFraction[0])! * Float(fraction[1])!) / Float(fraction[1])!
        }
        else if servings[0].contains("/") { // example: 1/2
            let fraction = String(servings[0]).split(separator: "/")
            servingsNumber = Float(fraction[0])! / Float(fraction[1])!
        }
        
        return servingsNumber
    }
    
    func parseServingsUnit(servings: [String.SubSequence]) -> String {
        return String(servings[1]).lowercased()
    }
}
