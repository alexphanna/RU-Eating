//
//  MenuSectionView.swift
//  MenRU
//
//  Created by alex on 9/7/24.
//

import SwiftUI

struct CategoryView : View {
    @Bindable var viewModel: CategoryViewModel
    
    var body : some View {
        if viewModel.isExpandable {
            Section(
                isExpanded: $viewModel.isExpanded,
                content: {
                    ForEach(viewModel.sortedItems) { item in
                        ItemNavigationLink(viewModel: ItemViewModel(item: item, sortBy: viewModel.sortBy, isEditing: viewModel.isEditing))
                    }
                },
                header: {
                    Text(viewModel.category.name)
                })
            .headerProminence(.increased)
        }
        else {
            Section(content: {
                ForEach(viewModel.sortedItems) { item in
                    ItemNavigationLink(viewModel: ItemViewModel(item: item, sortBy: viewModel.sortBy, isEditing: viewModel.isEditing))
                }
            }, header: {
                Text("Name")
            })
        }
    }
}
