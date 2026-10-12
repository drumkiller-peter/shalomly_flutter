import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shalomly_app/src/features/giving/data/giving_repository.dart';
import 'package:shalomly_app/src/features/giving/domain/fund.dart';

// Events
abstract class GivingEvent extends Equatable {
  const GivingEvent();
  @override
  List<Object?> get props => [];
}

class GivingOverviewFetchRequested extends GivingEvent {
  const GivingOverviewFetchRequested();
}

class DonationSubmitRequested extends GivingEvent {
  final double amount;
  final int fundId;
  final String paymentMethod;
  final String? referenceId;
  final String? note;
  final bool isAnonymous;

  const DonationSubmitRequested({
    required this.amount,
    required this.fundId,
    required this.paymentMethod,
    this.referenceId,
    this.note,
    this.isAnonymous = false,
  });

  @override
  List<Object?> get props => [amount, fundId, paymentMethod, referenceId, note, isAnonymous];
}

// States
abstract class GivingState extends Equatable {
  const GivingState();
  @override
  List<Object?> get props => [];
}

class GivingInitial extends GivingState {
  const GivingInitial();
}

class GivingLoading extends GivingState {
  const GivingLoading();
}

class GivingLoaded extends GivingState {
  final List<ChurchFund> funds;
  final List<DonationReceipt> myDonations;

  const GivingLoaded({
    required this.funds,
    required this.myDonations,
  });

  @override
  List<Object?> get props => [funds, myDonations];
}

class GivingError extends GivingState {
  final String message;
  const GivingError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class GivingBloc extends Bloc<GivingEvent, GivingState> {
  final GivingRepository repository;

  GivingBloc({required this.repository}) : super(const GivingInitial()) {
    on<GivingOverviewFetchRequested>(_onFetchRequested);
    on<DonationSubmitRequested>(_onDonationSubmitted);
  }

  Future<void> _onFetchRequested(
    GivingOverviewFetchRequested event,
    Emitter<GivingState> emit,
  ) async {
    emit(const GivingLoading());
    try {
      final funds = await repository.getFunds();
      final myDonations = await repository.getMyDonations();
      emit(GivingLoaded(funds: funds, myDonations: myDonations));
    } catch (e) {
      emit(GivingError(e.toString()));
    }
  }

  Future<void> _onDonationSubmitted(
    DonationSubmitRequested event,
    Emitter<GivingState> emit,
  ) async {
    try {
      await repository.recordManualDonation(
        amount: event.amount,
        fundId: event.fundId,
        paymentMethod: event.paymentMethod,
        referenceId: event.referenceId,
        note: event.note,
        isAnonymous: event.isAnonymous,
      );
      add(const GivingOverviewFetchRequested());
    } catch (e) {
      emit(GivingError(e.toString()));
    }
  }
}
