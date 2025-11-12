import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:esp_idf/esp_idf.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Parse QR code data
      // Expected format: {"ver":"v1","name":"PROV_123456","pop":"abcd1234","transport":"ble","security":1}
      final qrData = _parseQRCode(code);

      if (mounted) {
        Navigator.of(context).pop(qrData);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid QR code: $e')),
        );
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Map<String, dynamic> _parseQRCode(String code) {
    // Try to parse as JSON or custom format
    // This is a simplified parser - adjust based on your actual QR code format
    try {
      // Remove any whitespace
      final cleaned = code.trim();

      // Simple key-value parser for format like: name:PROV_123,pop:abcd,transport:ble,security:1
      if (cleaned.contains(':')) {
        final Map<String, String> data = {};
        final pairs = cleaned.split(',');

        for (final pair in pairs) {
          final parts = pair.split(':');
          if (parts.length == 2) {
            data[parts[0].trim()] = parts[1].trim();
          }
        }

        final transport = data['transport'] == 'softap' || data['transport'] == 'wifi'
            ? ESPTransportType.softAp
            : ESPTransportType.ble;

        ESPSecurityType security;
        final securityStr = data['security']?.toLowerCase();
        if (securityStr == '0' || securityStr == 'unsecured') {
          security = ESPSecurityType.unsecured;
        } else if (securityStr == '2' || securityStr == 'secure2') {
          security = ESPSecurityType.secure2;
        } else {
          security = ESPSecurityType.secure;
        }

        return {
          'name': data['name'] ?? '',
          'pop': data['pop'],
          'transport': transport,
          'security': security,
          'username': data['username'],
          'password': data['password'],
        };
      }

      throw Exception('Unsupported QR code format');
    } catch (e) {
      throw Exception('Failed to parse QR code: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => cameraController.toggleTorch(),
            tooltip: 'Toggle Flash',
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => cameraController.switchCamera(),
            tooltip: 'Switch Camera',
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: _onDetect,
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black87,
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.qr_code_scanner, color: Colors.white, size: 48),
                  SizedBox(height: 8),
                  Text(
                    'Scan the QR code on your ESP device',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'The QR code contains device name, security info, and connection details',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
