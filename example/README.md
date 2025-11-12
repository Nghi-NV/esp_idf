# esp_idf_example

A complete example application demonstrating how to use the `esp_idf` plugin for ESP32/ESP8266 device provisioning.

## Features Demonstrated

- **BLE Device Discovery**: Search and discover ESP devices via Bluetooth Low Energy
- **SoftAP Connection**: Connect to devices via Wi-Fi Access Point
- **QR Code Scanning**: Scan QR codes to quickly provision devices
- **Wi-Fi Network Scanning**: Scan available Wi-Fi networks from connected devices
- **Device Provisioning**: Provision devices with Wi-Fi credentials
- **Real-time Status Monitoring**: Monitor connection and provisioning status

## Getting Started

1. Ensure you have Flutter installed (>=3.3.0)
2. Clone the repository
3. Navigate to the example directory:
   ```bash
   cd example
   ```
4. Install dependencies:
   ```bash
   flutter pub get
   ```
5. Run the app:
   ```bash
   flutter run
   ```

## Usage

1. **Request Permissions**: The app will request necessary permissions for BLE and Wi-Fi operations
2. **Choose Connection Mode**: Select between BLE or WiFi (SoftAP) connection
3. **For BLE**:
   - Enter device prefix (default: "PROV_")
   - Tap "Start Scan" to discover devices
   - Select a device from the list to connect
4. **For SoftAP**:
   - Connect your phone to the device's Wi-Fi network first
   - Enter device name/SSID
   - Enter SoftAP password if required
   - Tap "Connect via WiFi (SoftAP)"
5. **Scan QR Code**: Use the QR code scanner button in the app bar
6. **Provision Device**: After connecting, select a Wi-Fi network and enter credentials to provision

## Requirements

- Android: Minimum SDK 21 (Android 5.0)
- iOS: Minimum iOS 13.0
- Bluetooth enabled (for BLE mode)
- Location permission (required for BLE scanning on Android)

## Notes

- For SoftAP mode, ensure your phone is connected to the device's Wi-Fi network before attempting to connect
- Proof of Possession (PoP) may be required depending on your device's security configuration
- QR code scanning uses native ESPProvision scanner on iOS, and falls back to Flutter-based scanner on Android
