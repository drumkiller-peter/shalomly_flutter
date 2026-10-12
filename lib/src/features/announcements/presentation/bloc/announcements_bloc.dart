import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shalomly_app/src/features/announcements/data/announcements_repository.dart';
import 'package:shalomly_app/src/features/announcements/domain/announcement.dart';

abstract class AnnouncementsEvent extends Equatable {
  const AnnouncementsEvent();

  @override
  List<Object?> get props => [];
}

class LoadAnnouncements extends AnnouncementsEvent {
  const LoadAnnouncements();
}

abstract class AnnouncementsState extends Equatable {
  const AnnouncementsState();

  @override
  List<Object?> get props => [];
}

class AnnouncementsInitial extends AnnouncementsState {
  const AnnouncementsInitial();
}

class AnnouncementsLoading extends AnnouncementsState {
  const AnnouncementsLoading();
}

class AnnouncementsLoaded extends AnnouncementsState {
  final List<Announcement> announcements;

  const AnnouncementsLoaded(this.announcements);

  @override
  List<Object?> get props => [announcements];
}

class AnnouncementsError extends AnnouncementsState {
  final String message;

  const AnnouncementsError(this.message);

  @override
  List<Object?> get props => [message];
}

class AnnouncementsBloc extends Bloc<AnnouncementsEvent, AnnouncementsState> {
  final AnnouncementsRepository repository;

  AnnouncementsBloc({required this.repository})
    : super(const AnnouncementsInitial()) {
    on<LoadAnnouncements>(_onLoad);
  }

  Future<void> _onLoad(
    LoadAnnouncements event,
    Emitter<AnnouncementsState> emit,
  ) async {
    // Keep the list on screen during a pull-to-refresh.
    if (state is! AnnouncementsLoaded) emit(const AnnouncementsLoading());
    try {
      emit(AnnouncementsLoaded(await repository.fetchAnnouncements()));
    } catch (e) {
      emit(AnnouncementsError(e.toString()));
    }
  }
}
