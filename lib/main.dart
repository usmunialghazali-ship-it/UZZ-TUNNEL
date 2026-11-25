import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_v2ray_client/flutter_v2ray.dart';

void main() { runApp(const UzzTunnelApp()); }

class UzzTunnelApp extends StatelessWidget {
  const UzzTunnelApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UZZ TUNNEL',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B0F14),
        colorScheme: const ColorScheme.dark(primary: Color(0xFF00E5A0)),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class ServerConfig {
  String name; String link; int ping;
  ServerConfig({required this.name, required this.link, this.ping = -1});
  Map<String, dynamic> toJson() => {'name': name, 'link': link};
  factory ServerConfig.fromJson(Map<String, dynamic> j) => ServerConfig(name: j['name'] ?? 'Server', link: j['link'] ?? '');
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late V2ray v2ray;
  List<ServerConfig> servers = [];
  int selected = 0;
  bool isConnected = false;
  bool isConnecting = false;
  String statusText = 'Disconnected';
  String upSpeed = '0 KB/s';
  String downSpeed = '0 KB/s';
  String duration = '00:00:00';
  String logText = 'Ready. Add server to start.';
  final linkController = TextEditingController();
  final nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    v2ray = V2ray(onStatusChanged: (status) {
      if (!mounted) return;
      setState(() {
        isConnected = status.state == 'CONNECTED';
        duration = status.duration;
        upSpeed = '${(status.uploadSpeed / 1024).toStringAsFixed(1)} KB/s';
downSpeed = '${(status.downloadSpeed / 1024).toStringAsFixed(1)} KB/s';
      
        if (isConnected) { statusText = 'Connected'; isConnecting = false; }
      });
    });
    _initV2ray();
    _loadServers();
  }

  Future<void> _initV2ray() async {
    try {
      await v2ray.initialize();
      await v2ray.requestPermission();
    } catch (e) {
      setState(() => logText = 'Init error: $e');
    }
  }

  Future<void> _loadServers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('servers');
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      setState(() => servers = list.map((e) => ServerConfig.fromJson(e)).toList());
    }
    if (servers.isEmpty) {
      setState(() => servers = [
        ServerConfig(name: 'Contoh - Ganti dengan link kamu', link: ''),
      ]);
    }
  }

  Future<void> _saveServers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('servers', jsonEncode(servers.map((e) => e.toJson()).toList()));
  }

  String _getConfig(String link) {
    final parser = V2ray.parseFromURL(link);
    return parser.getFullConfiguration();
  }

  Future<void> _toggleConnect() async {
    if (servers.isEmpty || selected >= servers.length) return;
    if (isConnected || isConnecting) {
      try { await v2ray.stopV2Ray(); } catch (_) {}
      setState(() { isConnected = false; isConnecting = false; statusText = 'Disconnected'; logText = 'Disconnected.'; });
      return;
    }
    final server = servers[selected];
    if (server.link.trim().isEmpty) {
      setState(() => logText = 'Link server kosong. Edit / tambah server dulu.');
      return;
    }
    setState(() { isConnecting = true; statusText = 'Connecting...'; logText = 'Connecting to ${server.name}...'; });
    try {
      final config = _getConfig(server.link.trim());
      final parser = V2ray.parseFromURL(server.link.trim());
      await v2ray.startV2Ray(remark: parser.remark, config: config);
      setState(() { logText = 'Connected to ${server.name}'; });
    } catch (e) {
      setState(() { isConnecting = false; statusText = 'Failed'; logText = 'Failed: $e'; });
    }
  }

  Future<void> _pingAll() async {
    setState(() => logText = 'Pinging servers...');
    for (int i = 0; i < servers.length; i++) {
      if (servers[i].link.trim().isEmpty) continue;
      try {
        final config = _getConfig(servers[i].link.trim());
        final delay = await v2ray.getServerDelay(config: config);
        setState(() => servers[i].ping = delay);
      } catch (_) { setState(() => servers[i].ping = 9999); }
    }
    setState(() => logText = 'Ping done.');
  }

  void _showAddDialog() {
    linkController.clear(); nameController.clear();
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Add Server'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nama Server')),
        const SizedBox(height: 12),
        TextField(controller: linkController, maxLines: 4, decoration: const InputDecoration(labelText: 'Link vmess:// / vless:// / trojan:// / ss://', hintText: 'Paste link disini')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton(onPressed: () {
          if (linkController.text.trim().isEmpty) return;
          setState(() => servers.add(ServerConfig(name: nameController.text.trim().isEmpty ? 'Server ${servers.length + 1}' : nameController.text.trim(), link: linkController.text.trim())));
          _saveServers(); Navigator.pop(context);
        }, child: const Text('Simpan')),
      ],
    ));
  }

  Future<void> _importFromFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result == null || result.files.single.path == null) return;
    try {
      final content = await Clipboard.getData('text/plain');
      setState(() => logText = 'File picked: ${result.files.single.name}. Paste link di Add Server ya.');
    } catch (e) { setState(() => logText = 'Import gagal: $e'); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('UZZ TUNNEL', style: TextStyle(fontWeight: FontWeight.bold)), centerTitle: true, backgroundColor: Colors.transparent, actions: [
        IconButton(icon: const Icon(Icons.speed), onPressed: _pingAll, tooltip: 'Ping All'),
        IconButton(icon: const Icon(Icons.file_open), onPressed: _importFromFile),
      ]),
      body: Column(children: [
        Container(margin: const EdgeInsets.all(16), padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFF131A22), borderRadius: BorderRadius.circular(20), border: Border.all(color: isConnected ? const Color(0xFF00E5A0) : Colors.white10)), child: Column(children: [
          Icon(Icons.shield, size: 56, color: isConnected ? const Color(0xFF00E5A0) : Colors.grey),
          const SizedBox(height: 8),
          Text(statusText, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(servers.isNotEmpty && selected < servers.length ? servers[selected].name : '-', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _stat('UP', upSpeed), _stat('DOWN', downSpeed), _stat('TIME', duration),
          ]),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: isConnected ? Colors.redAccent : const Color(0xFF00E5A0), foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            onPressed: isConnecting ? null : _toggleConnect,
            child: Text(isConnecting ? 'CONNECTING...' : (isConnected ? 'DISCONNECT' : 'CONNECT'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          )),
        ])),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: [
          const Text('Servers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Spacer(),
          TextButton.icon(onPressed: _showAddDialog, icon: const Icon(Icons.add, size: 18), label: const Text('Add')),
        ])),
        Expanded(child: ListView.builder(itemCount: servers.length, itemBuilder: (context, i) {
          final s = servers[i];
          final isSel = i == selected;
          return Container(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5), decoration: BoxDecoration(color: isSel ? const Color(0xFF1A2E26) : const Color(0xFF131A22), borderRadius: BorderRadius.circular(14), border: Border.all(color: isSel ? const Color(0xFF00E5A0) : Colors.white10)), child: ListTile(
            leading: CircleAvatar(backgroundColor: const Color(0xFF00E5A0), child: Text(s.name.isNotEmpty ? s.name[0].toUpperCase() : 'S', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
            title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(s.link.isEmpty ? 'No link' : s.link.length > 40 ? '${s.link.substring(0, 40)}...' : s.link, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)), child: Text(s.ping < 0 ? '-- ms' : s.ping >= 9999 ? 'Timeout' : '${s.ping} ms', style: TextStyle(fontSize: 11, color: s.ping < 0 ? Colors.grey : s.ping < 200 ? Colors.greenAccent : s.ping < 500 ? Colors.orange : Colors.redAccent))),
              IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey), onPressed: () { setState(() => servers.removeAt(i)); _saveServers(); }),
            ]),
            onTap: () => setState(() => selected = i),
          ));
        })),
        Container(width: double.infinity, margin: const EdgeInsets.all(16), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12)), child: Text(logText, style: const TextStyle(fontSize: 12, color: Colors.grey))),
      ]),
    );
  }

  Widget _stat(String label, String value) => Column(children: [Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)), const SizedBox(height: 4), Text(value, style: const TextStyle(fontWeight: FontWeight.bold))]);
}
