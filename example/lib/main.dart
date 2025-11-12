import 'package:flutter/material.dart';
import 'dart:async';

import 'package:esp_idf/esp_idf.dart';
import 'qr_scanner_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ESP-IDF Provisioning',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ProvisioningHomePage(),
    );
  }
}

enum ConnectionMode { ble, wifi }

class ProvisioningHomePage extends StatefulWidget {
  const ProvisioningHomePage({super.key});

  @override
  State<ProvisioningHomePage> createState() => _ProvisioningHomePageState();
}

class _ProvisioningHomePageState extends State<ProvisioningHomePage> {
  final _espIdf = EspIdf();
  final List<ESPDevice> _discoveredDevices = [];
  bool _isScanning = false;
  StreamSubscription? _bleScanSubscription;
  ConnectionMode _selectedMode = ConnectionMode.ble;

  final _devicePrefixController = TextEditingController(text: 'PROV_');
  final _popController = TextEditingController();
  final _deviceNameController = TextEditingController(text: 'PROV_');
  final _softApPasswordController = TextEditingController();

  String _statusMessage = 'Ready';

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  @override
  void dispose() {
    _bleScanSubscription?.cancel();
    _devicePrefixController.dispose();
    _popController.dispose();
    _deviceNameController.dispose();
    _softApPasswordController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    final hasPermissions = await _espIdf.checkPermissions();
    if (!hasPermissions) {
      _updateStatus('Permissions required');
    } else {
      _updateStatus('Ready to scan');
    }
  }

  Future<void> _requestPermissions() async {
    _updateStatus('Requesting permissions...');
    final granted = await _espIdf.requestPermissions();
    if (granted) {
      _updateStatus('Permissions granted');
    } else {
      _updateStatus('Permissions denied');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permissions are required for BLE and Wi-Fi operations'),
          ),
        );
      }
    }
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _discoveredDevices.clear();
      _statusMessage = 'Scanning for devices...';
    });

    try {
      final bleEnabled = await _espIdf.isBluetoothEnabled();
      if (!bleEnabled) {
        _updateStatus('Bluetooth is not enabled');
        setState(() => _isScanning = false);
        return;
      }

      _bleScanSubscription?.cancel();
      _bleScanSubscription = _espIdf
          .searchBleDevices(_devicePrefixController.text)
          .listen(
        (device) {
          setState(() {
            if (!_discoveredDevices.any((d) => d.name == device.name)) {
              _discoveredDevices.add(device);
            }
          });
          _updateStatus('Found ${_discoveredDevices.length} device(s)');
        },
        onError: (error) {
          _updateStatus('Scan error: $error');
          setState(() => _isScanning = false);
        },
      );

      // Stop scan after 30 seconds
      Future.delayed(const Duration(seconds: 30), () {
        if (_isScanning) {
          _stopScan();
        }
      });
    } catch (e) {
      _updateStatus('Error: $e');
      setState(() => _isScanning = false);
    }
  }

  Future<void> _stopScan() async {
    await _bleScanSubscription?.cancel();
    await _espIdf.stopBleSearch();
    setState(() {
      _isScanning = false;
    });
    _updateStatus('Scan stopped');
  }

  Future<void> _connectToDevice(ESPDevice device) async {
    _updateStatus('Connecting to ${device.name}...');

    try {
      final deviceId = await _espIdf.createDevice(
        deviceName: device.name,
        transport: ESPTransportType.ble,
        security: ESPSecurityType.secure,
        proofOfPossession: _popController.text.isNotEmpty
            ? _popController.text
            : null,
      );

      await _espIdf.connectDevice(deviceId);

      _updateStatus('Connected to ${device.name}');
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProvisioningPage(
              espIdf: _espIdf,
              deviceId: deviceId,
              deviceName: device.name,
            ),
          ),
        );
      }
    } catch (e) {
      _updateStatus('Connection failed: $e');
    }
  }

  Future<void> _connectManualWiFi() async {
    if (_deviceNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter device name')),
      );
      return;
    }

    _updateStatus('Creating WiFi device...');

    try {
      final deviceId = await _espIdf.createDevice(
        deviceName: _deviceNameController.text,
        transport: ESPTransportType.softAp,
        security: ESPSecurityType.secure,
        proofOfPossession: _popController.text.isNotEmpty
            ? _popController.text
            : null,
        softApPassword: _softApPasswordController.text.isNotEmpty
            ? _softApPasswordController.text
            : null,
      );

      _updateStatus('Connecting to device via WiFi...');
      await _espIdf.connectWiFiDevice(deviceId);

      _updateStatus('Connected via WiFi');
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProvisioningPage(
              espIdf: _espIdf,
              deviceId: deviceId,
              deviceName: _deviceNameController.text,
            ),
          ),
        );
      }
    } catch (e) {
      _updateStatus('WiFi connection failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection failed: $e')),
        );
      }
    }
  }

  Future<void> _scanQRCode() async {
    try {
      _updateStatus('Opening QR scanner...');

      // Try native QR scanner first (iOS uses native ESPProvision scanner)
      try {
        final qrData = await _espIdf.scanQRCode(
          title: 'Scan ESP Device',
          description: 'Point your camera at the QR code on your ESP device',
          cancelButtonText: 'Close',
        );

        _updateStatus('QR code scanned, connecting...');

        // Device is already created by native scanner on iOS
        // For Android, we need to create it
        final deviceId = qrData.name;

        if (qrData.transport == ESPTransportType.ble) {
          await _espIdf.connectDevice(deviceId);
        } else {
          await _espIdf.connectWiFiDevice(deviceId);
        }

        _updateStatus('Connected via QR code');
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProvisioningPage(
                espIdf: _espIdf,
                deviceId: deviceId,
                deviceName: qrData.name,
              ),
            ),
          );
        }
      } catch (e) {
        // If native scanner fails or not implemented, fall back to Flutter scanner
        if (e.toString().contains('NOT_IMPLEMENTED') ||
            e.toString().contains('USER_CANCELLED')) {
          if (!mounted) return;
          final result = await Navigator.push<Map<String, dynamic>>(
            context,
            MaterialPageRoute(
              builder: (context) => const QRScannerPage(),
            ),
          );

          if (result == null) return;

          _updateStatus('QR code scanned, connecting...');

          final deviceId = await _espIdf.createDevice(
            deviceName: result['name'] as String,
            transport: result['transport'] as ESPTransportType,
            security: result['security'] as ESPSecurityType,
            proofOfPossession: result['pop'] as String?,
            username: result['username'] as String?,
            softApPassword: result['password'] as String?,
          );

          if (result['transport'] == ESPTransportType.ble) {
            await _espIdf.connectDevice(deviceId);
          } else {
            await _espIdf.connectWiFiDevice(deviceId);
          }

          _updateStatus('Connected via QR code');
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProvisioningPage(
                  espIdf: _espIdf,
                  deviceId: deviceId,
                  deviceName: result['name'] as String,
                ),
              ),
            );
          }
        } else {
          rethrow;
        }
      }
    } catch (e) {
      _updateStatus('QR scan failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('QR scan failed: $e')),
        );
      }
    }
  }

  void _updateStatus(String message) {
    setState(() {
      _statusMessage = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ESP-IDF Provisioning'),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _scanQRCode,
            tooltip: 'Scan QR Code',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mode Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Connection Mode',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<ConnectionMode>(
                      segments: const [
                        ButtonSegment(
                          value: ConnectionMode.ble,
                          label: Text('BLE'),
                          icon: Icon(Icons.bluetooth),
                        ),
                        ButtonSegment(
                          value: ConnectionMode.wifi,
                          label: Text('WiFi (SoftAP)'),
                          icon: Icon(Icons.wifi),
                        ),
                      ],
                      selected: {_selectedMode},
                      onSelectionChanged: (Set<ConnectionMode> newSelection) {
                        setState(() {
                          _selectedMode = newSelection.first;
                          _discoveredDevices.clear();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Configuration Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Configuration',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_selectedMode == ConnectionMode.ble) ...[
                      TextField(
                        controller: _devicePrefixController,
                        decoration: const InputDecoration(
                          labelText: 'Device Prefix',
                          hintText: 'e.g., PROV_',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ] else ...[
                      TextField(
                        controller: _deviceNameController,
                        decoration: const InputDecoration(
                          labelText: 'Device Name / SSID',
                          hintText: 'Enter device WiFi name',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _softApPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'SoftAP Password (Optional)',
                          hintText: 'WiFi password if protected',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: _popController,
                      decoration: const InputDecoration(
                        labelText: 'Proof of Possession (Optional)',
                        hintText: 'Enter PoP if required',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_selectedMode == ConnectionMode.ble)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isScanning ? null : _requestPermissions,
                      icon: const Icon(Icons.lock_open),
                      label: const Text('Permissions'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isScanning ? _stopScan : _startScan,
                      icon: Icon(_isScanning ? Icons.stop : Icons.search),
                      label: Text(_isScanning ? 'Stop Scan' : 'Start Scan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isScanning ? Colors.red : Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: _connectManualWiFi,
                    icon: const Icon(Icons.wifi),
                    label: const Text('Connect via WiFi (SoftAP)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Connect your phone to the device\'s WiFi network first, then tap Connect.',
                            style: TextStyle(
                              color: Colors.orange.shade900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _statusMessage,
                      style: const TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_selectedMode == ConnectionMode.ble) ...[
              const Text(
                'Discovered Devices',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _discoveredDevices.isEmpty
                    ? Center(
                        child: Text(
                          _isScanning
                              ? 'Scanning...'
                              : 'No devices found. Start scanning to discover devices.',
                          style: TextStyle(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        itemCount: _discoveredDevices.length,
                        itemBuilder: (context, index) {
                          final device = _discoveredDevices[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.bluetooth),
                              ),
                              title: Text(device.name),
                              subtitle: Text('Transport: ${device.transport.name}'),
                              trailing: ElevatedButton(
                                onPressed: () => _connectToDevice(device),
                                child: const Text('Connect'),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ProvisioningPage extends StatefulWidget {
  final EspIdf espIdf;
  final String deviceId;
  final String deviceName;

  const ProvisioningPage({
    super.key,
    required this.espIdf,
    required this.deviceId,
    required this.deviceName,
  });

  @override
  State<ProvisioningPage> createState() => _ProvisioningPageState();
}

class _ProvisioningPageState extends State<ProvisioningPage> {
  List<ESPWifiNetwork> _wifiNetworks = [];
  bool _isScanning = false;
  bool _isProvisioning = false;
  String? _selectedSsid;
  final _passwordController = TextEditingController();
  String _statusMessage = 'Connected to device';

  @override
  void initState() {
    super.initState();
    _scanWifiNetworks();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _scanWifiNetworks() async {
    setState(() {
      _isScanning = true;
      _statusMessage = 'Scanning for Wi-Fi networks...';
    });

    try {
      final networks = await widget.espIdf.scanWifiNetworks(widget.deviceId);
      setState(() {
        _wifiNetworks = networks;
        _wifiNetworks.sort((a, b) => b.rssi.compareTo(a.rssi));
        _isScanning = false;
        _statusMessage = 'Found ${networks.length} network(s)';
      });
    } catch (e) {
      setState(() {
        _isScanning = false;
        _statusMessage = 'Scan failed: $e';
      });
    }
  }

  Future<void> _provision() async {
    if (_selectedSsid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a Wi-Fi network')),
      );
      return;
    }

    setState(() {
      _isProvisioning = true;
      _statusMessage = 'Provisioning device...';
    });

    try {
      await widget.espIdf.provisionDevice(
        deviceId: widget.deviceId,
        ssid: _selectedSsid!,
        password: _passwordController.text,
      );

      setState(() {
        _isProvisioning = false;
        _statusMessage = 'Provisioning successful!';
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Success'),
            content: Text(
              'Device "${widget.deviceName}" has been provisioned successfully with network "$_selectedSsid".',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isProvisioning = false;
        _statusMessage = 'Provisioning failed: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Provisioning failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Provision ${widget.deviceName}'),
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _statusMessage,
                      style: const TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  'Available Wi-Fi Networks',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _isScanning ? null : _scanWifiNetworks,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _isScanning
                  ? const Center(child: CircularProgressIndicator())
                  : _wifiNetworks.isEmpty
                      ? const Center(
                          child: Text('No Wi-Fi networks found'),
                        )
                      : ListView.builder(
                          itemCount: _wifiNetworks.length,
                          itemBuilder: (context, index) {
                            final network = _wifiNetworks[index];
                            final isSelected = _selectedSsid == network.ssid;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              color: isSelected
                                  ? Colors.blue.shade50
                                  : null,
                              child: ListTile(
                                leading: Icon(
                                  _getWifiIcon(network.rssi),
                                  color: isSelected ? Colors.blue : null,
                                ),
                                title: Text(
                                  network.ssid,
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                subtitle: Text(
                                  '${network.authModeString} • ${network.rssi} dBm',
                                ),
                                trailing: isSelected
                                    ? const Icon(
                                        Icons.check_circle,
                                        color: Colors.blue,
                                      )
                                    : null,
                                onTap: () {
                                  setState(() {
                                    _selectedSsid = network.ssid;
                                  });
                                },
                              ),
                            );
                          },
                        ),
            ),
            const SizedBox(height: 16),
            if (_selectedSsid != null) ...[
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Wi-Fi Password',
                  hintText: 'Enter password for $_selectedSsid',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isProvisioning ? null : _provision,
                icon: _isProvisioning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(_isProvisioning ? 'Provisioning...' : 'Provision Device'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getWifiIcon(int rssi) {
    if (rssi >= -50) {
      return Icons.wifi;
    } else if (rssi >= -70) {
      return Icons.wifi_2_bar;
    } else {
      return Icons.wifi_1_bar;
    }
  }
}
