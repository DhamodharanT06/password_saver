import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:hive_flutter/hive_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox<List>('passwordBox');
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
      home: Homepage(toggleTheme: toggleTheme),
    );
  }
}

class Homepage extends StatefulWidget {
  final VoidCallback toggleTheme;
  const Homepage({super.key, required this.toggleTheme});
  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _other = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> data = [];
  List<dynamic> _filteredData = [];
  bool _showSearchBar = false;
  late Box<List> box;

  // Multi-select state
  bool _isMultiSelectMode = false;
  Set<int> selectedIndexes = {};

  @override
  void initState() {
    super.initState();
    box = Hive.box<List>('passwordBox');
    data = box.get('data', defaultValue: <dynamic>[])!;
    _filteredData = data;
    _searchController.addListener(() {
      _runFilter(_searchController.text);
    });
  }

  void _saveData() {
    box.put('data', data);
  }

  void _runFilter(String enteredKeyword) {
    setState(() {
      _filteredData =
          enteredKeyword.isEmpty
              ? data
              : data.where((item) {
                final name = item['name'].toString().toLowerCase();
                final other = item['other'].toString().toLowerCase();
                final search = enteredKeyword.toLowerCase();
                return name.contains(search) || other.contains(search);
              }).toList();
    });
  }

  void showSmallTopSnackBar(BuildContext context, String message) {
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
            color: Colors.redAccent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
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
        Text(name, style: TextStyle(fontWeight: FontWeight.w500)),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _conc,
            decoration: InputDecoration(
              hintText: hint,
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.blue),
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
      _password.text = data[ind]["password"];
      _other.text = data[ind]["other"];
    } else {
      _name.clear();
      _password.clear();
      _other.clear();
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Details'),
          content: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Textfie("Name", "Enter application name", _name),
                  SizedBox(height: 20),
                  Textfie("Password", "Enter password", _password),
                  SizedBox(height: 20),
                  Textfie("Others", "Eg: Email,Hint etc..", _other),
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
                });
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (_name.text.trim().isEmpty ||
                    _password.text.trim().isEmpty ||
                    _other.text.trim().isEmpty) {
                  showSmallTopSnackBar(context, "All fields must be filled.");
                  return;
                }
                Navigator.of(context).pop();
                if (ind != null) {
                  data[ind] = {
                    "name": _name.text,
                    "password": _password.text,
                    "other": _other.text,
                  };
                } else {
                  data.add({
                    "name": _name.text,
                    "password": _password.text,
                    "other": _other.text,
                  });
                }
                _saveData();
                _runFilter(_searchController.text);
                setState(() {
                  _name.clear();
                  _password.clear();
                  _other.clear();
                });
              },
              child: Text(ind != null ? 'Update' : 'Save'),
            ),
          ],
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
        elevation: 3,
        color: isDark ? Colors.white12 : Color(0xFFE0F7FA),
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
          subtitle: Text(
            item["other"],
            style: TextStyle(color: isDark ? Colors.grey[400] : Colors.black54),
          ),
          trailing:
              _isMultiSelectMode
                  ? null
                  : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        child: Icon(
                          Icons.copy_rounded,
                          color: isDark ? Colors.white : Colors.blue,
                        ),
                        onTap: () {
                          Clipboard.setData(
                            ClipboardData(text: item['password']),
                          );
                          showSmallTopSnackBar(context, "Copied to clipboard");
                        },
                      ),
                      SizedBox(width: 16),
                      InkWell(
                        child: Icon(
                          Icons.edit_outlined,
                          color: isDark ? Colors.white : Colors.green,
                        ),
                        onTap: () {
                          showDia(context, ind: originalIndex);
                        },
                      ),
                      SizedBox(width: 16),
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
                        },
                      ),
                    ],
                  ),
        ),
      ),
      back: Card(
        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        color: Theme.of(context).cardColor,
        child: Container(
          height: 60,
          alignment: Alignment.center,
          child: Text(
            item["password"],
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.tealAccent[100] : Colors.deepOrange,
            ),
          ),
        ),
      ),
    );
  }

  void sharePassword(dynamic item) {
    final mapItem = Map<String, dynamic>.from(item); // cast properly
    Share.share(
      'App: ${mapItem["name"]}\nPassword: ${mapItem["password"]}\nOther: ${mapItem["other"]}',
      subject: 'Password Details',
    );
  }

  void shareMultiplePasswords(List<Map<String, dynamic>> items) {
    if (items.isEmpty) return;
    String content = items
        .map((item) {
          return 'App: ${item["name"]}\nPassword: ${item["password"]}\nOther: ${item["other"]}';
        })
        .join('\n\n');

    Share.share(content, subject: 'Selected Passwords');
  }

  @override
  Widget build(BuildContext context) {
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
        ],
      ),
      body: Column(
        children: [
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
                      itemBuilder: (ctx, i) => tile(i + 1),
                    ),
          ),
          SizedBox(height: 90),
        ],
      ),
      floatingActionButton: SpeedDial(
        label: Text("Menu"),
        icon: Icons.menu,
        activeIcon: Icons.close,
        backgroundColor:
            Theme.of(context).floatingActionButtonTheme.backgroundColor,
        animationAngle: 270,
        elevation: 8,
        overlayColor: Colors.black,
        overlayOpacity: 0.3,
        spacing: 16,
        spaceBetweenChildren: 8,
        animationDuration: Duration(milliseconds: 300),
        curve: Curves.slowMiddle,
        children: [
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
          SpeedDialChild(
            child: Icon(Icons.share),
            label: 'Share Selected',
            onTap: () {
              if (selectedIndexes.isEmpty) return;

              List<Map<String, dynamic>> itemsToShare =
                  selectedIndexes.map((i) {
                    final item = data[i];
                    return Map<String, dynamic>.from(
                      item.map((key, value) => MapEntry(key.toString(), value)),
                    );
                  }).toList();

              shareMultiplePasswords(itemsToShare);
            },
          ),
          SpeedDialChild(
            child: Icon(Icons.delete),
            label: 'Delete Selected',
            onTap: () {
              if (selectedIndexes.isEmpty) return;

              // Convert Set to List and sort descending
              List<int> indexesToDelete =
                  selectedIndexes.toList()..sort((a, b) => b.compareTo(a));

              for (int index in indexesToDelete) {
                data.removeAt(index);
              }

              selectedIndexes.clear(); // Clear selection after delete
              _saveData();
              _runFilter(_searchController.text); // Update filtered list
              setState(() {});
            },
          ),
        ],
      ),
    );
  }
}
