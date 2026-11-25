import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'V2ray Client',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.red),
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
  late final V2Ray v2ray;
  bool connected = false;
  String status = "Disconnected";
  String delayText = "-";
  List<Map<String, dynamic>> configs = [];
  int selected = 0;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    v2ray = V2Ray(
      onStatusChanged: (s) {
        if (!mounted) return;
        setState(() {
          connected = s.state == 'CONNECTED';
          if (connected) status = "Connected";
          if (s.state == 'DISCONNECTED') status = "Disconnected";
        });
      },
      onDelayChanged: (d) {
        if (!mounted) return;
        setState(() => delayText = "${d.delay}ms");
      },
    );
    _loadConfigs();
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadConfigs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('configs');
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      setState(() {
        configs = list.map((e) => Map<String, dynamic>.from(e)).toList();
      });
    }
  }

  Future<void> _saveConfigs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('configs', jsonEncode(configs));
  }

  void _addConfig(String link) {
    final trimmed = link.trim();
    if (trimmed.isEmpty) return;
    final name = _parseName(trimmed);
    setState(() {
      configs.add({'link': trimmed, 'name': name});
      selected = configs.length - 1;
    });
    _saveConfigs();
  }

  String _parseName(String link) {
    try {
      final hash = link.indexOf('#');
      if (hash != -1) {
        return Uri.decodeComponent(link.substring(hash + 1));
      }
      final uri = Uri.parse(link);
      return uri.fragment.isNotEmpty ? uri.fragment : uri.host;
    } catch (_) {
      return "Config ${configs.length + 1}";
    }
  }

  Future<void> toggleConnect() async {
    if (connected) {
      await v2ray.stopV2Ray();
      setState(() {
        connected = false;
        status = "Disconnected";
      });
      return;
    }
    if (configs.isEmpty) {
      setState(() => status = "Tambah config dulu");
      return;
    }
    setState(() => status = "Connecting...");
    await Future.delayed(const Duration(milliseconds: 300));
    final granted = await v2ray.requestPermission();
    if (!granted) {
      setState(() => status = "Izin VPN ditolak");
      return;
    }
    try {
      await v2ray.startV2Ray(
        remark: configs[selected]['name'],
        config: configs[selected]['link'],
        proxyOnly: false,
      );
    } catch (e) {
      setState(() => status = "Gagal: $e");
    }
  }

  void _showAddDialog() {
    final c = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Tambah Config"),
        content: TextField(
          controller: c,
          decoration: const InputDecoration(hintText: "vless:// / vmess:// / trojan://"),
          maxLines: 4,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () {
              _addConfig(c.text);
              Navigator.pop(context);
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.shield, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("V2Ray Client", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                          Text("Fast & Secure VPN", style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          children: [
                            Icon(Icons.circle, size: 10, color: connected ? Colors.greenAccent : Colors.white70),
                            const SizedBox(width: 6),
                            Text(connected ? "Connected" : "Offline", style: const TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Status", style: TextStyle(color: Colors.white70)),
                            Text(status, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Delay", style: TextStyle(color: Colors.white70)),
                            Text(delayText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Server", style: TextStyle(color: Colors.white70)),
                            Text(configs.isEmpty ? "-" : configs[selected]['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Quick Actions", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _showAddDialog,
                            icon: const Icon(Icons.add),
                            label: const Text("Tambah Config"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              if (configs.isEmpty) return;
                              setState(() {
                                configs.removeAt(selected);
                                if (selected >= configs.length) selected = configs.length - 1;
                                if (selected < 0) selected = 0;
                              });
                              _saveConfigs();
                            },
                            icon: const Icon(Icons.delete, color: Colors.red),
                            label: const Text("Hapus", style: TextStyle(color: Colors.red)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text("Configurations", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 10),
                    if (configs.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: const Text("Belum ada config.\nPencet Tambah Config dulu.", textAlign: TextAlign.center),
                      ),
                    ...configs.asMap().entries.map((e) {
                      final i = e.key;
                      final c = e.value;
                      return GestureDetector(
                        onTap: () => setState(() => selected = i),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: selected == i ? Colors.red.shade50 : Colors.white,
                            border: Border.all(color: selected == i ? Colors.red : Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.dns, color: selected == i ? Colors.red : Colors.grey),
                              const SizedBox(width: 12),
                              Expanded(child: Text(c['name'] ?? 'Config', style: const TextStyle(fontWeight: FontWeight.bold))),
                              if (selected == i) const Icon(Icons.check_circle, color: Colors.red),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: toggleConnect,
                  style: ElevatedButton.styleFrom(backgroundColor: connected ? Colors.grey : Colors.red, foregroundColor: Colors.white),
                  child: Text(connected ? "DISCONNECT" : "CONNECT", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
