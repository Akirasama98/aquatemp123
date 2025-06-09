import 'package:flutter/material.dart';

class UpdateSuhuPage extends StatefulWidget {
  final String minTerkini;
  final String maxTerkini;
  final TextEditingController minController;
  final TextEditingController maxController;
  final void Function(String) onUpdateMin;
  final void Function(String) onUpdateMax;

  const UpdateSuhuPage({
    Key? key,
    required this.minTerkini,
    required this.maxTerkini,
    required this.minController,
    required this.maxController,
    required this.onUpdateMin,
    required this.onUpdateMax,
  }) : super(key: key);

  @override
  State<UpdateSuhuPage> createState() => _UpdateSuhuPageState();
}

class _UpdateSuhuPageState extends State<UpdateSuhuPage> {
  String? minError;
  String? maxError;

  void handleUpdateMin() {
    final minText = widget.minController.text.isNotEmpty
        ? widget.minController.text
        : widget.minTerkini;
    final maxText = widget.maxController.text.isNotEmpty
        ? widget.maxController.text
        : widget.maxTerkini;
    final minVal = double.tryParse(minText);
    final maxVal = double.tryParse(maxText);
    setState(() {
      if (minVal == null || maxVal == null) {
        minError = 'Input tidak valid';
      } else if (minVal >= maxVal) {
        minError = 'Suhu minimum harus lebih kecil dari maksimum';
      } else if (minVal <= 0) {
        minError = 'Suhu minimum harus lebih dari 0';
      } else {
        minError = null;
        widget.onUpdateMin(minText);
        FocusScope.of(context).unfocus();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Suhu minimum berhasil diupdate!')),
        );
      }
    });
  }

  void handleUpdateMax() {
    final maxText = widget.maxController.text.isNotEmpty
        ? widget.maxController.text
        : widget.maxTerkini;
    final minText = widget.minController.text.isNotEmpty
        ? widget.minController.text
        : widget.minTerkini;
    final maxVal = double.tryParse(maxText);
    final minVal = double.tryParse(minText);
    setState(() {
      if (minVal == null || maxVal == null) {
        maxError = 'Input tidak valid';
      } else if (maxVal <= minVal) {
        maxError = 'Suhu maksimum harus lebih besar dari minimum';
      } else if (maxVal <= 0) {
        maxError = 'Suhu maksimum harus lebih dari 0';
      } else {
        maxError = null;
        widget.onUpdateMax(maxText);
        FocusScope.of(context).unfocus();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Suhu maksimum berhasil diupdate!')),
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.minController.text.isEmpty &&
        widget.minTerkini != "-" &&
        widget.minTerkini != "0" &&
        double.tryParse(widget.minTerkini) != null) {
      widget.minController.text = widget.minTerkini;
    }
    if (widget.maxController.text.isEmpty &&
        widget.maxTerkini != "-" &&
        widget.maxTerkini != "0" &&
        double.tryParse(widget.maxTerkini) != null) {
      widget.maxController.text = widget.maxTerkini;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 350;
    final cardPadding = size.width * 0.05;
    return Container(
      color: Color(0xFFF4F7FB),
      child: ListView(
        padding: EdgeInsets.symmetric(
            horizontal: cardPadding, vertical: cardPadding),
        children: [
          SizedBox(height: 12),
          Text(
            'Update Batas Suhu',
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: 1.1),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 6),
          Text(
            'Atur ulang batas suhu minimum dan maksimum sesuai kebutuhan kolam Anda.',
            style: TextStyle(color: Colors.black54, fontSize: 15),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          // Card Suhu Minimum
          Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.thermostat, color: Colors.blue, size: 28),
                      SizedBox(width: 10),
                      Text('Suhu Minimum',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18)),
                      Spacer(),
                      Text('${widget.minTerkini}°C',
                          style: TextStyle(
                              color: Colors.blue, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: widget.minController,
                    decoration: InputDecoration(
                      labelText: "Suhu Minimum Baru",
                      prefixIcon:
                          Icon(Icons.arrow_downward, color: Colors.blue),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      errorText: minError,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: handleUpdateMin,
                      child: Text("Update Suhu Minimum",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 18),
          // Card Suhu Maksimum
          Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.thermostat, color: Colors.red, size: 28),
                      SizedBox(width: 10),
                      Text('Suhu Maksimum',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18)),
                      Spacer(),
                      Text('${widget.maxTerkini}°C',
                          style: TextStyle(
                              color: Colors.red, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: widget.maxController,
                    decoration: InputDecoration(
                      labelText: "Suhu Maksimum Baru",
                      prefixIcon: Icon(Icons.arrow_upward, color: Colors.red),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      errorText: maxError,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: handleUpdateMax,
                      child: Text("Update Suhu Maksimum",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
