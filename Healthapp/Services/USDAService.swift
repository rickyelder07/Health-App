//
//  USDAService.swift
//  Health App
//
//  Service for handling USDA FoodData Central API integration
//

import Foundation

/// Service for managing USDA FoodData Central API integration
class USDAService {
    
    /// Search for foods in USDA database
    /// - Parameters:
    ///   - query: Search query string
    ///   - pageSize: Number of results per page (default: 25, max: 200)
    ///   - pageNumber: Page number (default: 1)
    /// - Returns: USDA food search results
    func searchFoods(
        query: String,
        pageSize: Int = 25,
        pageNumber: Int = 1
    ) async throws -> USDAFoodSearchResponse {
        var components = URLComponents(string: "\(Configuration.USDA.apiBaseUrl)/foods/search")
        
        components?.queryItems = [
            URLQueryItem(name: "api_key", value: Configuration.USDA.apiKey),
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "pageSize", value: "\(pageSize)"),
            URLQueryItem(name: "pageNumber", value: "\(pageNumber)")
        ]
        
        guard let url = components?.url else {
            throw USDAError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw USDAError.requestFailed
        }
        
        let searchResponse = try JSONDecoder().decode(USDAFoodSearchResponse.self, from: data)
        return searchResponse
    }
    
    /// Get detailed information about a specific food
    /// - Parameter fdcId: FDC ID of the food
    /// - Returns: Detailed food information
    func getFoodDetails(fdcId: String) async throws -> USDAFoodDetail {
        var components = URLComponents(string: "\(Configuration.USDA.apiBaseUrl)/food/\(fdcId)")
        
        components?.queryItems = [
            URLQueryItem(name: "api_key", value: Configuration.USDA.apiKey)
        ]
        
        guard let url = components?.url else {
            throw USDAError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw USDAError.requestFailed
        }
        
        let foodDetail = try JSONDecoder().decode(USDAFoodDetail.self, from: data)
        return foodDetail
    }
}

/// USDA service errors
enum USDAError: LocalizedError {
    case invalidURL
    case requestFailed
    case invalidResponse
    case foodNotFound
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL for USDA request."
        case .requestFailed:
            return "USDA API request failed."
        case .invalidResponse:
            return "Invalid response from USDA API."
        case .foodNotFound:
            return "Food not found in USDA database."
        }
    }
}

