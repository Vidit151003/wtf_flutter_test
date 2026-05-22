import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';

import 'providers/auth_provider.dart';
import 'providers/call_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/schedule_provider.dart';
import 'providers/session_provider.dart';
import 'screens/call/in_call_screen.dart';
import 'screens/call/pre_join_screen.dart';
import 'screens/chat/chat_list_screen.dart';
import 'screens/chat/conversation_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/onboarding/profile_setup_screen.dart';
import 'screens/schedule/schedule_screen.dart';
import 'screens/sessions/sessions_screen.dart';
import 'widgets/dev_panel_overlay.dart';

class GuruApp extends StatefulWidget {
  const GuruApp({super.key});

  @override
  State<GuruApp> createState() => _GuruAppState();
}

class _GuruAppState extends State<GuruApp> {
  late final MockAuthService _authService;
  late final MockChatService _chatService;
  late final MockCallService _callService;
  late final MockLogService _logService;

  late final AuthProvider _authProvider;
  late final ChatProvider _chatProvider;
  late final ScheduleProvider _scheduleProvider;
  late final SessionProvider _sessionProvider;
  late final CallProvider _callProvider;

  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authService = MockAuthService();
    _chatService = MockChatService();
    _callService = MockCallService();
    _logService = MockLogService();

    _authProvider = AuthProvider(_authService);
    _chatProvider = ChatProvider(_chatService, _authService);
    _scheduleProvider = ScheduleProvider(_callService, _authService);
    _sessionProvider = SessionProvider(_logService, _authService);
    _callProvider = CallProvider(_logService, _authService);

    _router = GoRouter(
      initialLocation: '/',
      redirect: (context, state) {
        final isOnboarded = _authProvider.isOnboarded;
        final loc = state.uri.toString();
        if (!isOnboarded &&
            loc != '/onboarding' &&
            loc != '/profile-setup') {
          return '/onboarding';
        }
        if (isOnboarded && loc == '/') {
          return '/home';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const SizedBox.shrink(),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/profile-setup',
          builder: (context, state) => const ProfileSetupScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/chat',
          builder: (context, state) => const ChatListScreen(),
        ),
        GoRoute(
          path: '/chat/:chatId',
          builder: (context, state) {
            final chatId = state.pathParameters['chatId'] ?? '';
            return ConversationScreen(chatId: chatId);
          },
        ),
        GoRoute(
          path: '/schedule',
          builder: (context, state) => const ScheduleScreen(),
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
  }

  @override
  void dispose() {
    _authService.dispose();
    _chatService.dispose();
    _callService.dispose();
    _logService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: _authProvider),
        ChangeNotifierProvider<ChatProvider>.value(value: _chatProvider),
        ChangeNotifierProvider<ScheduleProvider>.value(
            value: _scheduleProvider),
        ChangeNotifierProvider<SessionProvider>.value(value: _sessionProvider),
        ChangeNotifierProvider<CallProvider>.value(value: _callProvider),
      ],
      child: MaterialApp.router(
        title: 'Guru App',
        debugShowCheckedModeBanner: false,
        theme: getGuruTheme(),
        routerConfig: _router,
        builder: (context, child) => DevPanelOverlay(
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}
