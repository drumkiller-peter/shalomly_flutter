/// API path constants matching the Shalomly backend routes.
class ApiEndpoints {
  // Authentication & Tenancy
  static const String churchRegister = '/auth/register';
  static const String memberRegister = '/auth/member/register';
  static const String login = '/auth/login';
  static const String guestToken = '/auth/guest-token';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';

  // Events & Calendar
  static const String events = '/events';
  static String eventDetails(int id) => '/events/$id';
  static String eventRsvp(int id) => '/events/$id/rsvp';
  static String eventRsvps(int id) => '/events/$id/rsvps';

  // Devotional & Daily Quotes (Platform-wide catalogue)
  static const String dailyQuotes = '/daily-quotes';
  static String dailyQuoteDetails(int id) => '/daily-quotes/$id';

  // Funds & Donations
  static const String funds = '/funds';
  static const String fundBalance = '/funds/balance';
  static const String fundReconcile = '/funds/reconcile';
  static String fundDetails(int id) => '/funds/$id';
  static String fundDonors(int id) => '/funds/$id/donors';
  static const String donations = '/donations';
  static const String donationSummary = '/donations/summary';
  static String donationDetails(int id) => '/donations/$id';

  // Pastoral Care & Prayer Requests
  static const String prayerChain = '/prayers/chain';
  static const String privatePrayers = '/prayers/private';
  static String prayerDetails(int id) => '/prayers/$id';
  static String prayerAnswer(int id) => '/prayers/$id/answer';
  static String prayerClose(int id) => '/prayers/$id/close';
  static String prayerReopen(int id) => '/prayers/$id/reopen';
  static String prayerIntercessions(int id) => '/prayers/$id/intercessions';
  static String privatePrayerPastor(int id) => '/prayers/private/$id/pastor';
  static String privatePastoralPrayers(int id) => '/prayers/private/$id/pastoral-prayers';

  // Worship & Hymns
  static const String hymns = '/hymns';
  static String hymnDetails(int id) => '/hymns/$id';
  static const String hymnBookmarks = '/hymns/bookmarks';

  // Fellowships & Groups
  static const String groups = '/groups';
  static String groupDetails(int id) => '/groups/$id';
  static String groupJoin(int id) => '/groups/$id/join';
  static String groupLeave(int id) => '/groups/$id/leave';
  static String groupMembers(int id) => '/groups/$id/members';
  static String groupMember(int id, int userId) => '/groups/$id/members/$userId';
  static String groupLeader(int id, int userId) => '/groups/$id/leaders/$userId';
  static String groupPosts(int id) => '/groups/$id/posts';
  static String groupPost(int id, int postId) => '/groups/$id/posts/$postId';

  // Communication & Bulletins
  static const String bulletins = '/bulletins';
  static const String announcements = '/announcements';

  // Sermons
  static const String sermons = '/sermons';

  // The church's regular weekly worship, readable with a guest token
  static const String serviceTimes = '/service-times';

  // The church's colors, readable with a guest token
  static const String theme = '/theme';
}
