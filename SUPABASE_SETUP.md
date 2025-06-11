# Setup Database Supabase untuk AquaTemp Control

## 👥 User Management (Manual Account Creation)

Aplikasi ini menggunakan **manual account creation** untuk keamanan. Akun baru hanya bisa dibuat oleh administrator melalui dashboard Supabase.

### Cara Membuat Akun Baru:
1. Login ke [Supabase Dashboard](https://app.supabase.com)
2. Pilih project AquaTemp Control
3. Go to **Authentication** → **Users**
4. Klik **Add User**
5. Masukkan:
   - **Email**: Email pengguna baru
   - **Password**: Password sementara
   - **Confirm Password**: Konfirmasi password
   - ✅ **Auto Confirm User**: Centang agar langsung aktif
6. Klik **Create User**

### Membuat Profile untuk User Baru:
Setelah user dibuat, buat profile di tabel `profiles`:
```sql
INSERT INTO profiles (id, email, name, phone)
VALUES (
  'USER_ID_DARI_AUTH_TABLE',
  'user@example.com',
  'Nama Lengkap',
  '+62812345678'
);
```

> **💡 Tip**: User ID bisa dilihat di Authentication → Users → detail user

---

## 📋 Daftar Tabel yang Harus Dibuat di Supabase

### 1. **Tabel `profiles`** (User Profiles)
```sql
CREATE TABLE profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    name TEXT,
    phone TEXT,
    avatar_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Row Level Security (RLS):**
```sql
-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Policy untuk user hanya bisa akses profile sendiri
CREATE POLICY "Users can view own profile" ON profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON profiles
    FOR INSERT WITH CHECK (auth.uid() = id);
```

### 2. **Tabel `temperature_logs`** (Log Suhu)
```sql
CREATE TABLE temperature_logs (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    temperature DECIMAL(5,2) NOT NULL,
    min_temp DECIMAL(5,2) NOT NULL,
    max_temp DECIMAL(5,2) NOT NULL,
    mode TEXT NOT NULL CHECK (mode IN ('AUTO', 'OFF')),
    heater_active BOOLEAN DEFAULT false,
    pompa_active BOOLEAN DEFAULT false,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**RLS untuk temperature_logs:**
```sql
ALTER TABLE temperature_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own temperature logs" ON temperature_logs
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own temperature logs" ON temperature_logs
    FOR INSERT WITH CHECK (auth.uid() = user_id);
```

### 3. **Tabel `device_history`** (Log Device/Durasi)
```sql
CREATE TABLE device_history (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    device TEXT NOT NULL CHECK (device IN ('heater', 'pompa')),
    duration DECIMAL(10,2) NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**RLS untuk device_history:**
```sql
ALTER TABLE device_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own device history" ON device_history
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own device history" ON device_history
    FOR INSERT WITH CHECK (auth.uid() = user_id);
```

### 4. **Tabel `device_settings`** (Pengaturan Device per User)
```sql
CREATE TABLE device_settings (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
    min_temperature DECIMAL(5,2) DEFAULT 25.0,
    max_temperature DECIMAL(5,2) DEFAULT 30.0,
    auto_mode BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**RLS untuk device_settings:**
```sql
ALTER TABLE device_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own device settings" ON device_settings
    FOR ALL USING (auth.uid() = user_id);
```

## 🔧 **Triggers dan Functions**

### 1. **Auto-create Profile saat User Register**
```sql
-- Function untuk auto-create profile
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, name)
    VALUES (NEW.id, NEW.email, NEW.raw_user_meta_data->>'name');
    
    INSERT INTO public.device_settings (user_id)
    VALUES (NEW.id);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger untuk auto-create profile
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

### 2. **Update timestamp otomatis**
```sql
-- Function untuk update timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger untuk profiles
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger untuk device_settings
CREATE TRIGGER update_device_settings_updated_at
    BEFORE UPDATE ON device_settings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

## 🛡️ **Security & Authentication Setup**

### 1. **Email Authentication Settings**
Di Supabase Dashboard → Authentication → Settings:
- ✅ Enable email confirmations
- ✅ Enable email change confirmations 
- ✅ Enable secure password change
- Set minimum password length: 6

### 2. **Email Templates**
Customize email templates di Authentication → Email Templates:
- **Confirm signup**: Template untuk verifikasi email
- **Reset password**: Template untuk reset password
- **Change email address**: Template untuk ganti email

### 3. **URL Configuration**
Di Authentication → URL Configuration:
- **Site URL**: URL aplikasi production Anda
- **Redirect URLs**: Tambahkan URL yang diizinkan untuk redirect

## 📊 **Indexes untuk Performance**

```sql
-- Index untuk query yang sering digunakan
CREATE INDEX idx_temperature_logs_user_timestamp ON temperature_logs(user_id, timestamp DESC);
CREATE INDEX idx_device_history_user_timestamp ON device_history(user_id, timestamp DESC);
CREATE INDEX idx_device_history_device ON device_history(device);
```

## 🔑 **Environment Variables**

Pastikan file `lib/supabase_config.dart` sudah berisi:
```dart
class SupabaseConfig {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
  
  // URL dan key bisa didapat dari Supabase Dashboard → Settings → API
}
```

## 📱 **Testing Setup**

### 1. **Test Flutter App**
Jalankan aplikasi Flutter di PowerShell:
```powershell
# Pindah ke direktori project
cd "c:\Daftar materi\projek geden\tes"

# Install dependencies
flutter pub get

# Jalankan aplikasi (debug mode)
flutter run

# Atau build untuk production
flutter build apk
```

### 1.1 **PowerShell Alternative Commands**
Jika ada masalah dengan command di atas, gunakan alternatif ini:
```powershell
# Set location dan jalankan commands secara terpisah
Set-Location "c:\Daftar materi\projek geden\tes"
flutter pub get
flutter run

# Atau untuk production build
Set-Location "c:\Daftar materi\projek geden\tes"
flutter build apk
```

### 2. **Test User Login**
1. Buka aplikasi Flutter
2. Masukkan email dan password yang sudah dibuat manual
3. Pastikan bisa login dan melihat profile

### 3. **Test Data Flow**
1. Login ke aplikasi
2. Pastikan MQTT berfungsi
3. Cek apakah data suhu tersimpan di `temperature_logs`
4. Cek apakah data device tersimpan di `device_history`

## 🚀 **Production Checklist**

- [ ] Semua tabel sudah dibuat dengan benar
- [ ] RLS policies sudah diaktifkan dan ditest
- [ ] Triggers dan functions berfungsi
- [ ] Indexes sudah dibuat untuk performance
- [ ] Email authentication sudah dikonfigurasi
- [ ] Environment variables sudah diset
- [ ] Testing lengkap sudah dilakukan
- [ ] Backup strategy sudah disiapkan

## 📞 **Support**

Jika ada masalah dengan setup database:
1. Cek Supabase Dashboard → Logs untuk error messages
2. Test RLS policies dengan SQL Editor
3. Pastikan user sudah verified email mereka
4. Cek network connection untuk MQTT

---

**Note**: Pastikan untuk mengganti `YOUR_SUPABASE_URL` dan `YOUR_SUPABASE_ANON_KEY` dengan nilai sebenarnya dari project Supabase Anda.

## 🖥️ **PowerShell Commands Guide**

Karena menggunakan Windows PowerShell, berikut beberapa command yang perlu diperhatikan:

### ✅ **Commands yang Benar di PowerShell:**
```powershell
# Navigasi direktori
Set-Location "c:\Daftar materi\projek geden\tes"
# Atau gunakan cd dengan quotes untuk path dengan spasi
cd "c:\Daftar materi\projek geden\tes"

# Multiple commands secara berurutan (gunakan ; bukan &&)
flutter clean; flutter pub get; flutter run

# Check Flutter version
flutter --version

# List devices
flutter devices

# Run specific device
flutter run -d windows
flutter run -d chrome
```

### ❌ **Commands yang TIDAK BISA di PowerShell:**
```bash
# Jangan gunakan && (bash syntax)
flutter pub get && flutter run  # ❌ ERROR di PowerShell

# Gunakan ini sebagai gantinya:
flutter pub get; flutter run     # ✅ BENAR di PowerShell
```

### 🔧 **Troubleshooting PowerShell:**
```powershell
# Jika ada error "execution policy"
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Clear Flutter cache
flutter clean

# Reinstall dependencies
Remove-Item -Recurse -Force pubspec.lock; flutter pub get

# Check path variables
$env:PATH -split ';' | Where-Object { $_ -like "*flutter*" }
```

---

## 🔌 **Arduino Integration**

### **MQTT Topics yang Digunakan:**

#### **📤 Topics yang dikirim Arduino ke Flutter:**
- `esp/suhu` - Data suhu real-time (setiap 2 detik)
- `esp/batas_min_terkini` - Konfirmasi batas minimum yang diset
- `esp/batas_max_terkini` - Konfirmasi batas maksimum yang diset
- `esp/status_heater` - Status heater (on/off) real-time
- `esp/status_pompa` - Status pompa (on/off) real-time
- `esp/durasi_heater` - Total durasi heater aktif (setiap 60 detik)
- `esp/durasi_pompa` - Total durasi pompa aktif (setiap 60 detik)

#### **📥 Topics yang diterima Arduino dari Flutter:**
- `esp/mode` - Mode operasi ("on" untuk AUTO, "off" untuk OFF)
- `esp/batas_min` - Set batas suhu minimum
- `esp/batas_max` - Set batas suhu maksimum

### **Default Values yang Harus Sama:**
```
Suhu Minimum: 25.0°C
Suhu Maksimum: 30.0°C
Mode: OFF (saat startup)
```

### **Logic Pengendalian (Sesuai Arduino):**
1. **Mode AUTO**: 
   - Heater ON jika suhu < minimum
   - Pompa ON jika suhu > maksimum
   - Otomatis OFF jika sudah dalam range
2. **Mode OFF**: 
   - Semua device mati
   - Tidak ada pengendalian otomatis

### **Validasi Input:**
- Suhu minimum harus < suhu maksimum
- Error message sama dengan Arduino
- Real-time status update

### **File Arduino yang Sudah Disesuaikan:**
File `arduino_code_updated.ino` telah dibuat dengan fitur:
- ✅ Publish status heater/pompa real-time
- ✅ Validasi input sesuai Flutter
- ✅ Default values yang konsisten
- ✅ Error handling yang sama
- ✅ Status logging yang detail

---
