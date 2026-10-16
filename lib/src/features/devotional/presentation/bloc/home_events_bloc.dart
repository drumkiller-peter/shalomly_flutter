import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shalomly_app/src/features/devotional/domain/home_worship.dart';
import 'package:shalomly_app/src/features/events/data/events_repository.dart';
import 'package:shalomly_app/src/features/events/domain/event.dart';
import 'package:shalomly_app/src/features/events/domain/event_type.dart';

part 'home_events_event.dart';
part 'home_events_state.dart';

/// Home asks for Events by type itself, not through the shared `EventsBloc`,
/// whose list the calendar's filters overwrite. If the backend can't be
/// reached Home shows its plain worship card and no Notices, not an error.
class HomeEventsBloc extends Bloc<HomeEventsEvent, HomeEventsState> {
  final EventsRepository repository;

  /// How many Notices Home lists.
  static const noticeLimit = 3;

  HomeEventsBloc({required this.repository}) : super(const HomeEventsState()) {
    on<HomeEventsLoadRequested>(_onLoadRequested);
  }

  Future<void> _onLoadRequested(
    HomeEventsLoadRequested event,
    Emitter<HomeEventsState> emit,
  ) async {
    final now = event.now;
    final todayStart = DateTime(now.year, now.month, now.day);
    // What Home showed before stays on screen while it reloads.
    emit(state.copyWith(status: HomeEventsStatus.loading));
    final worshipRequest = _orNone(
      repository.getEvents(
        types: [EventType.worship],
        startsAfter: todayStart,
        pageSize: 10,
      ),
    );
    final noticesRequest = _orNone(
      repository.getEvents(
        types: [EventType.notice],
        startsAfter: todayStart,
        startsBefore: DateTime(now.year, now.month, now.day + 7),
        pageSize: noticeLimit,
      ),
    );
    final worship = await worshipRequest;
    final notices = await noticesRequest;
    // Built with the constructor, not copyWith, so "no worship Event" clears
    // the card instead of keeping the old one.
    emit(
      HomeEventsState(
        status: HomeEventsStatus.loaded,
        nextWorship: pickNextWorship(worship, now),
        notices: notices,
      ),
    );
  }

  Future<List<ChurchEvent>> _orNone(Future<List<ChurchEvent>> request) async {
    try {
      return await request;
    } catch (_) {
      return const [];
    }
  }
}
