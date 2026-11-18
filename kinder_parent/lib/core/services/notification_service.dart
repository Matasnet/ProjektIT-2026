import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Handler wiadomości w tle (wymagany przez FCM, musi być poza klasą).
/// Gdy aplikacja jest w tle/zamknięta, system sam pokazuje powiadomienie.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

/// Serwis powiadomień push oparty o FCM Topics.
/// Topics: `all_parents` (wszyscy) oraz `group_{groupId}` (grupa dziecka).
class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static final Set<String> _subscribedTopics = {};

  static final StreamController<RemoteNotification> _foregroundController =
      StreamController.broadcast();

  /// Powiadomienia odebrane, gdy aplikacja jest otwarta (UI pokazuje SnackBar).
  static Stream<RemoteNotification> get foregroundMessages =>
      _foregroundController.stream;

  static Future<void> init() async {
    // Prośba o zgodę na powiadomienia (Android 13+ i iOS)
    await _messaging.requestPermission();

    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification != null) _foregroundController.add(notification);
    });
  }

  static String topicForGroup(String groupId) => 'group_$groupId';

  /// Subskrybuje 'all_parents' + grupy dzieci, odsubskrybowuje nieaktualne.
  static Future<void> syncTopics(List<String> groupIds) async {
    final wanted = {'all_parents', ...groupIds.map(topicForGroup)};

    for (final topic in _subscribedTopics.difference(wanted)) {
      await _messaging.unsubscribeFromTopic(topic);
    }
    for (final topic in wanted.difference(_subscribedTopics)) {
      await _messaging.subscribeToTopic(topic);
    }
    _subscribedTopics
      ..clear()
      ..addAll(wanted);
  }

  /// Wywoływane przy wylogowaniu – telefon przestaje dostawać powiadomienia.
  static Future<void> unsubscribeFromAll() async {
    for (final topic in _subscribedTopics) {
      await _messaging.unsubscribeFromTopic(topic);
    }
    _subscribedTopics.clear();
  }
}
