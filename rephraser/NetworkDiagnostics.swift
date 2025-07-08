//
//  NetworkDiagnostics.swift
//  rephraser
//
//  Created by Rok Hoang on 7/7/25.
//

import Foundation
import Network

class NetworkDiagnostics: ObservableObject {
    @Published var isConnected = false
    @Published var connectionType = "Unknown"
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    init() {
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.connectionType = self?.getConnectionType(path: path) ?? "Unknown"
            }
        }
        monitor.start(queue: queue)
    }
    
    func stopMonitoring() {
        monitor.cancel()
    }
    
    private func getConnectionType(path: NWPath) -> String {
        if path.usesInterfaceType(.wifi) {
            return "WiFi"
        } else if path.usesInterfaceType(.cellular) {
            return "Cellular"
        } else if path.usesInterfaceType(.wiredEthernet) {
            return "Ethernet"
        } else {
            return "Other"
        }
    }
    
    func testAnthropicConnectivity() async -> (Bool, String) {
        do {
            print("🔍 Testing connectivity to api.anthropic.com...")
            
            let url = URL(string: "https://api.anthropic.com")!
            var request = URLRequest(url: url)
            request.httpMethod = "HEAD"
            request.timeoutInterval = 10.0
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                let success = httpResponse.statusCode < 500
                let message = success ? 
                    "✅ Can reach api.anthropic.com (HTTP \(httpResponse.statusCode))" :
                    "⚠️ api.anthropic.com server error (HTTP \(httpResponse.statusCode))"
                return (success, message)
            }
            
            return (false, "❌ Invalid response from api.anthropic.com")
            
        } catch {
            print("❌ Connectivity test failed: \(error)")
            
            if let urlError = error as? URLError {
                switch urlError.code {
                case .notConnectedToInternet:
                    return (false, "❌ No internet connection")
                case .cannotFindHost:
                    return (false, "❌ Cannot find api.anthropic.com (DNS issue)")
                case .timedOut:
                    return (false, "❌ Connection to api.anthropic.com timed out")
                case .cannotConnectToHost:
                    return (false, "❌ Cannot connect to api.anthropic.com")
                default:
                    return (false, "❌ Network error: \(urlError.localizedDescription)")
                }
            }
            
            return (false, "❌ Network error: \(error.localizedDescription)")
        }
    }
    
    func runFullDiagnostics() async -> [String] {
        var results: [String] = []
        
        // Basic connectivity
        results.append("🌐 Internet: \(isConnected ? "✅ Connected" : "❌ Disconnected")")
        results.append("📡 Connection: \(connectionType)")
        
        // DNS test
        let (canReach, reachMessage) = await testAnthropicConnectivity()
        results.append(reachMessage)
        
        // Additional info
        if !canReach {
            results.append("")
            results.append("🔧 Troubleshooting tips:")
            results.append("• Check your internet connection")
            results.append("• Try disabling VPN if using one")
            results.append("• Check firewall settings")
            results.append("• Try again in a few minutes")
        }
        
        return results
    }
}