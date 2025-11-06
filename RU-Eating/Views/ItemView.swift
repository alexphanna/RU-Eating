//
//  ItemView.swift
//  MenRU
//
//  Created by alex on 9/6/24.
//

import SwiftUI
import SwiftSoup
import SwiftData

struct ItemView: View {
    @ObservedObject var viewModel: ItemViewModel
    
    @AppStorage("carbonFootprints") var carbonFootprints: Bool = true
    @AppStorage("hideRestricted") var hideRestricted: Bool = false
    @AppStorage("itemDescriptions") var itemDescriptions: Bool = true
    @AppStorage("useHearts") var useHearts: Bool = false
    @AppStorage("filterIngredients") var filterIngredients: Bool = false
    
    var body : some View {
        if (hideRestricted && !viewModel.containsRestrictions) || !hideRestricted {
            NavigationStack {
                VStack {
                    if !viewModel.item.fetched {
                        ProgressView()
                    }
                    else if viewModel.item.ingredients.isEmpty {
                        Text("Nutritional information is not available for this item")
                    }
                    else {
                        List {
                            if filterIngredients && viewModel.containsRestrictions {
                                Section("Warning") {
                                    Label("Item may contain dietary restrictions.", systemImage: "exclamationmark.triangle.fill")
                                }
                                .headerProminence(.increased)
                            }
                            if itemDescriptions && !viewModel.item.excerpt.characters.isEmpty {
                                Section {
                                    Text(viewModel.item.excerpt)
                                } header: {
                                    Text("Description")
                                } footer: {
                                    if viewModel.item.address != nil {
                                        Link("Wikipedia", destination: viewModel.item.address!)
                                            .font(.footnote)
                                    }
                                }
                                .headerProminence(.increased)
                            }
                            NutritionView(viewModel: NutritionViewModel(category: Category(name: "", items: [viewModel.item]), showServingSize: true))
                            Section("Ingredients") {
                                Text(viewModel.item.ingredients)
                                    .font(.footnote)
                                    .italic()
                                    .foregroundStyle(.gray)
                            }
                            .headerProminence(.increased)
                        }
                    }
                }
                .onAppear {
                    if itemDescriptions {
                        Task {
                            await viewModel.item.fetchExcerpt()
                        }
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        HStack {
                            Text(viewModel.item.name)
                                .font(.headline)
                            if carbonFootprints && viewModel.item.carbonFootprint > 0 {
                                Image(systemName: "leaf")
                                    .imageScale(.medium)
                                    .foregroundStyle(viewModel.carbonFootprintColor)
                            }
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        // toggle was changing background color, so I use button
                        Button(action: { viewModel.favorite() }) {
                            if useHearts {
                                Image(systemName: viewModel.item.isFavorite ? "heart.fill" : "heart")
                                    .foregroundStyle(.pink)
                            }
                            else {
                                Image(systemName: viewModel.item.isFavorite ? "star.fill" : "star")
                                    .foregroundStyle(.yellow)
                            }
                        }
                    }
                }
            }
        }
    }
}
