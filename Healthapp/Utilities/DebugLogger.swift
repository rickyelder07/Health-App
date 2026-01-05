//
//  DebugLogger.swift
//  Netfuel
//
//  Enhanced logging with persistence and network request tracking
//

import Foundation

/// Enhanced logger with persistence for debugging
class DebugLogger {
    static let shared = DebugLogger()

    private var logs: [LogEntry] = []
    private let maxLogs = 1000
    private let queue = DispatchQueue(label: "com.netfuel.debuglogger", qos: .utility)

    private init() {
        loadPersistedLogs()
    }

    // MARK: - Log Entry Model

    struct LogEntry: Codable {
        let timestamp: Date
        let level: String
        let category: String
        let message: String
        let file: String
        let function: String
        let line: Int
        var metadata: [String: String]?

        var formattedString: String {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
            let timeString = dateFormatter.string(from: timestamp)

            var metaString = ""
            if let metadata = metadata, !metadata.isEmpty {
                metaString = " | " + metadata.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
            }

            return "[\(timeString)] [\(level)] [\(category)] \(message)\(metaString)\n    at \(file):\(line) \(function)"
        }
    }

    // MARK: - Logging Methods

    func log(
        _ message: String,
        level: Logger.Level = .info,
        category: Logger.Category = .general,
        metadata: [String: String]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let fileName = (file as NSString).lastPathComponent
        let entry = LogEntry(
            timestamp: Date(),
            level: String(describing: level),
            category: category.rawValue,
            message: message,
            file: fileName,
            function: function,
            line: line,
            metadata: metadata
        )

        queue.async {
            self.logs.append(entry)

            // Keep only last N logs
            if self.logs.count > self.maxLogs {
                self.logs.removeFirst(self.logs.count - self.maxLogs)
            }

            // Persist logs
            self.persistLogs()

            #if DEBUG
            print(entry.formattedString)
            #endif
        }

        // Also log to system logger
        Logger.log(message, level: level, category: category, file: file, function: function, line: line)
    }

    // MARK: - Network Logging

    func logNetworkRequest(
        url: String,
        method: String,
        headers: [String: String]? = nil,
        body: Data? = nil
    ) {
        var metadata: [String: String] = [
            "url": url,
            "method": method
        ]

        if let headers = headers {
            metadata["headers"] = headers.map { "\($0.key): \($0.value)" }.joined(separator: "; ")
        }

        if let body = body, let bodyString = String(data: body, encoding: .utf8) {
            metadata["body"] = String(bodyString.prefix(500)) // Limit body size
        }

        log(
            "Network Request: \(method) \(url)",
            level: .debug,
            category: .network,
            metadata: metadata
        )
    }

    func logNetworkResponse(
        url: String,
        statusCode: Int,
        data: Data?,
        error: Error? = nil
    ) {
        var metadata: [String: String] = [
            "url": url,
            "status": "\(statusCode)"
        ]

        if let data = data {
            metadata["size"] = "\(data.count) bytes"

            if let jsonString = String(data: data, encoding: .utf8) {
                metadata["response"] = String(jsonString.prefix(500)) // Limit response size
            }
        }

        if let error = error {
            metadata["error"] = error.localizedDescription
        }

        let level: Logger.Level = (200..<300).contains(statusCode) ? .info : .error
        log(
            "Network Response: \(statusCode) for \(url)",
            level: level,
            category: .network,
            metadata: metadata
        )
    }

    // MARK: - Error Logging

    func logError(
        _ error: Error,
        context: String? = nil,
        category: Logger.Category = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        var metadata: [String: String] = [
            "error_type": String(describing: type(of: error)),
            "error_description": error.localizedDescription
        ]

        if let context = context {
            metadata["context"] = context
        }

        log(
            "Error: \(error.localizedDescription)",
            level: .error,
            category: category,
            metadata: metadata,
            file: file,
            function: function,
            line: line
        )
    }

    // MARK: - Performance Logging

    func startPerformanceTimer(identifier: String) -> PerformanceTimer {
        PerformanceTimer(identifier: identifier, logger: self)
    }

    func logPerformance(identifier: String, duration: TimeInterval, metadata: [String: String]? = nil) {
        var meta = metadata ?? [:]
        meta["duration"] = String(format: "%.3fms", duration * 1000)

        log(
            "Performance: \(identifier)",
            level: .debug,
            category: .general,
            metadata: meta
        )
    }

    // MARK: - Log Management

    var logCount: Int {
        queue.sync { logs.count }
    }

    func getLogs() -> [LogEntry] {
        queue.sync { logs }
    }

    func exportLogs() -> String {
        let entries = getLogs()
        return entries.map { $0.formattedString }.joined(separator: "\n\n")
    }

    func clearLogs() {
        queue.async {
            self.logs.removeAll()
            self.persistLogs()
        }
    }

    // MARK: - Persistence

    private var logsFileURL: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("debug_logs.json")
    }

    private func persistLogs() {
        do {
            let data = try JSONEncoder().encode(logs)
            try data.write(to: logsFileURL)
        } catch {
            print("Failed to persist logs: \(error)")
        }
    }

    private func loadPersistedLogs() {
        guard FileManager.default.fileExists(atPath: logsFileURL.path) else { return }

        do {
            let data = try Data(contentsOf: logsFileURL)
            logs = try JSONDecoder().decode([LogEntry].self, from: data)
        } catch {
            print("Failed to load persisted logs: \(error)")
        }
    }
}

// MARK: - Performance Timer

class PerformanceTimer {
    let identifier: String
    let startTime: Date
    let logger: DebugLogger

    init(identifier: String, logger: DebugLogger) {
        self.identifier = identifier
        self.startTime = Date()
        self.logger = logger
    }

    func stop(metadata: [String: String]? = nil) {
        let duration = Date().timeIntervalSince(startTime)
        logger.logPerformance(identifier: identifier, duration: duration, metadata: metadata)
    }
}

// MARK: - Network Logger Wrapper

class NetworkLogger {
    static let shared = NetworkLogger()

    func logRequest(_ request: URLRequest) {
        guard let url = request.url?.absoluteString else { return }

        let method = request.httpMethod ?? "GET"
        let headers = request.allHTTPHeaderFields
        let body = request.httpBody

        DebugLogger.shared.logNetworkRequest(
            url: url,
            method: method,
            headers: headers,
            body: body
        )
    }

    func logResponse(_ response: URLResponse?, data: Data?, error: Error?) {
        guard let httpResponse = response as? HTTPURLResponse,
              let url = httpResponse.url?.absoluteString else { return }

        DebugLogger.shared.logNetworkResponse(
            url: url,
            statusCode: httpResponse.statusCode,
            data: data,
            error: error
        )
    }
}
