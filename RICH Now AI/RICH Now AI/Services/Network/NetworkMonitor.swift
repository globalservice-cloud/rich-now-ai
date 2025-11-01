//
//  NetworkMonitor.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import Network
import Combine

class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    @Published var isConnected: Bool = true
    @Published var connectionType: NWInterface.InterfaceType?
    @Published var isExpensive: Bool = false
    @Published var isConstrained: Bool = false
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    init() {
        startMonitoring()
    }
    
    deinit {
        monitor.cancel()
    }
    
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isConnected = path.status == .satisfied
                self?.connectionType = path.availableInterfaces.first?.type
                self?.isExpensive = path.isExpensive
                self?.isConstrained = path.isConstrained
            }
        }
        monitor.start(queue: queue)
    }
    
    func stopMonitoring() {
        monitor.cancel()
    }
    
    // MARK: - 網路狀態檢查
    
    func isNetworkAvailable() -> Bool {
        return isConnected
    }
    
    func isWifiConnected() -> Bool {
        return isConnected && connectionType == .wifi
    }
    
    func isCellularConnected() -> Bool {
        return isConnected && connectionType == .cellular
    }
    
    func isLowBandwidth() -> Bool {
        return isConstrained || isExpensive
    }
    
    // MARK: - 網路品質評估
    
    func getNetworkQuality() -> NetworkQuality {
        if !isConnected {
            return .offline
        } else if isLowBandwidth() {
            return .poor
        } else if isWifiConnected() {
            return .excellent
        } else if isCellularConnected() {
            return .good
        } else {
            return .unknown
        }
    }
}

// MARK: - 網路品質枚舉

enum NetworkQuality: String, CaseIterable {
    case offline = "offline"
    case poor = "poor"
    case good = "good"
    case excellent = "excellent"
    case unknown = "unknown"
    
    var displayName: String {
        switch self {
        case .offline: return "離線"
        case .poor: return "網路品質差"
        case .good: return "網路品質良好"
        case .excellent: return "網路品質優秀"
        case .unknown: return "網路狀態未知"
        }
    }
    
    var icon: String {
        switch self {
        case .offline: return "wifi.slash"
        case .poor: return "wifi.exclamationmark"
        case .good: return "wifi"
        case .excellent: return "wifi.circle.fill"
        case .unknown: return "wifi.questionmark"
        }
    }
    
    var color: String {
        switch self {
        case .offline: return "red"
        case .poor: return "orange"
        case .good: return "blue"
        case .excellent: return "green"
        case .unknown: return "gray"
        }
    }
}
