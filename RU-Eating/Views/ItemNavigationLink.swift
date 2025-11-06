//
//  ItemNavigationLink.swift
//  RU Eating
//
//  Created by alex on 9/25/24.
//

import SwiftUI

struct ItemNavigationLink : View {
    @ObservedObject var viewModel: ItemViewModel
    
    @AppStorage("useHearts") var useHearts: Bool = false
    
    var body: some View {
        if viewModel.isEditing {
            ItemLabel(viewModel: viewModel)
                .onTapGesture {
                    viewModel.item.isSelected.toggle()
                }
        }
        else {
            NavigationLink {
                ItemView(viewModel: viewModel)
            } label: {
                ItemLabel(viewModel: viewModel)
            }
            .swipeActions {
                Button(action: { viewModel.favorite() }) {
                    if useHearts {
                        Image(systemName: viewModel.item.isFavorite ? "heart.slash.fill" : "heart.fill")
                            .tint(.pink)
                    }
                    else {
                        Image(systemName: viewModel.item.isFavorite ? "star.slash.fill" : "star.fill")
                            .tint(.yellow)
                    }
                }
            }
        }
    }
}

struct ItemLabel : View {
    @ObservedObject var viewModel: ItemViewModel
    
    @AppStorage("carbonFootprints") var carbonFootprints: Bool = false
    @AppStorage("useHearts") var useHearts: Bool = false
    @AppStorage("filterIngredients") var filterIngredients: Bool = false
    
    var body: some View {
        HStack {
            if viewModel.isEditing {
                if viewModel.item.isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .imageScale(.large)
                        .foregroundStyle(.accent)
                }
                else {
                    Image(systemName: "circle")
                        .imageScale(.large)
                        .foregroundStyle(.gray)
                }
            }
            Label {
                Text(viewModel.item.name)
            } icon: {
                if viewModel.item.isFavorite {
                    if useHearts {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.pink)
                    }
                    else {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                    }
                }
                else if (filterIngredients && viewModel.containsRestrictions) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.accent)
                }
            }
            Spacer()
            if nutrients.contains(viewModel.sortBy) {
                if viewModel.item.amounts[viewModel.sortBy]! == nil {
                    Text("-")
                        .foregroundStyle(.gray)
                }
                else {
                    Text(String(formatFloat(n: viewModel.item.amounts[viewModel.sortBy]!!)) + nutrientUnits[viewModel.sortBy]!)
                        .foregroundStyle(.gray)
                }
            }
            else if viewModel.sortBy == "Carbon Footprint" || viewModel.sortBy == "None" {
                if (viewModel.sortBy != "None" || carbonFootprints) && viewModel.item.carbonFootprint > 0 {
                    Image(systemName: "leaf")
                        .imageScale(.medium)
                        .foregroundStyle(viewModel.carbonFootprintColor)
                }
            }
            else if viewModel.sortBy == "Ingredients" {
                if viewModel.item.ingredientsCount == nil {
                    Text("-")
                        .foregroundStyle(.gray)
                }
                else {
                    Text(String(viewModel.item.ingredientsCount!))
                        .foregroundStyle(.gray)
                }
            }
        }
        .listRowBackground(viewModel.item.isSelected ? Color(UIColor.systemGray4) : nil)
        .contentShape(Rectangle())
    }
}
