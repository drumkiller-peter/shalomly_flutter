import 'package:flutter_test/flutter_test.dart';
import 'package:shalomly_app/src/core/routing/app_routes.dart';

void main() {
  group('AppRoutes', () {
    test('defines correct path constants for shell tabs', () {
      expect(AppRoutes.devotional, '/devotional');
      expect(AppRoutes.home, AppRoutes.devotional);
      expect(AppRoutes.hymns, '/hymns');
      expect(AppRoutes.events, '/events');
      expect(AppRoutes.prayer, '/prayer');
      expect(AppRoutes.giving, '/giving');
    });

    test('defines correct path constants for standalone screens', () {
      expect(AppRoutes.bulletins, '/bulletins');
      expect(AppRoutes.sermons, '/sermons');
      expect(AppRoutes.groups, '/groups');
      expect(AppRoutes.groupDetailsPattern, '/groups/:id');
      expect(AppRoutes.login, '/auth/login');
      expect(AppRoutes.register, '/auth/register');
      expect(AppRoutes.admin, '/admin');
      expect(AppRoutes.workspace, '/workspace');
      expect(AppRoutes.watchGlance, '/watch/glance');
    });

    test('formats parameterized group routes', () {
      expect(AppRoutes.groupDetail(42), '/groups/42');
      expect(AppRoutes.groupDetails(42), '/groups/42');
      expect(AppRoutes.groupDetail('youth'), '/groups/youth');
    });
  });
}
