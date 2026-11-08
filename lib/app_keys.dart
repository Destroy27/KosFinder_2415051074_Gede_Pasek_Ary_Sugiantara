import 'package:flutter/material.dart';

/// Key global agar navigasi dan snackbar bisa dipanggil dari luar widget,
/// misalnya dari listener autentikasi dan dari handler notifikasi.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> messengerKey =
    GlobalKey<ScaffoldMessengerState>();
