import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/payments_repository.dart';
import '../../domain/payment_settings.dart';

enum PaymentsStatus { loading, loaded, error }

class PaymentsState extends Equatable {
  final PaymentsStatus status;

  /// null = opłata nie została jeszcze ustawiona w panelu
  final PaymentSettings? settings;

  const PaymentsState({required this.status, this.settings});

  @override
  List<Object?> get props => [status, settings];
}

/// Ustawienia opłaty na żywo. Statusy wpłat są w dzieciach (HomeCubit).
class PaymentsCubit extends Cubit<PaymentsState> {
  final PaymentsRepository _paymentsRepository;
  StreamSubscription<PaymentSettings?>? _sub;

  PaymentsCubit({required PaymentsRepository paymentsRepository})
    : _paymentsRepository = paymentsRepository,
      super(const PaymentsState(status: PaymentsStatus.loading));

  void start() {
    _sub = _paymentsRepository.watchSettings().listen(
      (settings) {
        if (!isClosed) {
          emit(
            PaymentsState(status: PaymentsStatus.loaded, settings: settings),
          );
        }
      },
      onError: (_) {
        if (!isClosed) {
          emit(const PaymentsState(status: PaymentsStatus.error));
        }
      },
    );
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
