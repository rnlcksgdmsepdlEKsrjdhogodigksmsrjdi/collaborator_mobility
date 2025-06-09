import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'check_dialog.dart';

class FCMHandler {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initializeFCM(BuildContext context) async {
    await _messaging.requestPermission();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleMessage(context, message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessage(context, message);
    });

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleMessage(context, initialMessage);
      });
    }
  }

  void _handleMessage(BuildContext context, RemoteMessage message) {
    if (message.data['showdialog'] == 'true') {
      final location = message.data['location'] ?? 'defaultLocation';
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => CarConfirmDialog(location: location),
      );
    }
  }
}
