//
//  AddFoodView.swift
//  Netfuel
//
//  View for adding food entries
//

import SwiftUI

struct AddFoodView: View {
    @StateObject private var viewModel = FoodSearchViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search food...", text: $viewModel.searchText)
                        .textFieldStyle(.plain)
                        .autocorrectionDisabled()
                        .onChange(of: viewModel.searchText) { _ in
                            viewModel.performSearch()
                        }
                    
                    if !viewModel.searchText.isEmpty {
                        Button {
                            viewModel.clearSearch()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding()
                
                // Content
                if viewModel.isSearching {
                    // Loading state
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Searching...")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                } else if let errorMessage = viewModel.errorMessage {
                    // Error state
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        Text(errorMessage)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                } else if !viewModel.searchResults.isEmpty {
                    // Results list
                    List(viewModel.searchResults) { food in
                        FoodSearchResultRow(food: food)
                    }
                    .listStyle(.plain)
                    
                } else if viewModel.searchText.isEmpty {
                    // Empty state - show quick actions
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Quick Add")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    QuickAddButton(title: "Recent Foods", icon: "clock.fill")
                                    QuickAddButton(title: "My Meals", icon: "star.fill")
                                    QuickAddButton(title: "Scan Barcode", icon: "barcode.viewfinder")
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        Spacer()
                        
                        VStack(spacing: 16) {
                            Image(systemName: "fork.knife.circle")
                                .font(.system(size: 60))
                                .foregroundColor(.secondary)
                            
                            Text("Search for foods")
                                .font(.title3)
                                .fontWeight(.medium)
                            
                            Text("Use USDA database to find nutrition info")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        Spacer()
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("Add Food")
        }
    }
}

struct FoodSearchResultRow: View {
    let food: USDAFood
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(food.description)
                .font(.headline)
                .lineLimit(2)
            
            if let brandName = food.brandName {
                Text(brandName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 16) {
                if let calories = food.calories {
                    NutrientLabel(icon: "flame.fill", value: "\(Int(calories))", unit: "cal", color: .orange)
                }
                if let protein = food.protein {
                    NutrientLabel(icon: "p.circle.fill", value: String(format: "%.1f", protein), unit: "g", color: .red)
                }
                if let carbs = food.carbohydrates {
                    NutrientLabel(icon: "c.circle.fill", value: String(format: "%.1f", carbs), unit: "g", color: .blue)
                }
                if let fat = food.fat {
                    NutrientLabel(icon: "f.circle.fill", value: String(format: "%.1f", fat), unit: "g", color: .purple)
                }
            }
            .font(.caption)
        }
        .padding(.vertical, 4)
    }
}

struct NutrientLabel: View {
    let icon: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text("\(value)\(unit)")
                .foregroundColor(.secondary)
        }
    }
}

struct QuickAddButton: View {
    let title: String
    let icon: String
    
    var body: some View {
        Button {
            // Handle quick add action
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(title)
                    .font(.subheadline)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.accentColor.opacity(0.1))
            .foregroundColor(.accentColor)
            .cornerRadius(20)
        }
    }
}

#Preview {
    AddFoodView()
}

