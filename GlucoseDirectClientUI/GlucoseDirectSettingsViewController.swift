//
//  SettingsView.swift
//  GlucoseDirectClientUI
//

import Combine
import GlucoseDirectClient
import HealthKit
import LoopKit
import LoopKitUI

// MARK: - GlucoseDirectSettingsViewController

public class GlucoseDirectSettingsViewController: UITableViewController {
    // MARK: Lifecycle

    init(cgmManager: GlucoseDirectManager, displayGlucosePreference: DisplayGlucosePreference) {
        self.cgmManager = cgmManager
        self.displayGlucosePreference = displayGlucosePreference

        super.init(style: .grouped)
        title = LocalizedString("CGM Settings")
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Public

    override public func viewDidLoad() {
        super.viewDidLoad()

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "text")
        tableView.register(SubtitleStyleCell.self, forCellReuseIdentifier: "subtitle")
        tableView.register(ValueStyleCell.self, forCellReuseIdentifier: "value")

        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTapped(_:)))
        navigationItem.setRightBarButton(doneButton, animated: false)

        let deleteButton = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(deleteTapped(_:)))
        navigationItem.setLeftBarButton(deleteButton, animated: false)
    }

    override public func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }

    override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .appInfo:
            return AppInfoSection.allCases.count

        case .latestReading:
            if let _ = cgmManager.latestGlucoseSample {
                return LatestReadingsSection.allCases.count
            }

            return 1

        case .transmitter:
            if cgmManager.transmitter != nil || cgmManager.transmitterBattery != nil || cgmManager.transmitterHardware != nil || cgmManager.transmitterFirmware != nil {
                return TransmitterSection.allCases.count
            }

            return 1
        case .sensor:
            if cgmManager.sensor != nil || cgmManager.sensorConnectionState != nil {
                return SensorSection.allCases.count
            }

            return 1
        }
    }

    override public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section)! {
        case .appInfo:
            return LocalizedString("App info")

        case .latestReading:
            return LocalizedString("Latest reading")

        case .transmitter:
            return LocalizedString("Transmitter")

        case .sensor:
            return LocalizedString("Sensor")
        }
    }

    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section)! {
        case .appInfo:
            switch AppInfoSection(rawValue: indexPath.row)! {
            case .version:
                let cell = tableView.dequeueReusableCell(withIdentifier: "subtitle", for: indexPath) as! SubtitleStyleCell
                cell.textLabel?.text = cgmManager.app ?? "-"
                cell.detailTextLabel?.text = cgmManager.appVersion ?? "-"
                cell.imageView?.image = appLogo

                return cell
            }

        case .latestReading:
            if let latestGlucoseSample = cgmManager.latestGlucoseSample {
                switch LatestReadingsSection(rawValue: indexPath.row)! {
                case .glucose:
                    let cell = tableView.dequeueReusableCell(withIdentifier: "value", for: indexPath) as! ValueStyleCell
                    cell.textLabel?.text = LocalizedString("Glucose")
                    cell.detailTextLabel?.text = displayGlucosePreference.format(latestGlucoseSample.quantity)

                    return cell
                case .trend:
                    let cell = tableView.dequeueReusableCell(withIdentifier: "value", for: indexPath) as! ValueStyleCell
                    cell.textLabel?.text = LocalizedString("Trend")
                    cell.detailTextLabel?.text = latestGlucoseSample.trend?.localizedDescription

                    return cell
                case .date:
                    let cell = tableView.dequeueReusableCell(withIdentifier: "value", for: indexPath) as! ValueStyleCell
                    cell.textLabel?.text = LocalizedString("Date")
                    cell.detailTextLabel?.text = dateFormatter.string(for: latestGlucoseSample.date)

                    return cell
                }
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "text", for: indexPath)
                cell.textLabel?.text = LocalizedString("No glucose reading available")

                return cell
            }

        case .transmitter:
            if cgmManager.transmitter != nil || cgmManager.transmitterBattery != nil || cgmManager.transmitterHardware != nil || cgmManager.transmitterFirmware != nil {
                switch TransmitterSection(rawValue: indexPath.row)! {
                case .model:
                    let cell = tableView.dequeueReusableCell(withIdentifier: "value", for: indexPath) as! ValueStyleCell
                    cell.textLabel?.text = LocalizedString("Transmitter model")
                    cell.detailTextLabel?.text = cgmManager.transmitter ?? "-"

                    return cell
                case .battery:
                    let cell = tableView.dequeueReusableCell(withIdentifier: "value", for: indexPath) as! ValueStyleCell
                    cell.textLabel?.text = LocalizedString("Transmitter battery")
                    cell.detailTextLabel?.text = cgmManager.transmitterBattery ?? "-"

                    return cell
                case .hardware:
                    let cell = tableView.dequeueReusableCell(withIdentifier: "value", for: indexPath) as! ValueStyleCell
                    cell.textLabel?.text = LocalizedString("Transmitter hardware")
                    cell.detailTextLabel?.text = cgmManager.transmitterHardware ?? "-"

                    return cell
                case .firmware:
                    let cell = tableView.dequeueReusableCell(withIdentifier: "value", for: indexPath) as! ValueStyleCell
                    cell.textLabel?.text = LocalizedString("Transmitter firmware")
                    cell.detailTextLabel?.text = cgmManager.transmitterFirmware ?? "-"

                    return cell
                }
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "text", for: indexPath)
                cell.textLabel?.text = LocalizedString("No transmitter in use")

                return cell
            }
        case .sensor:
            if cgmManager.sensor != nil || cgmManager.sensorConnectionState != nil {
                switch SensorSection(rawValue: indexPath.row)! {
                case .model:
                    let cell = tableView.dequeueReusableCell(withIdentifier: "value", for: indexPath) as! ValueStyleCell
                    cell.textLabel?.text = LocalizedString("Sensor model")
                    cell.detailTextLabel?.text = cgmManager.sensor ?? "-"

                    return cell
                case .connectionState:
                    let cell = tableView.dequeueReusableCell(withIdentifier: "value", for: indexPath) as! ValueStyleCell
                    cell.textLabel?.text = LocalizedString("Sensor connection state")
                    cell.detailTextLabel?.text = cgmManager.sensorConnectionState ?? "-"

                    return cell
                }
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "text", for: indexPath)
                cell.textLabel?.text = LocalizedString("No sensor data available")

                return cell
            }
        }
    }

    // MARK: Internal

    let displayGlucosePreference: DisplayGlucosePreference
    let cgmManager: GlucoseDirectManager

    @objc func doneTapped(_ sender: Any) {
        done()
    }

    @objc func deleteTapped(_ sender: Any) {
        delete()
    }

    // MARK: Private

    private enum Section: Int, CaseIterable {
        case latestReading
        case sensor
        case transmitter
        case appInfo
    }

    private enum AppInfoSection: Int, CaseIterable {
        case version
    }

    private enum LatestReadingsSection: Int, CaseIterable {
        case glucose
        case trend
        case date
    }

    private enum TransmitterSection: Int, CaseIterable {
        case model
        case battery
        case hardware
        case firmware
    }

    private enum SensorSection: Int, CaseIterable {
        case model
        case connectionState
    }

    private var appLogo: UIImage? = UIImage(named: "glucose-direct", in: FrameworkBundle.own, compatibleWith: nil)!.imageWithInsets(insets: UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0))

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium

        return formatter
    }

    private func delete() {
        cgmManager.notifyDelegateOfDeletion {
            DispatchQueue.main.async {
                self.done()
            }
        }
    }

    private func done() {
        if let nav = navigationController as? SettingsNavigationViewController {
            nav.notifyComplete()
        }
    }
}

// MARK: - SubtitleStyleCell

class SubtitleStyleCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - ValueStyleCell

class ValueStyleCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension UIImage {
    func imageWithInsets(insets: UIEdgeInsets) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: size.width + insets.left + insets.right, height: size.height + insets.top + insets.bottom), false, scale)
        let _ = UIGraphicsGetCurrentContext()
        let origin = CGPoint(x: insets.left, y: insets.top)

        draw(at: origin)

        let imageWithInsets = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return imageWithInsets
    }
}
