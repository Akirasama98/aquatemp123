import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'update_suhu_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final client = MqttServerClient.withPort('test.mosquitto.org', 'flutter_client', 1883);
  final minController = TextEditingController();
  final maxController = TextEditingController();
  final modeController = TextEditingController();

  String suhuTerkini = "-";
  String minTerkini = "-";
  String maxTerkini = "-";
  bool modeOn = false;

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    setupMqtt();
  }

  void setupMqtt() async {
    client.logging(on: false);
    client.keepAlivePeriod = 20;
    client.onConnected = onConnected;
    client.onDisconnected = onDisconnected;
    client.onSubscribed = (topic) => print('Subscribed to $topic');
    client.onUnsubscribed = (topic) => print('Unsubscribed from $topic');
    client.onSubscribeFail = (topic) => print('Failed to subscribe $topic');
    client.pongCallback = () => print('Ping response received');

    try {
      await client.connect();
    } catch (e) {
      print('MQTT Connection failed: $e');
      client.disconnect();
    }

    client.subscribe("esp/suhu", MqttQos.atLeastOnce);
    client.subscribe("esp/mode", MqttQos.atLeastOnce);
    client.subscribe("esp/batas_min_terkini", MqttQos.atLeastOnce);
    client.subscribe("esp/batas_max_terkini", MqttQos.atLeastOnce);

    client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final topic = c[0].topic;
      final recMess = c[0].payload as MqttPublishMessage;
      final pt = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      setState(() {
        if (topic == "esp/suhu") {
          suhuTerkini = pt;
        } else if (topic == "esp/mode") {
          modeOn = pt.trim().toLowerCase() == "on";
        } else if (topic == "esp/batas_min_terkini") {
          minTerkini = pt;
          minController.text = pt;
        } else if (topic == "esp/batas_max_terkini") {
          maxTerkini = pt;
          maxController.text = pt;
        }
      });
    });
  }

  void onConnected() {
    print('Connected to MQTT broker');
    // Publish state saat terkoneksi
    publishMessage("esp/mode", modeOn ? "on" : "off");
    publishMessage("esp/batas_min", minTerkini);
    publishMessage("esp/batas_max", maxTerkini);
  }

  void onDisconnected() {
    print('Disconnected from MQTT broker');
  }

  void publishMessage(String topic, String message) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!, retain: true);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text("Kontrol IoT - MQTT"),
        ),
        body: _selectedIndex == 0
            ? HomePage()
            : UpdateSuhuPage(
                minTerkini: minTerkini,
                maxTerkini: maxTerkini,
                minController: minController,
                maxController: maxController,
                onUpdateMin: (min) {
                  if (min.isNotEmpty) publishMessage("esp/batas_min", min);
                },
                onUpdateMax: (max) {
                  if (max.isNotEmpty) publishMessage("esp/batas_max", max);
                },
              ),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.thermostat),
              label: 'Update Suhu',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.blue,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    minController.dispose();
    maxController.dispose();
    modeController.dispose();
    client.disconnect();
    super.dispose();
  }
}

// Halaman utama sebagai widget terpisah
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final _MyAppState? parent = context.findAncestorStateOfType<_MyAppState>();
    if (parent == null) return SizedBox();
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Suhu Terkini: "+parent.suhuTerkini+" °C", style: TextStyle(fontSize: 20)),
          SizedBox(height: 8),
          Text("Suhu Minimum Terkini: "+parent.minTerkini+" °C", style: TextStyle(fontSize: 16)),
          Text("Suhu Maksimum Terkini: "+parent.maxTerkini+" °C", style: TextStyle(fontSize: 16)),
          SizedBox(height: 20),
          Row(
            children: [
              Text("Mode: ", style: TextStyle(fontSize: 16)),
              Switch(
                value: parent.modeOn,
                onChanged: (val) {
                  // Gunakan callback ke parent
                  (context.findAncestorStateOfType<_MyAppState>() as _MyAppState).setState(() {
                    parent.modeOn = val;
                    parent.publishMessage("esp/mode", parent.modeOn ? "on" : "off");
                  });
                },
              ),
              Text(parent.modeOn ? "ON" : "OFF"),
            ],
          ),
        ],
      ),
    );
  }
}
