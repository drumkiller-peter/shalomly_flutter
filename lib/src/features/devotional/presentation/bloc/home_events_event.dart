// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'home_events_bloc.dart';

abstract class HomeEventsEvent extends Equatable {
  const HomeEventsEvent();

  @override
  List<Object?> get props => [];
}

/// Read the next worship Event and this week's Notices as of [now].
class HomeEventsLoadRequested extends HomeEventsEvent {
  final DateTime now;
  const HomeEventsLoadRequested(this.now);

  @override
  List<Object?> get props => [now];
}
