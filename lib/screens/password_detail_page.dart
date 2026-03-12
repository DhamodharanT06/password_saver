import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/encryption_service.dart';
import 'add_edit_password_sheet.dart';

class PasswordDetailPage extends StatefulWidget {
  final Map<String, dynamic> entry;
  final int index;
  final EncryptionService encryptionService;
  final void Function(Map<String, dynamic> data, int index) onEdit;
  final void Function(int index) onDelete;

  const PasswordDetailPage({
    super.key,
    required this.entry,
    required this.index,
    required this.encryptionService,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<PasswordDetailPage> createState() => _PasswordDetailPageState();
}

class _PasswordDetailPageState extends State<PasswordDetailPage> {
  bool _showPassword = false;
  late Map<String, dynamic> _entry;

  @override
  void initState() {
    super.initState();
    _entry = Map<String, dynamic>.from(widget.entry);
  }

  String get _decryptedPassword {
    try {
      return widget.encryptionService.decryptPassword(_entry['password']);
    } catch (_) {
      return '[Error decrypting]';
    }
  }

  void _copy(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Password?'),
        content: Text(
            'Are you sure you want to delete "${_entry['name']}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // close dialog
              Navigator.pop(context); // close detail page
              widget.onDelete(widget.index);
            },
            child:
                const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTeal = isDark ? Colors.teal[700]! : Colors.tealAccent[400]!;
    final accentTeal = isDark ? Colors.teal[600]! : Colors.tealAccent[400]!;
    final name = _entry['name'] as String? ?? '';
    final email = _entry['email'] ?? _entry['other'] ?? '';
    final username = _entry['username'] ?? '';
    final category = _entry['category'] ?? 'Other';
    final editReasons = _entry['editReasons'] as List? ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(name, overflow: TextOverflow.ellipsis),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              await AddEditPasswordSheet.show(
                context,
                existingEntry: _entry,
                existingIndex: widget.index,
                encryptionService: widget.encryptionService,
                onSave: (data, _) {
                  setState(() => _entry = data);
                  widget.onEdit(data, widget.index);
                },
              );
            },
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Premium Header Card ──────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accentTeal.withAlpha(60),
                    accentTeal.withAlpha(40),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: accentTeal.withAlpha(120),
                  width: 2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [accentTeal, primaryTeal],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: accentTeal.withAlpha(80),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.transparent,
                        child: Text(
                          name.isEmpty ? '?' : name[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: accentTeal.withAlpha(40),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: accentTeal.withAlpha(80),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Password Section ─────────────────────────────────────────
            _buildDetailsCard(
              icon: Icons.lock_outline,
              title: 'PASSWORD',
              isDark: isDark,
              primaryTeal: primaryTeal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.blue[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: primaryTeal.withAlpha(120),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      _showPassword ? _decryptedPassword : '• ' * 8,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: _showPassword ? 1.2 : 0,
                        fontFamily: 'Courier',
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: _actionButton(
                          icon: _showPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          label: _showPassword ? 'Hide' : 'Show',
                          onPressed: () =>
                              setState(() => _showPassword = !_showPassword),
                          isDark: isDark,
                          primaryTeal: primaryTeal,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _actionButton(
                          icon: Icons.copy_rounded,
                          label: 'Copy',
                          onPressed: () =>
                              _copy(_decryptedPassword, 'Password'),
                          isDark: isDark,
                          primaryTeal: primaryTeal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Email Section ────────────────────────────────────────────
            if (email.isNotEmpty) ...[
              _buildDetailsCard(
                icon: Icons.email_outlined,
                title: 'EMAIL',
                isDark: isDark,
                primaryTeal: primaryTeal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.blue[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: primaryTeal.withAlpha(120),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        email,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: _actionButton(
                        icon: Icons.copy_rounded,
                        label: 'Copy Email',
                        onPressed: () => _copy(email, 'Email'),
                        isDark: isDark,
                        primaryTeal: primaryTeal,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Username Section ────────────────────────────────────────
            if (username.isNotEmpty) ...[
              _buildDetailsCard(
                icon: Icons.person_outline,
                title: 'USERNAME',
                isDark: isDark,
                primaryTeal: primaryTeal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.blue[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: primaryTeal.withAlpha(120),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        username,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: _actionButton(
                        icon: Icons.copy_rounded,
                        label: 'Copy Username',
                        onPressed: () => _copy(username, 'Username'),
                        isDark: isDark,
                        primaryTeal: primaryTeal,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Activity Section ────────────────────────────────────────
            _buildDetailsCard(
              icon: Icons.history_outlined,
              title: 'ACTIVITY',
              isDark: isDark,
              primaryTeal: primaryTeal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_entry['createdAt'] != null)
                    _activityItem('Created', _entry['createdAt'], isDark),
                  if (_entry['updatedAt'] != null) ...[
                    const SizedBox(height: 10),
                    _activityItem('Updated', _entry['updatedAt'], isDark),
                  ],
                  const SizedBox(height: 10),
                  _activityItem(
                    'Last accessed',
                    _entry['lastAccessed'] ?? 'Never',
                    isDark,
                  ),
                ],
              ),
            ),

            // ── Edit History Section ────────────────────────────────────
            if (editReasons.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildDetailsCard(
                icon: Icons.edit_note_outlined,
                title: 'EDIT HISTORY',
                isDark: isDark,
                primaryTeal: primaryTeal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: editReasons.reversed
                      .take(10)
                      .toList()
                      .asMap()
                      .entries
                      .map<Widget>((entry) {
                    final r = entry.value;
                    final isLast =
                        entry.key == (editReasons.reversed.take(10).length - 1);
                    return Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: accentTeal,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: accentTeal.withAlpha(80),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                              if (!isLast)
                                Container(
                                  width: 2,
                                  height: 30,
                                  color: accentTeal.withAlpha(100),
                                  margin: const EdgeInsets.only(top: 4),
                                ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r['reason'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  r['at'] ?? '',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard({
    required IconData icon,
    required String title,
    required Widget child,
    required bool isDark,
    required Color primaryTeal,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryTeal.withAlpha(100),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 60 : 20),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryTeal.withAlpha(100),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: isDark ? Colors.white : Colors.black),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white.withAlpha(200) : Colors.black.withAlpha(200),
                    letterSpacing: 0.7,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required bool isDark,
    required Color primaryTeal,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: primaryTeal.withAlpha(80),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: primaryTeal.withAlpha(150),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: isDark ? Colors.white : Colors.black),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _activityItem(String label, String value, bool isDark) {
    return Row(
      children: [
        SizedBox(
          width: 85,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
