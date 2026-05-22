import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';

import 'providers/auth_provider.dart';
import 'providers/call_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/members_provider.dart';
import 'providers/requests_provider.dart';
import 'providers/session_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/call/in_call_screen.dart';
import 'screens/call/pre_join_screen.dart';
import 'screens/chat/conversation_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/members/member_detail_screen.dart';
import 'screens/members/members_screen.dart';
import 'screens/requests/requests_screen.dart';
import 'screens/sessions/sessions_screen.dart';
import 'widgets/dev_panel_overlay.dart';

// ─── Services (singleton instances) ──────────────────────────────────────────
final _authService = MockAuthService();
final _chatService = MockChatService();
final _callService = MockCallService();
final _logService = MockLogService();

// ─── GoRouter ────────────────────────────────────────────────────────────────
final _router = GoRouter(
  initialLocation: '/',
  redirect: (BuildContext context, GoRouterState state) {
    final authProvider = context.read<TrainerAuthProvider>();
    final isLoggedIn = authProvider.isLoggedIn;
    final onLogin = state.matchedLocation == '/login';

    if (!isLoggedIn && !onLogin) return '/login';
    if (isLoggedIn && onLogin) return '/home';
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      redirect: (context, state) {
        final authProvider = context.read<TrainerAuthProvider>();
        return authProvider.isLoggedIn ? '/home' : '/login';
      },
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/members',
      builder: (context, state) => const MembersScreen(),
    ),
    GoRoute(
      path: '/members/:memberId',
      builder: (context, state) {
        final memberId = state.pathParameters['memberId']!;
        return MemberDetailScreen(memberId: memberId);
      },
    ),
    GoRoute(
      path: '/requests',
      builder: (context, state) => const RequestsScreen(),
    ),
    GoRoute(
      path: '/chat/:chatId',
      builder: (context, state) {
        final chatId = state.pathParameters['chatId']!;
        return ConversationScreen(chatId: chatId);
      },
    ),
    GoRoute(
      path: '/sessions',
      builder: (context, state) => const SessionsScreen(),
    ),
    GoRoute(
      path: '/call/pre-join',
      builder: (context, state) => const PreJoinScreen(),
    ),
    GoRoute(
      path: '/call/in-call',
      builder: (context, state) => const InCallScreen(),
    ),
  ],
);

// ─── Root App ─────────────────────────────────────────────────────────────────
class TrainerApp extends StatelessWidget {
  const TrainerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => TrainerAuthProvider(_authService),
        ),
        Provider<ChatService>.value(value: _chatService),
        Provider<CallService>.value(value: _callService),
        Provider<LogService>.value(value: _logService),
        ChangeNotifierProvider(
          create: (_) => MembersProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => RequestsProvider(
            callService: _callService,
            chatService: _chatService,
            trainerId: 'trainer_001',
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => TrainerSessionProvider(_logService),
        ),
        ChangeNotifierProvider(
          create: (_) => TrainerCallProvider(_logService),
        ),
      ],
      child: Builder(
        builder: (context) {
          return MaterialApp.router(
            title: 'WTF Trainer Portal',
            theme: getTrainerTheme(),
            routerConfig: _router,
            debugShowCheckedModeBanner: false,
            builder: (context, child) {
              return DevPanelOverlay(child: child ?? const SizedBox.shrink());
            },
          );
        },
      ),
    );
  }
}
