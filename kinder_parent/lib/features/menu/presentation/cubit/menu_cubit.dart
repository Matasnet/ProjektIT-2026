import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/dates.dart';
import '../../data/menu_repository.dart';
import '../../domain/menu_day.dart';

enum MenuStatus { loading, loaded, error }

class MenuState extends Equatable {
  final MenuStatus status;

  /// Poniedziałek wyświetlanego tygodnia
  final DateTime weekStart;

  /// Wybrany dzień (Pn–Pt wyświetlanego tygodnia)
  final DateTime selected;

  /// Klucz RRRR-MM-DD → jadłospis
  final Map<String, MenuDay> days;

  const MenuState({
    required this.status,
    required this.weekStart,
    required this.selected,
    this.days = const {},
  });

  List<DateTime> get weekdays =>
      List.generate(5, (i) => weekStart.add(Duration(days: i)));

  MenuDay? get selectedDay => days[Dates.dayKey(selected)];

  MenuState copyWith({
    MenuStatus? status,
    DateTime? weekStart,
    DateTime? selected,
    Map<String, MenuDay>? days,
  }) {
    return MenuState(
      status: status ?? this.status,
      weekStart: weekStart ?? this.weekStart,
      selected: selected ?? this.selected,
      days: days ?? this.days,
    );
  }

  @override
  List<Object?> get props => [status, weekStart, selected, days];
}

class MenuCubit extends Cubit<MenuState> {
  final MenuRepository _menuRepository;
  StreamSubscription<List<MenuDay>>? _sub;

  MenuCubit({required MenuRepository menuRepository, DateTime? now})
    : _menuRepository = menuRepository,
      super(_initial(now ?? DateTime.now()));

  /// Dziś, a w weekend – poniedziałek następnego tygodnia
  static MenuState _initial(DateTime now) {
    final today = Dates.dateOnly(now);
    final day = today.weekday >= DateTime.saturday
        ? Dates.mondayOf(today).add(const Duration(days: 7))
        : today;
    return MenuState(
      status: MenuStatus.loading,
      weekStart: Dates.mondayOf(day),
      selected: day,
    );
  }

  void start() => _watchWeek(state.weekStart);

  void selectDay(DateTime day) => emit(state.copyWith(selected: day));

  /// Poprzedni (-1) / następny (+1) tydzień – zaznacza jego poniedziałek
  void shiftWeek(int delta) {
    final monday = state.weekStart.add(Duration(days: 7 * delta));
    emit(
      state.copyWith(
        status: MenuStatus.loading,
        weekStart: monday,
        selected: monday,
      ),
    );
    _watchWeek(monday);
  }

  void _watchWeek(DateTime monday) {
    _sub?.cancel();
    final friday = monday.add(const Duration(days: 4));
    _sub = _menuRepository
        .watchRange(Dates.dayKey(monday), Dates.dayKey(friday))
        .listen(
          (list) {
            if (isClosed) return;
            emit(
              state.copyWith(
                status: MenuStatus.loaded,
                days: {for (final d in list) d.date: d},
              ),
            );
          },
          onError: (_) {
            if (!isClosed) emit(state.copyWith(status: MenuStatus.error));
          },
        );
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
