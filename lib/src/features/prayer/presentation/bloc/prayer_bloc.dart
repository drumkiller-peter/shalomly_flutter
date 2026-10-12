import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shalomly_app/src/features/prayer/data/prayer_repository.dart';
import 'package:shalomly_app/src/features/prayer/domain/prayer_request.dart';

// Events
abstract class PrayerEvent extends Equatable {
  const PrayerEvent();
  @override
  List<Object?> get props => [];
}

class PrayerChainFetchRequested extends PrayerEvent {
  const PrayerChainFetchRequested();
}

class PrayerIntercessionToggled extends PrayerEvent {
  final int prayerId;
  final bool intercede;
  const PrayerIntercessionToggled({required this.prayerId, required this.intercede});
  @override
  List<Object?> get props => [prayerId, intercede];
}

class PrayerCreateSubmitted extends PrayerEvent {
  final String title;
  final String content;
  final bool isPrivate;
  final bool isAnonymous;
  final int? assignedPastorId;

  const PrayerCreateSubmitted({
    required this.title,
    required this.content,
    required this.isPrivate,
    required this.isAnonymous,
    this.assignedPastorId,
  });

  @override
  List<Object?> get props => [title, content, isPrivate, isAnonymous, assignedPastorId];
}

// States
abstract class PrayerState extends Equatable {
  const PrayerState();
  @override
  List<Object?> get props => [];
}

class PrayerInitial extends PrayerState {
  const PrayerInitial();
}

class PrayerLoading extends PrayerState {
  const PrayerLoading();
}

class PrayerLoaded extends PrayerState {
  final List<PrayerRequest> publicPrayers;
  final List<PrayerRequest> privatePrayers;

  const PrayerLoaded({
    required this.publicPrayers,
    this.privatePrayers = const [],
  });

  @override
  List<Object?> get props => [publicPrayers, privatePrayers];
}

class PrayerError extends PrayerState {
  final String message;
  const PrayerError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class PrayerBloc extends Bloc<PrayerEvent, PrayerState> {
  final PrayerRepository repository;

  PrayerBloc({required this.repository}) : super(const PrayerInitial()) {
    on<PrayerChainFetchRequested>(_onFetchRequested);
    on<PrayerIntercessionToggled>(_onIntercessionToggled);
    on<PrayerCreateSubmitted>(_onCreateSubmitted);
  }

  Future<void> _onFetchRequested(
    PrayerChainFetchRequested event,
    Emitter<PrayerState> emit,
  ) async {
    emit(const PrayerLoading());
    try {
      final publicList = await repository.getPrayerChain();
      final privateList = await repository.getMyPrivatePrayers();
      emit(PrayerLoaded(publicPrayers: publicList, privatePrayers: privateList));
    } catch (e) {
      emit(PrayerError(e.toString()));
    }
  }

  Future<void> _onIntercessionToggled(
    PrayerIntercessionToggled event,
    Emitter<PrayerState> emit,
  ) async {
    if (state is PrayerLoaded) {
      final currentState = state as PrayerLoaded;
      final updatedPublic = currentState.publicPrayers.map((p) {
        if (p.id == event.prayerId) {
          final count = event.intercede ? p.intercessionCount + 1 : p.intercessionCount - 1;
          return p.copyWith(
            hasInterceded: event.intercede,
            intercessionCount: count < 0 ? 0 : count,
          );
        }
        return p;
      }).toList();

      emit(PrayerLoaded(
        publicPrayers: updatedPublic,
        privatePrayers: currentState.privatePrayers,
      ));

      try {
        await repository.toggleIntercession(event.prayerId, event.intercede);
      } catch (_) {
        // Revert to previous state so button returns to correct state on failure
        emit(PrayerLoaded(
          publicPrayers: currentState.publicPrayers,
          privatePrayers: currentState.privatePrayers,
        ));
      }
    }
  }

  Future<void> _onCreateSubmitted(
    PrayerCreateSubmitted event,
    Emitter<PrayerState> emit,
  ) async {
    try {
      await repository.createPrayerRequest(
        title: event.title,
        content: event.content,
        isPrivate: event.isPrivate,
        isAnonymous: event.isAnonymous,
        assignedPastorId: event.assignedPastorId,
      );
      add(const PrayerChainFetchRequested());
    } catch (e) {
      emit(PrayerError(e.toString()));
    }
  }
}
