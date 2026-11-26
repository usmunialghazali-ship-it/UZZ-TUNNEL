import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_v2ray_client/flutter_v2ray.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const MaterialApp(home: Home(), debugShowCheckedModeBanner: false));

class Home extends StatefulWidget {
  const Home({super.key});
  @override State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late V2ray v2ray;
  List<String> servers = [];
  int selected = 0;
  bool connected = false;
  bool connecting = false;
  String status = 'Ready';
  String up = '0 B/s', down = '0 B/s', time = '00:00:00';
  Map<String, String> pings = {};
  Timer? timer;
  DateTime? startTime;

  @override
  void initState() {
    super.initState();
    v2ray = V2ray(onStatusChanged: (s) {
      if (!mounted) return;
      if (s.state == 'connecting') return;
      setState(() {
        // state: connected / disconnected
        connected = s.state == 'connected';
        if (connected) { connecting = false; status = 'Connected'; }
        if (s.state == 'disconnected') { status = 'Ready'; up = '0 B/s'; down = '0 B/s'; time = '00:00:00'; timer?.cancel(); }
        up = '${s.uploadSpeed}';
        down = '${s.downloadSpeed}';
      });
    });
    _init();
  }

  Future<void> _init() async {
    await v2ray.initialize();
    final p = await SharedPreferences.getInstance();
    setState(() {
      servers = p.getStringList('servers') ?? [];
      selected = p.getInt('selected') ?? 0;
    });
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    p.setStringList('servers', servers);
    p.setInt('selected', selected);
  }

  String nameOf(String link) {
    try { return V2ray.parseFromURL(link).remark; } catch (_) { return 'Server'; }
  }

  Future<void> toggle() async {
  if (connecting) {
    try { await v2ray.stopV2Ray(); } catch (_) {}
    timer?.cancel();
    timer = null;
    setState(() {
      connecting = false;
      connected = false;
      status = 'Ready';
      time = '00:00:00';
      up = '0 B/s';
      down = '0 B/s';
    });
    return;
  }
  if (servers.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add server dulu')),
    );
    return;
  }
  if (connected) {
    try { await v2ray.stopV2Ray(); } catch (_) {}
    timer?.cancel();
    timer = null;
    setState(() {
      connected = false;
      connecting = false;
      status = 'Ready';
      time = '00:00:00';
      up = '0 B/s';
      down = '0 B/s';
    });
    return;
  }

  setState(() { connecting = true; status = 'Connecting...'; });
  try {
    final parser = V2ray.parseFromURL(servers[selected]);
    if (!await v2ray.requestPermission()) {
      setState(() { connecting = false; status = 'Ready'; });
      return;
    }
    startTime = DateTime.now();
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final d = DateTime.now().difference(startTime!);
      setState(() {
        time = '${d.inHours.toString().padLeft(2, '0')}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
      });
    });
    await v2ray.startV2Ray(
  remark: parser.remark,
  config: parser.getFullConfiguration(),
);
    setState(() {
      connecting = false;
      connected = true;
      status = 'Connected';
    });
  } catch (e) {
    timer?.cancel();
    timer = null;
    try { await v2ray.stopV2Ray(); } catch (_) {}
    setState(() { connecting = false; connected = false; status = 'Ready'; });
  }
  }
  void addServer() {
    final c = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Add Server'),
      content: TextField(controller: c, maxLines: 4, decoration: const InputDecoration(hintText: 'Paste vmess:// / vless:// ...')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton(onPressed: () {
          if (c.text.trim().isNotEmpty) { setState(() { servers.add(c.text.trim()); }); _save(); }
          Navigator.pop(context);
        }, child: const Text('Add')),
      ],
    ));
  }

  Future<void> pingAll() async {
    for (var link in servers) {
      try {
        final cfg = V2ray.parseFromURL(link).getFullConfiguration();
        final ms = await v2ray.getServerDelay(config: cfg);
        setState(() { pings[link] = '$ms ms'; });
      } catch (_) { setState(() { pings[link] = 'fail'; }); }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(backgroundColor: const Color(0xFF121212), title: const Text('UZZ TUNNEL', style: TextStyle(color: Colors.white)),
        actions: [IconButton(onPressed: pingAll, icon: const Icon(Icons.refresh, color: Colors.white))]),
      body: Column(children: [
        Container(margin: const EdgeInsets.all(16), padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(connected ? 'Connected' : connecting ? 'Connecting...' : 'Ready', style: TextStyle(color: connected ? Colors.green : Colors.red, fontSize: 20, fontWeight: FontWeight.bold)),
GestureDetector(
onTap: toggle,
child: Container(
width: 72, height: 72,
decoration: BoxDecoration(shape: BoxShape.circle, color: connected ? Colors.green : Colors.grey[800], border: Border.all(color: Colors.white24)),
child: Icon(connecting ? Icons.hourglass_top : Icons.power_settings_new, color: Colors.white, size: 32),
),
),
]),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _stat('UP', up), _stat('DOWN', down), _stat('TIME', time),
            ]),
            const SizedBox(height: 8),
            Text(servers.isEmpty ? 'Belum ada server' : nameOf(servers[selected]), style: const TextStyle(color: Colors.white70)),
          ])),
        Expanded(child: ListView.builder(itemCount: servers.length, itemBuilder: (_, i) => ListTile(
          onTap: () => setState(() => selected = i),
          leading: Icon(selected == i ? Icons.radio_button_checked : Icons.radio_button_off, color: Colors.green),
          title: Text(nameOf(servers[i]), style: const TextStyle(color: Colors.white)),
          subtitle: Text(servers[i].length > 40 ? '${servers[i].substring(0, 40)}...' : servers[i], style: const TextStyle(color: Colors.white54, fontSize: 11)),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(pings[servers[i]] ?? '-- ms', style: const TextStyle(color: Colors.white70)),
            IconButton(onPressed: () { setState(() { servers.removeAt(i); }); _save(); }, icon: const Icon(Icons.delete, color: Colors.red)),
          ]),
        ))),
      ]),
      floatingActionButton: FloatingActionButton(onPressed: addServer, backgroundColor: Colors.deepPurple, child: const Icon(Icons.add)),
    );
  }

  Widget _stat(String l, String v) => Column(children: [Text(l, style: const TextStyle(color: Colors.white54)), Text(v, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]);
}
