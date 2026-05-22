import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared/shared.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Hive init ────────────────────────────────────────────────────────────────
  await Hive.initFlutter();

  // Register type adapters
  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(UserModelAdapter());
  if (!Hive.isAdapterRegistered(10)) Hive.registerAdapter(UserRoleAdapter());
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(MessageModelAdapter());
  }
  if (!Hive.isAdapterRegistered(11)) {
    Hive.registerAdapter(MessageStatusAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(CallRequestModelAdapter());
  }
  if (!Hive.isAdapterRegistered(12)) {
    Hive.registerAdapter(CallStatusAdapter());
  }
  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(SessionLogModelAdapter());
  }
  if (!Hive.isAdapterRegistered(4)) {
    Hive.registerAdapter(RoomMetaModelAdapter());
  }

  // Open all boxes
  await Hive.openBox('prefs_box');
  await Hive.openBox<MessageModel>('messages_box');
  await Hive.openBox<CallRequestModel>('call_requests_box');
  await Hive.openBox<RoomMetaModel>('rooms_box');
  await Hive.openBox<SessionLogModel>('session_logs_box');

  runApp(const TrainerApp());
}
