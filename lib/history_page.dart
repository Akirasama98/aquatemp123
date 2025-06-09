import 'package:flutter/material.dart';
import 'supabase_config.dart';

class HistoryPage extends StatefulWidget {
  final String heaterDuration;
  final String pumpDuration;

  const HistoryPage({
    Key? key,
    required this.heaterDuration,
    required this.pumpDuration,
  }) : super(key: key);

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> historyList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final response = await SupabaseConfig.client
          .from('device_history')
          .select()
          .order('created_at', ascending: false)
          .limit(50);

      setState(() {
        historyList = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      print('Error loading history: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  String _formatDuration(double seconds) {
    int hours = (seconds / 3600).floor();
    int minutes = ((seconds % 3600) / 60).floor();
    int remainingSeconds = (seconds % 60).floor();

    if (hours > 0) {
      return '$hours jam $minutes menit';
    } else if (minutes > 0) {
      return '$minutes menit $remainingSeconds detik';
    } else {
      return '$remainingSeconds detik';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadHistory,
              child: ListView.builder(
                itemCount: historyList.length,
                itemBuilder: (context, index) {
                  final item = historyList[index];
                  final device = item['device'] as String;
                  final duration = item['duration'] as double;
                  final timestamp =
                      DateTime.parse(item['created_at'] as String);

                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            device == 'heater' ? Colors.orange : Colors.blue,
                        child: Icon(
                          device == 'heater'
                              ? Icons.thermostat
                              : Icons.water_drop,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(device == 'heater' ? 'Heater' : 'Pompa'),
                      subtitle: Text('Durasi: ${_formatDuration(duration)}'),
                      trailing: Text(
                        '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute}',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
