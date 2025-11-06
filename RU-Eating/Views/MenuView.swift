//
//  MenuView.swift
//  MenRU
//
//  Created by alex on 9/8/24.
//

import SwiftUI
import HDatePicker

struct MenuView: View {
    @State var viewModel: MenuViewModel
    
    var body: some View {
        NavigationLink {
            VStack(spacing: 0) {
                HDatePicker(selectedDay: $viewModel.date)
                    .onChange(of: viewModel.date) {
                        Task {
                            await viewModel.updateMenu()
                        }
                    }
                Divider()
                NavigationStack {
                    List {
                        if viewModel.groupByCategory {
                            ForEach(viewModel.menu, id: \.self) { category in
                                CategoryView(viewModel: CategoryViewModel(category: category, sortBy: viewModel.sortBy, sortOrder: viewModel.sortOrder, isEditing: viewModel.isEditing))
                            }
                        }
                        else {
                            CategoryView(viewModel: CategoryViewModel(category: viewModel.items, sortBy: viewModel.sortBy, sortOrder: viewModel.sortOrder, isExpandable: false, isEditing: viewModel.isEditing))
                        }
                    }
                    .overlay {
                        if viewModel.rawMenu.isEmpty && !viewModel.fetched {
                            ProgressView()
                        }
                        else if viewModel.rawMenu.isEmpty && viewModel.fetched {
                            ContentUnavailableView {
                                Text("No Items")
                                    .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                            }
                        }
                        else if viewModel.menu.isEmpty {
                            ContentUnavailableView("No Results", systemImage: "")
                        }
                    }
                    .listStyle(.sidebar)
                    .navigationTitle(viewModel.meal)
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarBackButtonHidden(viewModel.isEditing)
                    .toolbar(viewModel.isEditing ? .hidden : .visible, for: .tabBar)
                    .toolbar {
                        if viewModel.isEditing {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") {
                                    withAnimation(.easeInOut) {
                                        viewModel.isEditing = false
                                    }
                                    viewModel.resetSelection()
                                }
                            }
                            ToolbarItemGroup(placement: .bottomBar) {
                                Spacer()
                                Button("Copy") {
                                    UIPasteboard.general.string = viewModel.selection.joined(separator: "\n")
                                    withAnimation(.easeInOut) {
                                        viewModel.isEditing = false
                                    }
                                    viewModel.resetSelection()
                                }
                            }
                        }
                        else {
                            ToolbarTitleMenu {
                                Picker("Meal", selection: $viewModel.meal) {
                                    ForEach(viewModel.place.hasTakeout ? meals + ["Takeout"] : meals, id: \.self) { meal in
                                        Text(meal)
                                    }
                                }
                                .onChange(of: viewModel.meal) {
                                    Task {
                                        await viewModel.updateMenu()
                                    }
                                }
                                .pickerStyle(.inline)
                            }
                            ToolbarItem(placement: .topBarTrailing) {
                                Menu {
                                    Section {
                                        if viewModel.randomItem != nil {
                                            NavigationLink {
                                                ItemView(viewModel: ItemViewModel(item: viewModel.randomItem!, sortBy: viewModel.sortBy, isEditing: viewModel.isEditing))
                                                    .onAppear {
                                                        viewModel.randomItem = viewModel.items.items.randomElement() // update random element
                                                    }
                                            } label: {
                                                Label("Random Item", systemImage: "dice")
                                            }
                                        }
                                        Button("Select Items", systemImage: "checkmark.circle", action: { viewModel.isEditing.toggle() })
                                        Picker(selection: $viewModel.filter ) {
                                            Section {
                                                Label("All Items", systemImage: "carrot").tag("All Items")
                                            }
                                            Section {
                                                Label("Favorites", systemImage: "star").tag("Favorites")
                                                Label("Low Carbon Footprint", systemImage: "leaf").tag("Low Carbon Footprint")
                                            }
                                        } label: {
                                            Label("Filter", systemImage: viewModel.filter == "All Items" ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                                            Text(viewModel.filter)
                                        }
                                        .pickerStyle(.menu)
                                        Menu {
                                            Section {
                                                Picker("", selection: $viewModel.sortBy) {
                                                    Label("Name", systemImage: "textformat.alt").tag("Name")
                                                    Label("Carbon Footprint", systemImage: "leaf").tag("Carbon Footprint")
                                                    Label("Calories", systemImage: "bolt").tag("Calories")
                                                        .selectionDisabled(!viewModel.fetched)
                                                    Label("Fat", systemImage: "drop").tag("Fat")
                                                        .selectionDisabled(!viewModel.fetched)
                                                    Label("Protein", systemImage: "fish").tag("Protein")
                                                        .selectionDisabled(!viewModel.fetched)
                                                    Label("Carbohydrates", systemImage: "carrot").tag("Carbohydrates")
                                                        .selectionDisabled(!viewModel.fetched)
                                                    Label("Ingredients", systemImage: "number").tag("Ingredients")
                                                        .selectionDisabled(!viewModel.fetched)
                                                }
                                            }
                                            Section {
                                                Picker("", selection: $viewModel.sortOrder) {
                                                    Label("Ascending", systemImage: "arrow.down")
                                                        .tag("Ascending")
                                                    Label("Descending", systemImage: "arrow.up")
                                                        .tag("Descending")
                                                }
                                            }
                                        } label: {
                                            Label("Sort By" , systemImage: "arrow.up.arrow.down")
                                            Text(viewModel.sortBy)
                                        }
                                        .pickerStyle(.inline)
                                        Picker(selection: $viewModel.groupByCategory ) {
                                            Text("On")
                                                .tag(true)
                                            Text("Off")
                                                .tag(false)
                                        } label: {
                                            Label("Group By Category", systemImage: "list.bullet.below.rectangle")
                                            Text(viewModel.groupByCategory ? "On" : "Off")
                                        }
                                        .pickerStyle(.menu)
                                    }
                                    Link(destination: viewModel.place.getURL(meal: viewModel.meal, date: viewModel.date), label: {
                                        Label("View Source", systemImage: "link")
                                    })
                                } label: {
                                    Image(systemName: "ellipsis.circle")
                                }
                            }
                        }
                    }
                    .onAppear {
                        Task {
                            if viewModel.menu.isEmpty {
                                await viewModel.updateMenu()
                            }
                        }
                    }
                }
            }
        } label: {
            VStack (alignment: HorizontalAlignment.leading) {
                Text(viewModel.place.name)
                Text(viewModel.place.hasTakeout ? "Dine In / Takeout" : "Dine In")
                    .font(.footnote)
                    .italic()
                    .foregroundStyle(.gray)
            }
        }
    }
}
