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
    final minText = widget.minController.text.isNotEmpty ? widget.minController.text : widget.minTerkini;
    final maxText = widget.maxController.text.isNotEmpty ? widget.maxController.text : widget.maxTerkini;
    final minVal = double.tryParse(minText);
    final maxVal = double.tryParse(maxText);
    setState(() {
      if (minVal == null || maxVal == null) {
        minError = 'Input tidak valid';
      } else if (minVal >= maxVal) {
        minError = 'Suhu minimum harus lebih kecil dari maksimum';
      } else {
        minError = null;
        widget.onUpdateMin(minText);
      }
    });
  }

  void handleUpdateMax() {
    final maxText = widget.maxController.text.isNotEmpty ? widget.maxController.text : widget.maxTerkini;
    final minText = widget.minController.text.isNotEmpty ? widget.minController.text : widget.minTerkini;
    final maxVal = double.tryParse(maxText);
    final minVal = double.tryParse(minText);
    setState(() {
      if (minVal == null || maxVal == null) {
        maxError = 'Input tidak valid';
      } else if (maxVal <= minVal) {
        maxError = 'Suhu maksimum harus lebih besar dari minimum';
      } else {
        maxError = null;
        widget.onUpdateMax(maxText);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    // Set controller hanya jika belum ada input user dan minTerkini/maxTerkini valid
    if (widget.minController.text.isEmpty && widget.minTerkini != "-" && widget.minTerkini != "0" && double.tryParse(widget.minTerkini) != null) {
      widget.minController.text = widget.minTerkini;
    }
    if (widget.maxController.text.isEmpty && widget.maxTerkini != "-" && widget.maxTerkini != "0" && double.tryParse(widget.maxTerkini) != null) {
      widget.maxController.text = widget.maxTerkini;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Suhu Minimum Terkini: ${widget.minTerkini} °C", style: TextStyle(fontSize: 18)),
          TextField(
            controller: widget.minController,
            decoration: InputDecoration(
              labelText: "Suhu Minimum Baru",
              errorText: minError,
            ),
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: 8),
          ElevatedButton(
            onPressed: handleUpdateMin,
            child: Text("Update Suhu Minimum"),
          ),
          SizedBox(height: 24),
          Text("Suhu Maksimum Terkini: ${widget.maxTerkini} °C", style: TextStyle(fontSize: 18)),
          TextField(
            controller: widget.maxController,
            decoration: InputDecoration(
              labelText: "Suhu Maksimum Baru",
              errorText: maxError,
            ),
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: 8),
          ElevatedButton(
            onPressed: handleUpdateMax,
            child: Text("Update Suhu Maksimum"),
          ),
        ],
      ),
    );
  }
}
