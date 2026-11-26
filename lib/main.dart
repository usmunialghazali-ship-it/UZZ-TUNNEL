import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'UZZ TUNNEL',
      theme: ThemeData.dark(),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<String> servers = [];
  int selected = 0;
  String logText = 'Ready';
  bool isPinging = false;

  @override
  void initState() {
    super.initState();
    _loadServers();
  }

  Future<void> _loadServers() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      servers = prefs.getStringList('servers') ?? [];
      selected = prefs.getInt('selected') ?? 0;
    });
  }

  Future<void> _saveServers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('servers', servers);
    await prefs.setInt('selected', selected);
  }

  Future<void> _pingAll() async {
    if (servers.isEmpty) return;
    setState(() {
      isPinging = true;
      logText = 'Pinging...';
    });
    List<String> results = [];
    for (var s in servers) {
      try {
        final host = s.split(':').first.split('@').last;
        final port = int.tryParse(s.split(':').last) ?? 22;
        final socket = await Socket.connect(host, port, timeout: const Duration(seconds: 3));
        socket.destroy();
        results.add('$s : ONLINE');
      } catch (e) {
        results.add('$s : OFFLINE');
      }
    }
    setState(() {
      isPinging = false;
      logText = results.join('\n');
    });
  }

  void _showAddDialog() {
    final c = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Server'),
        content: TextField(controller: c, decoration: const InputDecoration(hintText: 'user@host:port')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (c.text.trim().isNotEmpty) {
                setState(() => servers.add(c.text.trim()));
                _saveServers();
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _importFromFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null && result.files.single.path != null) {
      try {
        final content = await File(result.files.single.path!).readAsString();
        final lines = content.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        setState(() {
          servers = lines;
          logText = 'Imported ${lines.length} servers';
        });
        await _saveServers();
      } catch (e) {
        setState(() => logText = 'Import failed: $e');
      }
    }
  }

  Future<void> _exportServers() async {
    if (servers.isEmpty) return;
    final result = await FilePicker.platform.saveFile(fileName: 'servers.txt');
    if (result != null) {
      await File(result).writeAsString(servers.join('\n'));
      setState(() => logText = 'Exported to $result');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UZZ TUNNEL'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _pingAll),
          IconButton(icon: const Icon(Icons.file_upload), onPressed: _importFromFile),
          IconButton(icon: const Icon(Icons.file_download), onPressed: _exportServers),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: servers.length,
              itemBuilder: (context, i) {
                return ListTile(
                  leading: Icon(Icons.dns, color: selected == i ? Colors.green : Colors.grey),
                  title: Text(servers[i]),
                  selected: selected == i,
                  onTap: () => setState(() => selected = i),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                    onPressed: () {
                      setState(() => servers.removeAt(i));
                      _saveServers();
                    },
                  ),
                );
              },
            ),
          ),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12)),
            child: Text(logText, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: _showAddDialog, child: const Icon(Icons.add)),
    );
  }
}
