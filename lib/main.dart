d)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text("Configurations", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 10),
                    if (configs.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: const Text("Belum ada config.\nPencet Tambah Config dulu.", textAlign: TextAlign.center),
                      ),
                    ...configs.asMap().entries.map((e) {
                      final i = e.key;
                      final c = e.value;
                      return GestureDetector(
                        onTap: () => setState(() => selected = i),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: selected == i ? Colors.red.shade50 : Colors.white,
                            border: Border.all(color: selected == i ? Colors.red : Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.dns, color: selected == i ? Colors.red : Colors.grey),
                              const SizedBox(width: 12),
                              Expanded(child: Text(c['name'] ?? 'Config', style: const TextStyle(fontWeight: FontWeight.bold))),
                              if (selected == i) const Icon(Icons.check_circle, color: Colors.red),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: toggleConnect,
                  style: ElevatedButton.styleFrom(backgroundColor: connected ? Colors.grey : Colors.red, foregroundColor: Colors.white),
                  child: Text(connected ? "DISCONNECT" : "CONNECT", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
