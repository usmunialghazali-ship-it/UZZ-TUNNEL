import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const UzzApp());

class Config {
  String name;
  String link;
  String ping;
  Config({required this.name, required this.link, required this.ping});
}

class UzzApp extends StatelessWidget {
  const UzzApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
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
  List<Config> configs = [];
  int selected = -1;
  bool connected = false;
  String status = "DISCONNECTED";

  void showImport() {
    TextEditingController ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Import Config"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Paste link vless:// / vmess:// / trojan:// / ss://"),
            const SizedBox(height: 10),
            TextField(
              controller: ctrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: "vless://...",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                var data = await Clipboard.getData('text/plain');
                if (data?.text != null) ctrl.text = data!.text!;
              },
              child: const Text("Paste dari Clipboard"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () {
              String link = ctrl.text.trim();
              if (link.startsWith("vless://") || link.startsWith("vmess://") || link.startsWith("trojan://") || link.startsWith("ss://")) {
                String name = "Config ${configs.length + 1}";
                if (link.contains("#")) {
                  name = Uri.decodeComponent(link.split("#").last);
                  if (name.isEmpty) name = "Config ${configs.length + 1}";
                }
                setState(() {
                  configs.add(Config(name: name, link: link, ping: "0 ms"));
                  selected = configs.length - 1;
                });
              }
              Navigator.pop(c);
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
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text("UZZ TUNNEL", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: const Icon(Icons.settings), onPressed: () {})],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  Text(status, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: connected ? Colors.green : Colors.red)),
                  const SizedBox(height: 8),
                  Text(selected >= 0 ? configs[selected].name : "Belum ada config"),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: connected ? Colors.red : Colors.blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
                      onPressed: () {
                        if (selected < 0) { showImport(); return; }
                        setState(() { connected = !connected; status = connected ? "CONNECTED" : "DISCONNECTED"; });
                      },
                      child: Text(connected ? "DISCONNECT" : "CONNECT", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: showImport,
                icon: const Icon(Icons.add),
                label: const Text("+ IMPORT CONFIG", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            const Align(alignment: Alignment.centerLeft, child: Text("PILIH CONFIG", style: TextStyle(fontWeight: FontWeight.bold))),
            const SizedBox(height: 8),
            Expanded(
              child: configs.isEmpty
                  ? const Center(child: Text("Belum ada config.\nKlik + IMPORT CONFIG di atas", textAlign: TextAlign.center))
                  : ListView.builder(
                      itemCount: configs.length,
                      itemBuilder: (c, i) {
                        return Card(
                          color: selected == i ? const Color(0xFF2563EB) : const Color(0xFF1E293B),
                          child: ListTile(
                            leading: const Icon(Icons.language, color: Colors.white),
                            title: Text(configs[i].name),
                            subtitle: Text(configs[i].link.length > 40 ? "${configs[i].link.substring(0, 40)}..." : configs[i].link),
                            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                              Text(configs[i].ping),
                              IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () { setState(() { configs.removeAt(i); if (selected == i) selected = -1; }); }),
                            ]),
                            onTap: () => setState(() => selected = i),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
