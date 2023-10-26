//
//  GlucoseDirectManager+UI.swift
//  GlucoseDirectClientUI
//
//  Created by Ivan Valkou on 21.10.2019.
//  Copyright © 2019 Ivan Valkou. All rights reserved.
//

import GlucoseDirectClient
import HealthKit
import LoopKit
import LoopKitUI

extension FrameworkBundle {
    static let own = Bundle(for: GlucoseDirectSettingsViewController.self)
}

// MARK: - GlucoseDirectManager + CGMManagerUI

extension GlucoseDirectManager: CGMManagerUI {
    // TODO: Placeholder.
    public static var onboardingImage: UIImage? {
        return UIImage(named: "glucose-direct", in: FrameworkBundle.own, compatibleWith: nil)!
    }

    public static func setupViewController(bluetoothProvider: BluetoothProvider, displayGlucosePreference: DisplayGlucosePreference, colorPalette: LoopUIColorPalette, allowDebugFeatures: Bool, prefersToSkipUserInteraction: Bool) -> SetupUIResult<CGMManagerViewController, CGMManagerUI> {
        return .createdAndOnboarded(GlucoseDirectManager())
    }

    public func settingsViewController(bluetoothProvider: BluetoothProvider, displayGlucosePreference: DisplayGlucosePreference, colorPalette: LoopUIColorPalette, allowDebugFeatures: Bool) -> CGMManagerViewController {
        let settings = GlucoseDirectSettingsViewController(cgmManager: self, displayGlucosePreference: displayGlucosePreference)
        let nav = CGMManagerSettingsNavigationViewController(rootViewController: settings)

        return nav
    }

    public var smallImage: UIImage? {
        return UIImage(named: "glucose-direct", in: FrameworkBundle.own, compatibleWith: nil)!
    }

    // TODO: Placeholder.
    public var cgmStatusHighlight: DeviceStatusHighlight? {
        return nil
    }

    // TODO: Placeholder.
    public var cgmStatusBadge: DeviceStatusBadge? {
        return nil
    }

    // TODO: Placeholder.
    public var cgmLifecycleProgress: DeviceLifecycleProgress? {
        return nil
    }
}
