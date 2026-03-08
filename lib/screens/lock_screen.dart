import 'package:flutter/material.dart';
import '../services/biometric_auth_service.dart';

class LockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  final BiometricAuthService authService;

  const LockScreen({
    super.key,
    required this.onUnlocked,
    required this.authService,
  });

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String _errorMessage = '';
  bool _isLoading = false;
  bool _canUseBiometric = false;
  int _biometricAttempts = 0;
  final int _maxBiometricAttempts = 3;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      final hasBio = await widget.authService.canUseBiometric();
      final bioEnabled = await widget.authService.isBiometricEnabled();

      setState(() {
        _canUseBiometric = hasBio && bioEnabled;
      });

      // Auto-attempt biometric if available (with small delay)
      if (_canUseBiometric) {
        Future.delayed(Duration(milliseconds: 500), () {
          _attemptBiometric();
        });
      }
    } catch (e) {
      print('Error initializing lock screen: $e');
      // If biometric fails to initialize, mark unavailable
      setState(() {
        _canUseBiometric = false;
      });
    }
  }

  Future<void> _attemptBiometric() async {
    setState(() => _isLoading = true);
    try {
      final authenticated = await widget.authService.authenticateWithBiometric(
        allowDeviceCredential: true,
      );
      if (authenticated) {
        if (mounted) widget.onUnlocked();
        return;
      } else {
        _biometricAttempts++;
      }
    } catch (e) {
      print('Biometric error: $e');
      _biometricAttempts++;
    }

    if (_biometricAttempts >= _maxBiometricAttempts) {
      // Max attempts reached - stop auto-retrying
      if (mounted)
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Authentication failed. Please use device lock to unlock.';
        });
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // PIN and in-app PIN fallback removed - app relies solely on device lock

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal.shade600, Colors.teal.shade900],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 72, color: Colors.white),
              SizedBox(height: 24),
              Text(
                'Unlock Password Manager',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  'Authenticate using your device lock\n(PIN - Pattern - Password - Biometric)',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
              SizedBox(height: 28),
              if (_isLoading) ...[
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 12),
                // Text(
                //   'Attempt ${_biometricAttempts + 1}/$_maxBiometricAttempts',
                //   style: TextStyle(color: Colors.white70),
                // ),
              ] else ...[
                SizedBox(
                  width: 200,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _attemptBiometric,
                    icon: Icon(Icons.fingerprint, size: 20),
                    label: Text('Use Device Lock'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
              SizedBox(height: 20),
              if (_errorMessage.isNotEmpty) ...[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    _errorMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.amberAccent),
                  ),
                ),
                SizedBox(height: 12),
                TextButton(
                  onPressed: _attemptBiometric,
                  child: Text('Retry', style: TextStyle(color: Colors.white70)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
