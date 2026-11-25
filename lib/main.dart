import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_v2ray_client/flutter_v2ray.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(MaterialApp(debugShowCheckedModeBanner: false, home: Home(), theme: ThemeData(scaffoldBackgroundColor: Color(0xFFF6F8F7))));

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<Map<String, dynamic>> configs = [];
  int selected = 0;
  bool connected = false;
  String status = "Disconnected";
  final v2ray = V2ray(
    onStatusChanged: (status) {
    setState(() {
      connected = status.state == 'CONNECTED';
      if (connected) status = "Connected";
    });
  },
);

  @override
  void initState() {
    super.initState();
    v2ray.initializeV2Ray();
    loadConfigs();
  }

  Future<void> loadConfigs() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('configs');
    if (list != null) {
      setState(() {
        configs = list.map((e) => Map<String, dynamic>.from(jsonDecode(e))).toList();
      });
    }
  }

  Future<void> saveConfigs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('configs', configs.map((e) => jsonEncode(e)).toList());
  }

  void parseAndAdd(String input) {
    input = input.trim();
    if (input.isEmpty) return;
    try {
      String name = "Config ${configs.length + 1}";
      String fullConfig = input;
      if (input.startsWith("vmess://")) {
        final b64 = input.substring(8);
        final normalized = b64 + "=" * ((4 - b64.length % 4) % 4);
        final decoded = utf8.decode(base64Decode(normalized.replaceAll('-', '+').replaceAll('_', '/')));
        final j = jsonDecode(decoded);
        name = j['ps'] ?? name;
        fullConfig = decoded;
      }
      setState(() {
        configs.add({"name": name, "config": fullConfig});
        selected = configs.length - 1;
      });
      saveConfigs();
      setState(() => status = "Config ditambah: $name");
    } catch (e) {
      setState(() => status = "Gagal parse: $e");
    }
  }

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // HEADER GRADIENT - PERSIS FOTO KEREN
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(20, 20, 20, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF00C853), Color(0xFF00A344)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(14)),
                        child: Icon(Icons.shield, color: Colors.white, size: 28),
                      ),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        chiFuture<void> toggleConnect() async {
    if (connected) {
      await v2ray.stopV2Ray();
      setState(() { connected = false; status = "Disconnected"; });
      return;
    }
    if (configs.isEmpty) {
      setState(() => status = "Tambah config dulu!");
      return;
    }
    try {
      setState(() => status = "Connecting...");
      final fullConfig = configs[selected]['config'].toString();
      await Future.delayed(Duration(seconds: 1));
      await v2ray.startV2Ray(
        remark: configs[selected]['name'],
        config: fullConfig,
        proxyOnly: false,
      );
      setState(() { connected = true; status = "Connected - ${configs[selected]['name']}"; });
    } catch (e) {
      setState(() => status = "Gagal: $e");
    }
                        }
                        ldren: [
                          Text("UZZ TUNNEL", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1)),
                          Text("Fast • Secure • Unlimited", style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                      Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          children: [
                            Icon(Icons.circle, size: 8, color: connected ? Colors.green : Colors.red),
                            SizedBox(width: 6),
                            Text(connected ? "Connected" : "Disconnected", style: TextStyle(color: connected ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 18),
                  Center(
                    child: Column(
                      children: [
                        Text(status, textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text(connected ? "Active • ${configs.isNotEmpty ? configs[selected]['name'] : ''}" : "Tap Connect to Start", style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // INPUT PASTE
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
                      child: TextField(
                        decoration: InputDecoration(hintText: "Paste vmess:// disini", border: InputBorder.none, icon: Icon(Icons.link, color: Colors.green)),
                        onSubmitted: parseAndAdd,
                      ),
                    ),
                    SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          var c = TextEditingController();
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text("Tambah Config"),
                              content: TextField(controller: c, decoration: InputDecoration(hintText: "Paste vmess:// / vless://")),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context), child: Text("Batal")),
                                ElevatedButton(onPressed: () { parseAndAdd(c.text); Navigator.pop(context); }, child: Text("Tambah")),
                              ],
                            ),
                          );
                        },
                        icon: Icon(Icons.add, color: Colors.green),
                        label: Text("Tambah Config", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.green), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Configurations", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        Container(padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: Text("${configs.length} Config", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12))),
                      ],
                    ),
                    SizedBox(height: 10),
                    if (configs.isEmpty)
                      Container(padding: EdgeInsets.all(20), width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: Center(child: Text("Belum ada config\nPaste vmess di atas", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)))),
                    ...configs.asMap().entries.map((entry) {
                      int i = entry.key;
                      var c = entry.value;
                      bool isSel = i == selected;
                      return GestureDetector(
                        onTap: () => setState(() => selected = i),
                        child: Container(
                          margin: EdgeInsets.only(bottom: 10),
                          padding: EdgeInsets.all(14),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isSel ? Colors.green : Colors.transparent, width: 1.5)),
                          child: Row(
                            children: [
                              Container(padding: EdgeInsets.all(10), decoration: BoxDecoration(color: isSel ? Colors.green : Colors.grey.shade200, borderRadius: BorderRadius.circular(12)), child: Icon(Icons.store, color: isSel ? Colors.white : Colors.grey)),
                              SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(c['name'].toString(), style: TextStyle(fontWeight: FontWeight.bold)), Text(isSel ? "Selected • Tap to connect" : "Tap to select", style: TextStyle(color: isSel ? Colors.green : Colors.grey, fontSize: 12))])),
                              if (isSel) Icon(Icons.check_circle, color: Colors.green),
                              IconButton(icon: Icon(Icons.delete, color: Colors.redAccent), onPressed: () { setState(() { configs.removeAt(i); if (selected >= configs.length) selected = 0; }); saveConfigs(); }),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: toggleConnect,
                  style: ElevatedButton.styleFrom(backgroundColor: connected ? Colors.red : Color(0xFF00C853), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), elevation: 6),
                  child: Text(connected ? "DISCONNECT" : "CONNECT", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
