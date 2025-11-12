/// Base exception for ESP IDF operations
class ESPException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  ESPException(this.message, {this.code, this.details});

  @override
  String toString() {
    if (code != null) {
      return 'ESPException($code): $message';
    }
    return 'ESPException: $message';
  }
}

/// Exception thrown when device connection fails
class ESPConnectionException extends ESPException {
  ESPConnectionException(super.message, {super.code, super.details});
}

/// Exception thrown when provisioning fails
class ESPProvisioningException extends ESPException {
  ESPProvisioningException(super.message, {super.code, super.details});
}

/// Exception thrown when Wi-Fi scanning fails
class ESPScanException extends ESPException {
  ESPScanException(super.message, {super.code, super.details});
}

/// Exception thrown when Bluetooth operations fail
class ESPBluetoothException extends ESPException {
  ESPBluetoothException(super.message, {super.code, super.details});
}

/// Exception thrown when permissions are not granted
class ESPPermissionException extends ESPException {
  ESPPermissionException(super.message, {super.code, super.details});
}
