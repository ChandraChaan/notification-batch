import '../../../l10n/app_localizations.dart';
import '../domain/app_suggester.dart';

extension AppKindLabel on AppKind {
  String? label(AppLocalizations l10n) => switch (this) {
    AppKind.shopping => l10n.kindShopping,
    AppKind.food => l10n.kindFood,
    AppKind.games => l10n.kindGames,
    AppKind.social => l10n.kindSocial,
    AppKind.messaging => l10n.kindMessaging,
    AppKind.important => l10n.kindImportant,
    AppKind.other => null,
  };
}
