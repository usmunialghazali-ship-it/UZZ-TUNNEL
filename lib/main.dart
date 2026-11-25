order: Border.all(color: isSel ? Colors.green : Colors.transparent, width: 1.5)),
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
