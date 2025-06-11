import 'package:flutter/material.dart';
import '../controllers/mqtt_controller.dart';

class UpdateTemperatureView extends StatefulWidget {
  final MqttController controller;

  const UpdateTemperatureView({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  State<UpdateTemperatureView> createState() => _UpdateTemperatureViewState();
}

class _UpdateTemperatureViewState extends State<UpdateTemperatureView> {
  final TextEditingController _minController = TextEditingController();
  final TextEditingController _maxController = TextEditingController();
  String? _minError;
  String? _maxError;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final model = widget.controller.model;
    if (_minController.text.isEmpty &&
        model.minTemperature != "-" &&
        model.minTemperature != "0" &&
        model.minTemperature.isNotEmpty &&
        double.tryParse(model.minTemperature) != null) {
      _minController.text = model.minTemperature;
    }
    if (_maxController.text.isEmpty &&
        model.maxTemperature != "-" &&
        model.maxTemperature != "0" &&
        model.maxTemperature.isNotEmpty &&
        double.tryParse(model.maxTemperature) != null) {
      _maxController.text = model.maxTemperature;
    }
  }

  void _handleUpdateMin() {
    final minText = _minController.text.isNotEmpty
        ? _minController.text
        : widget.controller.model.minTemperature;
    final maxText = _maxController.text.isNotEmpty
        ? _maxController.text
        : widget.controller.model.maxTemperature;

    final minVal = double.tryParse(minText);
    final maxVal = double.tryParse(maxText);

    setState(() {
      if (minVal == null ||
          maxVal == null ||
          minText == "-" ||
          maxText == "-") {
        _minError = 'Input tidak valid';
      } else if (minVal >= maxVal) {
        _minError = 'Suhu minimum harus lebih kecil dari maksimum';
      } else {
        _minError = null;
        widget.controller.updateMinTemperature(minText);
        _showSuccessSnackBar('Suhu minimum berhasil diupdate');
      }
    });
  }

  void _handleUpdateMax() {
    final maxText = _maxController.text.isNotEmpty
        ? _maxController.text
        : widget.controller.model.maxTemperature;
    final minText = _minController.text.isNotEmpty
        ? _minController.text
        : widget.controller.model.minTemperature;

    final maxVal = double.tryParse(maxText);
    final minVal = double.tryParse(minText);

    setState(() {
      if (minVal == null ||
          maxVal == null ||
          minText == "-" ||
          maxText == "-") {
        _maxError = 'Input tidak valid';
      } else if (maxVal <= minVal) {
        _maxError = 'Suhu maksimum harus lebih besar dari minimum';
      } else {
        _maxError = null;
        widget.controller.updateMaxTemperature(maxText);
        _showSuccessSnackBar('Suhu maksimum berhasil diupdate');
      }
    });
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = widget.controller.model;

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
            _buildHeaderCard(),
            SizedBox(height: 20),
            _buildMinTemperatureCard(model),
            SizedBox(height: 20),
            _buildMaxTemperatureCard(model),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
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
              Colors.orange.shade600,
              Colors.orange.shade800,
            ],
          ),
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune, color: Colors.white, size: 28),
                SizedBox(width: 12),
                Text(
                  'Pengaturan Suhu',
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
              'Atur batas suhu minimum dan maksimum sistem',
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

  Widget _buildMinTemperatureCard(model) {
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
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_downward,
                    color: Colors.blue.shade600,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  "Suhu Minimum",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                children: [
                  Text(
                    "Terkini: ",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    "${model.minTemperature} °C",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _minController,
              decoration: InputDecoration(
                labelText: "Suhu Minimum Baru",
                errorText: _minError,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
                ),
                prefixIcon: Icon(Icons.thermostat, color: Colors.blue.shade600),
                suffixText: "°C",
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleUpdateMin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.update, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Update Suhu Minimum",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaxTemperatureCard(model) {
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
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_upward,
                    color: Colors.orange.shade600,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  "Suhu Maksimum",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade100),
              ),
              child: Row(
                children: [
                  Text(
                    "Terkini: ",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    "${model.maxTemperature} °C",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _maxController,
              decoration: InputDecoration(
                labelText: "Suhu Maksimum Baru",
                errorText: _maxError,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      BorderSide(color: Colors.orange.shade600, width: 2),
                ),
                prefixIcon:
                    Icon(Icons.thermostat, color: Colors.orange.shade600),
                suffixText: "°C",
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleUpdateMax,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.update, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Update Suhu Maksimum",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }
}
