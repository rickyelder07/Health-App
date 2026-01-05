//
//  Logger.swift
//  Health App
//
//  Logging utility for debugging and error tracking
//

import Foundation
import os.log

/// Custom logger for the app
class Logger {
    
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.netfuel"
    
    /// Logger categories
    enum Category: String {
        case general = "General"
        case network = "Network"
        case auth = "Authentication"
        case database = "Database"
        case ui = "UI"
        case strava = "Strava"
        case usda = "USDA"
    }
    
    /// Log levels
    enum Level {
        case debug
        case info
        case warning
        case error
        case fault
        
        var osLogType: OSLogType {
            switch self {
            case .debug: return .debug
            case .info: return .info
            case .warning: return .default
            case .error: return .error
            case .fault: return .fault
            }
        }
    }
    
    /// Log a message
    /// - Parameters:
    ///   - message: Message to log
    ///   - level: Log level
    ///   - category: Log category
    ///   - file: Source file (automatically captured)
    ///   - function: Function name (automatically captured)
    ///   - line: Line number (automatically captured)
    static func log(
        _ message: String,
        level: Level = .info,
        category: Category = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let logger = os.Logger(subsystem: subsystem, category: category.rawValue)
        let fileName = (file as NSString).lastPathComponent
        let logMessage = "[\(fileName):\(line)] \(function) - \(message)"
        
        switch level {
        case .debug:
            logger.debug("\(logMessage)")
        case .info:
            logger.info("\(logMessage)")
        case .warning:
            logger.warning("\(logMessage)")
        case .error:
            logger.error("\(logMessage)")
        case .fault:
            logger.fault("\(logMessage)")
        }
        
        #if DEBUG
        print("[\(category.rawValue)] \(level): \(logMessage)")
        #endif
    }
    
    /// Log a debug message
    static func debug(_ message: String, category: Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, category: category, file: file, function: function, line: line)
    }
    
    /// Log an info message
    static func info(_ message: String, category: Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, category: category, file: file, function: function, line: line)
    }
    
    /// Log a warning message
    static func warning(_ message: String, category: Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, category: category, file: file, function: function, line: line)
    }
    
    /// Log an error message
    static func error(_ message: String, category: Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, category: category, file: file, function: function, line: line)
    }
    
    /// Log a fault message
    static func fault(_ message: String, category: Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .fault, category: category, file: file, function: function, line: line)
    }
}

