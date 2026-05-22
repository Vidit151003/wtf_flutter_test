/// Form and business-logic validators for the WTF apps.
class Validators {
  Validators._();

  /// Returns an error string if [dt] is not in the future; otherwise null.
  static String? validateScheduleTime(DateTime dt) {
    if (!dt.isAfter(DateTime.now())) {
      return 'Please choose a future time slot.';
    }
    return null;
  }

  /// Returns an error string if [note] exceeds 140 characters; otherwise null.
  static String? validateNote(String note) {
    if (note.length > 140) {
      return 'Note must be 140 characters or fewer.';
    }
    return null;
  }

  /// Returns an error string if [name] is blank or fewer than 2 characters;
  /// otherwise null.
  static String? validateName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return 'Name cannot be empty.';
    }
    if (trimmed.length < 2) {
      return 'Name must be at least 2 characters.';
    }
    return null;
  }

  /// Returns an error string if [email] is not a valid e-mail address;
  /// otherwise null.
  static String? validateEmail(String email) {
    final trimmed = email.trim();
    if (trimmed.isEmpty) {
      return 'Email cannot be empty.';
    }
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(trimmed)) {
      return 'Please enter a valid email address.';
    }
    return null;
  }
}
