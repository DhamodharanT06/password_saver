import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BiometricAuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  bool _isBiometricAvailable = false;

  // Keys for secure storage
  static const String _pinKey = 'app_pin';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _appLockedKey = 'app_locked';

  /// Initialize biometric service
  Future<void> initialize() async {
    try {
      _isBiometricAvailable = await canUseBiometric();
      print('Biometric available: $_isBiometricAvailable');
    } catch (e) {
      print('Error initializing biometric: $e');
      _isBiometricAvailable = false;
    }
  }

  /// Check if biometric is available on device
  Future<bool> canUseBiometric() async {
    try {
      // Check if device supports biometric
      final canCheck = await _localAuth.canCheckBiometrics;
      
      // Check if device has biometric enrolled
      if (canCheck) {
        final biometrics = await _localAuth.getAvailableBiometrics();
        return biometrics.isNotEmpty;
      }
      return false;
    } catch (e) {
      print('Error checking biometric availability: $e');
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      print('Error getting available biometrics: $e');
      return [];
    }
  }

  /// Authenticate with biometric
  Future<bool> authenticateWithBiometric({bool allowDeviceCredential = true}) async {
    try {
      final isAvailable = await canUseBiometric();
      if (!isAvailable) {
        print('Biometric not available');
        return false;
      }

      try {
        final authenticated = await _localAuth.authenticate(
          localizedReason: 'Unlock Password Manager',
          options: AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: !allowDeviceCredential,
          ),
        );
        return authenticated;
      } on Exception catch (e) {
        print('Biometric authentication error: $e');
        return false;
      }
    } catch (e) {
      print('Error in biometric authentication: $e');
      return false;
    }
  }

  /// Remove stored PIN
  Future<void> removePIN() async {
    try {
      await _secureStorage.delete(key: _pinKey);
    } catch (e) {
      print('Error removing PIN: $e');
    }
  }

  /// Set PIN code
  Future<void> setPIN(String pin) async {
    await _secureStorage.write(key: _pinKey, value: pin);
  }

  /// Verify PIN code
  Future<bool> verifyPIN(String pin) async {
    try {
      final storedPin = await _secureStorage.read(key: _pinKey);
      return storedPin == pin;
    } catch (e) {
      return false;
    }
  }

  /// Check if PIN is set
  Future<bool> isPINSet() async {
    try {
      final pin = await _secureStorage.read(key: _pinKey);
      return pin != null && pin.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get stored PIN
  Future<String?> getPIN() async {
    try {
      return await _secureStorage.read(key: _pinKey);
    } catch (e) {
      return null;
    }
  }

  /// Enable/disable biometric
  Future<void> setBiometricEnabled(bool enabled) async {
    await _secureStorage.write(
      key: _biometricEnabledKey,
      value: enabled.toString(),
    );
  }

  /// Check if biometric is enabled
  Future<bool> isBiometricEnabled() async {
    try {
      final value = await _secureStorage.read(key: _biometricEnabledKey);
      return value == 'true';
    } catch (e) {
      return false;
    }
  }

  /// Clear all security data
  Future<void> clearAllSecurityData() async {
    await _secureStorage.delete(key: _pinKey);
    await _secureStorage.delete(key: _biometricEnabledKey);
    await _secureStorage.delete(key: _appLockedKey);
  }

  /// Reset PIN
  Future<void> resetPIN() async {
    await _secureStorage.delete(key: _pinKey);
  }
}
