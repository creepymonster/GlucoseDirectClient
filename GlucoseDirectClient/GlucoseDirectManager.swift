//
//  GlucoseDirectManager.swift
//  GlucoseDirectClient
//
//  Created by Ivan Valkou on 10.10.2019.
//  Copyright © 2019 Ivan Valkou. All rights reserved.
//

import Combine
import HealthKit
import LoopKit

// MARK: - GlucoseDirectManager

public class GlucoseDirectManager: CGMManager {
    // MARK: Lifecycle

    public init() {
        sharedDefaults = UserDefaults(suiteName: Bundle.main.appGroupSuiteName)
        client = GlucoseDirectClient(sharedDefaults)
    }

    public required convenience init?(rawState: CGMManager.RawStateValue) {
        self.init()
        // shouldSyncToRemoteService = rawState[Config.shouldSyncKey] as? Bool ?? true
    }

    // MARK: Public

    public static let pluginIdentifier = "GlucoseDirectClient"
    public static let managerIdentifier = "GlucoseDirectClient"
    public static let localizedTitle = LocalizedString("Glucose Direct Client")

    public let delegate = WeakSynchronizedDelegate<CGMManagerDelegate>()
    public let providesBLEHeartbeat = false

    public var managedDataInterval: TimeInterval?
    public var shouldSyncToRemoteService = true
    public private(set) var latestGlucose: ClientGlucose?
    public private(set) var latestGlucoseSample: NewGlucoseSample?

    public var sensor: String? {
        sharedDefaults?.string(forKey: "glucosedirect--sensor")
    }

    public var sensorState: String? {
        sharedDefaults?.string(forKey: "glucosedirect--sensor-state")
    }

    public var sensorConnectionState: String? {
        sharedDefaults?.string(forKey: "glucosedirect--sensor-connection-state")
    }

    public var app: String? {
        sharedDefaults?.string(forKey: "glucosedirect--app")
    }

    public var appVersion: String? {
        sharedDefaults?.string(forKey: "glucosedirect--app-version")
    }

    public var transmitter: String? {
        sharedDefaults?.string(forKey: "glucosedirect--transmitter")
    }

    public var transmitterBattery: String? {
        sharedDefaults?.string(forKey: "glucosedirect--transmitter-battery")
    }

    public var transmitterHardware: String? {
        sharedDefaults?.string(forKey: "glucosedirect--transmitter-hardware")
    }

    public var transmitterFirmware: String? {
        sharedDefaults?.string(forKey: "glucosedirect--transmitter-firmware")
    }

    public var device: HKDevice? {
        HKDevice(
            name: managerIdentifier,
            manufacturer: nil,
            model: sensor,
            hardwareVersion: transmitterHardware,
            firmwareVersion: transmitterFirmware,
            softwareVersion: appVersion,
            localIdentifier: nil,
            udiDeviceIdentifier: nil
        )
    }

    public var managerIdentifier: String {
        return GlucoseDirectManager.managerIdentifier
    }

    public var localizedTitle: String {
        return GlucoseDirectManager.localizedTitle
    }

    public var glucoseDisplay: GlucoseDisplayable? { latestGlucose }

    public var cgmManagerStatus: CGMManagerStatus {
        // TODO: Probably need a better way to calculate this.
        if let latestGlucose = latestGlucose, latestGlucose.startDate.timeIntervalSinceNow > -TimeInterval(minutes: 4.5) {
            return .init(hasValidSensorSession: true, device: device)
        } else {
            return .init(hasValidSensorSession: false, device: device)
        }
    }

    public var isOnboarded: Bool {
        true
    }

    public var rawState: CGMManager.RawStateValue {
        [Config.shouldSyncKey: shouldSyncToRemoteService]
    }

    public var delegateQueue: DispatchQueue! {
        get { delegate.queue }
        set { delegate.queue = newValue }
    }

    public var cgmManagerDelegate: CGMManagerDelegate? {
        get { delegate.delegate }
        set { delegate.delegate = newValue }
    }

    public var debugDescription: String {
        "## GlucoseDirectManager\nlatestBackfill: \(String(describing: latestGlucose))\n"
    }

    public var appURL: URL? {
        return URL(string: "glucosedirect://")
    }

    public func fetchNewDataIfNeeded(_ completion: @escaping (CGMReadingResult) -> Void) {
        processQueue.async {
            guard let client = self.client else {
                self.delegateQueue.async {
                    completion(.noData)
                }

                return
            }

            // If our last glucose was less than 0.5 minutes ago, don't fetch.
            if let latestGlucose = self.latestGlucose, latestGlucose.startDate.timeIntervalSinceNow > -TimeInterval(minutes: 0.5) {
                self.delegateQueue.async {
                    completion(.noData)
                }

                return
            }

            do {
                let fetchedGlucose = try client.fetchLast(60)
                guard !fetchedGlucose.isEmpty else {
                    self.delegateQueue.async {
                        completion(.noData)
                    }
                    
                    return
                }

                let startDate = self.delegate.call { (delegate) -> Date? in
                    return delegate?.startDateToFilterNewData(for: self)?.addingTimeInterval(TimeInterval(seconds: 270))
                }

                let newGlucose = fetchedGlucose.filterDateRange(startDate, nil)
                let newGlucoseSamples = newGlucose.filter { $0.isStateValid }.map {
                    NewGlucoseSample(date: $0.startDate, quantity: $0.quantity, condition: nil, trend: $0.trendType, trendRate: $0.trendRate, isDisplayOnly: false, wasUserEntered: false, syncIdentifier: "\(Int($0.startDate.timeIntervalSince1970))", device: self.device)
                }
                
                guard !newGlucoseSamples.isEmpty else {
                    self.delegateQueue.async {
                        completion(.noData)
                    }
                    
                    return
                }

                self.latestGlucose = newGlucose.first
                self.latestGlucoseSample = newGlucoseSamples.first
                
                self.delegateQueue.async {
                    completion(.newData(newGlucoseSamples))
                }
            } catch let error as ClientError {
                self.delegateQueue.async {
                    completion(.error(error))
                }
            } catch {
                self.delegateQueue.async {
                    completion(.error(ClientError.fetchError))
                }
            }
        }
    }

    // MARK: Private

    private enum Config {
        static let shouldSyncKey = "GlucoseDirectClient.shouldSync"
    }

    private var client: GlucoseDirectClient?
    private let processQueue = DispatchQueue(label: "GlucoseDirectManager.processQueue")
    private let sharedDefaults: UserDefaults?
}

public extension GlucoseDirectManager {
    func acknowledgeAlert(alertIdentifier: Alert.AlertIdentifier, completion: @escaping (Error?) -> Void) {
        completion(nil)
    }
}

public extension GlucoseDirectManager {
    func getSoundBaseURL() -> URL? { return nil }
    func getSounds() -> [Alert.Sound] { return [] }
}

private extension Bundle {
    var appGroupSuiteName: String {
        return object(forInfoDictionaryKey: "AppGroupIdentifier") as! String
    }
}
