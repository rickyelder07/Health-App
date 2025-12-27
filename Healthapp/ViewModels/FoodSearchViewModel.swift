//
//  FoodSearchViewModel.swift
//  Health App
//
//  ViewModel for food search functionality
//

import Foundation
import Combine

/// ViewModel for searching and selecting foods from USDA database
@MainActor
class FoodSearchViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var searchResults: [USDAFood] = []
    @Published var isSearching: Bool = false
    @Published var errorMessage: String?
    
    private let usdaService = USDAService()
    private var searchTask: Task<Void, Never>?
    
    /// Perform food search with debouncing
    func performSearch() {
        // Cancel previous search
        searchTask?.cancel()
        
        // Clear results if search is empty
        guard !searchText.isEmpty else {
            searchResults = []
            return
        }
        
        // Debounce search by 0.5 seconds
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            guard !Task.isCancelled else { return }
            
            await executeSearch()
        }
    }
    
    /// Execute the actual search
    private func executeSearch() async {
        isSearching = true
        errorMessage = nil
        
        do {
            let response = try await usdaService.searchFoods(
                query: searchText,
                pageSize: 25,
                pageNumber: 1
            )
            
            searchResults = response.foods
            
            if searchResults.isEmpty {
                errorMessage = "No foods found for '\(searchText)'"
            }
            
        } catch {
            errorMessage = "Search failed: \(error.localizedDescription)"
            searchResults = []
        }
        
        isSearching = false
    }
    
    /// Clear search
    func clearSearch() {
        searchText = ""
        searchResults = []
        errorMessage = nil
        searchTask?.cancel()
    }
}

