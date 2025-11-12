Pod::Spec.new do |s|
  s.name             = 'esp_idf'
  s.version          = '0.0.1'
  s.summary          = 'Flutter plugin for ESP32/ESP8266 device provisioning using ESP-IDF'
  s.description      = <<-DESC
Flutter plugin for ESP32/ESP8266 device provisioning using ESP-IDF. 
Supports BLE and SoftAP transport with multiple security modes.
                       DESC
  s.homepage         = 'https://github.com/Nghi-NV/esp_idf'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Nghi-NV' => 'https://github.com/Nghi-NV' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'ESPProvision', '3.0.3'

  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
