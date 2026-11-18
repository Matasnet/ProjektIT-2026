import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class Meal extends Equatable {
  final String name;
  final List<String> allergens;

  const Meal({required this.name, this.allergens = const []});

  factory Meal.fromMap(Object? data) {
    final map = data is Map<String, dynamic> ? data : const <String, dynamic>{};
    return Meal(
      name: (map['name'] ?? '') as String,
      allergens: List<String>.from(map['allergens'] ?? const []),
    );
  }

  @override
  List<Object?> get props => [name, allergens];
}

/// Jadłospis na jeden dzień – dokument menu/{RRRR-MM-DD}.
class MenuDay extends Equatable {
  final String date; // RRRR-MM-DD
  final Meal breakfast;
  final Meal soup;
  final Meal main;
  final Meal snack;

  const MenuDay({
    required this.date,
    required this.breakfast,
    required this.soup,
    required this.main,
    required this.snack,
  });

  factory MenuDay.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return MenuDay(
      date: (data['date'] ?? doc.id) as String,
      breakfast: Meal.fromMap(data['breakfast']),
      soup: Meal.fromMap(data['soup']),
      main: Meal.fromMap(data['main']),
      snack: Meal.fromMap(data['snack']),
    );
  }

  @override
  List<Object?> get props => [date, breakfast, soup, main, snack];
}
