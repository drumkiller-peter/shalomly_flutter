import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shalomly_app/src/features/events/data/events_repository.dart';
import 'package:shalomly_app/src/features/events/domain/event.dart';
import 'package:shalomly_app/src/features/events/domain/event_draft.dart';

part 'event_detail_event.dart';
part 'event_detail_state.dart';

/// One Event, opened by id, so it works from the calendar, Home, or a Group
/// Post. RSVPs, edits and cancelling are followed by reading the Event again,
/// so the screen always shows what the server holds.
class EventDetailBloc extends Bloc<EventDetailEvent, EventDetailState> {
  final EventsRepository repository;
  int? _eventId;

  EventDetailBloc({required this.repository}) : super(const EventDetailState()) {
    on<EventDetailLoadRequested>(_onLoadRequested);
    on<EventDetailRsvpSubmitted>(
      (event, emit) => _act(
        emit,
        (id) => repository.setRsvp(eventId: id, status: event.status.value),
      ),
    );
    on<EventDetailRsvpWithdrawn>(
      (event, emit) => _act(emit, (id) => repository.withdrawRsvp(id)),
    );
    on<EventDetailCancelledChanged>(
      (event, emit) =>
          _act(emit, (id) => repository.setCancelled(id, event.cancelled)),
    );
    on<EventDetailUpdated>(
      (event, emit) =>
          _act(emit, (id) => repository.updateEvent(id, event.draft)),
    );
    on<EventDetailDeleteRequested>(_onDeleteRequested);
  }

  Future<void> _onLoadRequested(
    EventDetailLoadRequested event,
    Emitter<EventDetailState> emit,
  ) async {
    _eventId = event.eventId;
    if (state.status != EventDetailStatus.loaded) {
      emit(state.copyWith(status: EventDetailStatus.loading));
    }
    await _read(emit);
  }

  Future<void> _onDeleteRequested(
    EventDetailDeleteRequested event,
    Emitter<EventDetailState> emit,
  ) async {
    final id = _eventId;
    if (id == null) return;
    try {
      await repository.deleteEvent(id);
      emit(state.copyWith(status: EventDetailStatus.deleted));
    } catch (_) {
      emit(state.copyWith(actionFailures: state.actionFailures + 1));
    }
  }

  /// Runs one change, then reads the Event again. A change that fails leaves
  /// the Event on screen and counts a failure, so the screen reports every
  /// failure and not only the first.
  Future<void> _act(
    Emitter<EventDetailState> emit,
    Future<void> Function(int id) action,
  ) async {
    final id = _eventId;
    if (id == null) return;
    try {
      await action(id);
    } catch (_) {
      emit(state.copyWith(actionFailures: state.actionFailures + 1));
      return;
    }
    await _read(emit);
  }

  Future<void> _read(Emitter<EventDetailState> emit) async {
    final id = _eventId;
    if (id == null) return;
    try {
      final event = await repository.getEvent(id);
      emit(
        EventDetailState(
          status: EventDetailStatus.loaded,
          event: event,
          actionFailures: state.actionFailures,
        ),
      );
    } on DioException catch (e) {
      emit(
        EventDetailState(
          status: e.response?.statusCode == 404
              ? EventDetailStatus.notFound
              : EventDetailStatus.error,
          errorMessage: e.message ?? e.toString(),
          actionFailures: state.actionFailures,
        ),
      );
    } catch (e) {
      emit(
        EventDetailState(
          status: EventDetailStatus.error,
          errorMessage: e.toString(),
          actionFailures: state.actionFailures,
        ),
      );
    }
  }
}
