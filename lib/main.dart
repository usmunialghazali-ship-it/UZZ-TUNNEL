import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(MaterialApp(home: Home(), debugShowCheckedModeBanner: false));

class Home extends StatefulWidget {
  @override _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<Map<String, dynamic>> configs = [];
  int selected = 0;
  bool connected = false;
  String status = "Belum terhubung";
  final v2ray = FlutterV2ray(
  onStatusChanged: (s) {},
);

  @override void initState() { super.initState(); loadConfigs(); }

  Future<void> loadConfigs() async {
    final prefs = await SharedPreferences.getInstance();
    var data = prefs.getString('configs');
    if (data != null) {
      setState(() => configs = List<Map<String, dynamic>>.from(jsonDecode(data)));
    }
  }

  Future<void> saveConfigs() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('configs', jsonEncode(configs));
  }

  void parseAndAdd(String text) {
    String link = text.trim();
    if (link.isEmpty) return;
    try {
      Map<String, dynamic> vmess;
      String name = "";
      if (link.startsWith('vmess://')) {
        String b64 = link.substring(8).trim();
        b64 = b64.replaceAll('-', '+').replaceAll('_', '/');
        while (b64.length % 4 != 0) b64 += '=';
        vmess = jsonDecode(utf8.decode(base64Decode(b64)));
        name = vmess['ps'] ?? '';
      } else if (link.startsWith('{')) {
        vmess = jsonDecode(link);
        name = vmess['ps'] ?? '';
      } else if (link.startsWith('ey')) {
        String b64 = link;
        while (b64.length % 4 != 0) b64 += '=';
        vmess = jsonDecode(utf8.decode(base64Decode(b64)));
        name = vmess['ps'] ?? '';
      } else {
        throw 'Format tidak dikenal';
      }
      if (name.isEmpty) name = link.length > 20 ? link.substring(0, 20) : link;
      setState(() { configs.add({"name": name, "vmess": vmess}); });
      saveConfigs();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Link salah: $e')));
    }
  }

  String buildV2rayConfig(Map<String, dynamic> v) {
    return jsonEncode({
      "log": {"loglevel": "warning"},
      "inbounds": [{
        "port": 10808, "listen": "127.0.0.1", "protocol": "socks",
        "settings": {"auth": "noauth", "udp": true}
      }],
      "outbounds": [{
        "protocol": "vmess",
        "settings": {"vnext": [{
          "address": v['add'],
          "port": int.parse(v['port'].toString()),
          "users": [{
            "id": v['id'],
            "alterId": int.parse((v['aid'] ?? '0').toString()),
            "security": v['scy'] ?? 'auto'
          }]
        }]},
        "streamSettings": {
          "network": v['net'] ?? 'tcp',
          "security": v['tls'] ?? '',
          "wsSettings": {"path": v['path'] ?? '/', "headers": {"Host": v['host'] ?? ''}},
          "tlsSettings": {"serverName": (v['sni'] ?? v['host'] ?? v['add']).toString()}
        }
      }]
    });
  }

  Future<void> toggleConnect() async {
    if (configs.isEmpty) return;
    if (connected) {
      await v2ray.stopV2Ray();
      setState(() { connected = false; status = "Belum terhubung"; });
      return;
    }
    bool granted = await v2ray.requestPermission();
    if (!granted) return;
    try {
      var v = configs[selected]['vmess'];
      String fullConfig = buildV2rayConfig(v);
      await v2ray.startV2Ray(
        remark: configs[selected]['name'],
        config: fullConfig,
        proxyOnly: false,
      );
      setState(() { connected = true; status = "Connected"; });
    } catch (e) {
      setState(() => status = "Gagal: $e");
    }
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("UZZ TUNNEL")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(children: [
          Text(status, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(hintText: "Paste vmess:// disini", border: OutlineInputBorder()),
            onSubmitted: parseAndAdd,
          ),
          SizedBox(height: 10),
          ElevatedButton(onPressed: () => showDialog(context: context, builder: (_) {
            var c = TextEditingController();
            return AlertDialog(title: Text("Tambah Config"), content: TextField(controller: c), actions: [TextButton(onPressed: () { parseAndAdd(c.text); Navigator.pop(context); }, child: Text("Tambah"))]);
          }), child: Text("Tambah Config")),
          Expanded(child: ListView.builder(
            itemCount: configs.length,
            itemBuilder: (_, i) => ListTile(
              title: Text(configs[i]['name']),
              selected: i == selected,
              onTap: () => setState(() => selected = i),
              trailing: IconButton(icon: Icon(Icons.delete), onPressed: () { setState(() => configs.removeAt(i)); saveConfigs(); }),
            ),
          )),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: toggleConnect,style: ElevatedButton.styleFrom(
  backgroundColor: connected ? Colors.red : Color(0xFF00C853),
  foregroundColor: Colors.white,
  minimumSize: Size(double.infinity, 55),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(30),
  ),
),
            child: Text(connected ? "DISCONNECT" : "CONNECT"),
          )),
        ]),
      ),
    );
  }
}
