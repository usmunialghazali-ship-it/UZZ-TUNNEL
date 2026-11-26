 vertical: 4), decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)), child: Text(s.ping < 0 ? '-- ms' : s.ping >= 9999 ? 'Timeout' : '${s.ping} ms', style: TextStyle(fontSize: 11, color: s.ping < 0 ? Colors.grey : s.ping < 200 ? Colors.greenAccent : s.ping < 500 ? Colors.orange : Colors.redAccent))),
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
