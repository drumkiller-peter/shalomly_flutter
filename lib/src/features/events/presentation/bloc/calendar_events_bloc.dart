import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shalomly_app/src/features/events/data/events_repository.dart';
import 'package:shalomly_app/src/features/events/domain/event.dart';
import 'package:shalomly_app/src/features/events/domain/event_days.dart';

part 'calendar_events_event.dart';
part 'calendar_events_state.dart';

/// The Events around the month the calendar shows, for its markers and for the
/// list of a tapped day. It is separate from `EventsBloc`, whose list the
/// filters on the same screen overwrite.
class CalendarEventsBloc extends Bloc<CalendarEventsEvent, CalendarEventsState> {
  final EventsRepository repository;

  /// The backend's limit for one page, which is plenty for a month.
  static const pageSize = 100;

  /// Counts requests, so an older answer that arrives late (the member
  /// swiped on to the next month) doesn't replace a newer one.
  int _latest = 0;

  CalendarEventsBloc({required this.repository})
      : super(const CalendarEventsState()) {
    on<CalendarEventsLoadRequested>(_onLoadRequested);
  }

  Future<void> _onLoadRequested(
    CalendarEventsLoadRequested event,
    Emitter<CalendarEventsState> emit,
  ) async {
    final request = ++_latest;
    final range = monthGridRange(event.focusedDay);
    // What was shown stays on screen while the next month loads.
    emit(state.copyWith(status: CalendarEventsStatus.loading));
    try {
      final events = await repository.getEvents(
        startsAfter: range.startsAfter,
        startsBefore: range.startsBefore,
        pageSize: pageSize,
      );
      if (request != _latest) return;
      emit(CalendarEventsState(status: CalendarEventsStatus.loaded, events: events));
    } catch (e) {
      if (request != _latest) return;
      emit(
        CalendarEventsState(
          status: CalendarEventsStatus.error,
          events: state.events,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
