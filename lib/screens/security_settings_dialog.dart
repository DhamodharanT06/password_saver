import 'package:flutter/material.dart';
import '../services/biometric_auth_service.dart';

class SecuritySettingsDialog extends StatefulWidget {
  final BiometricAuthService authService;
  final VoidCallback onSettingsChanged;

  const SecuritySettingsDialog({
    super.key,
    required this.authService,
    required this.onSettingsChanged,
  });

  @override
  State<SecuritySettingsDialog> createState() => _SecuritySettingsDialogState();
}

class _SecuritySettingsDialogState extends State<SecuritySettingsDialog> {
  String _newPin = '';
  String _confirmPin = '';
  bool _biometricEnabled = false;
  bool _canUseBiometric = false;
  bool _isPinSet = false;
  String _errorMessage = '';
  String _successMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeSettings();
  }

  Future<void> _initializeSettings() async {
    final hasBio = await widget.authService.canUseBiometric();
    final bioEnabled = await widget.authService.isBiometricEnabled();
    final pinSet = await widget.authService.isPINSet();

    setState(() {
      _canUseBiometric = hasBio;
      _biometricEnabled = bioEnabled;
      _isPinSet = pinSet;
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
      title: Text('Security Settings'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            // Divider(),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Use device lock\n(PIN or Biometric)',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
                SizedBox(width: 1.5),
                Switch(
                  value: _biometricEnabled,
                  onChanged: (value) async {
                    // If enabling device lock, remove local PIN to rely on device credential
                    setState(() => _biometricEnabled = value);
                    await widget.authService.setBiometricEnabled(value);
                    if (value) {
                      // remove any app-specific PIN
                      await widget.authService.resetPIN();
                      setState(() {
                        _isPinSet = false;
                      });
                    }
                    widget.onSettingsChanged();
                  },
                ),
              ],
            ),
            SizedBox(height: 12),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Ok'),
        ),
        // ElevatedButton(
        //   onPressed: _isPinSet ? _changePin : _setupPin,
        //   child: Text(_isPinSet ? 'Update PIN' : 'Set PIN'),
        // ),
      ],
    );
  }
}
