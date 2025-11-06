//
//  AllergenView.swift
//  MenRU
//
//  Created by alex on 9/7/24.
//

import SwiftUI

struct RestrictionsView : View {
    @State private var isTextFieldShowing: Bool = false
    @FocusState private var isTextFieldFocused: Bool
    @State private var ingredient: String = ""
    
    @ObservationIgnored @AppStorage("restrictions") var restrictions: [String] = []
    
    private var tapGesture: some Gesture {
        isTextFieldShowing ? (TapGesture().onEnded {
            withAnimation(.easeOut) {
                isTextFieldShowing = false
                ingredient = ""
            }}) : nil
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(restrictions, id: \.self) { restriction in
                        Text(restriction)
                    }
                    .onDelete(perform: { restrictions.remove(atOffsets: $0) })
                    if isTextFieldShowing {
                        TextField("Ingredient Name", text: $ingredient)
                            .submitLabel(.done)
                            .focused($isTextFieldFocused)
                            .onSubmit {
                                isTextFieldShowing = false
                                if !ingredient.isEmpty {
                                    restrictions.append(ingredient.trimmingCharacters(in: .whitespaces))
                                    ingredient = ""
                                }
                            }
                            .onTapGesture { }
                    }
                } footer: {
                    if isTextFieldShowing {
                        Text("Enter dietary restrictions singularly for increased filtering accuracy, for example enter \"Peanut\", not \"Peanuts\". Dietary restrictions are not case-sensitive.")
                    }
                }
            }
            .overlay {
                if restrictions.count == 0 && !isTextFieldShowing {
                    ContentUnavailableView {
                        Text("No Ingredients")
                            .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                    } description: {
                        Text("Ingredients you've added will appear here.")
                    } actions: {
                        Button(action: showTextField) {
                            Text("Add Ingredient")
                        }
                    }
                }
            }
            .navigationTitle("Dietary Restrictions")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: showTextField) {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                }
            }
        }
        .gesture(tapGesture)
    }
    
    func showTextField() {
        withAnimation(.easeIn) {
            isTextFieldShowing = true
            isTextFieldFocused.toggle()
        }
    }
}
