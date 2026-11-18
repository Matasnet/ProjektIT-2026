import 'package:equatable/equatable.dart';

import '../../domain/models.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final List<Child> children;
  final Map<String, String> groupNames;
  final List<AppNotification> notifications;

  const HomeLoaded({
    required this.children,
    required this.groupNames,
    required this.notifications,
  });

  String groupName(String? groupId) {
    if (groupId == null) return 'Brak grupy';
    if (groupId == 'all') return 'Wszyscy';
    return groupNames[groupId] ?? 'Grupa';
  }

  @override
  List<Object?> get props => [children, groupNames, notifications];
}

class HomeError extends HomeState {
  final String message;

  const HomeError(this.message);

  @override
  List<Object?> get props => [message];
}
