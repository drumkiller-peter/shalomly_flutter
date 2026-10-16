/// Route path constants used throughout the application with GoRouter.
abstract final class AppRoutes {
  // Shell navigation destinations
  static const String devotional = '/devotional';
  static const String home = devotional;
  static const String hymns = '/hymns';
  static const String events = '/events';
  static const String eventDetailPattern = '/events/:id';
  static String eventDetail(Object id) => '/events/$id';
  static const String prayer = '/prayer';
  static const String giving = '/giving';

  // Content & Features
  static const String sermons = '/sermons';
  static const String groups = '/groups';
  static const String groupDetailsPattern = '/groups/:id';
  static String groupDetails(Object id) => '/groups/$id';
  static String groupDetail(Object id) => groupDetails(id);

  // Authentication
  static const String login = '/auth/login';
  static const String register = '/auth/register';

  // Administration & Workspace
  static const String admin = '/admin';
  static const String workspace = '/workspace';

  // Wear / Watch
  static const String watchGlance = '/watch/glance';
}
