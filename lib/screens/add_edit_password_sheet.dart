import 'package:flutter/material.dart';
import '../services/encryption_service.dart';
import '../services/password_generator.dart';

class AddEditPasswordSheet extends StatefulWidget {
  final Map<String, dynamic>? existingEntry;
  final int? existingIndex;
  final EncryptionService encryptionService;
  final void Function(Map<String, dynamic> data, int? index) onSave;

  const AddEditPasswordSheet({
    super.key,
    this.existingEntry,
    this.existingIndex,
    required this.encryptionService,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    Map<String, dynamic>? existingEntry,
    int? existingIndex,
    required EncryptionService encryptionService,
    required void Function(Map<String, dynamic> data, int? index) onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) => AddEditPasswordSheet(
        existingEntry: existingEntry,
        existingIndex: existingIndex,
        encryptionService: encryptionService,
        onSave: onSave,
      ),
    );
  }

  @override
  State<AddEditPasswordSheet> createState() => _AddEditPasswordSheetState();
}

class _AddEditPasswordSheetState extends State<AddEditPasswordSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  final _nameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _customCategoryCtrl = TextEditingController();
  final _editReasonCtrl = TextEditingController();

  bool _obscurePassword = true;
  String _selectedCategory = 'Other';
  bool _useCustomCategory = false;
  String? _emailError;

  static const List<String> predefinedCategories = [
    'Social Media',
    'Banking',
    'Email',
    'Shopping',
    'Work',
    'Entertainment',
    'Gaming',
    'Health',
    'Travel',
    'Other',
  ];

  bool get _isEditing => widget.existingEntry != null;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();

    if (_isEditing) {
      final entry = widget.existingEntry!;
      _nameCtrl.text = entry['name'] ?? '';
      try {
        _passwordCtrl.text =
            widget.encryptionService.decryptPassword(entry['password']);
      } catch (_) {
        _passwordCtrl.text = '';
      }
      _emailCtrl.text = entry['email'] ?? entry['other'] ?? '';
      _usernameCtrl.text = entry['username'] ?? '';

      final cat = entry['category'] ?? 'Other';
      if (predefinedCategories.contains(cat)) {
        _selectedCategory = cat;
      } else {
        _selectedCategory = 'Other';
        _useCustomCategory = true;
        _customCategoryCtrl.text = cat;
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameCtrl.dispose();
    _passwordCtrl.dispose();
    _emailCtrl.dispose();
    _usernameCtrl.dispose();
    _customCategoryCtrl.dispose();
    _editReasonCtrl.dispose();
    super.dispose();
  }

  int _strength(String p) {
    int s = 0;
    if (p.length >= 8) s++;
    if (p.length >= 12) s++;
    if (p.contains(RegExp(r'[a-z]'))) s++;
    if (p.contains(RegExp(r'[A-Z]'))) s++;
    if (p.contains(RegExp(r'[0-9]'))) s++;
    if (p.contains(RegExp(r'[!@#$%^&*(),.?\":{}|<>]'))) s++;
    return s;
  }

  Color _strengthColor(int s) {
    if (s <= 2) return Colors.red;
    if (s <= 4) return Colors.orange;
    return Colors.green;
  }

  String _strengthLabel(int s) {
    if (s <= 2) return 'Weak';
    if (s <= 4) return 'Medium';
    return 'Strong';
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final email = _emailCtrl.text.trim();

    if (name.isEmpty || password.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Title, Password and Email are required.')),
      );
      return;
    }

    // Validate email format
    if (!_isValidEmail(email)) {
      setState(() => _emailError = 'Please enter a valid email address.');
      return;
    }
    setState(() => _emailError = null);

    if (_isEditing && _editReasonCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a reason for editing.')),
      );
      return;
    }

    try {
      final encrypted = widget.encryptionService.encryptPassword(password);
      final now = DateTime.now().toString().split('.')[0];

      String category;
      if (_useCustomCategory && _customCategoryCtrl.text.trim().isNotEmpty) {
        category = _customCategoryCtrl.text.trim();
      } else {
        category = _selectedCategory;
      }

      final newData = <String, dynamic>{
        'name': name,
        'password': encrypted,
        'email': email,
        'username': _usernameCtrl.text.trim(),
        'other': email, // keep for backwards compat
        'category': category,
        'lastAccessed': _isEditing
            ? (widget.existingEntry!['lastAccessed'] ?? 'Never')
            : 'Never',
        'createdAt': _isEditing
            ? (widget.existingEntry!['createdAt'] ?? now)
            : now,
        'updatedAt': now,
      };

      if (_isEditing) {
        final prev = widget.existingEntry!['editReasons'];
        final List existingReasons = (prev is List) ? prev : [];
        newData['editReasons'] = [
          ...existingReasons,
          {'reason': _editReasonCtrl.text.trim(), 'at': now},
        ];
      }

      widget.onSave(newData, widget.existingIndex);
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = _strength(_passwordCtrl.text);

    return FadeTransition(
      opacity: _fadeAnim,
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.97,
        expand: false,
        builder: (ctx, scrollCtrl) {
          return Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade900 : const Color(0xFFF1FFF0),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 20,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Handle bar
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white30 : Colors.black26,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Header row
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 8, 0),
                  child: Row(
                    children: [
                      Icon(
                        _isEditing
                            ? Icons.edit_outlined
                            : Icons.add_circle_outline,
                        color: isDark
                            ? Colors.tealAccent
                            : Colors.tealAccent[700],
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _isEditing ? 'Edit Password' : 'New Password',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Scrollable content
                Expanded(
                  child: ListView(
                    controller: scrollCtrl,
                    padding: EdgeInsets.fromLTRB(
                      20,
                      16,
                      20,
                      MediaQuery.of(context).viewInsets.bottom + 24,
                    ),
                    children: [
                      _buildTextField(
                          'Title *', 'Enter service name', _nameCtrl),
                      const SizedBox(height: 16),
                      // Password field with strength bar
                      _buildLabel('Password *'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordCtrl,
                        obscureText: _obscurePassword,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Enter password',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),
                      if (_passwordCtrl.text.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: s / 6,
                                  minHeight: 6,
                                  backgroundColor: Colors.grey[300],
                                  valueColor: AlwaysStoppedAnimation(
                                      _strengthColor(s)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _strengthLabel(s),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _strengthColor(s),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            FilledButton.icon(
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('Generate'),
                              onPressed: () {
                                _passwordCtrl.text =
                                    PasswordGenerator.generate();
                                setState(() {});
                              },
                            ),
                            const SizedBox(width: 8),
                            FilledButton.icon(
                              icon: const Icon(Icons.lightbulb, size: 16),
                              label: const Text('Suggest'),
                              onPressed: () {
                                _passwordCtrl.text =
                                    PasswordGenerator.generatePassphrase();
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                          'Email *', 'Enter email address',
                          _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          errorMessage: _emailError),
                      const SizedBox(height: 16),
                      _buildTextField('Username (Optional)',
                          'Enter username if different from email',
                          _usernameCtrl),
                      const SizedBox(height: 16),
                      // Category dropdown
                      _buildLabel('Category'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                        ),
                        items: predefinedCategories
                            .map((cat) =>
                                DropdownMenuItem(value: cat, child: Text(cat)))
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedCategory = val ?? 'Other';
                            _useCustomCategory = false;
                          });
                        },
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Checkbox(
                            value: _useCustomCategory,
                            visualDensity: VisualDensity.compact,
                            onChanged: (v) =>
                                setState(() => _useCustomCategory = v ?? false),
                          ),
                          const Text('Use custom category',
                              style: TextStyle(fontSize: 13)),
                        ],
                      ),
                      if (_useCustomCategory) ...[
                        const SizedBox(height: 4),
                        TextField(
                          controller: _customCategoryCtrl,
                          decoration: InputDecoration(
                            hintText: 'Type your category name',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                      // Edit reason (only when editing)
                      if (_isEditing) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.teal.withAlpha(30)
                                : Colors.teal.withAlpha(20),
                            borderRadius: BorderRadius.circular(10),
                            border:
                                Border.all(color: Colors.teal.withAlpha(80)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.edit_note,
                                      size: 16, color: Colors.teal),
                                  SizedBox(width: 6),
                                  Text(
                                    'Reason for editing *',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.teal,
                                        fontSize: 13),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _editReasonCtrl,
                                maxLines: 2,
                                decoration: InputDecoration(
                                  hintText:
                                      'e.g., Changed due to security breach',
                                  hintStyle: const TextStyle(fontSize: 12),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton(
                          onPressed: _save,
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text(
                            _isEditing ? 'Update Password' : 'Save Password',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  bool _isValidEmail(String email) {
    // Basic email validation regex
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  Widget _buildLabel(String text) =>
      Text(text, style: const TextStyle(fontWeight: FontWeight.w600));

  Widget _buildTextField(
      String label, String hint, TextEditingController ctrl,
      {TextInputType? keyboardType, String? errorMessage}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorMessage,
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }
}
