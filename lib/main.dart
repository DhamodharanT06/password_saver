import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:flip_card/flip_card.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:url_launcher/url_launcher.dart';
import 'services/encryption_service.dart';
import 'services/biometric_auth_service.dart';
import 'services/settings_service.dart';
import 'screens/lock_screen.dart';
import 'screens/security_settings_dialog.dart';
import 'screens/add_edit_password_sheet.dart';
import 'screens/password_detail_page.dart';
import 'screens/about_page.dart';
import 'config/admob_config.dart';

late EncryptionService encryptionService;
late BiometricAuthService biometricAuthService;
late SettingsService settingsService;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox<List>('passwordBox');

  // Initialize AdMob
  await MobileAds.instance.initialize();

  // Initialize encryption service
  encryptionService = EncryptionService();
  await encryptionService.initialize();

  // Initialize biometric auth service
  biometricAuthService = BiometricAuthService();
  await biometricAuthService.initialize();

  // Initialize settings service
  settingsService = SettingsService();
  await settingsService.initialize();

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    // Load saved theme preference
    _themeMode = settingsService.getThemeMode();
  }

  void toggleTheme() {
    setState(() {
      _themeMode =
          (_themeMode == ThemeMode.light) ? ThemeMode.dark : ThemeMode.light;
      // Save theme preference
      settingsService.setThemeMode(_themeMode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF1FFF0),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.tealAccent[400],
          foregroundColor: Colors.black,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.tealAccent[400],
        ),
        cardColor: Colors.blue[50],
      ),
      darkTheme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.grey.shade900,
        appBarTheme: AppBarTheme(backgroundColor: Colors.teal[700]),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.teal[600],
        ),
        cardColor: Colors.white30,
      ),
      home: Homepage(
        toggleTheme: toggleTheme,
        authService: biometricAuthService,
      ),
    );
  }
}

class Homepage extends StatefulWidget {
  final VoidCallback toggleTheme;
  final BiometricAuthService authService;

  const Homepage({
    super.key,
    required this.toggleTheme,
    required this.authService,
  });

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final TextEditingController _searchController = TextEditingController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  List<dynamic> data = [];
  List<dynamic> _filteredData = [];
  Set<String> _categories = {'All'};
  String _selectedCategory = 'All';
  bool _showSearchBar = false;

  // Security state
  bool _isUnlocked = false;
  bool _isPinSetup = false;
  late Box<List> box;

  // Multi-select state
  bool _isMultiSelectMode = false;
  Set<int> selectedIndexes = {};
  
  // FAB position
  late FloatingActionButtonLocation _fabLocation;

  @override
  void initState() {
    super.initState();
    box = Hive.box<List>('passwordBox');
    _loadData();
    _searchController.addListener(() {
      _runFilter(_searchController.text);
    });
    _checkSecurity();
    _loadFabPosition();
  }

  void _loadFabPosition() {
    setState(() {
      _fabLocation = settingsService.getFabLocation();
    });
  }

  Future<void> _checkSecurity() async {
    // Check if security is enabled in app settings
    final isSecurityEnabled = settingsService.isSecurityEnabled();
    
    if (!isSecurityEnabled) {
      // Security is disabled, skip lock screen
      setState(() {
        _isPinSetup = false;
        _isUnlocked = true;
      });
      return;
    }

    // Security is enabled, check device lock
    final pinSet = await widget.authService.isPINSet();
    final deviceLockEnabled = await widget.authService.isBiometricEnabled();
    // Also show lock if the device itself has a screen lock (PIN/pattern/password/biometric)
    final deviceProtected = await widget.authService.isDeviceSupported();
    setState(() {
      _isPinSetup = deviceLockEnabled || pinSet || deviceProtected;
      _isUnlocked = !_isPinSetup; // If no security, user is unlocked
    });
    _loadFabPosition();
  }

  void _loadData() {
    setState(() {
      data = box.get('data', defaultValue: <dynamic>[])!.toList();
      _filteredData = data;
      _updateCategories();
    });
  }

  void _saveData() {
    box.put('data', data);
    _updateCategories();
  }

  void _updateCategories() {
    _categories.clear();
    _categories.add('All');
    for (var item in data) {
      var category = item['category'] ?? 'Other';
      _categories.add(category);
    }
  }

  void _runFilter(String enteredKeyword) {
    setState(() {
      _filteredData =
          data.where((item) {
            // Category filter
            if (_selectedCategory != 'All' &&
                item['category'] != _selectedCategory) {
              return false;
            }

            // Search filter – name, other, email, username
            final name = item['name']?.toString().toLowerCase() ?? '';
            final other = item['other']?.toString().toLowerCase() ?? '';
            final email = item['email']?.toString().toLowerCase() ?? '';
            final username = item['username']?.toString().toLowerCase() ?? '';
            final search = enteredKeyword.toLowerCase();
            return name.contains(search) ||
                other.contains(search) ||
                email.contains(search) ||
                username.contains(search);
          }).toList();
    });
  }

  // int _getPasswordStrength(String password) {
  //   int strength = 0;
  //   if (password.length >= 8) strength++;
  //   if (password.length >= 12) strength++;
  //   if (password.contains(RegExp(r'[a-z]'))) strength++;
  //   if (password.contains(RegExp(r'[A-Z]'))) strength++;
  //   if (password.contains(RegExp(r'[0-9]'))) strength++;
  //   if (password.contains(RegExp(r'[!@#$%^&*(),.?\":{}|<>]'))) strength++;
  //   return strength;
  // }

  // String _getStrengthLabel(int strength) {
  //   if (strength <= 2) return 'Weak';
  //   if (strength <= 4) return 'Medium';
  //   return 'Strong';
  // }

  // Color _getStrengthColor(int strength) {
  //   if (strength <= 2) return Colors.red;
  //   if (strength <= 4) return Colors.orange;
  //   return Colors.green;
  // }

  void showSmallTopSnackBar(BuildContext context, String message, Color color) {
    showTopSnackBar(
      Overlay.of(context),
      Material(
        elevation: 10,
        borderRadius: BorderRadius.circular(8),
        color: Colors.transparent,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          margin: EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(message, style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
      displayDuration: Duration(seconds: 2),
      animationDuration: Duration(milliseconds: 500),
      reverseAnimationDuration: Duration(milliseconds: 300),
    );
  }

  // ── Password save handler ─────────────────────────────────────────────────
  void _handleSave(Map<String, dynamic> newData, int? index) {
    setState(() {
      if (index != null) {
        data[index] = newData;
      } else {
        data.add(newData);
      }
      _saveData();
      _runFilter(_searchController.text);
    });
    showSmallTopSnackBar(
      context,
      index != null ? 'Password updated' : 'Password saved',
      Colors.green,
    );
  }

  // ── Multiselect helpers ───────────────────────────────────────────────────
  void _cancelMultiSelect() {
    setState(() {
      _isMultiSelectMode = false;
      selectedIndexes.clear();
    });
  }

  void _selectAll() {
    setState(() {
      if (selectedIndexes.length == data.length) {
        selectedIndexes.clear();
      } else {
        selectedIndexes = Set.from(List.generate(data.length, (i) => i));
      }
    });
  }

  void _shareSelected() {
    if (selectedIndexes.isEmpty) return;
    final items = selectedIndexes.map((i) => data[i]).toList();
    shareMultiplePasswords(items);
  }

  void _deleteSelected() {
    if (selectedIndexes.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${selectedIndexes.length} password(s)?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final sorted = selectedIndexes.toList()
                ..sort((a, b) => b.compareTo(a));
              for (final i in sorted) {
                data.removeAt(i);
              }
              selectedIndexes.clear();
              _isMultiSelectMode = false;
              _saveData();
              _runFilter(_searchController.text);
              Navigator.pop(ctx);
              showSmallTopSnackBar(context, 'Passwords deleted', Colors.green);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteOne(BuildContext ctx, int originalIndex) {
    showDialog(
      context: ctx,
      builder: (dlgCtx) => AlertDialog(
        title: const Text('Delete Password?'),
        content: Text(
            'Delete "${data[originalIndex]["name"]}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dlgCtx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(dlgCtx);
              setState(() {
                data.removeAt(originalIndex);
                _saveData();
                _runFilter(_searchController.text);
              });
              showSmallTopSnackBar(ctx, 'Password deleted', Colors.green);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ── Category "Show All" dialog ───────────────────────────────────────────
  void _showCategoryDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Filter by Category'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: _categories
                .map(
                  (cat) => RadioListTile<String>(
                    title: Text(cat),
                    value: cat,
                    groupValue: _selectedCategory,
                    onChanged: (val) {
                      setState(() => _selectedCategory = val ?? 'All');
                      _runFilter(_searchController.text);
                      Navigator.pop(ctx);
                    },
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close')),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AboutPage()),
    );
  }

  Future<void> _openPrivacyPolicy() async {
    const String privacyUrl = 'https://dynamicdragon-passwords-privacy-policy.vercel.app/';
    try {
      if (await canLaunchUrl(Uri.parse(privacyUrl))) {
        await launchUrl(Uri.parse(privacyUrl), mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open privacy policy')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error opening privacy policy')),
      );
    }
  }

  Widget _tile(int val) {
    final item = _filteredData[_filteredData.length - val];
    final originalIndex = data.indexOf(item);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onLongPress: () {
        setState(() {
          _isMultiSelectMode = true;
          if (selectedIndexes.contains(originalIndex)) {
            selectedIndexes.remove(originalIndex);
          } else {
            selectedIndexes.add(originalIndex);
          }
        });
      },
      child: FlipCard(
        direction: FlipDirection.HORIZONTAL,
        front: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 1,
          color: isDark ? Colors.white12 : const Color(0xFFE0F7FA),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          child: ListTile(
            leading: _isMultiSelectMode
                ? Checkbox(
                    value: selectedIndexes.contains(originalIndex),
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          selectedIndexes.add(originalIndex);
                        } else {
                          selectedIndexes.remove(originalIndex);
                        }
                      });
                    },
                  )
                : CircleAvatar(
                    child: Text(
                      item["name"].toString().isNotEmpty
                          ? item["name"][0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.grey[700],
                      ),
                    ),
                  ),
            title: Text(
              item["name"],
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item["email"] ?? item["other"] ?? '',
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.black54,
                    fontSize: 11,
                  ),
                ),
                Text(
                  'Category: ${item['category'] ?? 'Other'} '
                  '\nLast: ${item['lastAccessed'] ?? 'Never'}',
                  style: TextStyle(
                    color: isDark ? Colors.grey[500] : Colors.grey,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            trailing: _isMultiSelectMode
                ? null
                : PopupMenuButton(
                    color: isDark ? Colors.grey[800] : Colors.white,
                    itemBuilder: (ctx) => [
                      // View Details
                      PopupMenuItem(
                        onTap: () async {
                          await Future.delayed(Duration.zero);
                          if (!mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PasswordDetailPage(
                                entry: Map<String, dynamic>.from(item),
                                index: originalIndex,
                                encryptionService: encryptionService,
                                onEdit: (d, idx) => _handleSave(d, idx),
                                onDelete: (idx) {
                                  setState(() {
                                    data.removeAt(idx);
                                    _saveData();
                                    _runFilter(_searchController.text);
                                  });
                                  showSmallTopSnackBar(context,
                                      'Password deleted', Colors.green);
                                },
                              ),
                            ),
                          );
                        },
                        child: _menuRow(Icons.info_outline, 'View Details',
                            isDark ? Colors.white : Colors.blue, isDark),
                      ),
                      // Edit
                      PopupMenuItem(
                        onTap: () async {
                          await Future.delayed(Duration.zero);
                          if (!mounted) return;
                          AddEditPasswordSheet.show(
                            context,
                            existingEntry: Map<String, dynamic>.from(item),
                            existingIndex: originalIndex,
                            encryptionService: encryptionService,
                            onSave: _handleSave,
                          );
                        },
                        child: _menuRow(Icons.edit_outlined, 'Edit',
                            isDark ? Colors.white : Colors.green, isDark),
                      ),
                      // Delete (with confirmation)
                      PopupMenuItem(
                        onTap: () async {
                          await Future.delayed(Duration.zero);
                          if (!mounted) return;
                          _confirmDeleteOne(context, originalIndex);
                        },
                        child: _menuRow(
                            Icons.delete_outline_outlined,
                            'Delete',
                            isDark ? Colors.white : Colors.red,
                            isDark),
                      ),
                      // Share
                      PopupMenuItem(
                        onTap: () {
                          final pw = encryptionService
                              .decryptPassword(item['password']);
                          String shareText =
                              'Name: ${item["name"]}\nPassword: $pw'
                              '\nEmail: ${item["email"] ?? item["other"]}';
                          if ((item["username"] ?? '').isNotEmpty) {
                            shareText += '\nUsername: ${item["username"]}';
                          }
                          Share.share(shareText);
                        },
                        child: _menuRow(Icons.share_outlined, 'Share',
                            isDark ? Colors.white : Colors.blue, isDark),
                      ),
                    ],
                    icon: Icon(Icons.more_vert,
                        color: isDark ? Colors.white : Colors.black54),
                  ),
          ),
        ),
        back: Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          elevation: 1,
          child: Row(
            children: [
              Container(
                height: 80,
                width: MediaQuery.of(context).size.width * 0.65,
                alignment: Alignment.center,
                child: _buildPasswordDisplay(item, isDark),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 60,
                    width: MediaQuery.of(context).size.width * 0.25 - 32,
                    decoration: BoxDecoration(
                      color:
                          isDark ? Colors.grey : Colors.blue.withAlpha(50),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.copy_rounded,
                        color: isDark ? Colors.white : Colors.blue),
                  ),
                  onTap: () {
                    try {
                      final password = encryptionService
                          .decryptPassword(item['password']);
                      Clipboard.setData(ClipboardData(text: password));
                      item['lastAccessed'] =
                          DateTime.now().toString().split('.')[0];
                      _saveData();
                      _runFilter(_searchController.text);
                      showSmallTopSnackBar(
                          context, 'Copied to clipboard', Colors.green);
                    } catch (e) {
                      showSmallTopSnackBar(
                          context, 'Error decrypting password', Colors.red);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuRow(
      IconData icon, String label, Color iconColor, bool isDark) {
    return Row(
      children: [
        Icon(icon, color: iconColor),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87)),
      ],
    );
  }

  // Placeholder - old tile method body removed (now integrated into _tile above)
  // Widget _tile_placeholder_REMOVED() => const SizedBox.shrink();

  Widget _buildPasswordDisplay(dynamic item, bool isDark) {
    try {
      String password = encryptionService.decryptPassword(item['password']);
      return Text(
        password,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.tealAccent[100] : Colors.deepOrange,
          letterSpacing: 1.2,
        ),
        textAlign: TextAlign.center,
      );
    } catch (e) {
      return SelectableText(
        '[Error]',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.red,
        ),
        textAlign: TextAlign.center,
      );
    }
  }

  void shareMultiplePasswords(List<dynamic> items) {
    if (items.isEmpty) return;
    final content = items.map((item) {
      try {
        final pw = encryptionService.decryptPassword(item['password']);
        final email = item['email'] ?? item['other'] ?? '';
        final username = item['username'] ?? '';
        final category = item['category'] ?? 'Other';
        String text =
            'Service: ${item["name"]}\nEmail: $email\n'
            'Category: $category\nPassword: $pw';
        if (username.isNotEmpty) {
          text += '\nUsername: $username';
        }
        return text;
      } catch (e) {
        return 'Service: ${item["name"]}\nPassword: [Error]';
      }
    }).join('\n\n');
    Share.share(content, subject: 'Selected Passwords');
  }

  void _showSecuritySettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => SecuritySettingsDialog(
        authService: widget.authService,
        settingsService: settingsService,
        onSettingsChanged: _checkSecurity,
      ),
    );
  }

  void _showFabPositionDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setState) {
          String currentPosition = settingsService.getFabPosition();
          return AlertDialog(
            title: const Text('Add Button Position'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  title: const Text('Bottom-Right (Default)'),
                  value: 'bottom-right',
                  groupValue: currentPosition,
                  onChanged: (String? value) {
                    if (value != null) {
                      settingsService.setFabPosition(value);
                      setState(() => currentPosition = value);
                      _loadFabPosition();
                      Navigator.pop(ctx);
                    }
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Bottom-Left'),
                  value: 'bottom-left',
                  groupValue: currentPosition,
                  onChanged: (String? value) {
                    if (value != null) {
                      settingsService.setFabPosition(value);
                      setState(() => currentPosition = value);
                      _loadFabPosition();
                      Navigator.pop(ctx);
                    }
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Center-Bottom'),
                  value: 'center-bottom',
                  groupValue: currentPosition,
                  onChanged: (String? value) {
                    if (value != null) {
                      settingsService.setFabPosition(value);
                      setState(() => currentPosition = value);
                      _loadFabPosition();
                      Navigator.pop(ctx);
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show lock screen if not unlocked and security is set up
    if (!_isUnlocked && _isPinSetup) {
      return LockScreen(
        authService: widget.authService,
        onUnlocked: () => setState(() => _isUnlocked = true),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      appBar: _buildAppBar(),
      endDrawer: _buildEndDrawer(),
      body: Column(
        children: [
          if (_isMultiSelectMode)
            _buildMultiSelectBar()
          else ...[
            _buildCategoryFilterRow(),
            if (_showSearchBar) _buildSearchBar(),
          ],
          Expanded(child: _buildList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => AddEditPasswordSheet.show(
          context,
          encryptionService: encryptionService,
          onSave: _handleSave,
        ),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: _fabLocation,
      bottomNavigationBar: const _BannerAdWidget(),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────
  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Passwords',
          style: TextStyle(fontWeight: FontWeight.bold)),
      // centerTitle: true,
      // leading: Center(
      //   child: Text(
      //     _filteredData.length.toString(),
      //     style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      //   ),
      // ),
      actions: [
        IconButton(
          icon: Icon(_showSearchBar ? Icons.search_off : Icons.search),
          tooltip: _showSearchBar ? 'Close search' : 'Search',
          onPressed: () {
            setState(() {
              _showSearchBar = !_showSearchBar;
              if (!_showSearchBar) {
                _searchController.clear();
                _runFilter('');
              }
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.menu),
          tooltip: 'Menu',
          onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
        ),
      ],
      surfaceTintColor: Colors.transparent,
    );
  }

  // ── Right Drawer ──────────────────────────────────────────────────────────
  Widget _buildEndDrawer() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerBg = isDark ? Colors.teal[700]! : Colors.tealAccent[400]!;

    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            color: headerBg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lock, size: 40),
                const SizedBox(height: 10),
                const Text('Password Manager',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        )),
                const SizedBox(height: 4),
                Text(
                  '${data.length} password${data.length != 1 ? "s" : ""} saved',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('Toggle Theme'),
            onTap: () {
              // Navigator.pop(context);
              widget.toggleTheme();
            },
          ),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Security Settings'),
            onTap: () {
              Navigator.pop(context);
              _showSecuritySettings(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.add_location),
            title: const Text('Add Button Position'),
            onTap: () {
              Navigator.pop(context);
              _showFabPositionDialog();
            },
          ),
          ListTile(
            leading: Icon(_isMultiSelectMode ? Icons.done_all : Icons.select_all),
            title: Text(_isMultiSelectMode ? 'Exit Multi-Select' : 'Multi-Select'),
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _isMultiSelectMode = !_isMultiSelectMode;
                if (!_isMultiSelectMode) selectedIndexes.clear();
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            onTap: () {
              Navigator.pop(context);
              _showAboutDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy Policy'),
            onTap: () {
              Navigator.pop(context);
              _openPrivacyPolicy();
            },
          ),
        ],
      ),
    );
  }

  // ── Multiselect action bar ────────────────────────────────────────────────
  Widget _buildMultiSelectBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Colors.teal[800]! : Colors.tealAccent[100]!;

    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Cancel selection',
            onPressed: _cancelMultiSelect,
          ),
          Text(
            '${selectedIndexes.length} selected',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(selectedIndexes.length == data.length
                ? Icons.deselect
                : Icons.select_all),
            tooltip: selectedIndexes.length == data.length
                ? 'Deselect all'
                : 'Select all',
            onPressed: _selectAll,
          ),
          if (selectedIndexes.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: 'Share selected',
              onPressed: _shareSelected,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Delete selected',
              onPressed: _deleteSelected,
            ),
          ],
        ],
      ),
    );
  }

  // ── Search bar ────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Search by name, email, username...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Close search',
            onPressed: () {
              setState(() {
                _showSearchBar = false;
                _searchController.clear();
                _runFilter('');
              });
            },
          ),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
        ),
      ),
    );
  }

  // ── Category filter row ───────────────────────────────────────────────────
  Widget _buildCategoryFilterRow() {
    const int maxVisible = 4; // All + selected + 2 others
    final catList = _categories.toList();
    
    // Build visible list: Always show "All" and selected category first
    final visible = <String>['All'];
    if (_selectedCategory != 'All' && !visible.contains(_selectedCategory)) {
      visible.add(_selectedCategory);
    }
    
    // Add remaining categories up to maxVisible
    for (final cat in catList) {
      if (!visible.contains(cat) && visible.length < maxVisible) {
        visible.add(cat);
      }
    }
    
    final hiddenCount = catList.length - visible.length + 1; // +1 for "All"

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 2),
        child: Row(
          children: [
            ...visible.map((cat) {
              final isSelected = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  label: Text(cat),
                  selected: isSelected,
                  backgroundColor: Theme.of(context)
                      .appBarTheme
                      .backgroundColor!
                      .withAlpha(100),
                  selectedColor:
                      Theme.of(context).appBarTheme.backgroundColor,
                  onSelected: (_) {
                    setState(() => _selectedCategory = cat);
                    _runFilter(_searchController.text);
                  },
                ),
              );
            }),
            if (hiddenCount > 0)
              ActionChip(
                label: Text('+${hiddenCount-1} more'),
                onPressed: _showCategoryDialog,
                backgroundColor: Theme.of(context).appBarTheme.backgroundColor!.withAlpha(10),
              ),
            if (_selectedCategory != 'All')
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: ActionChip(
                  label: const Text('Clear'),
                  avatar: const Icon(Icons.close, size: 14),
                  onPressed: () {
                    setState(() => _selectedCategory = 'All');
                    _runFilter(_searchController.text);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Password list ─────────────────────────────────────────────────────────
  Widget _buildList() {
    if (_filteredData.isEmpty) {
      return const Center(
          child: Text('No entries found', textAlign: TextAlign.center));
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: _filteredData.length,
      itemBuilder: (ctx, i) => _tile(i + 1),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Banner Ad Widget
// ─────────────────────────────────────────────────────────────────────────────
class _BannerAdWidget extends StatefulWidget {
  const _BannerAdWidget();

  @override
  State<_BannerAdWidget> createState() => __BannerAdWidgetState();
}

class __BannerAdWidgetState extends State<_BannerAdWidget> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _ad = BannerAd(
      adUnitId: AdmobConfig.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, _) => ad.dispose(),
      ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _ad == null) return const SizedBox(height: 50);
    return SizedBox(
      height: _ad!.size.height.toDouble(),
      width: double.infinity,
      child: AdWidget(ad: _ad!),
    );
  }
}
