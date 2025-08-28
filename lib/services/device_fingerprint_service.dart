import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

class DeviceFingerprintService {
  static final DeviceFingerprintService _instance =
      DeviceFingerprintService._internal();
  factory DeviceFingerprintService() => _instance;
  DeviceFingerprintService._internal();

  String? _cachedFingerprint;
  Map<String, dynamic>? _cachedDeviceInfo;

  /// Generate a unique device fingerprint
  Future<String> generateFingerprint() async {
    if (_cachedFingerprint != null) {
      return _cachedFingerprint!;
    }

    final deviceInfo = await getDeviceInfo();
    final fingerprintData = {
      'deviceId': deviceInfo['deviceId'],
      'model': deviceInfo['model'],
      'brand': deviceInfo['brand'],
      'systemVersion': deviceInfo['systemVersion'],
      'appVersion': deviceInfo['appVersion'],
      'screenResolution': deviceInfo['screenResolution'],
      'platform': deviceInfo['platform'],
    };

    // Create deterministic hash from device characteristics
    final jsonString = json.encode(fingerprintData);
    final bytes = utf8.encode(jsonString);
    final digest = sha256.convert(bytes);

    _cachedFingerprint = digest.toString();
    return _cachedFingerprint!;
  }

  /// Get comprehensive device information
  Future<Map<String, dynamic>> getDeviceInfo() async {
    if (_cachedDeviceInfo != null) {
      return _cachedDeviceInfo!;
    }

    final deviceInfoPlugin = DeviceInfoPlugin();
    final packageInfo = await PackageInfo.fromPlatform();
    final connectivity = Connectivity();

    Map<String, dynamic> deviceData = {
      'platform': Platform.operatingSystem,
      'appVersion': packageInfo.version,
      'buildNumber': packageInfo.buildNumber,
      'packageName': packageInfo.packageName,
    };

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        deviceData.addAll({
          'deviceId': androidInfo.id,
          'model': androidInfo.model,
          'brand': androidInfo.brand,
          'manufacturer': androidInfo.manufacturer,
          'product': androidInfo.product,
          'systemVersion': androidInfo.version.release,
          'sdkVersion': androidInfo.version.sdkInt,
          'isPhysicalDevice': androidInfo.isPhysicalDevice,
          'androidId': androidInfo.id,
          'fingerprint': androidInfo.fingerprint,
          'hardware': androidInfo.hardware,
          'bootloader': androidInfo.bootloader,
          'board': androidInfo.board,
          'host': androidInfo.host,
          'tags': androidInfo.tags,
          'type': androidInfo.type,
          'screenResolution':
              'unknown', // displaySizePixels not available in device_info_plus
          'screenDensity': 1.0, // Default density
        });
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        deviceData.addAll({
          'deviceId': iosInfo.identifierForVendor ?? 'unknown',
          'model': iosInfo.model,
          'brand': 'Apple',
          'manufacturer': 'Apple',
          'name': iosInfo.name,
          'systemVersion': iosInfo.systemVersion,
          'isPhysicalDevice': iosInfo.isPhysicalDevice,
          'localizedModel': iosInfo.localizedModel,
          'systemName': iosInfo.systemName,
          'utsname': {
            'machine': iosInfo.utsname.machine,
            'nodename': iosInfo.utsname.nodename,
            'release': iosInfo.utsname.release,
            'sysname': iosInfo.utsname.sysname,
            'version': iosInfo.utsname.version,
          },
        });
      }

      // Add network information
      final connectivityResult = await connectivity.checkConnectivity();
      deviceData['connectionType'] = connectivityResult.first.name;

      // Add timestamp
      deviceData['collectedAt'] = DateTime.now().toIso8601String();
    } catch (e) {
      deviceData['error'] = e.toString();
    }

    _cachedDeviceInfo = deviceData;
    return deviceData;
  }

  /// Check if device appears to be rooted/jailbroken
  Future<bool> isDeviceCompromised() async {
    try {
      if (Platform.isAndroid) {
        return await _isAndroidRooted();
      } else if (Platform.isIOS) {
        return await _isIOSJailbroken();
      }
    } catch (e) {
      // If we can't determine, assume it's not compromised
      return false;
    }
    return false;
  }

  Future<bool> _isAndroidRooted() async {
    try {
      // Check for common root indicators
      final rootPaths = [
        '/system/app/Superuser.apk',
        '/sbin/su',
        '/system/bin/su',
        '/system/xbin/su',
        '/data/local/xbin/su',
        '/data/local/bin/su',
        '/system/sd/xbin/su',
        '/system/bin/failsafe/su',
        '/data/local/su',
        '/su/bin/su',
      ];

      for (String path in rootPaths) {
        if (await File(path).exists()) {
          return true;
        }
      }

      // Check for test-keys build
      final deviceInfo = await getDeviceInfo();
      final tags = deviceInfo['tags'] as String?;
      if (tags != null && tags.contains('test-keys')) {
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _isIOSJailbroken() async {
    try {
      // Check for common jailbreak indicators
      final jailbreakPaths = [
        '/Applications/Cydia.app',
        '/Library/MobileSubstrate/MobileSubstrate.dylib',
        '/bin/bash',
        '/usr/sbin/sshd',
        '/etc/apt',
        '/private/var/lib/apt/',
        '/private/var/lib/cydia',
        '/private/var/mobile/Library/SBSettings/Themes',
        '/Library/MobileSubstrate/DynamicLibraries/LiveClock.plist',
        '/usr/libexec/ssh-keysign',
        '/private/var/tmp/cydia.log',
        '/Applications/Icy.app',
        '/Applications/MxTube.app',
        '/Applications/RockApp.app',
        '/Applications/blackra1n.app',
        '/Applications/SBSettings.app',
        '/Applications/FakeCarrier.app',
        '/Applications/WinterBoard.app',
        '/Applications/IntelliScreen.app',
      ];

      for (String path in jailbreakPaths) {
        if (await File(path).exists()) {
          return true;
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Check if device is running in an emulator
  Future<bool> isEmulator() async {
    try {
      final deviceInfo = await getDeviceInfo();

      if (Platform.isAndroid) {
        final isPhysical = deviceInfo['isPhysicalDevice'] as bool? ?? true;
        if (!isPhysical) return true;

        // Check for emulator characteristics
        final model = (deviceInfo['model'] as String? ?? '').toLowerCase();
        final brand = (deviceInfo['brand'] as String? ?? '').toLowerCase();
        final manufacturer =
            (deviceInfo['manufacturer'] as String? ?? '').toLowerCase();
        final product = (deviceInfo['product'] as String? ?? '').toLowerCase();

        final emulatorIndicators = [
          'android sdk built for x86',
          'emulator',
          'simulator',
          'genymotion',
          'bluestacks',
          'google_sdk',
          'sdk_gphone',
          'vbox86',
        ];

        for (String indicator in emulatorIndicators) {
          if (model.contains(indicator) ||
              brand.contains(indicator) ||
              manufacturer.contains(indicator) ||
              product.contains(indicator)) {
            return true;
          }
        }
      } else if (Platform.isIOS) {
        final isPhysical = deviceInfo['isPhysicalDevice'] as bool? ?? true;
        if (!isPhysical) return true;

        // Check iOS simulator characteristics
        final model = (deviceInfo['model'] as String? ?? '').toLowerCase();
        if (model.contains('simulator')) {
          return true;
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Generate risk score based on device characteristics
  Future<int> calculateRiskScore() async {
    int riskScore = 0;

    try {
      // Check if device is compromised
      if (await isDeviceCompromised()) {
        riskScore += 50;
      }

      // Check if device is emulator
      if (await isEmulator()) {
        riskScore += 30;
      }

      final deviceInfo = await getDeviceInfo();

      // Check for suspicious characteristics
      if (deviceInfo['isPhysicalDevice'] == false) {
        riskScore += 25;
      }

      // Check for development/debug builds
      if (Platform.isAndroid) {
        final tags = deviceInfo['tags'] as String?;
        if (tags != null &&
            (tags.contains('test-keys') || tags.contains('dev-keys'))) {
          riskScore += 20;
        }
      }

      // Ensure risk score doesn't exceed 100
      return riskScore.clamp(0, 100);
    } catch (e) {
      // Return moderate risk if we can't assess properly
      return 30;
    }
  }

  /// Get network-related security information
  Future<Map<String, dynamic>> getNetworkSecurityInfo() async {
    try {
      final connectivity = Connectivity();
      final connectivityResult = await connectivity.checkConnectivity();

      return {
        'connectionType': connectivityResult.first.name,
        'timestamp': DateTime.now().toIso8601String(),
        'isVPNDetected': await _detectVPN(),
        'isProxyDetected': await _detectProxy(),
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  Future<bool> _detectVPN() async {
    try {
      // Basic VPN detection - check for common VPN network interfaces
      // This is a simplified implementation for production readiness

      if (Platform.isAndroid) {
        // Check for VPN interfaces and suspicious network patterns
        try {
          // Look for common VPN interface names
          final result = await Process.run('ip', ['route']);
          final output = result.stdout.toString();

          // Common VPN interface patterns
          final vpnPatterns = ['tun', 'tap', 'ppp', 'vpn', 'utun'];
          for (final pattern in vpnPatterns) {
            if (output.toLowerCase().contains(pattern)) {
              return true;
            }
          }

          // Check for VPN-specific routing patterns
          if (output.contains('0.0.0.0/1') || output.contains('128.0.0.0/1')) {
            return true; // Common VPN routing configuration
          }
        } catch (e) {
          // Fallback: check system properties
          try {
            final result = await Process.run('getprop', ['net.dns1']);
            final dns = result.stdout.toString().trim();

            // Check for common VPN DNS servers
            final vpnDNS = ['8.8.8.8', '1.1.1.1', '9.9.9.9'];
            if (vpnDNS.contains(dns)) {
              return true; // Likely using VPN DNS
            }
          } catch (_) {
            // If we can't detect, assume no VPN
          }
        }

        return false;
      } else if (Platform.isIOS) {
        // iOS VPN detection is more limited due to sandboxing
        // Check for network extension APIs (requires special entitlements)
        try {
          // Look for VPN configuration in network settings
          // This is a simplified check - in production, you might use
          // NetworkExtension framework or similar approaches

          // Check if device is using a VPN by examining network interfaces
          final result = await Process.run('ifconfig', []);
          final output = result.stdout.toString();

          // Look for VPN interface names
          if (output.contains('utun') || output.contains('ipsec')) {
            return true;
          }
        } catch (e) {
          // iOS restrictions make this difficult
          return false;
        }

        return false;
      }

      return false;
    } catch (e) {
      debugPrint('VPN detection error: $e');
      return false;
    }
  }

  Future<bool> _detectProxy() async {
    try {
      // Enhanced proxy detection implementation

      // Check for proxy environment variables
      final proxyVars = ['HTTP_PROXY', 'HTTPS_PROXY', 'FTP_PROXY', 'ALL_PROXY'];
      for (final envVar in proxyVars) {
        final value = Platform.environment[envVar];
        if (value != null && value.isNotEmpty) {
          return true;
        }
      }

      // Check for common proxy ports in network connections
      try {
        final commonProxyPorts = [8080, 3128, 8888, 8000, 1080];

        for (final port in commonProxyPorts) {
          try {
            final socket = await Socket.connect('localhost', port,
                timeout: const Duration(milliseconds: 100));
            socket.destroy();
            return true; // Found an active proxy port
          } catch (_) {
            // Port not open, continue checking
          }
        }
      } catch (e) {
        debugPrint('Proxy port check error: $e');
      }

      // Check for proxy-specific network configurations
      if (Platform.isAndroid) {
        try {
          // Check Android proxy settings
          final result =
              await Process.run('settings', ['get', 'global', 'http_proxy']);
          final proxySettings = result.stdout.toString().trim();
          if (proxySettings.isNotEmpty && proxySettings != 'null') {
            return true;
          }
        } catch (_) {
          // Settings command might not be available
        }
      }

      return false;
    } catch (e) {
      debugPrint('Proxy detection error: $e');
      return false;
    }
  }

  /// Clear cached data
  void clearCache() {
    _cachedFingerprint = null;
    _cachedDeviceInfo = null;
  }

  /// Get fingerprint for logging (first 8 characters)
  String getShortFingerprint(String fullFingerprint) {
    return fullFingerprint.substring(0, 8);
  }
}
