import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shalomly_app/src/features/service_times/data/service_times_repository.dart';
import 'package:shalomly_app/src/features/service_times/domain/service_time.dart';

abstract class ServiceTimesEvent extends Equatable {
  const ServiceTimesEvent();

  @override
  List<Object?> get props => [];
}

class LoadServiceTimes extends ServiceTimesEvent {
  const LoadServiceTimes();
}

/// The church's Service Times; empty until they load, or if it has none.
class ServiceTimesState extends Equatable {
  final List<ServiceTime> serviceTimes;

  const ServiceTimesState({this.serviceTimes = const []});

  @override
  List<Object?> get props => [serviceTimes];
}

class ServiceTimesBloc extends Bloc<ServiceTimesEvent, ServiceTimesState> {
  final ServiceTimesRepository repository;

  ServiceTimesBloc({required this.repository})
    : super(const ServiceTimesState()) {
    on<LoadServiceTimes>(_onLoad);
  }

  Future<void> _onLoad(
    LoadServiceTimes event,
    Emitter<ServiceTimesState> emit,
  ) async {
    // The repository never throws: it falls back to the kept copy or nothing.
    emit(ServiceTimesState(serviceTimes: await repository.fetchServiceTimes()));
  }
}
