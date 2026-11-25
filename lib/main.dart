import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const MaterialApp(home: TunnelApp(), debugShowCheckedModeBanner: false));

class TunnelApp extends StatefulWidget {
  const TunnelApp({super.key});
  @override
  State<TunnelApp> createState() => _TunnelAppState();
}

class _TunnelAppState extends State<TunnelApp> {
  late FlutterV2ray v2ray;
  List<Map<String, dynamic>> configs = [];
  int selected = 0;
  bool connected = false;
  String status = "DISCONNECTED";

  @override
  void initState() {
    super.initState();
    v2ray = FlutterV2ray(onStatusChanged: (s) {
      setState(() {
        connected = s == V2RayStatus.connected;
        status = connected ? "CONNECTED" : "DISCONNECTED";
      });
    });
    loadConfigs();
  }

  Future<void> loadConfigs() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('configs');
    if (data != null) {
      setState(() => configs = List<Map<String, dynamic>>.from(jsonDecode(data)));
    }
  }

  Future<void> saveConfigs() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('configs', jsonEncode(configs));
  }

  void parseAndAdd(String text) {
    try {
      Uri uri = Uri.parse(text.trim());
      String name = uri.fragment.isNotEmpty ? Uri.decodeComponent(uri.fragment) : "${uri.host}:${uri.port}";
      setState(() => configs.add({"name": name, "link": text.trim()}));
      saveConfigs();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Config $name ditambah!")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Config tidak valid")));
    }
  }

  Future<void> toggleConnect() async {
    if (configs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tambah config dulu!")));
      return;
    }
    if (connected) {
      await v2ray.stopV2Ray();
    } else {
      bool granted = await v2ray.requestPermission();
      if (!granted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Izin VPN ditolak!")));
        return;
      }
      try {
        await v2ray.startV2Ray(
          remark: configs[selected]['name'],
          config: configs[selected]['link'],
          proxyOnly: false,
          bypassLan: false,
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal konek: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(title: const Text("UZZ TUNNEL", style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: const Color(0xFF0F172A), centerTitle: true),
      body: Column(children: [
        const SizedBox(height: 20),
        CircleAvatar(radius: 60, backgroundColor: connected ? Colors.green : Colors.grey, child: const Icon(Icons.power_settings_new, size: 60, color: Colors.white)),
        const SizedBox(height: 10),
        Text(status, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Expanded(child: ListView.builder(
          itemCount: configs.length,
          itemBuilder: (c, i) => ListTile(
            onTap: () => setState(() => selected = i),
            leading: Icon(Icons.check_circle, color: selected == i ? Colors.blue : Colors.grey),
            title: Text(configs[i]['name'], style: const TextStyle(color: Colors.white)),
            subtitle: const Text("Tap untuk pilih", style: TextStyle(color: Colors.grey)),
          ),
        )),
        Padding(padding: const EdgeInsets.all(16), child: Column(children: [
          ElevatedButton(onPressed: toggleConnect, style: ElevatedButton.styleFrom(backgroundColor: connected ? Colors.red : Colors.green, minimumSize: const Size(double.infinity, 50)), child: Text(connected ? "DISCONNECT" : "CONNECT")),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: ElevatedButton(onPressed: () {
              String input = "";
              showDialog(context: context, builder: (_) => AlertDialog(title: const Text("Tambah Config"), content: TextField(onChanged: (v) => input = v, decoration: const InputDecoration(hintText: "Paste vless://...")), actions: [TextButton(onPressed: () { Navigator.pop(context); parseAndAdd(input); }, child: const Text("SIMPAN"))]));
            }, child: const Text("+ TAMBAH"))),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton(onPressed: () {
              String input = "";
              showDialog(context: context, builder: (_) => AlertDialog(title: const Text("Import Config"), content: TextField(maxLines: 5, onChanged: (v) => input = v, decoration: const InputDecoration(hintText: "Paste isi file .txt")), actions: [TextButton(onPressed: () { Navigator.pop(context); for (var line in input.split('\n')) { if (line.trim().startsWith('vless://') || line.trim().startsWith('vmess://')) parseAndAdd(line.trim()); } }, child: const Text("IMPORT"))]));
            }, style: ElevatedButton.styleFrom(backgroundColor: Colors.purple), child: const Text("IMPORT CONFIG"))),
          ]),
        ])),
      ]),
    );
  }
}
