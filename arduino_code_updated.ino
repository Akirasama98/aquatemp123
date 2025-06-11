#include <WiFi.h>
#include <PubSubClient.h>
#include <OneWire.h>
#include <DallasTemperature.h>

// Pin konfigurasi
#define HEATER_RELAY_PIN 4
#define POMPA_RELAY_PIN 17
#define ONE_WIRE_BUS 33

// WiFi
const char* ssid = "FASILKOM-ACCESS";
const char* password = "Integer!";

// MQTT Broker
const char* mqtt_server = "test.mosquitto.org";

// Global MQTT dan sensor
WiFiClient espClient;
PubSubClient client(espClient);
OneWire oneWire(ONE_WIRE_BUS);
DallasTemperature sensors(&oneWire);

// Mode pengendalian
enum Mode { OFF, AUTO };
Mode mode = OFF;

// Ambang suhu (default values yang sama dengan Flutter)
float ambangMinimum = 25.0;
float ambangMaksimum = 30.0;

// Timer durasi aktif
unsigned long heaterOnTime = 0;
unsigned long pompaOnTime = 0;
unsigned long lastHeaterMillis = 0;
unsigned long lastPompaMillis = 0;
bool heaterStatus = false;
bool pompaStatus = false;

// Timer publish data
unsigned long lastPublishMillis = 0;
unsigned long lastStatusPublish = 0;

void setup_wifi() {
  delay(10);
  Serial.print("Menghubungkan ke WiFi ");
  Serial.println(ssid);
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi terhubung");
}

void callback(char* topic, byte* payload, unsigned int length) {
  String msg;
  for (unsigned int i = 0; i < length; i++) {
    msg += (char)payload[i];
  }
  msg.trim(); 
  msg.toLowerCase();

  if (String(topic) == "esp/mode") {
    if (msg == "on") {
      mode = AUTO;
      Serial.println("Mode: AUTO");
    } else if (msg == "off") {
      mode = OFF;
      Serial.println("Mode: OFF");
      // Turn off devices when mode is OFF
      digitalWrite(HEATER_RELAY_PIN, HIGH);
      digitalWrite(POMPA_RELAY_PIN, HIGH);
      heaterStatus = false;
      pompaStatus = false;
      // Publish status immediately
      client.publish("esp/status_heater", "off", true);
      client.publish("esp/status_pompa", "off", true);
    }
  } else if (String(topic) == "esp/batas_min") {
    float val = msg.toFloat();
    if (val < ambangMaksimum) {
      ambangMinimum = val;
      Serial.print("Suhu minimum diubah menjadi ");
      Serial.println(ambangMinimum);
      client.publish("esp/batas_min_terkini", String(ambangMinimum).c_str(), true);
    } else {
      Serial.println("ERROR: suhu minimum harus < suhu maksimum");
    }
  } else if (String(topic) == "esp/batas_max") {
    float val = msg.toFloat();
    if (val > ambangMinimum) {
      ambangMaksimum = val;
      Serial.print("Suhu maksimum diubah menjadi ");
      Serial.println(ambangMaksimum);
      client.publish("esp/batas_max_terkini", String(ambangMaksimum).c_str(), true);
    } else {
      Serial.println("ERROR: suhu maksimum harus > suhu minimum");
    }
  }
}

void reconnect() {
  while (!client.connected()) {
    Serial.print("Menyambung ke MQTT...");
    if (client.connect("esp32_client")) {
      Serial.println("Tersambung ke Mosquitto");
      
      // Subscribe to topics
      client.subscribe("esp/mode");
      client.subscribe("esp/batas_min");
      client.subscribe("esp/batas_max");
      
      // Publish initial values
      client.publish("esp/batas_min_terkini", String(ambangMinimum).c_str(), true);
      client.publish("esp/batas_max_terkini", String(ambangMaksimum).c_str(), true);
      client.publish("esp/mode", mode == AUTO ? "on" : "off", true);
      client.publish("esp/status_heater", heaterStatus ? "on" : "off", true);
      client.publish("esp/status_pompa", pompaStatus ? "on" : "off", true);
      
    } else {
      Serial.print("Gagal, coba lagi 5 detik\n");
      delay(5000);
    }
  }
}

void publishStatus() {
  // Publish heater and pompa status
  client.publish("esp/status_heater", heaterStatus ? "on" : "off", true);
  client.publish("esp/status_pompa", pompaStatus ? "on" : "off", true);
}

void setup() {
  Serial.begin(115200);
  pinMode(HEATER_RELAY_PIN, OUTPUT);
  pinMode(POMPA_RELAY_PIN, OUTPUT);
  digitalWrite(HEATER_RELAY_PIN, HIGH);  // Relay OFF
  digitalWrite(POMPA_RELAY_PIN, HIGH);   // Relay OFF
  sensors.begin();
  setup_wifi();
  client.setServer(mqtt_server, 1883);
  client.setCallback(callback);
}

void loop() {
  if (!client.connected()) {
    reconnect();
  }
  client.loop();

  sensors.requestTemperatures();
  float suhu = sensors.getTempCByIndex(0);
  Serial.print("Suhu: ");
  Serial.print(suhu);
  Serial.print("°C, Mode: ");
  Serial.print(mode == AUTO ? "AUTO" : "OFF");
  Serial.print(", Heater: ");
  Serial.print(heaterStatus ? "ON" : "OFF");
  Serial.print(", Pompa: ");
  Serial.println(pompaStatus ? "ON" : "OFF");
  
  // Publish temperature every loop
  client.publish("esp/suhu", String(suhu).c_str(), true);

  unsigned long now = millis();
  bool statusChanged = false;

  if (mode == AUTO) {
    // HEATER CONTROL
    if (suhu < ambangMinimum) {
      digitalWrite(HEATER_RELAY_PIN, LOW); // Turn ON heater
      if (!heaterStatus) {
        heaterStatus = true;
        lastHeaterMillis = now;
        statusChanged = true;
        Serial.println("Heater ON - Suhu terlalu rendah");
      }
    } else {
      digitalWrite(HEATER_RELAY_PIN, HIGH); // Turn OFF heater
      if (heaterStatus) {
        heaterOnTime += (now - lastHeaterMillis) / 1000;
        heaterStatus = false;
        statusChanged = true;
        Serial.println("Heater OFF - Suhu sudah cukup");
      }
    }

    // POMPA CONTROL
    if (suhu > ambangMaksimum) {
      digitalWrite(POMPA_RELAY_PIN, LOW); // Turn ON pompa
      if (!pompaStatus) {
        pompaStatus = true;
        lastPompaMillis = now;
        statusChanged = true;
        Serial.println("Pompa ON - Suhu terlalu tinggi");
      }
    } else {
      digitalWrite(POMPA_RELAY_PIN, HIGH); // Turn OFF pompa
      if (pompaStatus) {
        pompaOnTime += (now - lastPompaMillis) / 1000;
        pompaStatus = false;
        statusChanged = true;
        Serial.println("Pompa OFF - Suhu sudah normal");
      }
    }
  } else {
    // Mode OFF - turn off all devices
    digitalWrite(HEATER_RELAY_PIN, HIGH);
    digitalWrite(POMPA_RELAY_PIN, HIGH);
    if (heaterStatus || pompaStatus) {
      heaterStatus = false;
      pompaStatus = false;
      statusChanged = true;
    }
  }

  // Publish status immediately when changed
  if (statusChanged || (now - lastStatusPublish >= 5000)) {
    publishStatus();
    lastStatusPublish = now;
  }

  // Publish duration every 60 seconds
  if (now - lastPublishMillis >= 60000) {
    lastPublishMillis = now;
    client.publish("esp/durasi_heater", String(heaterOnTime).c_str(), true);
    client.publish("esp/durasi_pompa", String(pompaOnTime).c_str(), true);
    
    Serial.print("Total durasi - Heater: ");
    Serial.print(heaterOnTime);
    Serial.print("s, Pompa: ");
    Serial.print(pompaOnTime);
    Serial.println("s");
  }

  delay(2000);
}
