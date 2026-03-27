import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class EncryptionService {
  static const String _keyStorageKey = 'encryption_master_key';
  static const String _ivStorageKey = 'encryption_iv';
  late final FlutterSecureStorage _secureStorage;
  late encrypt.Key _encryptionKey;
  late encrypt.IV _iv;

  EncryptionService() {
    // Use default secure storage options for broad compatibility
    _secureStorage = const FlutterSecureStorage();
  }

  /// Initialize encryption with stored key or generate new one
  Future<void> initialize() async {
    try {
      String? storedKey;
      String? storedIv;

      try {
        storedKey = await _secureStorage.read(key: _keyStorageKey);
        storedIv = await _secureStorage.read(key: _ivStorageKey);
      } catch (readError) {
        debugPrint('Error reading keys from secure storage: $readError');
        throw Exception('Failed to read encryption keys: $readError');
      }

      if (storedKey == null || storedIv == null) {
        try {
          // Generate new key and IV
          _encryptionKey = encrypt.Key.fromSecureRandom(32); // 256-bit key
          _iv = encrypt.IV.fromSecureRandom(16);

          // Store them securely
          await _secureStorage.write(
            key: _keyStorageKey,
            value: base64.encode(_encryptionKey.bytes),
          );
          await _secureStorage.write(
            key: _ivStorageKey,
            value: base64.encode(_iv.bytes),
          );
        } catch (generateError, stackTrace) {
          debugPrint('Error generating encryption keys: $generateError\nStack: $stackTrace');
          throw Exception('Failed to generate encryption keys: $generateError');
        }
      } else {
        try {
          // Load existing key and IV
          _encryptionKey = encrypt.Key(base64.decode(storedKey));
          _iv = encrypt.IV(base64.decode(storedIv));

          // Validate key and IV lengths
          if (_encryptionKey.bytes.length != 32) {
            throw Exception('Invalid key length: ${_encryptionKey.bytes.length} (expected 32)');
          }
          if (_iv.bytes.length != 16) {
            throw Exception('Invalid IV length: ${_iv.bytes.length} (expected 16)');
          }
        } catch (decodeError, stackTrace) {
          debugPrint('Error loading encryption keys: $decodeError\nStack: $stackTrace');
          throw Exception('Failed to load encryption keys: $decodeError');
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Critical encryption initialization error: $e\nStack: $stackTrace');
      throw Exception('Failed to initialize encryption: $e');
    }
  }

  /// Encrypt a string
  String encryptPassword(String plainText) {
    try {
      if (plainText.isEmpty) {
        throw Exception('Cannot encrypt empty text');
      }

      if (plainText.length > 10000) {
        throw Exception('Text too large to encrypt (max 10000 characters)');
      }

      try {
        final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey));
        final encrypted = encrypter.encrypt(plainText, iv: _iv);
        
        if (encrypted.base64.isEmpty) {
          throw Exception('Encryption produced empty result');
        }
        
        return encrypted.base64;
      } catch (encryptError, stackTrace) {
        debugPrint('AES encryption error: $encryptError\nStack: $stackTrace');
        throw Exception('Encryption failed: $encryptError');
      }
    } catch (e, stackTrace) {
      debugPrint('Error encrypting password: $e\nStack: $stackTrace');
      throw Exception('Encryption failed: $e');
    }
  }

  /// Decrypt a string
  String decryptPassword(String encryptedText) {
    try {
      if (encryptedText.isEmpty) {
        throw Exception('Cannot decrypt empty text');
      }

      try {
        final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey));
        final decrypted = encrypter.decrypt64(encryptedText, iv: _iv);
        
        if (decrypted.isEmpty) {
          throw Exception('Decryption produced empty result');
        }
        
        return decrypted;
      } catch (aesError, stackTrace) {
        debugPrint('AES decryption error: $aesError\nStack: $stackTrace');
        // Check if it's a format error
        if (encryptedText.length < 24) {
          throw Exception('Invalid encrypted text format (too short)');
        }
        throw Exception('Decryption failed: Invalid data or corrupted password');
      }
    } catch (e, stackTrace) {
      debugPrint('Error decrypting password: $e\nStack: $stackTrace');
      throw Exception('Decryption failed: $e');
    }
  }

  /// Reset encryption (generate new key) - useful for security breach scenarios
  Future<void> resetEncryption() async {
    try {
      try {
        await _secureStorage.delete(key: _keyStorageKey);
        await _secureStorage.delete(key: _ivStorageKey);
      } catch (deleteError) {
        debugPrint('Error deleting old keys: $deleteError');
      }
      
      try {
        await initialize();
      } catch (initError, stackTrace) {
        debugPrint('Error reinitializing encryption: $initError\nStack: $stackTrace');
        throw Exception('Failed to reset encryption - reinitialization failed: $initError');
      }
    } catch (e, stackTrace) {
      debugPrint('Error resetting encryption: $e\nStack: $stackTrace');
      throw Exception('Failed to reset encryption: $e');
    }
  }

  /// Get encrypted key summary (if ever needed for backup)
  Future<String> getEncryptedKeyBackup() async {
    final keyData = base64.encode(_encryptionKey.bytes);
    return keyData;
  }
}
