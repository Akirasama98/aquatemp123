# 🌊 AquaTemp Control - Arduino Integration Guide

## 📋 **Project Overview**

Sistem kontrol dan monitoring suhu air menggunakan:
- **ESP32** dengan sensor DS18B20
- **Flutter** aplikasi mobile dengan autentikasi user
- **Supabase** database dan authentication
- **MQTT** untuk komunikasi real-time

## 🔌 **Hardware Requirements**

### **Komponen:**
- ESP32 Development Board
- Sensor suhu DS18B20 (waterproof)
- 2x Relay Module (heater & pompa)
- Breadboard dan kabel jumper
- Resistor 4.7kΩ (pull-up untuk DS18B20)

### **Wiring Diagram:**
```
ESP32          | DS18B20    | Relay Module
GPIO 33        | Data       | -
GPIO 4         | -          | IN1 (Heater)
GPIO 17        | -          | IN2 (Pompa)
3.3V           | VCC        | VCC
GND            | GND        | GND
```

## 🚀 **Setup Instructions**

### **1. Arduino Setup**
```bash
# Install libraries di Arduino IDE:
- WiFi (ESP32)
- PubSubClient
- OneWire  
- DallasTemperature
```

Upload file `arduino_code_updated.ino` ke ESP32:
1. Sesuaikan WiFi credentials:
   ```cpp
   const char* ssid = "YOUR_WIFI_SSID";
   const char* password = "YOUR_WIFI_PASSWORD";
   ```
2. Upload code ke ESP32
3. Monitor Serial untuk memastikan koneksi WiFi dan MQTT berhasil

### **2. Flutter App Setup**
```powershell
# Pindah ke direktori project
Set-Location "c:\Daftar materi\projek geden\tes"

# Install dependencies
flutter pub get

# Jalankan aplikasi
flutter run
```

### **3. Database Setup**
Ikuti petunjuk lengkap di `SUPABASE_SETUP.md`

## 📡 **MQTT Communication Flow**

### **Topics yang Digunakan:**

#### **📤 Arduino → Flutter:**
- `esp/suhu` - Suhu real-time (°C, setiap 2 detik)
- `esp/batas_min_terkini` - Konfirmasi batas minimum 
- `esp/batas_max_terkini` - Konfirmasi batas maksimum
- `esp/status_heater` - Status heater (on/off)
- `esp/status_pompa` - Status pompa (on/off)  
- `esp/durasi_heater` - Total durasi heater (detik, setiap 60s)
- `esp/durasi_pompa` - Total durasi pompa (detik, setiap 60s)

#### **📥 Flutter → Arduino:**
- `esp/mode` - Mode operasi ("on"=AUTO, "off"=OFF)
- `esp/batas_min` - Set suhu minimum (°C)
- `esp/batas_max` - Set suhu maksimum (°C)

## 🎮 **Control Logic**

### **Mode AUTO:**
1. **Heater**: ON jika suhu < minimum, OFF jika suhu >= minimum
2. **Pompa**: ON jika suhu > maksimum, OFF jika suhu <= maksimum  
3. **Real-time status**: Publish status change immediately

### **Mode OFF:**
1. Semua device dimatikan
2. Tidak ada kontrol otomatis
3. Status di-publish sebagai "off"

### **Validasi:**
- Suhu minimum < suhu maksimum
- Error message konsisten Arduino ↔ Flutter
- Default values: min=25°C, max=30°C

## 📊 **Database Schema**

### **Tables Created:**
1. `profiles` - User profile data
2. `temperature_logs` - Real-time temperature & device status 
3. `device_history` - Device usage duration logs
4. `device_settings` - Per-user temperature settings

### **Data Flow:**
```
Arduino MQTT → Flutter → Supabase Database
                    ↓
              User Authentication
                    ↓  
              User-specific Data
```

## 🛠️ **Testing & Troubleshooting**

### **1. Test Arduino Connection:**
```cpp
// Check Serial Monitor for:
- WiFi connection success
- MQTT broker connection
- Temperature readings
- Device status changes
```

### **2. Test Flutter App:**
1. Login dengan akun yang dibuat manual di Supabase
2. Verifikasi MQTT connection
3. Test mode AUTO/OFF switching  
4. Cek perubahan suhu minimum/maksimum
5. Monitor real-time status heater/pompa

### **3. Test Database Integration:**
1. Cek data tersimpan di `temperature_logs`
2. Verifikasi `device_history` logging
3. Test user-specific data filtering

### **Common Issues:**

#### **Arduino tidak connect MQTT:**
- Cek WiFi credentials
- Pastikan internet connection stabil
- Monitor Serial untuk error messages

#### **Flutter tidak terima data:**
- Restart MQTT connection di app
- Cek topic names (case sensitive)
- Verifikasi broker: test.mosquitto.org

#### **Database error:**
- Cek Supabase connection
- Verifikasi user authentication
- Check RLS policies

## 📈 **Features Implemented**

### ✅ **Hardware Control:**
- [x] Real-time temperature monitoring
- [x] Automatic heater control (suhu < minimum)
- [x] Automatic pompa control (suhu > maksimum)  
- [x] Manual mode switching (AUTO/OFF)
- [x] Duration tracking untuk setiap device

### ✅ **Mobile App:**
- [x] User authentication (manual account creation)
- [x] Real-time temperature display
- [x] Device status monitoring (heater/pompa)
- [x] Temperature range setting dengan validasi
- [x] History logging dengan user-specific data
- [x] Mode control (AUTO/OFF)

### ✅ **Database Integration:**
- [x] User-specific data storage
- [x] Real-time logging temperature + device status
- [x] Device usage history tracking
- [x] Row Level Security (RLS) policies
- [x] Auto-create profile untuk user baru

## 🔮 **Future Enhancements**

### **Possible Improvements:**
- [ ] Push notifications untuk alert suhu
- [ ] Historical data charts/graphs
- [ ] Multiple device support per user
- [ ] WiFi configuration via app
- [ ] OTA (Over-The-Air) updates untuk Arduino
- [ ] Backup MQTT broker configuration
- [ ] Export data to CSV/PDF

## 📞 **Support & Contact**

Jika ada masalah atau pertanyaan:
1. Check logs di Supabase Dashboard
2. Monitor Arduino Serial output  
3. Test MQTT topics dengan MQTT client tools
4. Verify database RLS policies

---

**✨ Happy Coding!** 🚀
