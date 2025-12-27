//
//  HomeViewModel.swift
//  Health App
//
//  ViewModel for home screen displaying daily summary
//

import Foundation
import Combine

/// ViewModel for home screen with daily summary
@MainActor
class HomeViewModel: ObservableObject {
    @Published var dailySummary: DailySummary?
    @Published var foodEntries: [FoodEntry] = []
    @Published var activities: [Activity] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let userId: UUID
    
    init(userId: UUID) {
        self.userId = userId
    }
    
    /// Load today's summary data
    func loadTodaySummary() async {
        isLoading = true
        errorMessage = nil
        
        // TODO: Implement data loading from Supabase
        // For now, create a mock summary
        let mockSummary = DailySummary(
            userId: userId,
            date: Date(),
            weight: nil,
            caloriesConsumed: 0,
            proteinConsumed: 0,
            carbsConsumed: 0,
            fatConsumed: 0,
            caloriesBurnedBmr: 0,
            caloriesBurnedExercise: 0,
            totalCaloriesBurned: 0,
            netCalories: 0,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        dailySummary = mockSummary
        isLoading = false
    }
    
    /// Refresh all data
    func refresh() async {
        await loadTodaySummary()
    }
}

