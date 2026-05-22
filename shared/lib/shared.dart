/// Shared package — exports all models, services, utils, and widgets.
library shared;

// ─── Models ───────────────────────────────────────────────────────────────────
export 'models/call_request_model.dart';
export 'models/message_model.dart';
export 'models/room_meta_model.dart';
export 'models/session_log_model.dart';
export 'models/user_model.dart';

// ─── Services ─────────────────────────────────────────────────────────────────
export 'services/auth_service.dart';
export 'services/call_service.dart';
export 'services/chat_service.dart';
export 'services/log_service.dart';

// ─── Utils ────────────────────────────────────────────────────────────────────
export 'utils/app_logger.dart';
export 'utils/app_theme.dart';
export 'utils/extensions.dart';
export 'utils/validators.dart';

// ─── Widgets ──────────────────────────────────────────────────────────────────
export 'widgets/app_avatar.dart';
export 'widgets/chat_bubble.dart';
export 'widgets/empty_state_widget.dart';
export 'widgets/session_log_tile.dart';
export 'widgets/skeleton_loader.dart';
