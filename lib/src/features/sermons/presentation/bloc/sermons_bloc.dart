import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shalomly_app/src/features/sermons/data/sermons_repository.dart';
import 'package:shalomly_app/src/features/sermons/domain/sermon.dart';

abstract class SermonsEvent extends Equatable {
  const SermonsEvent();

  @override
  List<Object?> get props => [];
}

class LoadSermons extends SermonsEvent {
  const LoadSermons();
}

class RefreshSermons extends SermonsEvent {
  const RefreshSermons();
}

class FilterSermonsByPreacher extends SermonsEvent {
  final String? preacher;

  const FilterSermonsByPreacher(this.preacher);

  @override
  List<Object?> get props => [preacher];
}

class SearchSermons extends SermonsEvent {
  final String query;

  const SearchSermons(this.query);

  @override
  List<Object?> get props => [query];
}

class SelectSermon extends SermonsEvent {
  final Sermon sermon;

  const SelectSermon(this.sermon);

  @override
  List<Object?> get props => [sermon];
}

abstract class SermonsState extends Equatable {
  const SermonsState();

  @override
  List<Object?> get props => [];
}

class SermonsInitial extends SermonsState {
  const SermonsInitial();
}

class SermonsLoading extends SermonsState {
  const SermonsLoading();
}

class SermonsLoaded extends SermonsState {
  final List<Sermon> allSermons;
  final List<Sermon> filteredSermons;
  final List<String> preachers;
  final String? selectedPreacher;
  final String searchQuery;
  final Sermon? selectedSermon;

  const SermonsLoaded({
    required this.allSermons,
    required this.filteredSermons,
    required this.preachers,
    this.selectedPreacher,
    this.searchQuery = '',
    this.selectedSermon,
  });

  @override
  List<Object?> get props => [
        allSermons,
        filteredSermons,
        preachers,
        selectedPreacher,
        searchQuery,
        selectedSermon,
      ];
}

class SermonError extends SermonsState {
  final String message;

  const SermonError(this.message);

  @override
  List<Object?> get props => [message];
}

class SermonsBloc extends Bloc<SermonsEvent, SermonsState> {
  final SermonsRepository repository;

  SermonsBloc({required this.repository}) : super(const SermonsInitial()) {
    on<LoadSermons>(_onLoadSermons);
    on<RefreshSermons>(_onRefreshSermons);
    on<FilterSermonsByPreacher>(_onFilterByPreacher);
    on<SearchSermons>(_onSearchSermons);
    on<SelectSermon>(_onSelectSermon);
  }

  Future<void> _onLoadSermons(
    LoadSermons event,
    Emitter<SermonsState> emit,
  ) async {
    emit(const SermonsLoading());
    try {
      final sermons = await repository.fetchSermons();
      final preachers = sermons.map((s) => s.preacher).toSet().toList();
      emit(
        SermonsLoaded(
          allSermons: sermons,
          filteredSermons: sermons,
          preachers: preachers,
        ),
      );
    } catch (e) {
      emit(SermonError(e.toString()));
    }
  }

  Future<void> _onRefreshSermons(
    RefreshSermons event,
    Emitter<SermonsState> emit,
  ) async {
    try {
      final sermons = await repository.fetchSermons();
      final preachers = sermons.map((s) => s.preacher).toSet().toList();
      final currentPreacher = state is SermonsLoaded
          ? (state as SermonsLoaded).selectedPreacher
          : null;
      final currentQuery = state is SermonsLoaded
          ? (state as SermonsLoaded).searchQuery
          : '';

      final filtered = _filterSermons(sermons, currentPreacher, currentQuery);

      emit(
        SermonsLoaded(
          allSermons: sermons,
          filteredSermons: filtered,
          preachers: preachers,
          selectedPreacher: currentPreacher,
          searchQuery: currentQuery,
        ),
      );
    } catch (e) {
      emit(SermonError(e.toString()));
    }
  }

  void _onFilterByPreacher(
    FilterSermonsByPreacher event,
    Emitter<SermonsState> emit,
  ) {
    if (state is SermonsLoaded) {
      final current = state as SermonsLoaded;
      final filtered = _filterSermons(
        current.allSermons,
        event.preacher,
        current.searchQuery,
      );
      emit(
        SermonsLoaded(
          allSermons: current.allSermons,
          filteredSermons: filtered,
          preachers: current.preachers,
          selectedPreacher: event.preacher,
          searchQuery: current.searchQuery,
          selectedSermon: current.selectedSermon,
        ),
      );
    }
  }

  void _onSearchSermons(
    SearchSermons event,
    Emitter<SermonsState> emit,
  ) {
    if (state is SermonsLoaded) {
      final current = state as SermonsLoaded;
      final filtered = _filterSermons(
        current.allSermons,
        current.selectedPreacher,
        event.query,
      );
      emit(
        SermonsLoaded(
          allSermons: current.allSermons,
          filteredSermons: filtered,
          preachers: current.preachers,
          selectedPreacher: current.selectedPreacher,
          searchQuery: event.query,
          selectedSermon: current.selectedSermon,
        ),
      );
    }
  }

  void _onSelectSermon(
    SelectSermon event,
    Emitter<SermonsState> emit,
  ) {
    if (state is SermonsLoaded) {
      final current = state as SermonsLoaded;
      emit(
        SermonsLoaded(
          allSermons: current.allSermons,
          filteredSermons: current.filteredSermons,
          preachers: current.preachers,
          selectedPreacher: current.selectedPreacher,
          searchQuery: current.searchQuery,
          selectedSermon: event.sermon,
        ),
      );
    }
  }

  List<Sermon> _filterSermons(
    List<Sermon> sermons,
    String? preacher,
    String query,
  ) {
    return sermons.where((sermon) {
      final matchesPreacher =
          preacher == null || preacher.isEmpty || sermon.preacher == preacher;
      final matchesQuery = query.isEmpty ||
          sermon.title.toLowerCase().contains(query.toLowerCase()) ||
          (sermon.description?.toLowerCase().contains(query.toLowerCase()) ??
              false);
      return matchesPreacher && matchesQuery;
    }).toList();
  }
}
