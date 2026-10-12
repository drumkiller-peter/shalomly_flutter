import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shalomly_app/src/features/hymns/data/hymns_repository.dart';
import 'package:shalomly_app/src/features/hymns/domain/hymn.dart';

// Events
abstract class HymnsEvent extends Equatable {
  const HymnsEvent();
  @override
  List<Object?> get props => [];
}

class HymnsFetchRequested extends HymnsEvent {
  final bool forceRefresh;
  const HymnsFetchRequested({this.forceRefresh = false});
  @override
  List<Object?> get props => [forceRefresh];
}

class HymnBookmarkToggled extends HymnsEvent {
  final int hymnId;
  final bool isBookmarked;
  const HymnBookmarkToggled({required this.hymnId, required this.isBookmarked});
  @override
  List<Object?> get props => [hymnId, isBookmarked];
}

// States
abstract class HymnsState extends Equatable {
  const HymnsState();
  @override
  List<Object?> get props => [];
}

class HymnsInitial extends HymnsState {
  const HymnsInitial();
}

class HymnsLoading extends HymnsState {
  const HymnsLoading();
}

class HymnsLoaded extends HymnsState {
  final List<Hymn> hymns;
  const HymnsLoaded(this.hymns);
  @override
  List<Object?> get props => [hymns];
}

class HymnsError extends HymnsState {
  final String message;
  const HymnsError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class HymnsBloc extends Bloc<HymnsEvent, HymnsState> {
  final HymnsRepository repository;

  HymnsBloc({required this.repository}) : super(const HymnsInitial()) {
    on<HymnsFetchRequested>(_onFetchRequested);
    on<HymnBookmarkToggled>(_onBookmarkToggled);
  }

  Future<void> _onFetchRequested(
    HymnsFetchRequested event,
    Emitter<HymnsState> emit,
  ) async {
    emit(const HymnsLoading());
    try {
      final hymns = await repository.getHymns(forceRefresh: event.forceRefresh);
      emit(HymnsLoaded(hymns));
    } catch (e) {
      emit(HymnsError(e.toString()));
    }
  }

  Future<void> _onBookmarkToggled(
    HymnBookmarkToggled event,
    Emitter<HymnsState> emit,
  ) async {
    if (state is HymnsLoaded) {
      final currentList = (state as HymnsLoaded).hymns;
      final updatedList = currentList.map((h) {
        if (h.id == event.hymnId) {
          return h.copyWith(isBookmarked: event.isBookmarked);
        }
        return h;
      }).toList();

      emit(HymnsLoaded(updatedList));
      await repository.toggleBookmark(event.hymnId, event.isBookmarked);
    }
  }
}
