# AquaTemp Control - MVC Structure

Aplikasi IoT untuk mengontrol suhu menggunakan MQTT dengan arsitektur MVC.

## Struktur MVC

### Model (`lib/models/`)
- **TemperatureModel**: Model data untuk menyimpan state suhu (current, min, max) dan mode

### View (`lib/views/`)
- **HomeView**: Tampilan halaman utama dengan display suhu dan toggle mode
- **UpdateTemperatureView**: Tampilan untuk mengupdate batas suhu minimum dan maksimum

### Controller (`lib/controllers/`)
- **MqttController**: Controller untuk mengelola koneksi MQTT dan business logic

## Fitur

1. **Monitoring Suhu Real-time**
   - Menampilkan suhu terkini dari sensor
   - Menampilkan batas suhu minimum dan maksimum

2. **Kontrol Mode**
   - Toggle mode AUTO/OFF
   - Sinkronisasi dengan perangkat IoT

3. **Update Batas Suhu**
   - Input suhu minimum dan maksimum
   - Validasi input (min < max)
   - Feedback sukses/error

4. **Komunikasi MQTT**
   - Subscribe: esp/suhu, esp/mode, esp/batas_min_terkini, esp/batas_max_terkini
   - Publish: esp/mode, esp/batas_min, esp/batas_max

## Keunggulan Arsitektur MVC

1. **Separation of Concerns**: Logika bisnis, data, dan UI terpisah
2. **Reusability**: Component dapat digunakan ulang
3. **Maintainability**: Mudah untuk maintenance dan debugging
4. **Testability**: Setiap layer dapat di-test secara terpisah
5. **Scalability**: Mudah untuk menambah fitur baru

## Penggunaan

1. Jalankan aplikasi Flutter
2. Pastikan perangkat IoT terhubung ke broker MQTT yang sama
3. Monitor suhu real-time di halaman Beranda
4. Update batas suhu di halaman "Update Suhu"
5. Toggle mode AUTO/OFF sesuai kebutuhan
