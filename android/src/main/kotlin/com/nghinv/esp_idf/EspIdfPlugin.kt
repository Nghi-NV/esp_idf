package com.nghinv.esp_idf

import android.Manifest
import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.espressif.provisioning.ESPConstants
import com.espressif.provisioning.ESPDevice
import com.espressif.provisioning.ESPProvisionManager
import com.espressif.provisioning.WiFiAccessPoint
import com.espressif.provisioning.listeners.BleScanListener
import com.espressif.provisioning.listeners.ProvisionListener
import com.espressif.provisioning.listeners.WiFiScanListener
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import java.util.UUID

/** EspIdfPlugin */
class EspIdfPlugin : FlutterPlugin, MethodCallHandler, ActivityAware,
    PluginRegistry.RequestPermissionsResultListener {

    private lateinit var channel: MethodChannel
    private lateinit var bleDeviceEventChannel: EventChannel
    private lateinit var connectionEventChannel: EventChannel
    private lateinit var provisioningEventChannel: EventChannel

    private var bleDeviceEventSink: EventChannel.EventSink? = null
    private var provisionManager: ESPProvisionManager? = null
    private val devices = mutableMapOf<String, ESPDevice>()
    private var activity: Activity? = null
    private var context: Context? = null
    private var pendingPermissionResult: Result? = null
    private var pendingQRResult: Result? = null

    companion object {
        private const val PERMISSION_REQUEST_CODE = 1001
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "esp_idf")
        channel.setMethodCallHandler(this)

        bleDeviceEventChannel = EventChannel(
            flutterPluginBinding.binaryMessenger,
            "esp_idf/ble_devices"
        )
        bleDeviceEventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                bleDeviceEventSink = events
            }

            override fun onCancel(arguments: Any?) {
                bleDeviceEventSink = null
            }
        })

        connectionEventChannel = EventChannel(
            flutterPluginBinding.binaryMessenger,
            "esp_idf/connection_status"
        )

        provisioningEventChannel = EventChannel(
            flutterPluginBinding.binaryMessenger,
            "esp_idf/provisioning_status"
        )

        provisionManager = ESPProvisionManager.getInstance(context)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "searchBleDevices" -> searchBleDevices(call, result)
            "stopBleSearch" -> stopBleSearch(result)
            "createDevice" -> createDevice(call, result)
            "connectDevice" -> connectDevice(call, result)
            "disconnectDevice" -> disconnectDevice(call, result)
            "scanWifiNetworks" -> scanWifiNetworks(call, result)
            "provisionDevice" -> provisionDevice(call, result)
            "isBluetoothEnabled" -> isBluetoothEnabled(result)
            "requestPermissions" -> requestPermissions(result)
            "checkPermissions" -> checkPermissions(result)
            "scanQRCode" -> scanQRCode(result)
            "connectWiFiDevice" -> connectWiFiDevice(call, result)
            else -> result.notImplemented()
        }
    }

    private fun searchBleDevices(call: MethodCall, result: Result) {
        val prefix = call.argument<String>("prefix") ?: ""

        provisionManager?.searchBleEspDevices(prefix, object : BleScanListener {
            override fun scanStartFailed() {
                bleDeviceEventSink?.error("SCAN_FAILED", "Failed to start BLE scan", null)
            }

            override fun onPeripheralFound(device: BluetoothDevice?, scanResult: android.bluetooth.le.ScanResult?) {
                device?.let {
                    val deviceName = it.name ?: ""
                    val deviceMap = mapOf(
                        "name" to deviceName,
                        "transport" to "ble",
                        "security" to "secure",
                        "deviceId" to it.address
                    )
                    bleDeviceEventSink?.success(deviceMap)
                }
            }

            override fun scanCompleted() {
                // Scan completed
            }

            override fun onFailure(e: Exception?) {
                bleDeviceEventSink?.error("SCAN_ERROR", e?.message ?: "Unknown error", null)
            }
        })

        result.success(null)
    }

    private fun stopBleSearch(result: Result) {
        // The Android library doesn't have an explicit stop method
        // Scan automatically stops after timeout
        result.success(null)
    }

    private fun createDevice(call: MethodCall, result: Result) {
        val deviceName = call.argument<String>("deviceName") ?: ""
        val transport = call.argument<String>("transport") ?: "ble"
        val security = call.argument<String>("security") ?: "secure"
        val proofOfPossession = call.argument<String>("proofOfPossession")
        val username = call.argument<String>("username")
        val softApPassword = call.argument<String>("softApPassword")
        val primaryServiceUuid = call.argument<String>("primaryServiceUuid")

        val espTransport = when (transport) {
            "ble" -> ESPConstants.TransportType.TRANSPORT_BLE
            "softAp" -> ESPConstants.TransportType.TRANSPORT_SOFTAP
            else -> ESPConstants.TransportType.TRANSPORT_BLE
        }

        val espSecurity = when (security) {
            "unsecured" -> ESPConstants.SecurityType.SECURITY_0
            "secure" -> ESPConstants.SecurityType.SECURITY_1
            "secure2" -> ESPConstants.SecurityType.SECURITY_2
            else -> ESPConstants.SecurityType.SECURITY_1
        }

        val device = provisionManager?.createESPDevice(espTransport, espSecurity)

        device?.let {
            it.deviceName = deviceName
            proofOfPossession?.let { pop -> it.proofOfPossession = pop }
            username?.let { user -> it.userName = user }

            if (espTransport == ESPConstants.TransportType.TRANSPORT_BLE && primaryServiceUuid != null) {
                it.primaryServiceUuid = primaryServiceUuid
            }

            val deviceId = deviceName // Use device name as ID
            devices[deviceId] = it
            result.success(deviceId)
        } ?: result.error("CREATE_FAILED", "Failed to create device", null)
    }

    private fun connectDevice(call: MethodCall, result: Result) {
        val deviceId = call.argument<String>("deviceId") ?: ""
        val device = devices[deviceId]

        if (device == null) {
            result.error("DEVICE_NOT_FOUND", "Device not found", null)
            return
        }

        device.connectToDevice()
        result.success(null)
    }

    private fun disconnectDevice(call: MethodCall, result: Result) {
        val deviceId = call.argument<String>("deviceId") ?: ""
        val device = devices[deviceId]

        if (device == null) {
            result.error("DEVICE_NOT_FOUND", "Device not found", null)
            return
        }

        device.disconnectDevice()
        result.success(null)
    }

    private fun scanWifiNetworks(call: MethodCall, result: Result) {
        val deviceId = call.argument<String>("deviceId") ?: ""
        val device = devices[deviceId]

        if (device == null) {
            result.error("DEVICE_NOT_FOUND", "Device not found", null)
            return
        }

        device.scanNetworks(object : WiFiScanListener {
            override fun onWifiListReceived(wifiList: ArrayList<WiFiAccessPoint>?) {
                val networks = wifiList?.map { wifi ->
                    mapOf(
                        "ssid" to wifi.wifiName,
                        "rssi" to wifi.rssi,
                        "auth" to wifi.security,
                        "channel" to 0
                    )
                } ?: emptyList()

                result.success(networks)
            }

            override fun onWiFiScanFailed(e: Exception?) {
                result.error("SCAN_FAILED", e?.message ?: "Wi-Fi scan failed", null)
            }
        })
    }

    private fun provisionDevice(call: MethodCall, result: Result) {
        val deviceId = call.argument<String>("deviceId") ?: ""
        val ssid = call.argument<String>("ssid") ?: ""
        val password = call.argument<String>("password") ?: ""
        val device = devices[deviceId]

        if (device == null) {
            result.error("DEVICE_NOT_FOUND", "Device not found", null)
            return
        }

        device.provision(ssid, password, object : ProvisionListener {
            override fun createSessionFailed(e: Exception?) {
                result.error("SESSION_FAILED", e?.message ?: "Session creation failed", null)
            }

            override fun wifiConfigSent() {
                // Config sent
            }

            override fun wifiConfigFailed(e: Exception?) {
                result.error("CONFIG_FAILED", e?.message ?: "Config failed", null)
            }

            override fun wifiConfigApplied() {
                // Config applied
            }

            override fun wifiConfigApplyFailed(e: Exception?) {
                result.error("APPLY_FAILED", e?.message ?: "Apply failed", null)
            }

            override fun provisioningFailedFromDevice(failureReason: ESPConstants.ProvisionFailureReason?) {
                result.error("PROVISION_FAILED", "Provisioning failed: $failureReason", null)
            }

            override fun deviceProvisioningSuccess() {
                result.success(null)
            }

            override fun onProvisioningFailed(e: Exception?) {
                result.error("PROVISION_ERROR", e?.message ?: "Provisioning error", null)
            }
        })
    }

    private fun scanQRCode(result: Result) {
        if (activity == null) {
            result.error("NO_ACTIVITY", "Activity not available", null)
            return
        }

        // Store the result for later use when QR code is scanned
        pendingQRResult = result

        // For QR code scanning, we'll use a simpler approach
        // The app should handle QR scanning UI and pass the data to createDevice
        result.error("NOT_IMPLEMENTED",
            "QR scanning should be implemented in the Flutter UI layer. Use a package like mobile_scanner or qr_code_scanner, then pass the data to createDevice().",
            null)
    }

    private fun connectWiFiDevice(call: MethodCall, result: Result) {
        val deviceId = call.argument<String>("deviceId") ?: ""
        val device = devices[deviceId]

        if (device == null) {
            result.error("DEVICE_NOT_FOUND", "Device not found", null)
            return
        }

        // For SoftAP, we need to use connectWiFiDevice() instead of connectToDevice()
        device.connectWiFiDevice()
        result.success(null)
    }

    private fun isBluetoothEnabled(result: Result) {
        val bluetoothManager = context?.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
        val bluetoothAdapter = bluetoothManager?.adapter
        result.success(bluetoothAdapter?.isEnabled == true)
    }

    private fun checkPermissions(result: Result) {
        val permissions = getRequiredPermissions()
        val allGranted = permissions.all { permission ->
            ContextCompat.checkSelfPermission(context!!, permission) == PackageManager.PERMISSION_GRANTED
        }
        result.success(allGranted)
    }

    private fun requestPermissions(result: Result) {
        if (activity == null) {
            result.error("NO_ACTIVITY", "Activity not available", null)
            return
        }

        val permissions = getRequiredPermissions()
        val notGranted = permissions.filter { permission ->
            ContextCompat.checkSelfPermission(context!!, permission) != PackageManager.PERMISSION_GRANTED
        }

        if (notGranted.isEmpty()) {
            result.success(true)
            return
        }

        pendingPermissionResult = result
        ActivityCompat.requestPermissions(
            activity!!,
            notGranted.toTypedArray(),
            PERMISSION_REQUEST_CODE
        )
    }

    private fun getRequiredPermissions(): List<String> {
        val permissions = mutableListOf<String>()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            permissions.add(Manifest.permission.BLUETOOTH_SCAN)
            permissions.add(Manifest.permission.BLUETOOTH_CONNECT)
        } else {
            permissions.add(Manifest.permission.BLUETOOTH)
            permissions.add(Manifest.permission.BLUETOOTH_ADMIN)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            permissions.add(Manifest.permission.ACCESS_FINE_LOCATION)
        } else {
            permissions.add(Manifest.permission.ACCESS_COARSE_LOCATION)
            permissions.add(Manifest.permission.ACCESS_FINE_LOCATION)
        }

        permissions.add(Manifest.permission.ACCESS_WIFI_STATE)
        permissions.add(Manifest.permission.CHANGE_WIFI_STATE)
        permissions.add(Manifest.permission.ACCESS_NETWORK_STATE)
        permissions.add(Manifest.permission.CHANGE_NETWORK_STATE)

        return permissions
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ): Boolean {
        if (requestCode == PERMISSION_REQUEST_CODE) {
            val allGranted = grantResults.all { it == PackageManager.PERMISSION_GRANTED }
            pendingPermissionResult?.success(allGranted)
            pendingPermissionResult = null
            return true
        }
        return false
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        bleDeviceEventChannel.setStreamHandler(null)
        connectionEventChannel.setStreamHandler(null)
        provisioningEventChannel.setStreamHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activity = null
    }
}
