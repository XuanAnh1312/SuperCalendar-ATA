import 'package:flutter_application/core/utils/strings_vi.dart';

/// UI language (AC-41, NFR-09). English text is the key; [tr] looks it up in
/// the Vietnamese table and falls back to English when a line is missing.
abstract final class AppStrings {
  /// Value of `AppSettings.language` that turns Vietnamese on.
  static const vietnamese = 'Tiếng Việt';

  static bool vi = false;
}

/// [en] in the current UI language.
String tr(String en) => AppStrings.vi ? (viStrings[en] ?? en) : en;

/// [tr] with `{name}` placeholders filled from [args], e.g.
/// `trf('{n} events', {'n': '3'})`.
String trf(String en, Map<String, Object> args) {
  var text = tr(en);
  args.forEach((key, value) => text = text.replaceAll('{$key}', '$value'));
  return text;
}
