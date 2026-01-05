//
//  ProfileService.swift
//  Netfuel
//
//  Service for managing user profile data in Supabase
//

import Foundation
import Supabase

/// Service for managing user profiles
class ProfileService {
    private let supabase = SupabaseClient.shared
    
    // MARK: - Request Types
    
    /// Request struct for creating/updating a profile
    private struct UpdateProfileRequest: Encodable {
        let name: String?
        let weight: Double?
        let height: Double?
        let age: Int?
        let gender: String?
        let activityLevel: String?
        let bmr: Double
        let tdee: Double
        let updatedAt: String

        enum CodingKeys: String, CodingKey {
            case name
            case weight
            case height
            case age
            case gender
            case activityLevel = "activity_level"
            case bmr
            case tdee
            case updatedAt = "updated_at"
        }
    }
    
    // MARK: - Profile Operations
    
    /// Fetch user profile from database
    /// - Parameter userId: User's UUID
    /// - Returns: User profile
    /// - Throws: Error if fetch fails
    func fetchProfile(userId: UUID) async throws -> User {
        do {
            let response = try await supabase.client
                .from("users")
                .select("id, weight, height, age, gender, activity_level, bmr, tdee, created_at, updated_at")
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
            
            let decoder = JSONDecoder()
            // Don't use convertFromSnakeCase - User model has explicit CodingKeys
            decoder.dateDecodingStrategy = .iso8601
            
            let user = try decoder.decode(User.self, from: response.data)
            print("✅ Profile fetched for user: \(userId)")
            
            return user
            
        } catch {
            print("❌ Failed to fetch profile: \(error)")
            throw ProfileError.fetchFailed(error.localizedDescription)
        }
    }
    
    /// Create a new user profile (actually updates the row created by the database trigger)
    /// - Parameters:
    ///   - userId: User's UUID
    ///   - weight: Weight in kg
    ///   - height: Height in cm
    ///   - age: Age in years
    ///   - gender: User's gender
    ///   - activityLevel: Activity level
    /// - Returns: Created user profile
    /// - Throws: Error if creation fails
    /// - Note: The row already exists from the handle_new_user() trigger, so we UPDATE instead of INSERT
    func createProfile(
        userId: UUID,
        weight: Double,
        height: Double,
        age: Int,
        gender: Gender,
        activityLevel: ActivityLevel
    ) async throws -> User {
        do {
            // Calculate BMR and TDEE
            let bmr = calculateBMR(weight: weight, height: height, age: age, gender: gender)
            let tdee = calculateTDEE(bmr: bmr, activityLevel: activityLevel)
            
            let profileData = UpdateProfileRequest(
                name: nil,
                weight: weight,
                height: height,
                age: age,
                gender: gender.rawValue,
                activityLevel: activityLevel.rawValue,
                bmr: bmr,
                tdee: tdee,
                updatedAt: ISO8601DateFormatter().string(from: Date())
            )
            
            // Use UPDATE instead of INSERT because row already exists from trigger
            let response = try await supabase.client
                .from("users")
                .update(profileData)
                .eq("id", value: userId.uuidString)
                .select()
                .single()
                .execute()
            
            // Debug: Print raw JSON response
            if let jsonString = String(data: response.data, encoding: .utf8) {
                print("📥 Raw Supabase response for createProfile:")
                print(jsonString)
            }
            
            let decoder = JSONDecoder()
            // Don't use convertFromSnakeCase - User model has explicit CodingKeys
            decoder.dateDecodingStrategy = .iso8601
            
            let user = try decoder.decode(User.self, from: response.data)
            print("✅ Profile created for user: \(userId)")
            
            return user
            
        } catch {
            print("❌ Failed to create profile: \(error)")
            throw ProfileError.createFailed(error.localizedDescription)
        }
    }
    
    /// Update user profile
    /// - Parameters:
    ///   - userId: User's UUID
    ///   - weight: Weight in kg (optional)
    ///   - height: Height in cm (optional)
    ///   - age: Age in years (optional)
    ///   - gender: User's gender (optional)
    ///   - activityLevel: Activity level (optional)
    /// - Returns: Updated user profile
    /// - Throws: Error if update fails
    func updateProfile(
        userId: UUID,
        name: String? = nil,
        weight: Double? = nil,
        height: Double? = nil,
        age: Int? = nil,
        gender: Gender? = nil,
        activityLevel: ActivityLevel? = nil
    ) async throws -> User {
        do {
            // Fetch current profile to get existing values
            let currentProfile = try await fetchProfile(userId: userId)

            // Use provided values or fall back to current values
            let finalWeight = weight ?? currentProfile.weight ?? 0
            let finalHeight = height ?? currentProfile.height ?? 0
            let finalAge = age ?? currentProfile.age ?? 0
            let finalGender = gender ?? currentProfile.gender ?? .other
            let finalActivityLevel = activityLevel ?? currentProfile.activityLevel ?? .sedentary

            // Calculate BMR and TDEE with new values
            let bmr = calculateBMR(weight: finalWeight, height: finalHeight, age: finalAge, gender: finalGender)
            let tdee = calculateTDEE(bmr: bmr, activityLevel: finalActivityLevel)

            let updateData = UpdateProfileRequest(
                name: name,
                weight: weight,
                height: height,
                age: age,
                gender: gender?.rawValue,
                activityLevel: activityLevel?.rawValue,
                bmr: bmr,
                tdee: tdee,
                updatedAt: ISO8601DateFormatter().string(from: Date())
            )
            
            let response = try await supabase.client
                .from("users")
                .update(updateData)
                .eq("id", value: userId.uuidString)
                .select()
                .single()
                .execute()
            
            let decoder = JSONDecoder()
            // Don't use convertFromSnakeCase - User model has explicit CodingKeys
            decoder.dateDecodingStrategy = .iso8601
            
            let user = try decoder.decode(User.self, from: response.data)
            print("✅ Profile updated for user: \(userId)")
            
            return user
            
        } catch {
            print("❌ Failed to update profile: \(error)")
            throw ProfileError.updateFailed(error.localizedDescription)
        }
    }
    
    /// Update only the user's weight
    /// - Parameters:
    ///   - userId: User's UUID
    ///   - weight: New weight in kg
    /// - Returns: Updated user profile
    /// - Throws: Error if update fails
    func updateWeight(userId: UUID, weight: Double) async throws -> User {
        return try await updateProfile(userId: userId, weight: weight)
    }
    
    // MARK: - Calculations
    
    /// Calculate Basal Metabolic Rate using Mifflin-St Jeor Equation
    /// This matches the User model's calculateBMR() method and the database function
    /// - Parameters:
    ///   - weight: Weight in kg
    ///   - height: Height in cm
    ///   - age: Age in years
    ///   - gender: User's gender
    /// - Returns: BMR in calories per day
    func calculateBMR(weight: Double, height: Double, age: Int, gender: Gender) -> Double {
        let baseBMR = (10 * weight) + (6.25 * height) - (5 * Double(age))
        
        switch gender {
        case .male:
            return baseBMR + 5
        case .female:
            return baseBMR - 161
        case .other:
            return baseBMR - 78 // Average of male and female
        }
    }
    
    /// Calculate Total Daily Energy Expenditure
    /// This matches the User model's calculateTDEE() method and the database function
    /// - Parameters:
    ///   - bmr: Basal Metabolic Rate
    ///   - activityLevel: User's activity level
    /// - Returns: TDEE in calories per day
    func calculateTDEE(bmr: Double, activityLevel: ActivityLevel) -> Double {
        return bmr * activityLevel.multiplier
    }

    /// Delete user account and all associated data
    /// - Parameter userId: User's UUID
    /// - Throws: Error if deletion fails
    func deleteUserAccount(userId: UUID) async throws {
        // Note: In Supabase, you should set up CASCADE delete on foreign keys
        // or delete related records manually. For now, we'll just delete the user record.
        // The database should handle cascading deletes via foreign key constraints.

        do {
            try await supabase.client
                .from("users")
                .delete()
                .eq("id", value: userId.uuidString)
                .execute()

            print("✅ User account deleted successfully")
        } catch {
            print("❌ Failed to delete user account: \(error)")
            throw ProfileError.updateFailed(error.localizedDescription)
        }
    }
}

/// Profile service errors
enum ProfileError: LocalizedError {
    case fetchFailed(String)
    case createFailed(String)
    case updateFailed(String)
    case invalidData
    case userNotFound
    
    var errorDescription: String? {
        switch self {
        case .fetchFailed(let message):
            return "Failed to fetch profile: \(message)"
        case .createFailed(let message):
            return "Failed to create profile: \(message)"
        case .updateFailed(let message):
            return "Failed to update profile: \(message)"
        case .invalidData:
            return "Invalid profile data provided."
        case .userNotFound:
            return "User profile not found."
        }
    }
}

