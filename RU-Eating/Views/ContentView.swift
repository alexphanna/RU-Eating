//
//  ContentView.swift
//  MenRU
//
//  Created by alex on 9/6/24.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            MenusView()
                .tabItem {
                    Label("Menus", systemImage: "fork.knife")
                }
            MealView()
                .tabItem {
                    Label("Meal", systemImage: "carrot")
                }
        }
    }
}
