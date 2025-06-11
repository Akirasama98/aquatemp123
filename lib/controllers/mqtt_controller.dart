import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../models/temperature_model.dart';
import '../supabase_config.dart';
import 'auth_controller.dart';

class MqttController {
  late MqttServerClient _client;
  TemperatureModel _model = TemperatureModel();
  Function? _onDataUpdate;

  MqttController() {
    _client =
        MqttServerClient.withPort('test.mosquitto.org', 'flutter_client', 1883);
    _setupMqtt();
  }

  TemperatureModel get model => _model;

  void setOnDataUpdateCallback(Function callback) {
    _onDataUpdate = callback;
  }

  void _setupMqtt() async {
    _client.logging(on: false);
    _client.keepAlivePeriod = 20;
    _client.onConnected = _onConnected;
    _client.onDisconnected = _onDisconnected;
    _client.onSubscribed = (topic) => print('Subscribed to $topic');
    _client.onUnsubscribed = (topic) => print('Unsubscribed from $topic');
    _client.onSubscribeFail = (topic) => print('Failed to subscribe $topic');
    _client.pongCallback = () => print('Ping response received');

    try {
      await _client.connect();
    } catch (e) {
      print('MQTT Connection failed: $e');
      _client.disconnect();
    }

    _subscribeToTopics();
    _setupMessageListener();
  }
  void _subscribeToTopics() {
    _client.subscribe("esp/suhu", MqttQos.atLeastOnce);
    _client.subscribe("esp/mode", MqttQos.atLeastOnce);
    _client.subscribe("esp/batas_min_terkini", MqttQos.atLeastOnce);
    _client.subscribe("esp/batas_max_terkini", MqttQos.atLeastOnce);
    _client.subscribe("esp/durasi_heater", MqttQos.atLeastOnce);
    _client.subscribe("esp/durasi_pompa", MqttQos.atLeastOnce);
    _client.subscribe("esp/status_heater", MqttQos.atLeastOnce);
    _client.subscribe("esp/status_pompa", MqttQos.atLeastOnce);
  }

  void _setupMessageListener() {
    _client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final topic = c[0].topic;
      final recMess = c[0].payload as MqttPublishMessage;
      final pt =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      _handleIncomingMessage(topic, pt);
    });
  }
  void _handleIncomingMessage(String topic, String message) {
    switch (topic) {
      case "esp/suhu":
        _model.updateCurrentTemperature(message);
        _saveTemperatureLog(message);
        break;
      case "esp/mode":
        // Arduino sends "on" for AUTO mode, "off" for OFF mode
        _model.updateMode(message.trim().toLowerCase() == "on");
        break;
      case "esp/batas_min_terkini":
        _model.updateMinTemperature(message);
        break;
      case "esp/batas_max_terkini":
        _model.updateMaxTemperature(message);
        break;
      case "esp/durasi_heater":
        final duration = double.tryParse(message) ?? 0.0;
        _model.updateHeaterDuration(duration);
        if (duration > 0) {
          _saveDeviceHistory("heater", duration);
        }
        break;
      case "esp/durasi_pompa":
        final duration = double.tryParse(message) ?? 0.0;
        _model.updatePompaDuration(duration);
        if (duration > 0) {
          _saveDeviceHistory("pompa", duration);
        }
        break;
      case "esp/status_heater":
        _model.updateHeaterStatus(message.trim().toLowerCase() == "on");
        break;
      case "esp/status_pompa":
        _model.updatePompaStatus(message.trim().toLowerCase() == "on");
        break;
    }

    // Notify the view to update
    if (_onDataUpdate != null) {
      _onDataUpdate!();
    }
  }
  void _onConnected() {
    print('Connected to MQTT broker');
    // Publish current state when connected - sesuai dengan Arduino defaults
    publishMessage("esp/mode", _model.modeOn ? "on" : "off");
    publishMessage("esp/batas_min", _model.minTemperature);
    publishMessage("esp/batas_max", _model.maxTemperature);
  }

  void _onDisconnected() {
    print('Disconnected from MQTT broker');
  }

  void publishMessage(String topic, String message) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    _client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!,
        retain: true);
  }
  void updateMinTemperature(String temperature) {
    if (temperature.isNotEmpty) {
      final tempVal = double.tryParse(temperature);
      final maxVal = double.tryParse(_model.maxTemperature);
      
      // Validasi seperti di Arduino: min harus < max
      if (tempVal != null && maxVal != null && tempVal < maxVal) {
        publishMessage("esp/batas_min", temperature);
        print("Suhu minimum diubah menjadi $temperature");
      } else {
        print("ERROR: suhu minimum harus < suhu maksimum");
      }
    }
  }

  void updateMaxTemperature(String temperature) {
    if (temperature.isNotEmpty) {
      final tempVal = double.tryParse(temperature);
      final minVal = double.tryParse(_model.minTemperature);
      
      // Validasi seperti di Arduino: max harus > min
      if (tempVal != null && minVal != null && tempVal > minVal) {
        publishMessage("esp/batas_max", temperature);
        print("Suhu maksimum diubah menjadi $temperature");
      } else {
        print("ERROR: suhu maksimum harus > suhu minimum");
      }
    }
  }

  void updateMode(bool mode) {
    _model.updateMode(mode);
    publishMessage("esp/mode", mode ? "on" : "off");
    if (_onDataUpdate != null) {
      _onDataUpdate!();
    }
  }

  bool validateTemperatureRange(String minStr, String maxStr) {
    final minVal = double.tryParse(minStr);
    final maxVal = double.tryParse(maxStr);

    if (minVal == null || maxVal == null) return false;
    return _model.isValidTemperatureRange(minVal, maxVal);
  }
  void disconnect() {
    _client.disconnect();
  }
  
  // Database functions
  Future<void> _saveTemperatureLog(String temperature) async {
    try {
      final user = AuthController.currentUser;
      if (user == null) return;

      await SupabaseConfig.client.from('temperature_logs').insert({
        'user_id': user.id,
        'temperature': double.tryParse(temperature) ?? 0.0,
        'min_temp': double.tryParse(_model.minTemperature) ?? 0.0,
        'max_temp': double.tryParse(_model.maxTemperature) ?? 0.0,
        'mode': _model.modeOn ? 'AUTO' : 'OFF',
        'heater_active': _model.heaterActive,
        'pompa_active': _model.pompaActive,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error saving temperature log: $e');
    }
  }

  Future<void> _saveDeviceHistory(String device, double duration) async {
    try {
      final user = AuthController.currentUser;
      if (user == null) return;

      await SupabaseConfig.client.from('device_history').insert({
        'user_id': user.id,
        'device': device,
        'duration': duration,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error saving device history: $e');
    }
  }
  Future<List<Map<String, dynamic>>> getTemperatureHistory(
      {int limit = 50}) async {
    try {
      final user = AuthController.currentUser;
      if (user == null) return [];

      final response = await SupabaseConfig.client
          .from('temperature_logs')
          .select()
          .eq('user_id', user.id)
          .order('timestamp', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error loading temperature history: $e');
      return [];
    }
  }
  Future<List<Map<String, dynamic>>> getDeviceHistory({int limit = 50}) async {
    try {
      final user = AuthController.currentUser;
      if (user == null) return [];

      final response = await SupabaseConfig.client
          .from('device_history')
          .select()
          .eq('user_id', user.id)
          .order('timestamp', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error loading device history: $e');
      return [];
    }
  }
}
