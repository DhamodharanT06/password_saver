import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About' , style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              context,
              'Overview',
              'Password Manager is a secure local application designed to help you store, manage, and organize all your passwords in one encrypted location. All data is stored locally on your device with industry-standard encryption. No information is sent to external servers or the cloud.',
            ),
            _buildSection(
              context,
              'Key Features',
              [
                'Password Storage - Add, edit, and delete passwords with full encryption',
                'Search & Filter - Find passwords instantly by title, email, or username',
                'Category Organization - Organize passwords by categories (Social, Work, Banking, etc.)',
                'Edit History - Track modification dates and reasons for password changes',
                'Multi-Select - Select and manage multiple passwords at once',
                'Theme Support - Switch between light and dark modes',
                'Biometric Authentication - Optional fingerprint or face recognition authentication',
                'Local Storage Only - All data remains on your device, no cloud syncing',
                'Email Validation - Automatic validation of email addresses during entry',
                'Password Strength Indicator - Visual feedback on password security level',
              ],
            ),
            _buildSection(
              context,
              'How to Use',
              [
                'Adding Passwords - Tap the add button (+) to create a new password entry. Fill in title, password, email, and optional username. Select or create a category.',
                'Editing Passwords - Tap on any password card to view details. Use the edit button to modify information and add a reason for the change.',
                'Viewing Details - Click on a password to flip the card and see full details including email, username, and modification history.',
                'Searching - Use the search icon in the top bar to search by password title, email, or username.',
                'Filtering by Category - Use category filters at the top to view passwords by type.',
                'Multi-Select Mode - Long-press a password to enter multi-select mode, or toggle it from the menu.',
                'Bulk Delete - Select multiple passwords and use the delete option to remove them together.',
                'Sharing - Share password details securely through your device\'s sharing options.',
                'Theme Toggle - Switch between light and dark themes from the menu.',
                'Customizing FAB Position - Change the add button position via Menu > Add Button Position.',
              ],
            ),
            _buildSection(
              context,
              'Security Features',
              [
                'Encryption - All passwords are encrypted using AES-256 encryption standard',
                'Authentication - Optional app-level authentication using your device\'s biometric or PIN',
                'Local Storage - Passwords stored only on your device, never transmitted',
                'Data Control - You have complete control over your data and can delete it anytime',
              ],
            ),
            _buildSection(
              context,
              'Menu Options',
              [
                'Toggle Theme - Switch between light and dark modes',
                'Security Settings - Enable/disable app authentication',
                'Add Button Position - Change the floating action button location',
                'Multi-Select - Toggle bulk selection mode',
                'Privacy Policy - View detailed privacy and data handling information',
                'About - This information page',
              ],
            ),
            _buildSection(
              context,
              'Password Management',
              [
                'Strength Indicator - Passwords are rated based on length and character complexity',
                'Required Fields - Title, password, and email are required for all entries',
                'Email Validation - Email addresses are validated for correct format',
                'Category Customization - Create custom categories for your password types',
                'Edit Tracking - Each edit includes date and reason for reference',
              ],
            ),
            _buildSection(
              context,
              'Data Privacy',
              [
                'No Cloud Storage - Your passwords are never stored online',
                'No Tracking - The app does not track or collect usage data',
                'No Sharing - Your passwords are never shared with third parties',
                'Device Control - Only accessible on your device with authentication',
                'Local Encryption - Data encrypted at rest on your device',
              ],
            ),
            _buildSection(
              context,
              'System Requirements',
              [
                'Operating System - Works on iOS and Android devices',
                'Storage - Requires local device storage for password data',
                'Permissions - May require biometric or device credential permissions for authentication',
              ],
            ),
            _buildSection(
              context,
              'Tips & Best Practices',
              [
                'Use Strong Passwords - The app shows password strength indicators',
                'Update Regularly - Change passwords periodically and note the reason',
                'Organize Categories - Use meaningful category names for easy filtering',
                'Backup Information - Keep backup copies of critical passwords elsewhere',
                'Use Authentication - Enable app authentication for additional security',
                'Review History - Check edit history to track password changes',
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Text(
                    'Password Manager v1.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[400]
                          : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'All rights reserved.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[400]
                          : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'For privacy details, see the Privacy Policy in the menu.',
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[400]
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, dynamic content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (content is String)
            Text(
              content,
              style: TextStyle(
                fontSize: 13,
                height: 1.6,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withAlpha(220)
                    : Colors.black87,
              ),
            )
          else if (content is List<String>)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: content
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '• ',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              item,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.5,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white.withAlpha(220)
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}
