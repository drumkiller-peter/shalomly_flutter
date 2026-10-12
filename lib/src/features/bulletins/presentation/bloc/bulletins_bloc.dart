import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shalomly_app/src/features/bulletins/data/bulletins_repository.dart';
import 'package:shalomly_app/src/features/bulletins/domain/bulletin.dart';

abstract class BulletinsEvent extends Equatable {
  const BulletinsEvent();

  @override
  List<Object?> get props => [];
}

class LoadBulletins extends BulletinsEvent {
  const LoadBulletins();
}

class RefreshBulletins extends BulletinsEvent {
  const RefreshBulletins();
}

class SelectBulletin extends BulletinsEvent {
  final Bulletin bulletin;

  const SelectBulletin(this.bulletin);

  @override
  List<Object?> get props => [bulletin];
}

abstract class BulletinsState extends Equatable {
  const BulletinsState();

  @override
  List<Object?> get props => [];
}

class BulletinsInitial extends BulletinsState {
  const BulletinsInitial();
}

class BulletinsLoading extends BulletinsState {
  const BulletinsLoading();
}

class BulletinsLoaded extends BulletinsState {
  final List<Bulletin> bulletins;
  final Bulletin? selectedBulletin;

  const BulletinsLoaded({
    required this.bulletins,
    this.selectedBulletin,
  });

  @override
  List<Object?> get props => [bulletins, selectedBulletin];
}

class BulletinsError extends BulletinsState {
  final String message;

  const BulletinsError(this.message);

  @override
  List<Object?> get props => [message];
}

class BulletinsBloc extends Bloc<BulletinsEvent, BulletinsState> {
  final BulletinsRepository repository;

  BulletinsBloc({required this.repository}) : super(const BulletinsInitial()) {
    on<LoadBulletins>(_onLoadBulletins);
    on<RefreshBulletins>(_onRefreshBulletins);
    on<SelectBulletin>(_onSelectBulletin);
  }

  Future<void> _onLoadBulletins(
    LoadBulletins event,
    Emitter<BulletinsState> emit,
  ) async {
    emit(const BulletinsLoading());
    try {
      final bulletins = await repository.fetchBulletins();
      emit(
        BulletinsLoaded(
          bulletins: bulletins,
          selectedBulletin: bulletins.isNotEmpty ? bulletins.first : null,
        ),
      );
    } catch (e) {
      emit(BulletinsError(e.toString()));
    }
  }

  Future<void> _onRefreshBulletins(
    RefreshBulletins event,
    Emitter<BulletinsState> emit,
  ) async {
    try {
      final bulletins = await repository.fetchBulletins();
      final currentSelected = state is BulletinsLoaded
          ? (state as BulletinsLoaded).selectedBulletin
          : null;

      emit(
        BulletinsLoaded(
          bulletins: bulletins,
          // Keep the one being read, unless it is no longer published.
          selectedBulletin: bulletins.contains(currentSelected)
              ? currentSelected
              : (bulletins.isNotEmpty ? bulletins.first : null),
        ),
      );
    } catch (e) {
      emit(BulletinsError(e.toString()));
    }
  }

  void _onSelectBulletin(
    SelectBulletin event,
    Emitter<BulletinsState> emit,
  ) {
    if (state is BulletinsLoaded) {
      final current = state as BulletinsLoaded;
      emit(
        BulletinsLoaded(
          bulletins: current.bulletins,
          selectedBulletin: event.bulletin,
        ),
      );
    }
  }
}
