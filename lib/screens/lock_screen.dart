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
  bool _canUseDeviceLock = false;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      final deviceSupported = await widget.authService.isDeviceSupported();
      setState(() {
        _canUseDeviceLock = deviceSupported;
      });

      // Auto-attempt if device has any lock (biometric, PIN, pattern, password)
      if (_canUseDeviceLock) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _attemptAuth();
        });
      }
    } catch (e) {
      print('Error initializing lock screen: $e');
      setState(() {
        _canUseDeviceLock = false;
      });
    }
  }

  Future<void> _attemptAuth() async {
    setState(() => _isLoading = true);
    try {
      final authenticated = await widget.authService.authenticateWithDevice();
      if (authenticated) {
        if (mounted) widget.onUnlocked();
        return;
      }
    } catch (e) {
      print('Auth error: $e');
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Authentication failed. Please try again.';
      });
    }
  }

  // App relies on device lock (PIN / pattern / password / biometric)

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
                  'Authenticate using your device lock\n(PIN / Pattern / Password / Biometric)',
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
                    onPressed: _attemptAuth,
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
                  onPressed: _attemptAuth,
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
