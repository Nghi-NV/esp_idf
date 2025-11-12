import Flutter
import UIKit
import ESPProvision
import CoreLocation

public class EspIdfPlugin: NSObject, FlutterPlugin {
    private var bleDeviceEventSink: FlutterEventSink?
    private var provisionManager: ESPProvisionManager?
    private var devices: [String: ESPDevice] = [:]
    private var bleDevices: [String: ESPDevice] = [:]
    private var pendingQRResult: FlutterResult?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "esp_idf", binaryMessenger: registrar.messenger())
        let instance = EspIdfPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)

        let bleDeviceEventChannel = FlutterEventChannel(
            name: "esp_idf/ble_devices",
            binaryMessenger: registrar.messenger()
        )
        bleDeviceEventChannel.setStreamHandler(BleDeviceStreamHandler(plugin: instance))

        let connectionEventChannel = FlutterEventChannel(
            name: "esp_idf/connection_status",
            binaryMessenger: registrar.messenger()
        )
        connectionEventChannel.setStreamHandler(ConnectionStreamHandler())

        let provisioningEventChannel = FlutterEventChannel(
            name: "esp_idf/provisioning_status",
            binaryMessenger: registrar.messenger()
        )
        provisioningEventChannel.setStreamHandler(ProvisioningStreamHandler())
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "searchBleDevices":
            searchBleDevices(call: call, result: result)
        case "stopBleSearch":
            stopBleSearch(result: result)
        case "createDevice":
            createDevice(call: call, result: result)
        case "connectDevice":
            connectDevice(call: call, result: result)
        case "disconnectDevice":
            disconnectDevice(call: call, result: result)
        case "scanWifiNetworks":
            scanWifiNetworks(call: call, result: result)
        case "provisionDevice":
            provisionDevice(call: call, result: result)
        case "isBluetoothEnabled":
            isBluetoothEnabled(result: result)
        case "requestPermissions":
            requestPermissions(result: result)
        case "checkPermissions":
            checkPermissions(result: result)
        case "scanQRCode":
            scanQRCode(call: call, result: result)
        case "connectWiFiDevice":
            connectWiFiDevice(call: call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func searchBleDevices(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let prefix = args["prefix"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }

        provisionManager = ESPProvisionManager.shared

        provisionManager?.searchESPDevices(devicePrefix: prefix, transport: .ble, security: .secure) { foundDevices, error in
            if let error = error {
                self.bleDeviceEventSink?(FlutterError(
                    code: "SCAN_ERROR",
                    message: error.localizedDescription,
                    details: nil
                ))
                return
            }

            if let foundDevices = foundDevices {
                for device in foundDevices {
                    self.bleDevices[device.name] = device
                    let deviceMap: [String: Any] = [
                        "name": device.name,
                        "transport": "ble",
                        "security": "secure",
                        "deviceId": device.name
                    ]
                    self.bleDeviceEventSink?(deviceMap)
                }
            }
        }

        result(nil)
    }

    private func stopBleSearch(result: @escaping FlutterResult) {
        provisionManager?.stopESPDevicesSearch()
        result(nil)
    }

    private func createDevice(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let deviceName = args["deviceName"] as? String,
              let transportStr = args["transport"] as? String,
              let securityStr = args["security"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }

        let transport: ESPTransport = transportStr == "ble" ? .ble : .softap
        let security: ESPSecurity

        switch securityStr {
        case "unsecured":
            security = .unsecure
        case "secure":
            security = .secure
        case "secure2":
            security = .secure2
        default:
            security = .secure
        }

        let proofOfPossession = args["proofOfPossession"] as? String
        let username = args["username"] as? String
        let softApPassword = args["softApPassword"] as? String

        let device = ESPDevice(name: deviceName, security: security, transport: transport, proofOfPossession: proofOfPossession, username: username, softAPPassword: softApPassword)

        let deviceId = deviceName
        devices[deviceId] = device

        result(deviceId)
    }

    private func connectDevice(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let deviceId = args["deviceId"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }

        guard let device = devices[deviceId] ?? bleDevices[deviceId] else {
            result(FlutterError(code: "DEVICE_NOT_FOUND", message: "Device not found", details: nil))
            return
        }

        device.connect(delegate: self) { status in
            switch status {
            case .connected:
                result(nil)
            case let .failedToConnect(error):
                result(FlutterError(
                    code: "CONNECT_FAILED",
                    message: error.localizedDescription,
                    details: nil
                ))
            default:
                break
            }
        }
    }

    private func disconnectDevice(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let deviceId = args["deviceId"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }

        guard let device = devices[deviceId] ?? bleDevices[deviceId] else {
            result(FlutterError(code: "DEVICE_NOT_FOUND", message: "Device not found", details: nil))
            return
        }

        device.disconnect()
        result(nil)
    }

    private func scanWifiNetworks(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let deviceId = args["deviceId"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }

        guard let device = devices[deviceId] ?? bleDevices[deviceId] else {
            result(FlutterError(code: "DEVICE_NOT_FOUND", message: "Device not found", details: nil))
            return
        }

        device.scanWifiList { wifiList, error in
            if let error = error {
                result(FlutterError(
                    code: "SCAN_FAILED",
                    message: error.localizedDescription,
                    details: nil
                ))
                return
            }

            if let wifiList = wifiList {
                let networks = wifiList.map { wifi -> [String: Any] in
                    return [
                        "ssid": wifi.ssid,
                        "rssi": wifi.rssi,
                        "auth": wifi.auth.rawValue,
                        "channel": wifi.channel
                    ]
                }
                result(networks)
            } else {
                result([])
            }
        }
    }

    private func provisionDevice(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let deviceId = args["deviceId"] as? String,
              let ssid = args["ssid"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }

        let password = args["password"] as? String ?? ""

        guard let device = devices[deviceId] ?? bleDevices[deviceId] else {
            result(FlutterError(code: "DEVICE_NOT_FOUND", message: "Device not found", details: nil))
            return
        }

        device.provision(ssid: ssid, passPhrase: password) { status in
            switch status {
            case .success:
                result(nil)
            case let .failure(error):
                result(FlutterError(
                    code: "PROVISION_FAILED",
                    message: error.localizedDescription,
                    details: nil
                ))
            case .configApplied:
                // Config applied
                break
            }
        }
    }

    private func isBluetoothEnabled(result: @escaping FlutterResult) {
        // iOS doesn't provide a direct way to check Bluetooth state without permissions
        // Return true as a default
        result(true)
    }

    private func checkPermissions(result: @escaping FlutterResult) {
        // Check if location permission is granted (required for Wi-Fi SSID access)
        let status = CLLocationManager.authorizationStatus()
        let granted = status == .authorizedWhenInUse || status == .authorizedAlways
        result(granted)
    }

    private func requestPermissions(result: @escaping FlutterResult) {
        // Permissions need to be requested from the app level
        // Return true to indicate that the method was called
        // Actual permission requests should be handled by the app
        result(true)
    }

    private func scanQRCode(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
            result(FlutterError(
                code: "NO_VIEW_CONTROLLER",
                message: "Unable to get root view controller",
                details: nil
            ))
            return
        }

        pendingQRResult = result

        let scannerVC = ESPQRScannerViewController()
        scannerVC.delegate = self

        // Apply custom parameters if provided
        if let args = call.arguments as? [String: Any] {
            if let title = args["title"] as? String {
                scannerVC.customTitle = title
            }
            if let description = args["description"] as? String {
                scannerVC.customDescription = description
            }
            if let cancelButtonText = args["cancelButtonText"] as? String {
                scannerVC.customCancelButtonText = cancelButtonText
            }
        }

        scannerVC.modalPresentationStyle = .fullScreen

        rootViewController.present(scannerVC, animated: true)
    }

    private func connectWiFiDevice(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let deviceId = args["deviceId"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }

        guard let device = devices[deviceId] ?? bleDevices[deviceId] else {
            result(FlutterError(code: "DEVICE_NOT_FOUND", message: "Device not found", details: nil))
            return
        }

        // For SoftAP transport, the connection is established when connected to the device's WiFi
        // This method just initiates the session
        device.connect(delegate: self) { status in
            switch status {
            case .connected:
                result(nil)
            case let .failedToConnect(error):
                result(FlutterError(
                    code: "CONNECT_FAILED",
                    message: error.localizedDescription,
                    details: nil
                ))
            default:
                break
            }
        }
    }

    func setBleDeviceEventSink(_ sink: FlutterEventSink?) {
        bleDeviceEventSink = sink
    }
}

// MARK: - ESPDeviceConnectionDelegate
extension EspIdfPlugin: ESPDeviceConnectionDelegate {
    public func getProofOfPossesion(forDevice: ESPDevice, completionHandler: @escaping (String) -> Void) {
        // In ESPProvision 3.0.3, proof of possession is passed in the initializer
        // We don't need to provide it again here, return empty string
        completionHandler("")
    }

    public func getUsername(forDevice: ESPDevice, completionHandler: @escaping (String?) -> Void) {
        // In ESPProvision 3.0.3, username is passed in the initializer
        // We don't need to provide it again here
        completionHandler(nil)
    }
}

// MARK: - ESPQRScannerDelegate
extension EspIdfPlugin: ESPQRScannerDelegate {
    func qrScannerDidScan(device: ESPDevice) {
        // Store the device
        let deviceId = device.name
        devices[deviceId] = device
        bleDevices[deviceId] = device

        // Determine transport and security
        let transport = device.transport == .ble ? "ble" : "softAp"
        let securityStr: String
        switch device.security {
        case .unsecure:
            securityStr = "unsecured"
        case .secure:
            securityStr = "secure"
        case .secure2:
            securityStr = "secure2"
        @unknown default:
            securityStr = "secure"
        }

        // Return device info to Flutter
        let deviceMap: [String: Any] = [
            "name": device.name,
            "transport": transport,
            "security": securityStr,
            "deviceId": deviceId
        ]

        pendingQRResult?(deviceMap)
        pendingQRResult = nil
    }

    func qrScannerDidCancel() {
        pendingQRResult?(FlutterError(
            code: "USER_CANCELLED",
            message: "QR code scanning was cancelled",
            details: nil
        ))
        pendingQRResult = nil
    }

    func qrScannerDidFail(error: Error) {
        pendingQRResult?(FlutterError(
            code: "SCAN_FAILED",
            message: error.localizedDescription,
            details: nil
        ))
        pendingQRResult = nil
    }
}

// MARK: - Stream Handlers
class BleDeviceStreamHandler: NSObject, FlutterStreamHandler {
    weak var plugin: EspIdfPlugin?

    init(plugin: EspIdfPlugin) {
        self.plugin = plugin
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        plugin?.setBleDeviceEventSink(events)
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        plugin?.setBleDeviceEventSink(nil)
        return nil
    }
}

class ConnectionStreamHandler: NSObject, FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        return nil
    }
}

class ProvisioningStreamHandler: NSObject, FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        return nil
    }
}
