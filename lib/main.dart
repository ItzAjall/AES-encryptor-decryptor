import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'secure_crypto.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final textController = TextEditingController();
  final passController = TextEditingController();
  final crypto = SecureCrypto();
  final auth = LocalAuthentication();

  String output = "";
  bool showPassword = false;

  Map<String, String> savedPasswords = {};
  List<String> history = [];
  Set<String> pinned = {};
  bool biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final p = prefs.getString("passwords");
    final h = prefs.getString("history");
    final pin = prefs.getString("pinned");
    final bio = prefs.getBool("bio") ?? false;

    if (p != null) savedPasswords = Map<String, String>.from(jsonDecode(p));
    if (h != null) history = List<String>.from(jsonDecode(h));
    if (pin != null) pinned = Set<String>.from(jsonDecode(pin));

    biometricEnabled = bio;
    setState(() {});
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString("passwords", jsonEncode(savedPasswords));
    prefs.setString("history", jsonEncode(history));
    prefs.setString("pinned", jsonEncode(pinned.toList()));
    prefs.setBool("bio", biometricEnabled);
  }

  Future<bool> unlock() async {
    if (!biometricEnabled) return true;

    try {
      return await auth.authenticate(
        localizedReason: "Unlock",
        options: const AuthenticationOptions(biometricOnly: true),
      );
    } catch (_) {
      return false;
    }
  }

  void encrypt() {
    final res = crypto.encryptText(
      textController.text,
      passController.text,
    );
    setState(() => output = res);
    addHistory("🔐 $res");
  }

  void decrypt() {
    final res = crypto.decryptText(
      textController.text,
      passController.text,
    );
    setState(() => output = res);
    addHistory("🔓 $res");
  }

  void addHistory(String text) {
    history.insert(0, text);
    if (history.length > 20) history.removeLast();
    saveData();
  }

  void deleteHistory(int i) {
    history.removeAt(i);
    saveData();
    setState(() {});
  }

  void deletePassword(String key) {
    savedPasswords.remove(key);
    pinned.remove(key);
    saveData();
    setState(() {});
  }

  void togglePin(String key) {
    if (pinned.contains(key)) {
      pinned.remove(key);
    } else {
      pinned.add(key);
    }
    saveData();
    setState(() {});
  }

  void showSaveDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Save Password"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: "Name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            child: const Text("Save"),
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                savedPasswords[nameController.text] =
                    passController.text;
                saveData();
              }
              Navigator.pop(context);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  String generateStrongPassword({int length = 16}) {
    const chars =
        "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*()-_=+[]{};:,.<>?";
    final rand = Random.secure();
    return List.generate(length, (index) {
      return chars[rand.nextInt(chars.length)];
    }).join();
  }

  Widget glass(Widget child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget drawerMenu() {
    final sortedKeys = savedPasswords.keys.toList()
      ..sort((a, b) {
        if (pinned.contains(a) && !pinned.contains(b)) return -1;
        if (!pinned.contains(a) && pinned.contains(b)) return 1;
        return a.compareTo(b);
      });

    return Drawer(
      child: Container(
        color: const Color(0xFF0F172A),
        child: ListView(
          children: [
            const DrawerHeader(
              child: Text("Menu", style: TextStyle(fontSize: 20)),
            ),

            SwitchListTile(
              title: const Text("Biometric Lock"),
              value: biometricEnabled,
              onChanged: (v) {
                biometricEnabled = v;
                saveData();
                setState(() {});
              },
            ),

            const Padding(
              padding: EdgeInsets.all(8),
              child: Text("Saved Passwords"),
            ),

            ...sortedKeys.map((key) => ListTile(
                  title: Row(
                    children: [
                      if (pinned.contains(key))
                        const Icon(Icons.star,
                            color: Colors.amber, size: 16),
                      const SizedBox(width: 6),
                      Text(key),
                    ],
                  ),
                  onTap: () async {
                    if (await unlock()) {
                      passController.text = savedPasswords[key]!;
                      Navigator.pop(context);
                      setState(() {});
                    }
                  },
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(pinned.contains(key)
                            ? Icons.star
                            : Icons.star_border),
                        onPressed: () => togglePin(key),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => deletePassword(key),
                      ),
                    ],
                  ),
                )),

            const Divider(),

            const Padding(
              padding: EdgeInsets.all(8),
              child: Text("History"),
            ),

            ...history.asMap().entries.map((e) {
              int i = e.key;
              return ListTile(
                title: Text(e.value),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => deleteHistory(i),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: drawerMenu(),
      appBar: AppBar(title: const Text("AES Secure")),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1F1C2C), Color(0xFF928DAB)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [

              glass(
                TextField(
                  controller: textController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: "Enter text",
                    border: InputBorder.none,
                  ),
                ),
              ),

              glass(
                TextField(
                  controller: passController,
                  obscureText: !showPassword,
                  decoration: InputDecoration(
                    hintText: "Password",
                    border: InputBorder.none,
                    suffixIcon: IconButton(
                      icon: Icon(showPassword
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () {
                        setState(() => showPassword = !showPassword);
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    passController.text = generateStrongPassword();
                  },
                  icon: const Icon(Icons.bolt),
                  label: const Text("Generate Strong Password"),
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: encrypt,
                      child: const Text("Encrypt"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: decrypt,
                      child: const Text("Decrypt"),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: showSaveDialog,
                child: const Text("Save Password"),
              ),

              const SizedBox(height: 20),

              glass(SelectableText(output)),
            ],
          ),
        ),
      ),
    );
  }
}