import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  String output = "";
  bool showPassword = false;

  Map<String, String> savedPasswords = {};
  List<String> history = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final p = prefs.getString("passwords");
    final h = prefs.getString("history");

    if (p != null) {
      savedPasswords = Map<String, String>.from(jsonDecode(p));
    }
    if (h != null) {
      history = List<String>.from(jsonDecode(h));
    }

    setState(() {});
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString("passwords", jsonEncode(savedPasswords));
    prefs.setString("history", jsonEncode(history));
  }

  void addHistory(String text) {
    history.insert(0, text);
    if (history.length > 20) history.removeLast();
    saveData();
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
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
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
    return Drawer(
      child: Container(
        color: const Color(0xFF0F172A),
        child: ListView(
          children: [

            const DrawerHeader(
              child: Text("Menu", style: TextStyle(fontSize: 20)),
            ),

            const Padding(
              padding: EdgeInsets.all(8),
              child: Text("Saved Passwords"),
            ),

            ...savedPasswords.keys.map((key) => ListTile(
                  title: Text(key),
                  onTap: () {
                    passController.text = savedPasswords[key]!;
                    Navigator.pop(context);
                    setState(() {});
                  },
                )),

            const Divider(),

            const Padding(
              padding: EdgeInsets.all(8),
              child: Text("History"),
            ),

            ...history.map((item) => ListTile(
                  title: Text(item),
                  onTap: () {
                    textController.text = item;
                    Navigator.pop(context);
                    setState(() {});
                  },
                )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: drawerMenu(),

      appBar: AppBar(
        title: const Text("AES Secure"),
      ),

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

              Row(
                children: [
                  Expanded(
                      child: ElevatedButton(
                          onPressed: encrypt, child: const Text("Encrypt"))),
                  const SizedBox(width: 10),
                  Expanded(
                      child: ElevatedButton(
                          onPressed: decrypt, child: const Text("Decrypt"))),
                ],
              ),

              const SizedBox(height: 10),

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