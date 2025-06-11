class TemperatureModel {
  String currentTemperature;
  String minTemperature;
  String maxTemperature;
  bool modeOn;
  bool heaterActive;
  bool pompaActive;
  double heaterDuration;
  double pompaDuration;

  TemperatureModel({
    this.currentTemperature = "-",
    this.minTemperature = "25.0", // Default sama dengan Arduino
    this.maxTemperature = "30.0", // Default sama dengan Arduino
    this.modeOn = false,
    this.heaterActive = false,
    this.pompaActive = false,
    this.heaterDuration = 0.0,
    this.pompaDuration = 0.0,
  });

  void updateCurrentTemperature(String temperature) {
    currentTemperature = temperature;
  }

  void updateMinTemperature(String temperature) {
    minTemperature = temperature;
  }

  void updateMaxTemperature(String temperature) {
    maxTemperature = temperature;
  }
  void updateMode(bool mode) {
    modeOn = mode;
  }

  void updateHeaterStatus(bool active) {
    heaterActive = active;
  }

  void updatePompaStatus(bool active) {
    pompaActive = active;
  }

  void updateHeaterDuration(double duration) {
    heaterDuration = duration;
  }

  void updatePompaDuration(double duration) {
    pompaDuration = duration;
  }

  // Validasi range suhu (minimum harus < maksimum)
  bool isValidTemperatureRange(double min, double max) {
    return min < max;
  }

  // Helper untuk mendapatkan status current temperature
  String get temperatureStatus {
    final current = double.tryParse(currentTemperature);
    final min = double.tryParse(minTemperature);
    final max = double.tryParse(maxTemperature);
    
    if (current == null || min == null || max == null) return "Unknown";
    
    if (current < min) return "Cold";
    if (current > max) return "Hot";
    return "Normal";
  }
  Map<String, dynamic> toJson() {
    return {
      'currentTemperature': currentTemperature,
      'minTemperature': minTemperature,
      'maxTemperature': maxTemperature,
      'modeOn': modeOn,
      'heaterActive': heaterActive,
      'pompaActive': pompaActive,
      'heaterDuration': heaterDuration,
      'pompaDuration': pompaDuration,
    };
  }

  factory TemperatureModel.fromJson(Map<String, dynamic> json) {
    return TemperatureModel(
      currentTemperature: json['currentTemperature'] ?? "-",
      minTemperature: json['minTemperature'] ?? "25.0",
      maxTemperature: json['maxTemperature'] ?? "30.0",
      modeOn: json['modeOn'] ?? false,
      heaterActive: json['heaterActive'] ?? false,
      pompaActive: json['pompaActive'] ?? false,
      heaterDuration: json['heaterDuration'] ?? 0.0,
      pompaDuration: json['pompaDuration'] ?? 0.0,
    );
  }
}
