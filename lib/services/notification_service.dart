import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:smch_mobile/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter/foundation.dart';
import '../models/notification.dart';
import 'api_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  Timer? _pollingTimer;
  final _notificationsController = StreamController<List<Notification>>.broadcast();
  Stream<List<Notification>> get notificationsStream => _notificationsController.stream;

  List<Notification> _notifications = [];
  List<Notification> get notifications => List.unmodifiable(_notifications);

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
      },
    );

    // Start polling for notifications
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _fetchNotifications();
    });
  }

  Future<void> _fetchNotifications() async {
    try {
      final response = await http.get(
        Uri.parse('${const String.fromEnvironment('API_URL')}/api/notifications'),
        headers: {
          'Authorization': 'Bearer ${await _getToken()}',
          'Accept': 'application/json',
          'Cache-Control': 'no-cache',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final newNotifications = data.map((json) => Notification.fromJson(json)).toList();
        
        // Only update if there are new notifications
        if (!_areNotificationsEqual(_notifications, newNotifications)) {
          _notifications = newNotifications;
          _notificationsController.add(_notifications);
          
          // Show local notifications for new unread ones
          for (final notification in _notifications.where((n) => !n.read)) {
            await _showLocalNotification(notification);
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    }
  }

  bool _areNotificationsEqual(List<Notification> list1, List<Notification> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  Future<void> _showLocalNotification(Notification notification) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'smch_notifications',
      'SMCH Notifications',
      channelDescription: 'Notifications from SMCH System',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _notifications.show(
      notification.id,
      notification.title,
      notification.message,
      platformChannelSpecifics,
      payload: json.encode(notification.toJson()),
    );
  }

  Future<String?> _getToken() async {
    // Implement token retrieval from your auth provider
    return null;
  }

  Future<void> loadNotifications({int page = 1, int perPage = 20}) async {
    try {
      final response = await ApiService().get(
        '/notifications',
        queryParameters: {
          'page': page,
          'per_page': perPage,
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        final newNotifications = data.map((json) => Notification.fromJson(json)).toList();
        
        if (page == 1) {
          _notifications = newNotifications;
        } else {
          _notifications = [..._notifications, ...newNotifications];
        }
        
        _notificationsController.add(_notifications);
      } else {
        throw Exception('Failed to load notifications');
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
      rethrow;
    }
  }

  Future<void> markAsRead(int notificationId) async {
    try {
      final response = await ApiService().post(
        '/notifications/$notificationId/mark-as-read',
        {},
      );
      if (response.statusCode == 200) {
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          _notifications[index] = _notifications[index].copyWith(read: true);
          _notificationsController.add(_notifications);
        }
      } else {
        throw Exception('Failed to mark notification as read');
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      rethrow;
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final response = await ApiService().post('/notifications/mark-all-read', {});
      if (response.statusCode == 200) {
        _notifications = _notifications.map((n) => n.copyWith(read: true)).toList();
        _notificationsController.add(_notifications);
      } else {
        throw Exception('Failed to mark all notifications as read');
      }
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      rethrow;
    }
  }

  Future<void> deleteNotification(int notificationId) async {
    try {
      final response = await ApiService().delete('/notifications/$notificationId');
      if (response.statusCode == 200) {
        _notifications.removeWhere((n) => n.id == notificationId);
        _notificationsController.add(_notifications);
      } else {
        throw Exception('Failed to delete notification');
      }
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      rethrow;
    }
  }

  Future<void> deleteAllNotifications() async {
    try {
      final response = await ApiService().delete('/notifications');
      if (response.statusCode == 200) {
        _notifications.clear();
        _notificationsController.add(_notifications);
      } else {
        throw Exception('Failed to delete all notifications');
      }
    } catch (e) {
      debugPrint('Error deleting all notifications: $e');
      rethrow;
    }
  }

  void dispose() {
    _pollingTimer?.cancel();
    _notificationsController.close();
  }
}

class Notification {
  final int id;
  final String title;
  final String message;
  final String type;
  final bool read;
  final DateTime createdAt;

  Notification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.read,
    required this.createdAt,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      type: json['type'],
      read: json['read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'read': read,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get timeAgo => timeago.format(createdAt);

  Notification copyWith({
    int? id,
    String? title,
    String? message,
    String? type,
    bool? read,
    DateTime? createdAt,
  }) {
    return Notification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
    );
  }
} 