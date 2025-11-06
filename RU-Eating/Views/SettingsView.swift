//
//  SettingsView.swift
//  MenRU
//
//  Created by alex on 9/7/24.
//

import SwiftUI

struct SettingsView : View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openURL
    
    @AppStorage("filterIngredients") var filterIngredients: Bool = false
    @AppStorage("restrictions") var restrictions: [String] = []
    @AppStorage("hideRestricted") var hideRestricted: Bool = false
    @AppStorage("favoriteItems") var favoriteItems: [String] = []
    @AppStorage("numberOfUses") var numberOfUses: Int = 0
    @AppStorage("hideZeros") var hideZeros: Bool = false
    @AppStorage("hideNils") var hideNils: Bool = false
    @AppStorage("carbonFootprints") var carbonFootprints: Bool = true
    @AppStorage("fdaDailyValues") var fdaDailyValues: Bool = false
    @AppStorage("lastDiningHall") var lastDiningHall: String = "Busch"
    @AppStorage("useHearts") var useHearts: Bool = false
    @AppStorage("itemDescriptions") var itemDescriptions: Bool = true
    
    var body : some View {
        NavigationStack {
            VStack {
                Form {
                    Section {
                        NavigationLink("Favorites") {
                            List {
                                ForEach(favoriteItems, id: \.self) { item in
                                    Text(item)
                                }
                                .onDelete(perform: { favoriteItems.remove(atOffsets: $0) })
                            }
                            .navigationTitle("Favorites")
                            .toolbar {
                                ToolbarItem(placement: .topBarTrailing) {
                                    EditButton()
                                }
                            }
                        }
                        Toggle(isOn: $itemDescriptions) {
                            Text("Show Item Descriptions")
                        }
                        Toggle(isOn: $useHearts) {
                            Text("Use Hearts for Favorites")
                        }
                        Toggle(isOn: $carbonFootprints) {
                            Text("Carbon Footprints")
                        }
                    } header: {
                        Text("General")
                    } footer: {
                        Text("Display a \(Image(systemName: "leaf.fill")) next to items with the color corresponding to the carbon footprint: green = low, orange = medium, red = high. Not all items have carbon footprint information.")
                    }
                    Section {
                        Toggle(isOn: $hideZeros) {
                            Text("Hide Nutrients With Zero Value")
                        }
                        Toggle(isOn: $hideNils) {
                            Text("Hide Nutrients With No Value")
                        }
                        Toggle(isOn: $fdaDailyValues) {
                            Text("FDA Daily Values")
                        }
                    } header: {
                        Text("Nutrition Facts")
                    } footer: {
                        Text("Calculate extra nutrient values not in the source menu (Cholesterol, Iron, and Calcium).")
                    }
                    Section {
                        Toggle(isOn: $filterIngredients) {
                            Text("Filter Ingredients")
                        }
                        if (filterIngredients) {
                            Toggle(isOn: $hideRestricted) {
                                Text("Hide Restricted Items")
                            }
                            NavigationLink("Dietary Restrictions") {
                                RestrictionsView()
                            }
                        }
                    } header: {
                        Text("Dietary Restrictions")
                    } footer: {
                        Text("Filter through item's ingredients and display a \(Image(systemName: "exclamationmark.triangle.fill")) next to items or hide items that may contain dietary restrictions.")
                    }
                    Section("Appearance") {
                        if UIApplication.shared.supportsAlternateIcons {
                            NavigationLink("App Icon") {
                                List {
                                    ForEach(["Scarlet", "White", "Blue"], id: \.self) { icon in
                                        Button {
                                            UIApplication.shared.setAlternateIconName(icon == "Scarlet" ? nil : icon)
                                        } label: {
                                            HStack {
                                                Image(icon + "Image")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 64, height: 64)
                                                    .clipShape(.rect(cornerRadius: 12))
                                                Text(icon)
                                                    .foregroundStyle(Color(uiColor: .label))
                                            }
                                        }
                                    }
                                }
                                .navigationTitle("App Icon")
                            }
                        }
                    }
                    Section("Credits") { // Inspired by delta
                        Button {
                            openURL(URL(string: "https://www.github.com/alexphanna")!)
                        } label: {
                            HStack {
                                Text("Alex Hanna")
                                    .foregroundStyle(Color(uiColor: .label))
                                Spacer()
                                Text("Developer")
                                    .foregroundStyle(.gray)
                                NavigationLink(destination: EmptyView(), label: { EmptyView() })
                                    .fixedSize()
                                    .foregroundStyle(Color(uiColor: .label))
                            }
                        }
                        Button {
                            openURL(URL(string: "https://www.instagram.com/avg4cyl")!)
                        } label: {
                            HStack {
                                Text("Frankie Gonzales")
                                    .foregroundStyle(Color(uiColor: .label))
                                Spacer()
                                Text("Name")
                                    .foregroundStyle(.gray)
                                NavigationLink(destination: EmptyView(), label: { EmptyView() })
                                    .fixedSize()
                                    .foregroundStyle(Color(uiColor: .label))
                            }
                        }
                    }
                    Section {
                        Link(destination: URL(string: "mailto:alex.hanna@rutgers.edu")!, label: {
                            Label("Email the Developer", systemImage: "envelope")
                                .foregroundStyle(.foreground)
                        })
                        Link(destination: URL(string: "https://www.github.com/alexphanna/RU-Eating/issues/new")!, label: {
                            Label("Create an Issue", systemImage: "smallcircle.fill.circle")
                                .foregroundStyle(.foreground)
                        })
                        Link(destination: URL(string: "https://apps.apple.com/us/app/ru-eating/id6692608792?action=write-review")!, label: {
                            Label("Write a Review", systemImage: "message")
                                .foregroundStyle(.foreground)
                        })
                    } header: {
                        Text("Feedback")
                    } footer: {
                        Text("App Version: 1.3.0")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .navigationTitle("Settings")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done", action: { dismiss() })
                    }
                }
            }
        }
    }
}
