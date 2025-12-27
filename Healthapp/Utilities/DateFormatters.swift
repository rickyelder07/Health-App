//
//  DateFormatters.swift
//  Health App
//
//  Custom date formatters for JSON encoding/decoding
//

import Foundation

/// Custom date formatters for working with Supabase timestamps
enum DateFormatters {
    
    /// ISO8601 date formatter with fractional seconds for Supabase timestamps
    /// Format: "2024-01-15T10:30:45.123456+00:00"
    static let iso8601WithFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    /// Standard ISO8601 date formatter without fractional seconds
    /// Format: "2024-01-15T10:30:45+00:00"
    static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
    
    /// Date-only formatter for daily summaries
    /// Format: "2024-01-15"
    static let dateOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
    
    /// Display formatter for showing dates to users
    /// Format: "January 15, 2024"
    static let displayDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()
    
    /// Display formatter for showing dates and times to users
    /// Format: "Jan 15, 2024 at 10:30 AM"
    static let displayDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    /// JSONDecoder configured for Supabase date decoding
    static var supabaseDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Try ISO8601 with fractional seconds first (Supabase default)
            if let date = iso8601WithFractionalSeconds.date(from: dateString) {
                return date
            }
            
            // Fallback to standard ISO8601
            if let date = iso8601.date(from: dateString) {
                return date
            }
            
            // Fallback to date-only format
            if let date = dateOnly.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date string: \(dateString)"
            )
        }
        return decoder
    }
    
    /// JSONEncoder configured for Supabase date encoding
    static var supabaseEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}


