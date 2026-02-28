import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'services/encryption_service.dart';
import 'services/password_generator.dart';
import 'services/biometric_auth_service.dart';
import 'screens/lock_screen.dart';
import 'screens/security_settings_dialog.dart';

late EncryptionService encryptionService;
late BiometricAuthService biometricAuthService;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox<List>('passwordBox');

  // Initialize encryption service
  encryptionService = EncryptionService();
  await encryptionService.initialize();

  // Initialize biometric auth service
  biometricAuthService = BiometricAuthService();
  await biometricAuthService.initialize();

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;
  void toggleTheme() {
    setState(() {
      _themeMode =
          (_themeMode == ThemeMode.light) ? ThemeMode.dark : ThemeMode.light;
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
  final TextEditingController _name = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _other = TextEditingController();
  final TextEditingController _category = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

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

  @override
  void initState() {
    super.initState();
    box = Hive.box<List>('passwordBox');
    _loadData();
    _searchController.addListener(() {
      _runFilter(_searchController.text);
    });
    _checkSecurity();
  }

  Future<void> _checkSecurity() async {
    final pinSet = await widget.authService.isPINSet();
    final deviceLock = await widget.authService.isBiometricEnabled();
    setState(() {
      // If device lock is enabled or PIN is set, require unlock
      _isPinSetup = deviceLock || pinSet;
      _isUnlocked = !_isPinSetup; // If no security, user is unlocked
    });
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

            // Search filter
            final name = item['name'].toString().toLowerCase();
            final other = item['other'].toString().toLowerCase();
            final search = enteredKeyword.toLowerCase();
            return name.contains(search) || other.contains(search);
          }).toList();
    });
  }

  int _getPasswordStrength(String password) {
    int strength = 0;
    if (password.length >= 8) strength++;
    if (password.length >= 12) strength++;
    if (password.contains(RegExp(r'[a-z]'))) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?\":{}|<>]'))) strength++;
    return strength;
  }

  String _getStrengthLabel(int strength) {
    if (strength <= 2) return 'Weak';
    if (strength <= 4) return 'Medium';
    return 'Strong';
  }

  Color _getStrengthColor(int strength) {
    if (strength <= 2) return Colors.red;
    if (strength <= 4) return Colors.orange;
    return Colors.green;
  }

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

  Widget Textfie(String name, String hint, TextEditingController _conc) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: TextStyle(fontWeight: FontWeight.w700)),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _conc,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(fontSize: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: BorderSide(color: Colors.black54),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void showDia(BuildContext context, {int? ind}) {
    if (ind != null) {
      _name.text = data[ind]["name"];
      try {
        _password.text = encryptionService.decryptPassword(
          data[ind]["password"],
        );
      } catch (e) {
        _password.text = '[Error decrypting]';
      }
      _other.text = data[ind]["other"];
      _category.text = data[ind]["category"] ?? 'Other';
    } else {
      _name.clear();
      _password.clear();
      _other.clear();
      _category.text = 'Other';
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        bool isDark = Theme.of(context).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setState) {
            int strength = _getPasswordStrength(_password.text);
            return AlertDialog(
              // backgroundColor: isDark ? Colors.grey.shade50 : Colors.white,
              backgroundColor: Theme.of(context).secondaryHeaderColor,
              title: Text(ind != null ? 'Edit Password' : 'Add Password'),
              content: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Textfie("Title", "Enter service name", _name),
                      SizedBox(height: 20),
                      Textfie("Password", "Enter password", _password),
                      // SizedBox(height: 10),
                      // Password strength indicator (Leveller)
                      // Row(
                      //   children: [
                      //     Text(
                      //       'Strength: ',
                      //       style: TextStyle(
                      //         fontSize: 12,
                      //         fontWeight: FontWeight.w500,
                      //       ),
                      //     ),
                      //     Expanded(
                      //       child: ClipRRect(
                      //         borderRadius: BorderRadius.circular(4),
                      //         child: LinearProgressIndicator(
                      //           value: strength / 6,
                      //           backgroundColor: Colors.grey[300],
                      //           valueColor: AlwaysStoppedAnimation<Color>(
                      //             _getStrengthColor(strength),
                      //           ),
                      //           minHeight: 8,
                      //         ),
                      //       ),
                      //     ),
                      //     SizedBox(width: 10),
                      //     Text(
                      //       _getStrengthLabel(strength),
                      //       style: TextStyle(
                      //         fontSize: 12,
                      //         fontWeight: FontWeight.bold,
                      //         color: _getStrengthColor(strength),
                      //       ),
                      //     ),
                      //   ],
                      // ),
                      SizedBox(height: 10),
                      // Generator and Suggestor buttons
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            FilledButton.icon(
                              icon: const Icon(Icons.refresh),
                              label: const Text('Generate'),
                              onPressed: () {
                                final newPass = PasswordGenerator.generate();
                                _password.text = newPass;
                                setState(() {});
                              },
                              style: ButtonStyle(
                                elevation: MaterialStateProperty.all(0),
                              ),
                            ),
                            SizedBox(width: 8),
                            FilledButton.icon(
                              icon: const Icon(Icons.lightbulb),
                              label: const Text('Suggest'),
                              onPressed: () {
                                final newPass =
                                    PasswordGenerator.generatePassphrase();
                                _password.text = newPass;
                                setState(() {});
                              },
                              style: ButtonStyle(
                                elevation: MaterialStateProperty.all(0),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      Textfie("Email/Username", "Email or username", _other),
                      SizedBox(height: 20),
                      Textfie(
                        "Category",
                        "e.g., Email, Social, Banking",
                        _category,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _name.clear();
                      _password.clear();
                      _other.clear();
                      _category.text = 'Other';
                    });
                  },
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    if (_name.text.trim().isEmpty ||
                        _password.text.trim().isEmpty ||
                        _other.text.trim().isEmpty) {
                      showSmallTopSnackBar(
                        context,
                        "All fields must be filled.",
                        Colors.orange,
                      );
                      return;
                    }
                    Navigator.of(context).pop();

                    try {
                      String encrypted = encryptionService.encryptPassword(
                        _password.text,
                      );

                      if (ind != null) {
                        data[ind] = {
                          "name": _name.text,
                          "password": encrypted,
                          "other": _other.text,
                          "category":
                              _category.text.isEmpty ? 'Other' : _category.text,
                          "lastAccessed": data[ind]['lastAccessed'] ?? 'Never',
                        };
                      } else {
                        data.add({
                          "name": _name.text,
                          "password": encrypted,
                          "other": _other.text,
                          "category":
                              _category.text.isEmpty ? 'Other' : _category.text,
                          "lastAccessed": 'Never',
                        });
                      }
                      _saveData();
                      _runFilter(_searchController.text);
                      setState(() {
                        _name.clear();
                        _password.clear();
                        _other.clear();
                        _category.text = 'Other';
                      });
                      showSmallTopSnackBar(
                        context,
                        ind != null ? 'Password updated' : 'Password saved',
                        Colors.green,
                      );
                    } catch (e) {
                      showSmallTopSnackBar(
                        context,
                        'Encryption error: $e',
                        Colors.red,
                      );
                    }
                  },
                  child: Text(ind != null ? 'Update' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget tile(int val) {
    final item = _filteredData[val - 1];
    final originalIndex = data.indexOf(item);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FlipCard(
      direction: FlipDirection.HORIZONTAL,
      front: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 1,
        color: isDark ? Colors.white12 : Color(0xFFE0F7FA),
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        child: ListTile(
          leading:
              _isMultiSelectMode
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
                      val.toString(),
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
                item["other"],
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.black54,
                  fontSize: 11,
                ),
              ),
              Text(
                'Category: ${item['category'] ?? 'Other'} \nLast: ${item['lastAccessed'] ?? 'Never'}',
                style: TextStyle(
                  color: isDark ? Colors.grey[500] : Colors.grey,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          trailing:
              _isMultiSelectMode
                  ? null
                  : PopupMenuButton(
                    color: isDark ? Colors.grey[800] : Colors.white,
                    itemBuilder:
                        (context) => [
                          PopupMenuItem(
                            child: Row(
                              children: [
                                InkWell(
                                  child: Icon(
                                    Icons.edit_outlined,
                                    color: isDark ? Colors.white : Colors.green,
                                  ),
                                  onTap: () {
                                    showDia(context, ind: originalIndex);
                                  },
                                ),
                                SizedBox(width: 5),
                                Text(
                                  "Edit",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color:
                                        isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            child: Row(
                              children: [
                                InkWell(
                                  splashColor: Colors.red,
                                  child: Icon(
                                    Icons.delete_outline_outlined,
                                    color: isDark ? Colors.white : Colors.red,
                                  ),
                                  onTap: () {
                                    setState(() {
                                      data.removeAt(originalIndex);
                                      _saveData();
                                      _runFilter(_searchController.text);
                                    });
                                    showSmallTopSnackBar(
                                      context,
                                      "Password deleted",
                                      Colors.green,
                                    );
                                  },
                                ),
                                SizedBox(width: 5),
                                Text(
                                  "Delete",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color:
                                        isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                    icon: Icon(
                      Icons.more_vert,
                      color: isDark ? Colors.white : Colors.black54,
                    ),
                  ),
        ),
      ),
      back: Card(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 1,
        child: Row(
          children: [
            Container(
              height: 80,
              width: MediaQuery.of(context).size.width * 0.65,
              alignment: Alignment.center,
              child: _buildPasswordDisplay(item, isDark),
            ),
            // SizedBox(width: 8),
            Spacer(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: InkWell(
                child: Container(
                  height: 60,
                  width: MediaQuery.of(context).size.width * 0.25 - 32,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey : Colors.blue.withAlpha(50),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.copy_rounded,
                    color: isDark ? Colors.white : Colors.blue,
                  ),
                ),
                onTap: () {
                  try {
                    var password = encryptionService.decryptPassword(
                      item['password'],
                    );
                    Clipboard.setData(ClipboardData(text: password));
                    // Update last accessed
                    item['lastAccessed'] =
                        DateTime.now().toString().split('.')[0];
                    _saveData();
                    _runFilter(_searchController.text);
                    showSmallTopSnackBar(
                      context,
                      "Copied to clipboard",
                      Colors.green,
                    );
                  } catch (e) {
                    showSmallTopSnackBar(
                      context,
                      "Error decrypting password",
                      Colors.red,
                    );
                  }
                },
              ),
            ),
            // Positioned(
            //   top: 0,
            //   bottom: 0,
            //   right: 8,
            //   child:
            // ),
          ],
        ),
      ),
    );
  }

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
    String content = items
        .map((item) {
          try {
            var password = encryptionService.decryptPassword(item['password']);
            return 'Service: ${item["name"]}\nUsername: ${item["other"]}\nCategory: ${item['category'] ?? 'Other'}\nPassword: $password';
          } catch (e) {
            return 'Service: ${item["name"]}\nUsername: ${item["other"]}\nPassword: [Error]';
          }
        })
        .join('\n\n');

    Share.share(content, subject: 'Selected Passwords');
  }

  void _showSecuritySettings(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => SecuritySettingsDialog(
            authService: widget.authService,
            onSettingsChanged: () {
              _checkSecurity();
            },
          ),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _password.dispose();
    _other.dispose();
    _category.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show lock screen if not unlocked and PIN is set
    if (!_isUnlocked && _isPinSetup) {
      return LockScreen(
        authService: widget.authService,
        onUnlocked: () {
          setState(() => _isUnlocked = true);
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Passwords", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: Center(child: Text(_filteredData.length.toString())),
        actions: [
          IconButton(
            icon: Icon(Icons.brightness_6),
            onPressed: widget.toggleTheme,
          ),
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      backgroundColor: Theme.of(context).secondaryHeaderColor,
                      title: Text('About Passwords'),
                      content: Text(
                        'Passwords is a simple yet powerful password manager. It allows you to securely store and manage your passwords with features like encryption, biometric auth, password generation, and more. Your data is stored locally on your device, ensuring privacy and security.',
                        style: TextStyle(wordSpacing: 2),
                        // textAlign: TextAlign.center,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Close'),
                        ),
                      ],
                    ),
              );
            },
            icon: Icon(Icons.info_outline),
          ),
          git,
        ],
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // Category filter row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Wrap(
                spacing: 10,
                children:
                    _categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return FilterChip(
                        backgroundColor: Theme.of(
                          context,
                        ).appBarTheme.backgroundColor!.withAlpha(100),
                        label: Text(cat),
                        selected: isSelected,
                        selectedColor:
                            Theme.of(context).appBarTheme.backgroundColor,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = cat;
                          });
                          _runFilter(_searchController.text);
                        },
                      );
                    }).toList(),
              ),
            ),
          ),
          if (_showSearchBar)
            Padding(
              padding: EdgeInsets.all(8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          Expanded(
            child:
                _filteredData.isEmpty
                    ? Center(
                      child: Text(
                        "No entries found",
                        textAlign: TextAlign.center,
                      ),
                    )
                    : ListView.builder(
                      itemCount: _filteredData.length,
                      itemBuilder: (ctx, i) => tile((i + 1)),
                    ),
          ),
          SizedBox(height: 90),
          // SizedBox(height: MediaQuery.of(context).size.height * 0.115),
        ],
      ),
      floatingActionButton: SpeedDial(
        label: Text("Menu"),
        icon: Icons.menu,
        activeIcon: Icons.close,
        backgroundColor:
            Theme.of(context).floatingActionButtonTheme.backgroundColor,
        // animationAngle: 270,
        elevation: 8,
        overlayColor: Colors.black,
        overlayOpacity: 0.3,
        spacing: 16,
        spaceBetweenChildren: 8,
        animationDuration: Duration(milliseconds: 100),
        curve: Curves.slowMiddle,
        children: [
          SpeedDialChild(
            child: Icon(Icons.security),
            label: 'Security Settings',
            onTap: () => _showSecuritySettings(context),
          ),
          SpeedDialChild(
            child: Icon(Icons.search),
            label: 'Search',
            onTap: () => setState(() => _showSearchBar = !_showSearchBar),
          ),
          SpeedDialChild(
            child: Icon(Icons.add),
            label: 'Add Password',
            onTap: () => showDia(context),
          ),
          SpeedDialChild(
            child: Icon(Icons.select_all),
            label: _isMultiSelectMode ? 'Cancel Multi-Select' : 'Multi-Select',
            onTap: () {
              setState(() {
                _isMultiSelectMode = !_isMultiSelectMode;
                if (!_isMultiSelectMode) selectedIndexes.clear();
              });
            },
          ),
          if (_isMultiSelectMode)
            SpeedDialChild(
              child: Icon(
                selectedIndexes.length == data.length
                    ? Icons.deselect
                    : Icons.select_all,
              ),
              label:
                  selectedIndexes.length == data.length
                      ? 'Deselect All'
                      : 'Select All',
              onTap: () {
                setState(() {
                  if (selectedIndexes.length == data.length) {
                    // Deselect all
                    selectedIndexes.clear();
                  } else {
                    // Select all
                    selectedIndexes.clear();
                    for (int i = 0; i < data.length; i++) {
                      selectedIndexes.add(i);
                    }
                  }
                });
              },
            ),
          if (_isMultiSelectMode && selectedIndexes.isNotEmpty)
            SpeedDialChild(
              child: Icon(Icons.share),
              label: 'Share Selected',
              onTap: () {
                if (selectedIndexes.isEmpty) return;
                List<dynamic> itemsToShare =
                    selectedIndexes.map((i) => data[i]).toList();
                shareMultiplePasswords(itemsToShare);
              },
            ),
          if (_isMultiSelectMode && selectedIndexes.isNotEmpty)
            SpeedDialChild(
              child: Icon(Icons.delete, color: Colors.red),
              label: 'Delete Selected',
              onTap: () {
                if (selectedIndexes.isEmpty) return;

                showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: Text(
                          'Delete ${selectedIndexes.length} password(s)?',
                        ),
                        content: Text('This action cannot be undone.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              // Sort descending to avoid index issues
                              final indexesToDelete =
                                  selectedIndexes.toList()
                                    ..sort((a, b) => b.compareTo(a));
                              for (int idx in indexesToDelete) {
                                data.removeAt(idx);
                              }
                              selectedIndexes.clear();
                              _saveData();
                              _runFilter(_searchController.text);
                              Navigator.pop(context);
                              showSmallTopSnackBar(
                                context,
                                "Passwords deleted",
                                Colors.green,
                              );
                            },
                            child: Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                );
              },
            ),
        ],
      ),
    );
  }
}
