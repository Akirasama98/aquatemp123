import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'update_suhu_page.dart';
import 'history_page.dart';
import 'supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final client =
      MqttServerClient.withPort('test.mosquitto.org', 'flutter_client', 1883);
  final minController = TextEditingController();
  final maxController = TextEditingController();
  final modeController = TextEditingController();

  String suhuTerkini = "-";
  String minTerkini = "-";
  String maxTerkini = "-";
  String heaterDuration = "0";
  String pumpDuration = "0";
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
    client.subscribe("esp/durasi_heater", MqttQos.atLeastOnce);
    client.subscribe("esp/durasi_pompa", MqttQos.atLeastOnce);

    client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final topic = c[0].topic;
      final recMess = c[0].payload as MqttPublishMessage;
      final pt =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

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
        } else if (topic == "esp/durasi_heater") {
          heaterDuration = pt;
          _saveHistory("heater", double.parse(pt));
        } else if (topic == "esp/durasi_pompa") {
          pumpDuration = pt;
          _saveHistory("pump", double.parse(pt));
        }
      });
    });
  }

  Future<void> _saveHistory(String device, double duration) async {
    try {
      await SupabaseConfig.client.from('device_history').insert({
        'device': device,
        'duration': duration,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error saving history: $e');
    }
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
    client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!,
        retain: true);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.set_meal, color: Colors.white, size: 20),
              ),
              SizedBox(width: 8),
              Text(
                'AQUATEMP',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        body: _selectedIndex == 0
            ? HomePage()
            : _selectedIndex == 1
                ? UpdateSuhuPage(
                    minTerkini: minTerkini,
                    maxTerkini: maxTerkini,
                    minController: minController,
                    maxController: maxController,
                    onUpdateMin: (min) {
                      final minVal = double.tryParse(min);
                      final maxVal = double.tryParse(maxTerkini);
                      if (min.isNotEmpty &&
                          minVal != null &&
                          minVal > 0 &&
                          maxVal != null &&
                          minVal < maxVal) {
                        publishMessage("esp/batas_min", min);
                      }
                    },
                    onUpdateMax: (max) {
                      final maxVal = double.tryParse(max);
                      final minVal = double.tryParse(minTerkini);
                      if (max.isNotEmpty &&
                          maxVal != null &&
                          minVal != null &&
                          maxVal > minVal &&
                          maxVal > 0) {
                        publishMessage("esp/batas_max", max);
                      }
                    },
                  )
                : HistoryPage(
                    heaterDuration: heaterDuration,
                    pumpDuration: pumpDuration,
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
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'History',
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
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 350;
    final cardHeight = size.height * 0.18 > 140 ? 140.0 : size.height * 0.18;
    final cardHeightSuhu =
        size.height * 0.28 > 200 ? 200.0 : size.height * 0.28;
    final cardPadding = size.width * 0.05;
    final fontTitle = isSmall ? 18.0 : 22.0;
    final fontBig = isSmall ? 26.0 : 36.0;
    final fontMid = isSmall ? 14.0 : 18.0;
    final fontBound = isSmall ? 18.0 : 26.0;

    return Container(
      color: Color(0xFFF4F7FB),
      child: ListView(
        padding: EdgeInsets.symmetric(
            horizontal: cardPadding, vertical: cardPadding),
        children: [
          // Logo dan nama aplikasi (DIHAPUS)
          // Row(
          //   children: [
          //     Container(
          //       width: isSmall ? 32 : 40,
          //       height: isSmall ? 32 : 40,
          //       decoration: BoxDecoration(
          //         color: Colors.blue,
          //         borderRadius: BorderRadius.circular(12),
          //       ),
          //       child: Icon(Icons.set_meal, color: Colors.white, size: isSmall ? 20 : 28),
          //     ),
          //     SizedBox(width: isSmall ? 8 : 12),
          //     Text(
          //       'AQUATEMP',
          //       style: TextStyle(
          //         fontWeight: FontWeight.bold,
          //         fontSize: fontTitle,
          //         letterSpacing: 1.2,
          //       ),
          //     ),
          //   ],
          // ),
          // SizedBox(height: isSmall ? 16 : 24),
          // Kartu Suhu Air (sendiri, dipanjangkan)
          Builder(
            builder: (context) {
              double? suhu = double.tryParse(parent.suhuTerkini);
              double? min = double.tryParse(parent.minTerkini);
              double? max = double.tryParse(parent.maxTerkini);
              String status = 'Normal';
              Color statusColor = Colors.grey;
              List<Color> gradColors = [
                Color(0xFF9CA3AF),
                Color(0xFFD1D5DB)
              ]; // default abu-abu
              if (suhu != null && min != null && max != null) {
                if (suhu < min) {
                  status = 'Dingin';
                  statusColor = Colors.blue;
                  gradColors = [Color(0xFF2563EB), Color(0xFF60A5FA)]; // biru
                } else if (suhu > max) {
                  status = 'Panas';
                  statusColor = Colors.red;
                  gradColors = [Color(0xFFEF4444), Color(0xFFFCA5A5)]; // merah
                }
              }
              return Container(
                width: double.infinity,
                height: cardHeightSuhu,
                margin: EdgeInsets.only(bottom: isSmall ? 12 : 18),
                padding: EdgeInsets.all(isSmall ? 10 : 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.water_drop,
                            color: Colors.black54, size: isSmall ? 16 : 20),
                        SizedBox(width: 6),
                        Text('Suhu Air',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: fontMid)),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          parent.suhuTerkini != '-' ? parent.suhuTerkini : '--',
                          style: TextStyle(
                              fontSize: fontBig, fontWeight: FontWeight.bold),
                        ),
                        Padding(
                          padding: EdgeInsets.only(bottom: 6, left: 2),
                          child: Text('°C',
                              style: TextStyle(
                                  fontSize: fontMid, color: Colors.black54)),
                        ),
                        Spacer(),
                        Text(
                          status,
                          style: TextStyle(
                              color: statusColor,
                              fontSize: fontMid,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Spacer(),
                    Container(
                      height: isSmall ? 18 : 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: gradColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: CustomPaint(
                        painter: _WavePainter(),
                        child: Container(),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          // Kartu IoT (sendiri)
          Container(
            width: double.infinity,
            height: cardHeight,
            margin: EdgeInsets.only(bottom: isSmall ? 12 : 18),
            padding: EdgeInsets.all(isSmall ? 10 : 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.memory,
                        color: Colors.black54, size: isSmall ? 16 : 20),
                    SizedBox(width: 6),
                    Text('IoT',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: fontMid)),
                  ],
                ),
                Spacer(),
                Center(
                  child: Column(
                    children: [
                      Switch(
                        value: parent.modeOn,
                        activeColor: Colors.white,
                        activeTrackColor: Colors.green,
                        inactiveTrackColor: Colors.grey.shade300,
                        onChanged: (val) {
                          (context.findAncestorStateOfType<_MyAppState>()
                                  as _MyAppState)
                              .setState(() {
                            parent.modeOn = val;
                            parent.publishMessage(
                                "esp/mode", parent.modeOn ? "on" : "off");
                          });
                        },
                      ),
                      Text(
                        parent.modeOn ? 'ON' : 'OFF',
                        style: TextStyle(
                          color: parent.modeOn ? Colors.green : Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: fontMid,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Kartu Batas Suhu
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isSmall ? 12 : 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.show_chart,
                        color: Colors.black54, size: isSmall ? 16 : 20),
                    SizedBox(width: 6),
                    Text('Batas Suhu',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: fontMid)),
                  ],
                ),
                SizedBox(height: isSmall ? 10 : 18),
                Container(
                  width: double.infinity,
                  height: isSmall ? 36 : 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFFEF4444)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: isSmall ? 12 : 24),
                        child: Text(
                          parent.minTerkini != '-'
                              ? parent.minTerkini + '°C'
                              : '--°C',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: fontBound,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(right: isSmall ? 12 : 24),
                        child: Text(
                          parent.maxTerkini != '-'
                              ? parent.maxTerkini + '°C'
                              : '--°C',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: fontBound,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Widget untuk menggambar gelombang air pada kartu suhu
class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(
        size.width * 0.25, size.height, size.width * 0.5, size.height * 0.7);
    path.quadraticBezierTo(
        size.width * 0.75, size.height * 0.4, size.width, size.height * 0.7);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
