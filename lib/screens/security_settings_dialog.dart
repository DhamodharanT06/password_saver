import 'package:flutter/material.dart';
import '../services/biometric_auth_service.dart';
import '../services/settings_service.dart';

class SecuritySettingsDialog extends StatefulWidget {
  final BiometricAuthService authService;
  final SettingsService settingsService;
  final VoidCallback onSettingsChanged;

  const SecuritySettingsDialog({
    super.key,
    required this.authService,
    required this.settingsService,
    required this.onSettingsChanged,
  });

  @override
  State<SecuritySettingsDialog> createState() => _SecuritySettingsDialogState();
}

class _SecuritySettingsDialogState extends State<SecuritySettingsDialog> {
  bool _securityEnabled = true;

  @override
  void initState() {
    super.initState();
    _initializeSettings();
  }

  Future<void> _initializeSettings() async {
    setState(() {
      _securityEnabled = widget.settingsService.isSecurityEnabled();
    });
  }

  // Future<void> _setupPin() async {
  //   setState(() {
  //     _errorMessage = '';
  //     _successMessage = '';
  //   });
  //
  //   if (_newPin.isEmpty || _confirmPin.isEmpty) {
  //     setState(() => _errorMessage = 'Please enter PIN');
  //     return;
  //   }
  //
  //   if (_newPin.length < 4) {
  //     setState(() => _errorMessage = 'PIN must be at least 4 digits');
  //     return;
  //   }
  //
  //   if (_newPin != _confirmPin) {
  //     setState(() => _errorMessage = 'PINs do not match');
  //     return;
  //   }
  //
  //   try {
  //     await widget.authService.setPIN(_newPin);
  //     setState(() {
  //       _successMessage = 'PIN set successfully!';
  //       _newPin = '';
  //       _confirmPin = '';
  //       _isPinSet = true;
  //     });
  //     widget.onSettingsChanged();
  //
  //     Future.delayed(Duration(seconds: 2), () {
  //       Navigator.of(context).pop();
  //     });
  //   } catch (e) {
  //     setState(() => _errorMessage = 'Error setting PIN');
  //   }
  // }

  // Future<void> _changePin() async {
  //   setState(() {
  //     _errorMessage = '';
  //     _successMessage = '';
  //   });
  //
  //   if (_newPin.isEmpty || _confirmPin.isEmpty) {
  //     setState(() => _errorMessage = 'Please enter new PIN');
  //     return;
  //   }
  //
  //   if (_newPin.length < 4) {
  //     setState(() => _errorMessage = 'PIN must be at least 4 digits');
  //     return;
  //   }
  //
  //   if (_newPin != _confirmPin) {
  //     setState(() => _errorMessage = 'PINs do not match');
  //     return;
  //   }
  //
  //   try {
  //     await widget.authService.setPIN(_newPin);
  //     setState(() {
  //       _successMessage = 'PIN changed successfully!';
  //       _newPin = '';
  //       _confirmPin = '';
  //     });
  //     widget.onSettingsChanged();
  //
  //     Future.delayed(Duration(seconds: 2), () {
  //       Navigator.of(context).pop();
  //     });
  //   } catch (e) {
  //     setState(() => _errorMessage = 'Error changing PIN');
  //   }
  // }

  // Future<void> _removeSecurity() async {
  //   try {
  //     await widget.authService.resetPIN();
  //     await widget.authService.setBiometricEnabled(false);
  //     setState(() {
  //       _isPinSet = false;
  //       _biometricEnabled = false;
  //     });
  //     widget.onSettingsChanged();
  //     Navigator.of(context).pop();
  //   } catch (e) {
  //     setState(() => _errorMessage = 'Error removing security');
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Security Settings'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'App Authentication',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Require authentication on app startup',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[400]
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _securityEnabled,
                onChanged: (value) async {
                  // Require authentication before changing security setting
                  try {
                    final isAuthenticated = await widget.authService.authenticateWithBiometric();
                    if (isAuthenticated) {
                      setState(() => _securityEnabled = value);
                      await widget.settingsService.setSecurityEnabled(value);
                      widget.onSettingsChanged();
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Authentication failed')),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _securityEnabled
                  ? 'Authentication is enabled. You will be prompted to authenticate when opening the app.'
                  : 'Authentication is disabled. The app will open without authentication.',
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : Colors.black87,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        // ElevatedButton(
        //   onPressed: _isPinSet ? _changePin : _setupPin,
        //   child: Text(_isPinSet ? 'Update PIN' : 'Set PIN'),
        // ),
      ],
    );
  }
}
