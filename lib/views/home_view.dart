import 'package:flutter/material.dart';
import '../controllers/mqtt_controller.dart';

class HomeView extends StatelessWidget {
  final MqttController controller;
  final VoidCallback onModeToggle;

  const HomeView({
    Key? key,
    required this.controller,
    required this.onModeToggle,
  }) : super(key: key);

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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            SizedBox(height: 20),
            _buildTemperatureCard(),
            SizedBox(height: 20),
            _buildModeCard(),
            SizedBox(height: 20),
            _buildStatusCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.waves, color: Colors.white, size: 28),
                SizedBox(width: 12),
                Text(
                  'AquaTemp Control',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Sistem Monitoring & Kontrol Suhu Air',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemperatureCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.thermostat, color: Colors.red.shade400, size: 24),
                SizedBox(width: 8),
                Text(
                  'Status Suhu',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Current Temperature
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Column(
                children: [
                  Text(
                    'Suhu Terkini',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "${controller.model.currentTemperature} °C",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade600,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Min and Max Temperature
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.arrow_downward,
                            color: Colors.blue.shade600, size: 20),
                        SizedBox(height: 4),
                        Text(
                          'Minimum',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          "${controller.model.minTemperature} °C",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade100),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.arrow_upward,
                            color: Colors.orange.shade600, size: 20),
                        SizedBox(height: 4),
                        Text(
                          'Maksimum',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          "${controller.model.maxTemperature} °C",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: controller.model.modeOn
                    ? Colors.green.shade100
                    : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                controller.model.modeOn ? Icons.power : Icons.power_off,
                color: controller.model.modeOn
                    ? Colors.green.shade600
                    : Colors.grey.shade600,
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mode Sistem',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  Text(
                    controller.model.modeOn ? 'AUTO' : 'OFF',
                    style: TextStyle(
                      fontSize: 14,
                      color: controller.model.modeOn
                          ? Colors.green.shade600
                          : Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: controller.model.modeOn,
              onChanged: (val) {
                controller.updateMode(val);
              },
              activeColor: Colors.green.shade600,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status Perangkat',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: 16),            Row(
              children: [
                Expanded(
                  child: _buildDeviceStatus(
                    icon: Icons.local_fire_department,
                    label: 'Heater',
                    isActive: controller.model.heaterActive,
                    duration: controller.model.heaterDuration,
                    color: Colors.red.shade400,
                    status: _getHeaterStatus(),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildDeviceStatus(
                    icon: Icons.water_drop,
                    label: 'Pompa',
                    isActive: controller.model.pompaActive,
                    duration: controller.model.pompaDuration,
                    color: Colors.blue.shade400,
                    status: _getPompaStatus(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildDeviceStatus({
    required IconData icon,
    required String label,
    required bool isActive,
    required Color color,
    required double duration,
    required String status,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.1) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? color.withOpacity(0.3) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: isActive ? color : Colors.grey.shade400,
            size: 24,
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isActive ? color : Colors.grey.shade400,
            ),
          ),
          SizedBox(height: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? Colors.green.shade600 : Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (duration > 0) ...[
            SizedBox(height: 2),
            Text(
              '${duration.toStringAsFixed(0)}s',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
          ],
          SizedBox(height: 4),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive ? Colors.green : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  String _getHeaterStatus() {
    if (!controller.model.modeOn) return 'OFF';
    if (controller.model.heaterActive) return 'HEATING';
    
    final current = double.tryParse(controller.model.currentTemperature);
    final min = double.tryParse(controller.model.minTemperature);
    
    if (current != null && min != null) {
      if (current < min) return 'STANDBY';
      return 'IDLE';
    }
    return 'UNKNOWN';
  }

  String _getPompaStatus() {
    if (!controller.model.modeOn) return 'OFF';
    if (controller.model.pompaActive) return 'COOLING';
    
    final current = double.tryParse(controller.model.currentTemperature);
    final max = double.tryParse(controller.model.maxTemperature);
    
    if (current != null && max != null) {
      if (current > max) return 'STANDBY';
      return 'IDLE';
    }
    return 'UNKNOWN';
  }
}
