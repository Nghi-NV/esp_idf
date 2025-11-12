import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'esp_idf_platform_interface.dart';
import 'src/models.dart';

/// An implementation of [EspIdfPlatform] that uses method channels.
class MethodChannelEspIdf extends EspIdfPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('esp_idf');

  /// Event channel for BLE device discovery
  @visibleForTesting
  final bleDeviceEventChannel = const EventChannel('esp_idf/ble_devices');

  /// Event channel for connection status
  @visibleForTesting
  final connectionEventChannel = const EventChannel(
    'esp_idf/connection_status',
  );

  /// Event channel for provisioning status
  @visibleForTesting
  final provisioningEventChannel = const EventChannel(
    'esp_idf/provisioning_status',
  );

  final Map<String, StreamController<ESPConnectionStatus>>
  _connectionControllers = {};
  final Map<String, StreamController<ESPProvisionStatus>>
  _provisioningControllers = {};
  StreamSubscription? _bleDeviceSubscription;
  StreamController<ESPDevice>? _bleDeviceController;

  @override
  Stream<ESPDevice> searchBleDevices(String prefix) {
    _bleDeviceController?.close();
    _bleDeviceController = StreamController<ESPDevice>.broadcast();

    methodChannel.invokeMethod('searchBleDevices', {'prefix': prefix});

    _bleDeviceSubscription = bleDeviceEventChannel
        .receiveBroadcastStream()
        .listen(
          (event) {
            if (event is Map) {
              final device = ESPDevice.fromMap(
                Map<String, dynamic>.from(event),
              );
              _bleDeviceController?.add(device);
            }
          },
          onError: (error) {
            _bleDeviceController?.addError(error);
          },
        );

    return _bleDeviceController!.stream;
  }

  @override
  Future<void> stopBleSearch() async {
    await methodChannel.invokeMethod('stopBleSearch');
    await _bleDeviceSubscription?.cancel();
    await _bleDeviceController?.close();
    _bleDeviceController = null;
  }

  @override
  Future<String> createDevice({
    required String deviceName,
    required ESPTransportType transport,
    required ESPSecurityType security,
    String? proofOfPossession,
    String? username,
    String? softApPassword,
    String? primaryServiceUuid,
  }) async {
    final result = await methodChannel.invokeMethod<String>('createDevice', {
      'deviceName': deviceName,
      'transport': transport.name,
      'security': security.name,
      'proofOfPossession': proofOfPossession,
      'username': username,
      'softApPassword': softApPassword,
      'primaryServiceUuid': primaryServiceUuid,
    });
    return result ?? '';
  }

  @override
  Future<void> connectDevice(String deviceId) async {
    await methodChannel.invokeMethod('connectDevice', {'deviceId': deviceId});
  }

  @override
  Future<void> disconnectDevice(String deviceId) async {
    await methodChannel.invokeMethod('disconnectDevice', {
      'deviceId': deviceId,
    });
  }

  @override
  Future<List<ESPWifiNetwork>> scanWifiNetworks(String deviceId) async {
    final result = await methodChannel.invokeMethod<List>('scanWifiNetworks', {
      'deviceId': deviceId,
    });

    if (result == null) return [];

    return result
        .map((e) => ESPWifiNetwork.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<void> provisionDevice({
    required String deviceId,
    required String ssid,
    String? password,
  }) async {
    await methodChannel.invokeMethod('provisionDevice', {
      'deviceId': deviceId,
      'ssid': ssid,
      'password': password,
    });
  }

  @override
  Stream<ESPConnectionStatus> getConnectionStatusStream(String deviceId) {
    if (!_connectionControllers.containsKey(deviceId)) {
      _connectionControllers[deviceId] =
          StreamController<ESPConnectionStatus>.broadcast();

      connectionEventChannel
          .receiveBroadcastStream(deviceId)
          .listen(
            (event) {
              if (event is String) {
                final status = ESPConnectionStatus.values.firstWhere(
                  (e) => e.name == event,
                  orElse: () => ESPConnectionStatus.disconnected,
                );
                _connectionControllers[deviceId]?.add(status);
              }
            },
            onError: (error) {
              _connectionControllers[deviceId]?.addError(error);
            },
          );
    }

    return _connectionControllers[deviceId]!.stream;
  }

  @override
  Stream<ESPProvisionStatus> getProvisioningStatusStream(String deviceId) {
    if (!_provisioningControllers.containsKey(deviceId)) {
      _provisioningControllers[deviceId] =
          StreamController<ESPProvisionStatus>.broadcast();

      provisioningEventChannel
          .receiveBroadcastStream(deviceId)
          .listen(
            (event) {
              if (event is String) {
                final status = ESPProvisionStatus.values.firstWhere(
                  (e) => e.name == event,
                  orElse: () => ESPProvisionStatus.failed,
                );
                _provisioningControllers[deviceId]?.add(status);
              }
            },
            onError: (error) {
              _provisioningControllers[deviceId]?.addError(error);
            },
          );
    }

    return _provisioningControllers[deviceId]!.stream;
  }

  @override
  Future<bool> isBluetoothEnabled() async {
    final result = await methodChannel.invokeMethod<bool>('isBluetoothEnabled');
    return result ?? false;
  }

  @override
  Future<bool> requestPermissions() async {
    final result = await methodChannel.invokeMethod<bool>('requestPermissions');
    return result ?? false;
  }

  @override
  Future<bool> checkPermissions() async {
    final result = await methodChannel.invokeMethod<bool>('checkPermissions');
    return result ?? false;
  }

  @override
  Future<ESPQRCodePayload> scanQRCode({
    String? title,
    String? description,
    String? cancelButtonText,
  }) async {
    final result = await methodChannel.invokeMethod<Map>('scanQRCode', {
      'title': title,
      'description': description,
      'cancelButtonText': cancelButtonText,
    });

    if (result == null) {
      throw Exception('QR code scanning failed');
    }

    final resultMap = Map<String, dynamic>.from(result);

    // Convert the result to ESPQRCodePayload format
    return ESPQRCodePayload(
      name: resultMap['name'] as String,
      transport: ESPTransportType.values.firstWhere(
        (e) => e.name == resultMap['transport'],
        orElse: () => ESPTransportType.ble,
      ),
      security: ESPSecurityType.values.firstWhere(
        (e) => e.name == resultMap['security'],
        orElse: () => ESPSecurityType.secure,
      ),
      proofOfPossession: resultMap['pop'] as String?,
      username: resultMap['username'] as String?,
      password: resultMap['password'] as String?,
    );
  }

  @override
  Future<void> connectWiFiDevice(String deviceId) async {
    await methodChannel.invokeMethod('connectWiFiDevice', {
      'deviceId': deviceId,
    });
  }
}
