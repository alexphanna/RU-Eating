//
//  NutritionView.swift
//  MenRU
//
//  Created by alex on 9/8/24.
//

import SwiftUI

struct NutritionView: View {
    @ObservedObject var viewModel: NutritionViewModel
    
    @AppStorage("hideNils") var hideNils = false
    @AppStorage("hideZeros") var hideZeros = false
    
    var body: some View {
        Section {
            Picker("Unit", selection: $viewModel.unit) {
                ForEach(["Amounts", "% Daily Values"], id: \.self) { unit in
                    Text(unit)
                }
            }
            .pickerStyle(.segmented)
            .listRowSeparator(.hidden)
            .padding()
            .listRowInsets(EdgeInsets())
            if viewModel.showServingSize {
                LabeledContent("Serving Size", value: viewModel.category.items[0].servingSize)
                    .fontWeight(.bold)
            }
            if viewModel.values["Calories"]! != nil { // skips items without nutrients
                ForEach(Array(viewModel.values.keys), id: \.self) { key in
                    if key == "Calories" {
                        LabeledContent(key, value: String(formatFloat(n: viewModel.values[key]!!)) + (viewModel.unit == "Amounts" ? nutrientUnits[key]! : "%"))
                            .fontWeight(key == "Calories" ? .bold : .regular)
                    }
                    else {
                        if viewModel.values[key]! == nil && !hideNils {
                            LabeledContent(key, value: "-")
                        }
                        else if viewModel.values[key]! != nil && (viewModel.values[key]!! != 0 || !hideZeros) {
                            LabeledContent(key, value: formatFloat(n: viewModel.values[key]!!) + (viewModel.unit == "Amounts" ? nutrientUnits[key]! : "%"))
                        }
                    }
                }
            }
        } header: {
            Text("Nutrition Facts")
        } footer: {
            Text("Percent Daily Values are based on a 2,000 calorie diet.")
        }
        .headerProminence(.increased)
    }
}
