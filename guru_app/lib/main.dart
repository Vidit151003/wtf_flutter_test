import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared/shared.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    AppLogger.write(LogTag.auth, 'Firebase initialized for Guru App');
  } catch (e) {
    AppLogger.write(LogTag.auth, 'Firebase init failed; working offline: $e');
  }

  // Initialize Hive
  await Hive.initFlutter();

  // Register all adapters (manual .g.dart)
  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(UserModelAdapter());
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(MessageModelAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(CallRequestModelAdapter());
  }
  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(SessionLogModelAdapter());
  }
  if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(RoomMetaModelAdapter());
  if (!Hive.isAdapterRegistered(10)) Hive.registerAdapter(UserRoleAdapter());
  if (!Hive.isAdapterRegistered(11)) {
    Hive.registerAdapter(MessageStatusAdapter());
  }
  if (!Hive.isAdapterRegistered(12)) Hive.registerAdapter(CallStatusAdapter());

  // Open boxes
  await Hive.openBox<dynamic>('prefs_box');
  await Hive.openBox<MessageModel>('messages_box');
  await Hive.openBox<CallRequestModel>('call_requests_box');
  await Hive.openBox<SessionLogModel>('session_logs_box');
  await Hive.openBox<RoomMetaModel>('rooms_box');
  await Hive.openBox<dynamic>('app_prefs');

  runApp(const GuruApp());
}
