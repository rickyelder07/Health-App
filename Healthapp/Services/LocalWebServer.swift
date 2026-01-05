//
//  LocalWebServer.swift
//  Netfuel
//
//  Lightweight HTTP server for OAuth callbacks
//

import Foundation
import Network

/// Simple local HTTP server for handling OAuth callbacks
class LocalWebServer {
    private var listener: NWListener?
    private var connection: NWConnection?
    private let port: UInt16 = 8080
    var onCodeReceived: ((String) -> Void)?
    
    /// Start the local server
    func start() throws {
        let parameters = NWParameters.tcp
        parameters.allowLocalEndpointReuse = true
        
        listener = try NWListener(using: parameters, on: NWEndpoint.Port(integerLiteral: port))
        
        listener?.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                print("✅ Local server listening on port \(self?.port ?? 0)")
            case .failed(let error):
                print("❌ Server failed: \(error)")
            case .cancelled:
                print("ℹ️ Server cancelled")
            default:
                break
            }
        }
        
        listener?.newConnectionHandler = { [weak self] newConnection in
            self?.handleConnection(newConnection)
        }
        
        listener?.start(queue: .main)
    }
    
    /// Stop the server
    func stop() {
        connection?.cancel()
        listener?.cancel()
        listener = nil
        print("🛑 Local server stopped")
    }
    
    /// Handle incoming connection
    private func handleConnection(_ connection: NWConnection) {
        self.connection = connection
        
        connection.stateUpdateHandler = { state in
            if state == .ready {
                self.receiveRequest(on: connection)
            }
        }
        
        connection.start(queue: .main)
    }
    
    /// Receive HTTP request
    private func receiveRequest(on connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, _, error in
            guard let data = data,
                  let request = String(data: data, encoding: .utf8) else {
                connection.cancel()
                return
            }
            
            print("📥 Received HTTP request")
            
            // Extract authorization code from request
            if let code = self?.extractCode(from: request) {
                print("✅ Extracted authorization code")
                
                // Send success response
                self?.sendResponse(on: connection, html: self?.successHTML() ?? "")
                
                // Notify callback
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self?.onCodeReceived?(code)
                }
            } else {
                print("❌ Failed to extract code from request")
                self?.sendResponse(on: connection, html: self?.errorHTML() ?? "")
            }
            
            // Stop server after handling request
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self?.stop()
            }
        }
    }
    
    /// Extract authorization code from HTTP request
    private func extractCode(from request: String) -> String? {
        // Parse the GET request line
        guard let firstLine = request.components(separatedBy: "\r\n").first,
              let urlPart = firstLine.components(separatedBy: " ").dropFirst().first else {
            return nil
        }
        
        // Extract query parameters
        let components = URLComponents(string: "http://localhost\(urlPart)")
        return components?.queryItems?.first(where: { $0.name == "code" })?.value
    }
    
    /// Send HTTP response
    private func sendResponse(on connection: NWConnection, html: String) {
        let response = """
            HTTP/1.1 200 OK
            Content-Type: text/html; charset=utf-8
            Content-Length: \(html.utf8.count)
            Connection: close
            
            \(html)
            """
        
        let data = response.data(using: .utf8)!
        connection.send(content: data, completion: .contentProcessed { error in
            if let error = error {
                print("❌ Failed to send response: \(error)")
            }
            connection.cancel()
        })
    }
    
    /// Success HTML page
    private func successHTML() -> String {
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Success</title>
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    min-height: 100vh;
                    margin: 0;
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                }
                .container {
                    text-align: center;
                    background: white;
                    padding: 3rem;
                    border-radius: 20px;
                    box-shadow: 0 20px 60px rgba(0,0,0,0.3);
                }
                .checkmark {
                    font-size: 64px;
                    color: #4CAF50;
                    margin-bottom: 1rem;
                }
                h1 {
                    color: #333;
                    margin: 0 0 1rem 0;
                }
                p {
                    color: #666;
                    margin: 0;
                }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="checkmark">✓</div>
                <h1>Connected to Strava!</h1>
                <p>You can close this window and return to the app.</p>
            </div>
            <script>
                setTimeout(() => {
                    window.close();
                }, 2000);
            </script>
        </body>
        </html>
        """
    }
    
    /// Error HTML page
    private func errorHTML() -> String {
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Error</title>
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    min-height: 100vh;
                    margin: 0;
                    background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
                }
                .container {
                    text-align: center;
                    background: white;
                    padding: 3rem;
                    border-radius: 20px;
                    box-shadow: 0 20px 60px rgba(0,0,0,0.3);
                }
                .error {
                    font-size: 64px;
                    color: #f44336;
                    margin-bottom: 1rem;
                }
                h1 {
                    color: #333;
                    margin: 0 0 1rem 0;
                }
                p {
                    color: #666;
                    margin: 0;
                }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="error">✗</div>
                <h1>Authorization Failed</h1>
                <p>Please try again.</p>
            </div>
        </body>
        </html>
        """
    }
}

