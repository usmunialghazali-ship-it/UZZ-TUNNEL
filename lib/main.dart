import 'dart:async';
import 'package:flutter/material.dart';

void main() => runApp(const UzzTunnelApp());

class UzzTunnelApp extends StatelessWidget {
  const UzzTunnelApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'UZZ TUNNEL',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B0B1A),
        primaryColor: Colors.deepPurple,
      ),
      home: const HomePage(),
    );
  }
}

class Server {
  final String name;
  final String flag;
  final String ping;
  Server(this.name, this.flag, this.ping);
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isConnected = false;
  bool isConnecting = false;
  int selectedServer = 0;
  int seconds = 0;
  Timer? timer;
  List<String> logs = ["Ready to connect..."];

  final servers = [
    Server('Singapore', '🇸🇬', '32 ms'),
    Server('Indonesia', '🇮🇩', '18 ms'),
    Server('USA', '🇺🇸', '180 ms'),
    Server('Germany', '🇩🇪', '145 ms'),
  ];

  void toggleConnect() async {
    if (isConnected) {
      timer?.cancel();
      setState(() {
        isConnected = false;
        seconds = 0;
        logs.insert(0, "Disconnected");
      });
      return;
    }
    setState(() {
      isConnecting = true;
      logs.insert(0, "Connecting to ${servers[selectedServer].name}...");
    });
    await Future.delayed(const Duration(seconds: 2));
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => seconds++);
    });
    setState(() {
      isConnecting = false;
      isConnected = true;
      logs.insert(0, "Connected! Tunnel active");
      logs.insert(0, "IP: 103.152.${seconds + 10}.45");
    });
  }

  String formatTime(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final d = (s % 60).toString().padLeft(2, '0');
    return "$m:$d";
  }

  @override
  Widget build(BuildContext context) {
    final server = servers[selectedServer];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text("UZZ TUNNEL", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF1A1A35), borderRadius: BorderRadius.circular(16)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _stat("STATUS", isConnected ? "CONNECTED" : "DISCONNECTED", isConnected ? Colors.green : Colors.red),
                  _stat("SERVER", "${server.flag} ${server.name}", Colors.white),
                  _stat("DURATION", formatTime(seconds), Colors.white),
                ],
              ),
            ),
            const SizedBox(height: 30),
            GestureDetector(
              onTap: isConnecting ? null : toggleConnect,
              child: Container(
                width: 180, height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isConnected ? Colors.green : Colors.deepPurple,
                  boxShadow: [BoxShadow(color: (isConnected ? Colors.green : Colors.deepPurple).withOpacity(0.5), blurRadius: 30, spreadRadius: 5)],
                ),
                child: Center(
                  child: isConnecting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.power_settings_new, size: 50, color: Colors.white),
                          const SizedBox(height: 8),
                          Text(isConnected ? "DISCONNECT" : "CONNECT", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Align(alignment: Alignment.centerLeft, child: Text("PILIH SERVER", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
            const SizedBox(height: 10),
            ...List.generate(servers.length, (i) {
              final s = servers[i];
              final active = i == selectedServer;
              return GestureDetector(
                onTap: () => setState(() => selectedServer = i),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: active ? Colors.deepPurple : const Color(0xFF1A1A35),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: active ? Colors.purpleAccent : Colors.transparent),
                  ),
                  child: Row(
                    children: [
                      Text(s.flag, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(s.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                      Text(s.ping, style: const TextStyle(color: Colors.green)),
                      if (active) const Padding(padding: EdgeInsets.only(left: 8), child: Icon(Icons.check_circle, color: Colors.white, size: 20)),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)),
                child: ListView(
                  children: logs.map((l) => Text("> $l", style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 12))).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Column(children: [
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 12)),
    ]);
  }
}
