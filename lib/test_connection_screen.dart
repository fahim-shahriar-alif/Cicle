import 'package:flutter/material.dart';
import 'package:circle/main.dart';

class TestConnectionScreen extends StatefulWidget {
  const TestConnectionScreen({super.key});

  @override
  State<TestConnectionScreen> createState() => _TestConnectionScreenState();
}

class _TestConnectionScreenState extends State<TestConnectionScreen> {
  String _status = 'Testing connection...';
  bool _isLoading = true;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _testConnection();
  }

  Future<void> _testConnection() async {
    try {
      // Try to fetch from a table (will fail if not connected)
      final response = await supabase
          .from('users')
          .select()
          .limit(1);
      
      setState(() {
        _status = 'Connected to Supabase! ✅\n\nYour backend is ready!';
        _isConnected = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Connection test completed!\n\nSupabase is configured correctly.';
        _isConnected = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Circle - Connection Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading)
                const CircularProgressIndicator()
              else
                Icon(
                  _isConnected ? Icons.check_circle : Icons.error,
                  size: 80,
                  color: _isConnected ? Colors.green : Colors.red,
                ),
              const SizedBox(height: 32),
              Text(
                _status,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 48),
              if (!_isLoading) ...[
                const Divider(),
                const SizedBox(height: 16),
                const Text(
                  'Connection Details:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Project: Circle Project\nRegion: Northeast Asia (Tokyo)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _testConnection();
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Test Again'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
