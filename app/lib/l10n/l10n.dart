import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

export 'app_language.dart';
export 'app_localizations.dart';

extension L10nContext on BuildContext {
  /// UI strings in the language picked in settings (lib/l10n/app_*.arb).
  AppLocalizations get l10n => AppLocalizations.of(this);
}
