import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shalomly_app/src/features/devotional/data/devotional_repository.dart';
import 'package:shalomly_app/src/features/devotional/domain/daily_quote.dart';

part 'devotional_event.dart';
part 'devotional_state.dart';

class DevotionalBloc extends Bloc<DevotionalEvent, DevotionalState> {
  final DevotionalRepository repository;

  DevotionalBloc({required this.repository}) : super(const DevotionalState()) {
    on<DevotionalFetchRequested>(_onFetchRequested);
  }

  Future<void> _onFetchRequested(
    DevotionalFetchRequested event,
    Emitter<DevotionalState> emit,
  ) async {
    emit(state.copyWith(status: DevotionalStatus.loading));
    try {
      final quotes = await repository.getDailyQuotes(
        forceRefresh: event.forceRefresh,
      );
      emit(state.copyWith(status: DevotionalStatus.loaded, quotes: quotes));
    } catch (e) {
      emit(state.copyWith(status: DevotionalStatus.error));
    }
  }
}
