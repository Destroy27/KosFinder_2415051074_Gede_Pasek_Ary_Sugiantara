# KosFinder — Authentication, Authorization & Push Notification

Aplikasi Flutter untuk studi kasus **KosFinder** pada Worksheet 9 Pemrograman Mobile: pengguna dapat mencari kos, pemilik kos dapat memasarkan kosnya, dan admin dapat mengelola data. Keamanan data ditegakkan di **Supabase** melalui **Row Level Security**, dan aplikasi menerima **push notification** melalui **Firebase Cloud Messaging**.

| Atribut | Keterangan |
| --- | --- |
| Nama | Gede Pasek Ary Sugiantara |
| NIM | 2415051074 |
| Kelas | PTI 5C |
| Mata Kuliah | Pemrograman Mobile |
| Dosen | Dr. Ir. I Ketut Resika Arthana, S.T., M.Kom |
| Teaching Assistant | Made Yuda Sadewa, S.Pd. |

---

## 1. Fitur

### Authentication
- Registrasi dengan nama, email, password, konfirmasi password, dan pilihan role (pencari kos / pemilik kos).
- Login dengan email dan password.
- Session dipulihkan otomatis saat aplikasi dibuka kembali.
- Logout menghapus session dan kembali ke halaman login.
- Listener `onAuthStateChange` mengarahkan pengguna ke login bila session berakhir.

### Authorization
- Tabel `profiles` menyimpan role `seeker`, `owner`, atau `admin`.
- Role dibuat otomatis oleh trigger `handle_new_user`, tidak dapat diubah dari aplikasi.
- `RoleGuard` menyembunyikan menu yang tidak sesuai role.
- **RLS** pada tabel `kos` membatasi SELECT, INSERT, UPDATE, DELETE.
- Pemilik kos tidak dapat mengubah atau menghapus kos milik pengguna lain, walaupun memanggil API langsung.
- Admin memiliki policy tambahan untuk mengelola seluruh data.

### Push Notification (FCM)
- Permintaan izin notifikasi (`POST_NOTIFICATIONS` pada Android 13+).
- Pengambilan FCM token dan penyimpanan token ke tabel `device_tokens`.
- Listener notifikasi untuk kondisi **foreground**, **background**, dan **terminated**.
- Notifikasi dengan `data.kos_id` membuka halaman detail kos terkait (bonus).

---

## 2. Struktur Project

```text
lib/
├── main.dart                     # init Firebase + Supabase, check session
├── app_keys.dart                 # navigatorKey & messengerKey
├── config/
│   └── supabase_config.dart      # URL + publishable key
├── core/
│   └── messages.dart             # pesan error yang ramah pengguna
├── models/
│   └── kos.dart
├── pages/
│   ├── login_page.dart
│   ├── register_page.dart
│   ├── home_page.dart
│   ├── my_kos_page.dart
│   ├── admin_page.dart
│   ├── kos_detail_page.dart
│   ├── kos_form_page.dart
│   └── setup_page.dart
├── services/
│   ├── auth_service.dart
│   ├── profile_service.dart
│   ├── kos_service.dart
│   └── notification_service.dart
├── theme/
│   └── app_theme.dart
└── widgets/
    ├── auth_scaffold.dart
    ├── kos_card.dart
    └── role_guard.dart
```

---

## 3. Setup Backend Supabase

1. Buat project di [Supabase Dashboard](https://supabase.com/dashboard).
2. Buka **SQL Editor**, jalankan seluruh isi [`tugas9_supabase.sql`](tugas9_supabase.sql).
   File ini membuat tabel `profiles`, `kos`, `device_tokens`, trigger profile otomatis, dan policy RLS.
3. Buka **Project Settings → API Keys**, salin:
   - `Project URL` → `SupabaseConfig.url`
   - `publishable` / `anon` key → `SupabaseConfig.publishableKey`
4. (Opsional, untuk latihan) **Authentication → Providers → Email**: nonaktifkan **Confirm email** agar akun baru langsung mendapat session.
5. Jalankan aplikasi. Bila kredensial belum diisi, aplikasi menampilkan halaman panduan setup, bukan crash.

> **Keamanan:** jangan pernah memakai `service_role` / secret key di aplikasi Flutter. Key tersebut melewati RLS.

### Membuat akun admin

Daftarkan akun dari aplikasi, lalu jalankan di SQL Editor:

```sql
update public.profiles
set role = 'admin'
where email = 'admin@contoh.com';
```

---

## 4. Setup Firebase Cloud Messaging

1. Install tools (sekali saja):

   ```bash
   npm install -g firebase-tools
   firebase login
   dart pub global activate flutterfire_cli
   ```

2. Dari root project:

   ```bash
   flutterfire configure
   ```

   Perintah ini membuat `lib/firebase_options.dart`, menambahkan `google-services.json` (Android), dan plugin Gradle yang dibutuhkan.

3. Kode di project ini sudah siap:
   - `Firebase.initializeApp()` dipanggil di `main.dart` (dibungkus `try/catch`, jadi aplikasi tetap berjalan bila Firebase belum dikonfigurasi).
   - `firebaseMessagingBackgroundHandler` didaftarkan dengan `FirebaseMessaging.onBackgroundMessage`.
   - Izin `android.permission.POST_NOTIFICATIONS` sudah ada di `AndroidManifest.xml`.

4. Jalankan di **perangkat Android fisik atau emulator dengan Google Play Services**:

   ```bash
   flutter run
   ```

5. Ambil token:
   - Lihat log `FCM Token: ...`, atau
   - Buka kartu **Notifikasi** di Home → tombol **Ambil token** (token juga bisa disalin dari aplikasi).
6. Firebase Console → **Cloud Messaging** → **Create notification** → **Send test message** → tempel token → **Test**.

7. Uji tiga kondisi:
   - **Foreground:** aplikasi terbuka, notifikasi tampil sebagai snackbar di dalam aplikasi.
   - **Background:** tekan Home, kirim notifikasi, notifikasi muncul di status bar.
   - **Terminated:** tutup aplikasi dari recent apps, kirim notifikasi, notifikasi tetap diterima.

> Token FCM bersifat rahasia dan berubah setelah aplikasi di-install ulang atau data dihapus. Jangan menulis token di source code atau commit ke repository.

---

## 5. Pengujian Keamanan (Dua Akun)

Siapkan dua akun **owner**: User A dan User B.

| No | Percobaan | Expected | Cara |
| --- | --- | --- | --- |
| 1 | User A melihat daftar kos | Allowed | Login User A → daftar tampil |
| 2 | User A menambah kos | Allowed | Tombol Tambah Kos |
| 3 | User A mengubah kos miliknya | Allowed | Menu Ubah pada kartu |
| 4 | User B mengubah kos User A | Denied | Login User B, buka detail kos A, tombol ubah tidak muncul; panggil `update()` lewat security test |
| 5 | User B menghapus kos User A | Denied | `delete()` mengembalikan daftar kosong → pesan "ditolak RLS" |
| 6 | Seeker menambah kos | Denied | Policy INSERT menolak role seeker (error 42501) |
| 7 | Owner memverifikasi kosnya sendiri | Denied | Trigger mengembalikan `is_verified` ke nilai lama |

Pengujian dari SQL Editor (simulasi User B):

```sql
begin;
set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"UUID_USER_B","role":"authenticated"}',
  true
);
update public.kos set name = 'HACK' where id = 'UUID_KOS_USER_A'; -- UPDATE 0
delete from public.kos where id = 'UUID_KOS_USER_A';              -- DELETE 0
rollback;
```

---

## 6. Perintah Git

History dibuat bertahap agar proses pengerjaan terlihat:

```bash
git checkout -b feature/auth-notification

# 1. Autentikasi
git add . && git commit -m "feat: implement user authentication"

# 2. Session dan logout
git add . && git commit -m "feat: implement authentication session and logout"

# 3. Role pengguna
git add . && git commit -m "feat: implement user roles"

# 4. Authorization pada UI
git add . && git commit -m "feat: implement role based interface authorization"

# 5. Row Level Security
git add . && git commit -m "security: implement row level security policies"

# 6. Konfigurasi Firebase
git add . && git commit -m "chore: configure firebase cloud messaging"

# 7. Push notification
git add . && git commit -m "feat: implement push notification with FCM"

git push -u origin feature/auth-notification
```

---

## 7. Catatan Implementasi

- **Session** disimpan oleh `supabase_flutter` di perangkat dan dipulihkan saat `Supabase.initialize()`.
- **Role** diambil dari tabel `profiles`, bukan dari `userMetadata`, sehingga tidak bisa dipalsukan dari client.
- **RLS** adalah pengaman utama. Menyembunyikan tombol hanya melindungi tampilan, bukan data.
- Operasi UPDATE/DELETE yang ditolak RLS **tidak melempar error**; Supabase mengembalikan daftar kosong. Karena itu `KosService.update()` dan `delete()` memeriksa hasil `select()`.
- **Token FCM** tidak pernah ditulis di source code. Token disimpan di `device_tokens` dengan policy milik sendiri.
- **Admin** diverifikasi lewat fungsi `is_admin()` dengan `security definer`, lalu dipakai pada policy `kos_admin_all`.

---

## 8. Referensi

- [Supabase Auth](https://supabase.com/docs/guides/auth)
- [Supabase Flutter signInWithPassword](https://supabase.com/docs/reference/dart/auth-signinwithpassword)
- [Supabase Row Level Security](https://supabase.com/docs/guides/database/postgres/row-level-security)
- [Firebase Cloud Messaging for Flutter](https://firebase.google.com/docs/cloud-messaging/flutter/client)
- [Receive messages in a Flutter app](https://firebase.google.com/docs/cloud-messaging/flutter/receive)
