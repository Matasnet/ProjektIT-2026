import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/notification_service.dart';
import '../../data/home_repository.dart';
import '../../domain/models.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final HomeRepository _homeRepository;
  final String _userId;

  StreamSubscription<List<Child>>? _childrenSub;
  StreamSubscription<List<AppNotification>>? _notificationsSub;

  List<Child> _children = [];
  Map<String, String> _groupNames = {};
  List<AppNotification> _notifications = [];
  List<String>? _groupIds; // null = jeszcze nie subskrybowano

  HomeCubit({required HomeRepository homeRepository, required String userId})
    : _homeRepository = homeRepository,
      _userId = userId,
      super(HomeLoading());

  void start() {
    _childrenSub = _homeRepository
        .watchChildren(_userId)
        .listen(_onChildren, onError: _onError);
  }

  Future<void> _onChildren(List<Child> children) async {
    _children = children;
    final groupIds = children
        .map((c) => c.groupId)
        .whereType<String>()
        .toSet()
        .toList();

    try {
      _groupNames = await _homeRepository.getGroupNames();
    } catch (e) {
      _onError(e);
      return;
    }

    // Zmieniły się grupy dzieci → nowe topiki FCM i nowe zapytanie
    if (!listEquals(groupIds..sort(), _groupIds)) {
      _groupIds = groupIds;
      unawaited(NotificationService.syncTopics(groupIds).catchError((_) {}));
      await _notificationsSub?.cancel();
      _notificationsSub = _homeRepository.watchNotifications(groupIds).listen((
        list,
      ) {
        _notifications = list;
        _emitLoaded();
      }, onError: _onError);
    }
    _emitLoaded();
  }

  void _emitLoaded() {
    if (isClosed) return;
    emit(
      HomeLoaded(
        children: _children,
        groupNames: _groupNames,
        notifications: _notifications,
      ),
    );
  }

  void _onError(Object error) {
    if (isClosed) return;
    emit(const HomeError('Nie udało się pobrać danych'));
  }

  @override
  Future<void> close() {
    _childrenSub?.cancel();
    _notificationsSub?.cancel();
    return super.close();
  }
}
