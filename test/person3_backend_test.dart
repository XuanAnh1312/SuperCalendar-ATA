import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application/core/data/document_store.dart';
import 'package:flutter_application/core/services/app_state.dart';
import 'package:flutter_application/features/settings_screen/data/user_repository.dart';
import 'package:flutter_application/features/settings_screen/domain/user.dart';
import 'package:flutter_application/features/vip/domain/purchase.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('canAccess follows VIP status (BR-06)', () async {
    final app = AppState(store: MemoryDocumentStore());
    await app.load();
    expect(app.canAccess(VipFeature.themeBuilder), isFalse);
    app.completeVipPayment(PaymentResult.failed);
    expect(app.canAccess(VipFeature.themeBuilder), isFalse);
    app.completeVipPayment(PaymentResult.success);
    expect(app.canAccess(VipFeature.themeBuilder), isTrue);
    expect(app.templates.hasPurchased(app.user.id, Purchase.vipProductId), isTrue);
  });

  test('theme mode and settings persist across reload', () async {
    final store = MemoryDocumentStore();
    final app = AppState(store: store);
    await app.load();
    app.setDarkMode(true);
    app.setWeekStart(WeekStartSetting.sunday);
    app.account.updateProfile(email: 'a@b.c');
    await app.flush();

    final reloaded = UserRepository(store);
    await reloaded.load();
    expect(reloaded.settings.themeMode, ThemeModeSetting.dark);
    expect(reloaded.settings.darkMode, isTrue);
    expect(reloaded.settings.weekStart, WeekStartSetting.sunday);
    expect(reloaded.user.email, 'a@b.c');
  });

  test('seed has 3 free + 2 premium system templates', () async {
    final app = AppState(store: MemoryDocumentStore());
    await app.load();
    final seeded = app.templates.templates.where((t) => t.isSystem);
    expect(seeded.where((t) => !t.isPremium).length, 3);
    expect(seeded.where((t) => t.isPremium).length, 2);
  });
}
