import 'package:flutter/material.dart';
import '../controllers/mqtt_controller.dart';
import 'package:intl/intl.dart';

class HistoryView extends StatefulWidget {
  final MqttController controller;

  const HistoryView({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  List<Map<String, dynamic>> temperatureHistory = [];
  List<Map<String, dynamic>> deviceHistory = [];
  bool isLoading = true;
  int selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadHistoryData();
  }

  Future<void> _loadHistoryData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Load temperature history and device history in parallel
      final results = await Future.wait([
        widget.controller.getTemperatureHistory(limit: 30),
        widget.controller.getDeviceHistory(limit: 50),
      ]);

      setState(() {
        temperatureHistory = results[0];
        deviceHistory = results[1];
        isLoading = false;
      });
    } catch (e) {
      print('Error loading history data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue.shade50,
            Colors.white,
          ],
        ),
      ),
      child: isLoading ? _buildLoadingState() : _buildHistoryContent(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
          ),
          SizedBox(height: 16),
          Text(
            'Memuat riwayat data...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryContent() {
    return RefreshIndicator(
      onRefresh: _loadHistoryData,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildStatsCard(),
                  SizedBox(height: 20),
                  _buildTabBar(),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            sliver: selectedTabIndex == 0
                ? _buildTemperatureHistorySliver()
                : _buildDeviceHistorySliver(),
          ),
          SliverToBoxAdapter(
            child: SizedBox(height: 100), // Bottom padding
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    final tempCount = temperatureHistory.length;
    final deviceCount = deviceHistory.length;
    double avgTemp = 0.0;

    if (temperatureHistory.isNotEmpty) {
      double total = 0.0;
      for (var temp in temperatureHistory) {
        total += (temp['temperature'] as num).toDouble();
      }
      avgTemp = total / temperatureHistory.length;
    }

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade600,
              Colors.blue.shade800,
            ],
          ),
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.white, size: 28),
                SizedBox(width: 12),
                Text(
                  'Statistik Data',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.thermostat,
                    label: 'Log Suhu',
                    value: '$tempCount',
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.memory,
                    label: 'Log Device',
                    value: '$deviceCount',
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.analytics,
                    label: 'Rata-rata',
                    value: '${avgTemp.toStringAsFixed(1)}°C',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => selectedTabIndex = 0),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selectedTabIndex == 0
                    ? Colors.blue.shade600
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Log Suhu',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selectedTabIndex == 0
                      ? Colors.white
                      : Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => selectedTabIndex = 1),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selectedTabIndex == 1
                    ? Colors.blue.shade600
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Log Device',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selectedTabIndex == 1
                      ? Colors.white
                      : Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTemperatureHistorySliver() {
    if (temperatureHistory.isEmpty) {
      return SliverToBoxAdapter(
        child: _buildEmptyState('Belum ada log suhu tersimpan'),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildTemperatureCard(temperatureHistory[index]),
        childCount: temperatureHistory.length,
      ),
    );
  }

  Widget _buildDeviceHistorySliver() {
    if (deviceHistory.isEmpty) {
      return SliverToBoxAdapter(
        child: _buildEmptyState('Belum ada log device tersimpan'),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildDeviceCard(deviceHistory[index]),
        childCount: deviceHistory.length,
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureCard(Map<String, dynamic> data) {
    final timestamp = DateTime.parse(data['timestamp']);
    final formattedDate = DateFormat('dd/MM/yyyy').format(timestamp);
    final formattedTime = DateFormat('HH:mm').format(timestamp);

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$formattedDate $formattedTime',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: data['mode'] == 'AUTO'
                        ? Colors.green.shade100
                        : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    data['mode'],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: data['mode'] == 'AUTO'
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTempInfo(
                    'Suhu',
                    '${data['temperature']}°C',
                    Colors.red.shade400,
                    Icons.thermostat,
                  ),
                ),
                Expanded(
                  child: _buildTempInfo(
                    'Min',
                    '${data['min_temp']}°C',
                    Colors.blue.shade400,
                    Icons.arrow_downward,
                  ),
                ),
                Expanded(
                  child: _buildTempInfo(
                    'Max',
                    '${data['max_temp']}°C',
                    Colors.orange.shade400,
                    Icons.arrow_upward,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceCard(Map<String, dynamic> data) {
    final timestamp = DateTime.parse(data['timestamp']);
    final formattedDate = DateFormat('dd/MM/yyyy').format(timestamp);
    final formattedTime = DateFormat('HH:mm').format(timestamp);
    final duration = data['duration'] as double;

    String formatDuration(double seconds) {
      int hours = (seconds / 3600).floor();
      int minutes = ((seconds % 3600) / 60).floor();
      if (hours > 0) {
        return '$hours jam $minutes menit';
      } else if (minutes > 0) {
        return '$minutes menit';
      } else {
        return '${seconds.toInt()} detik';
      }
    }

    final isHeater = data['device'] == 'heater';
    final color = isHeater ? Colors.red.shade400 : Colors.blue.shade400;
    final icon = isHeater ? Icons.local_fire_department : Icons.water_drop;

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isHeater ? 'Heater' : 'Pompa',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  Text(
                    'Durasi: ${formatDuration(duration)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    '$formattedDate $formattedTime',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTempInfo(
      String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
