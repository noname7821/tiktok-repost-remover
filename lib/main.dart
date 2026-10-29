import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Repost {
  final String id;
  final String url;
  Repost({required this.id, required this.url});
}

class Config {
  static String sessionId = '';
  static double delay = 2.0;
}

class Scraper {
  final http.Client client;
  Scraper({http.Client? client}) : client = client ?? http.Client();

  Future<List<Repost>> getReposts(String username) async {
    final url = Uri.parse('https://www.tiktok.com/@$username');
    final resp = await client.get(url, headers: {
      'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15',
    });
    final html = resp.body;
    final found = <Repost>[];
    final regex = RegExp(r'"id":\s*"(\d+)".*?"isRepost":\s*true', dotAll: true);
    for (final m in regex.allMatches(html)) {
      found.add(Repost(id: m.group(1)!, url: 'https://www.tiktok.com/@$username/video/${m.group(1)}'));
    }
    if (found.isEmpty) {
      final fallback = RegExp(r"/(@[\w.]+)/video/(\d+)");
      for (final m in fallback.allMatches(html)) {
        found.add(Repost(id: m.group(2)!, url: 'https://www.tiktok.com${m.group(0)}'));
      }
    }
    final seen = <String>{};
    return found.where((r) => seen.add(r.id)).toList();
  }
}

class Remover {
  final http.Client client;
  Remover({http.Client? client}) : client = client ?? http.Client();

  Future<int> remove(List<Repost> reposts, {double delay = 2.0}) async {
    int removed = 0;
    for (final item in reposts) {
      try {
        final r = await client.post(
          Uri.parse('https://www.tiktok.com/api/video/remove/'),
          body: {'video_id': item.id},
          headers: {
            'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15',
            'Referer': 'https://www.tiktok.com/',
            'Cookie': 'sessionid=${Config.sessionId}',
          },
        );
        if (r.statusCode == 200) {
          debugPrint('removed ${item.id}');
          removed++;
        } else {
          debugPrint('failed ${item.id}: ${r.statusCode}');
        }
      } catch (e) {
        debugPrint('error ${item.id}: $e');
      }
      await Future.delayed(Duration(seconds: delay.toInt()));
    }
    return removed;
  }
}

void main() {
  runApp(const RemoverApp());
}

class RemoverApp extends StatelessWidget {
  const RemoverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Repost Remover',
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
  final _user = TextEditingController();
  final _scraper = Scraper();
  final _remover = Remover();
  List<Repost> _reposts = [];
  bool _loading = false;
  String _status = '';

  Future<void> _scan() async {
    setState(() { _loading = true; _status = ''; });
    try {
      _reposts = await _scraper.getReposts(_user.text.trim());
      setState(() => _status = 'found ${_reposts.length} reposts');
    } catch (e) {
      setState(() => _status = 'error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _remove() async {
    setState(() { _loading = true; });
    final n = await _remover.remove(_reposts, delay: Config.delay);
    setState(() {
      _loading = false;
      _status = 'removed $n reposts';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TikTok Repost Remover')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(controller: _user, decoration: const InputDecoration(labelText: 'username')),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loading ? null : _scan, child: const Text('Scan')),
            if (_status.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(_status),
            ],
            if (_reposts.isNotEmpty) ...[
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loading ? null : _remove, child: const Text('Remove All')),
            ],
            if (_loading) const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
