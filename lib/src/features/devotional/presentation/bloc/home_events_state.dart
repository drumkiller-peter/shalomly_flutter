// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'home_events_bloc.dart';

enum HomeEventsStatus { initial, loading, loaded }

/// What Home shows of the calendar: the next worship Event and this week's
/// Notices.
class HomeEventsState extends Equatable {
  final HomeEventsStatus status;
  final ChurchEvent? nextWorship;
  final List<ChurchEvent> notices;

  const HomeEventsState({
    this.status = HomeEventsStatus.initial,
    this.nextWorship,
    this.notices = const [],
  });

  HomeEventsState copyWith({
    HomeEventsStatus? status,
    ChurchEvent? nextWorship,
    List<ChurchEvent>? notices,
  }) {
    return HomeEventsState(
      status: status ?? this.status,
      nextWorship: nextWorship ?? this.nextWorship,
      notices: notices ?? this.notices,
    );
  }

  @override
  List<Object?> get props => [status, nextWorship, notices];
}
