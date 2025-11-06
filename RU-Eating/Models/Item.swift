//
//  Item.swift
//  MenRU
//
//  Created by alex on 9/6/24.
//

import Foundation
import OrderedCollections
import SwiftSoup
import SwiftUI
import Observation

@Observable class Item: Hashable, Identifiable {
    static func == (lhs: Item, rhs: Item) -> Bool {
        return lhs.name == rhs.name
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(id)
        hasher.combine(portion)
    }
    
    private(set) var name : String
    private(set) var id : String
    private(set) var servingsNumber: Float
    private(set) var servingsUnit: String
    private(set) var servingsUnitPlural: String
    var servingSize: String {
        get {
            let number = servingsNumber.remainder(dividingBy: 1.0) == 0 ? String(servingsNumber.formatted(.number.precision(.fractionLength(0)))) : String(servingsNumber)
            return "\(number) \(servingsNumber == 1 ? servingsUnit : servingsUnitPlural)"
        }
    }
    private(set) var portion: Float // number of servings
    var isFavorite: Bool
    private(set) var carbonFootprint: Int
    
    var ingredients: String
    var ingredientsCount: Int? {
        if ingredients.isEmpty {
            return nil
        }
        return ingredients.filter { $0 == "," }.count + 1
    }
    
    var isSelected : Bool
    
    private var rawDailyValues: OrderedDictionary<String, Float?>
    var dailyValues:  OrderedDictionary<String, Float?> {
        return multiplyDictionary(dict: rawDailyValues, multiplier: portion)
    }
    private var rawAmounts: OrderedDictionary<String, Float?>
    var amounts:  OrderedDictionary<String, Float?> {
        return multiplyDictionary(dict: rawAmounts, multiplier: portion)
    }
    private(set) var fetched: Bool
    
    private(set) var address: URL?
    private(set) var excerpt: AttributedString
    
    var nameCombinations: [String] {
        var titles: [String] = []
        let titleArray = name.lowercased().split(separator: " ")
        
        for i in (0...titleArray.count - 1).reversed() {
            for j in 0...titleArray.count - 1 - i {
                var title = ""
                for k in 0...i {
                    title += "\(titleArray[j + k]) "
                }
                title.removeLast()
                titles.append(String(title))
                
                if title.hasSuffix("ies") { // patties -> patty
                    titles.append(String(title.dropLast("ies".count)) + "y")
                }
                else if title.last == "s" { 
                    titles.append(String(title.dropLast()))
                }
            }
        }
        
        return titles
    }
    
    init(name: String = "", id: String, servingsNumber: Float = 0, servingsUnit: String = "", portion: Float = 1, carbonFootprint: Int = 0, isFavorite: Bool = false) {
        self.name = name
        self.id = id
        self.servingsNumber = servingsNumber
        let unit = servingsUnit == "oz" || servingsUnit == "ozl" ? "oz" : servingsUnit.capitalized
        self.servingsUnit = unit
        self.servingsUnitPlural = unit + (unit == "Each" || unit == "oz" ? "" : "s")
        self.portion = portion
        self.carbonFootprint = carbonFootprint
        self.isFavorite = isFavorite
        
        self.ingredients = ""
        self.rawDailyValues = ["Calories" : 0, "Fat" : 0, "Carbohydrates" : 0, "Saturated Fat" : 0, "Dietary Fiber" : 0, "Trans Fat" : nil, "Sugars" : 0, "Cholesterol" : nil, "Protein" : 0, "Sodium" : 0, "Iron" : 0, "Calcium" : 0]
        self.rawAmounts = ["Calories" : 0, "Fat" : 0, "Carbohydrates" : 0, "Saturated Fat" : 0, "Dietary Fiber" : 0, "Trans Fat" : 0, "Sugars" : 0, "Cholesterol" : 0, "Protein" : 0, "Sodium" : 0, "Iron" : nil, "Calcium" : nil]
        self.fetched = false
        self.excerpt = ""
        self.isSelected = false
    }
    
    func incrementPortion() {
        portion += 0.5
    }
    
    func decrementPoriton() {
        portion -= 0.5
        if portion < 0 { portion = 0 }
    }
    
    func fetchData() async {
        fetched = false
        if let doc = try? await fetchDoc(url: URL(string: "https://menuportal23.dining.rutgers.edu/foodpronet/label.aspx?&RecNumAndPort=" + id + "*1")!) {
            if hasNutritionalReport(doc: doc) {
                parseIngredients(doc: doc)
                parseAmounts(doc: doc)
                parseDailyValues(doc: doc)
            }
        }
        fetched = true
    }
    
    func fetchExcerpt() async {
        let titles: [String] = nameCombinations
        
        for title in titles {
            let encodedTitle = title.replacingOccurrences(of: " ", with: "_")
            let urlString = "https://en.wikipedia.org/w/api.php?action=query&format=json&prop=extracts|categories&exintro=true&explaintext=true&titles=\(encodedTitle)&redirects=true&cllimit=max"
            let request = URLRequest(url: URL(string: urlString)!)
            
            do {
                let data = try await URLSession.shared.data(for: request).0
                
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any],
                   let query = json["query"] as? [String : Any],
                   let pages = query["pages"] as? [String : Any],
                   let page = pages.values.first as? [String : Any],
                   let extract = page["extract"] as? String,
                   let categories = page["categories"] as? [[String: Any]] {
                    if !extract.isEmpty && isFoodRelated(categories: categories) {
                        address = URL(string: "https://en.wikipedia.org/wiki/\(encodedTitle)")
                        excerpt = boldTerms(text: extractFirstSentence(text: extract), terms: titles.filter { !$0.contains(" ") } )
                        break
                    }
                }
            } catch {
                // do nothing
            }
        }
    }
    
    func isFoodRelated(categories: [[String : Any]]) -> Bool {
        let foodCategories = ["food", "dish", "cuisine", /*"cooking",*/ "fruit", "berries", "berry", "vegetable", "sandwich"]
        
        return categories.contains { category in
            for _title in (category["title"] as? String)!.split(separator: " ") {
                for foodCategory in foodCategories {
                    if _title.lowercased().hasSuffix(foodCategory) || _title.lowercased().hasPrefix(foodCategory) {
                        return true
                    }
                }
            }
            return false
        }
    }
    
    func parseIngredients(doc: Document) {
        if let element = try? doc.select("div.col-md-12 > p").array().first {
            let text = try! element.text()
            let textArray = text.split(separator: "\u{00A0}")
            
            ingredients = String(textArray[textArray.count - 1]).capitalized;
        }
    }
    
    func parseAmounts(doc: Document) {
        let elements = try! doc.select("div#nutritional-info table td, div#nutritional-info p:contains(Calories)").array()
        for element in elements {
            let text = try! element.text()
            let textArray = text.split(separator: "\u{00A0}")
            
            if textArray.count != 2 || perfectNutrients[String(textArray[0])] == nil {
                continue
            }
            
            let nutrient = perfectNutrients[String(textArray[0])]!
            if var value = Float(textArray[1].replacingOccurrences(of: nutrientUnits[nutrient]!, with: "")) {
                value *= Float(servingsNumber)
                if nutrient == "Cholesterol" {
                    rawDailyValues[nutrient] = value / 3
                }
                rawAmounts[nutrient] = value
            }
        }
    }
    
    func parseDailyValues(doc: Document) {
        let elements = try! doc.select("div#nutritional-info ul li").array()
        for element in elements {
            let text = try! element.text()
            let textArray = text.split(separator: " \u{00A0}\u{00A0}")
            
            if textArray.count != 2 || perfectNutrients[String(textArray[0])] == nil {
                continue
            }
            
            let nutrient = perfectNutrients[String(textArray[0])]!
            if var value = Float(textArray[1].replacingOccurrences(of: "%", with: "")) {
                value *= Float(servingsNumber)
                if nutrient == "Iron" || nutrient == "Calcium" {
                    rawAmounts[nutrient] = value / 100 * (nutrient == "Iron" ? 18 : 1300)
                }
                rawDailyValues[nutrient] = value
            }
        }
    }
}
