import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

class CacheEntry<T> {
  final T value;
  final DateTime timestamp;
  final Duration maxAge;
  final bool isPendingSync;

  CacheEntry({
    required this.value,
    required this.timestamp,
    required this.maxAge,
    this.isPendingSync = false,
  });

  bool get isExpired => DateTime.now().difference(timestamp) > maxAge;

  Map<String, dynamic> toJson() => {
    'value': value,
    'timestamp': timestamp.toIso8601String(),
    'maxAge': maxAge.inSeconds,
    'isPendingSync': isPendingSync,
  };

  factory CacheEntry.fromJson(Map<String, dynamic> json) {
    return CacheEntry(
      value: json['value'],
      timestamp: DateTime.parse(json['timestamp']),
      maxAge: Duration(seconds: json['maxAge']),
      isPendingSync: json['isPendingSync'] ?? false,
    );
  }
}

class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  static const int _maxEntries = 1000; // Increased for offline support
  static const Duration _defaultMaxAge = Duration(days: 7); // Increased for offline support
  final Map<String, CacheEntry<dynamic>> _cache = {};
  final _controller = StreamController<String>.broadcast();
  Timer? _persistenceTimer;
  Timer? _syncTimer;
  bool _initialized = false;
  late Database _database;
  final _connectivity = Connectivity();
  StreamSubscription? _connectivitySubscription;
  String? _cacheFilePath;
  final Map<String, DateTime> _cacheTimestamps = {};
  final Duration _cacheDuration = const Duration(minutes: 5);
  static const String _cacheKey = 'app_cache';

  Stream<String> get changes => _controller.stream;

  Future<void> initialize() async {
    if (_initialized) return;
    
    // Initialize SQLite database
    final dbPath = await getDatabasesPath();
    _database = await openDatabase(
      path.join(dbPath, 'offline_cache.db'),
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE offline_cache (
            key TEXT PRIMARY KEY,
            data TEXT,
            timestamp TEXT,
            max_age INTEGER,
            is_pending_sync INTEGER
          )
        ''');
        
        await db.execute('''
          CREATE TABLE pending_actions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            method TEXT,
            endpoint TEXT,
            data TEXT,
            timestamp TEXT
          )
        ''');
      },
    );

    await _loadFromDisk();
    await _loadFromDatabase();
    _initialized = true;
    _startPersistenceTimer();
    _startSyncTimer();
    _setupConnectivityListener();
  }

  void _setupConnectivityListener() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        _syncPendingActions();
      }
    });
  }

  Future<void> _loadFromDatabase() async {
    final records = await _database.query('offline_cache');
    for (final record in records) {
      try {
        final entry = CacheEntry.fromJson(json.decode(record['data'] as String));
        if (!entry.isExpired) {
          _cache[record['key'] as String] = entry;
        }
      } catch (e) {
        debugPrint('Error loading cache entry from database: $e');
      }
    }
  }

  Future<void> savePendingAction(String method, String endpoint, dynamic data) async {
    await _database.insert('pending_actions', {
      'method': method,
      'endpoint': endpoint,
      'data': json.encode(data),
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _syncPendingActions() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) return;

    final pendingActions = await _database.query('pending_actions', orderBy: 'timestamp ASC');
    
    for (final action in pendingActions) {
      try {
        // Implement your API service call here based on the action
        // If successful, delete the action from the database
        await _database.delete(
          'pending_actions',
          where: 'id = ?',
          whereArgs: [action['id']],
        );
      } catch (e) {
        debugPrint('Error syncing pending action: $e');
      }
    }
  }

  void _startSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(
      const Duration(minutes: 15),
      (_) => _syncPendingActions(),
    );
  }

  Future<void> _loadFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = prefs.getString(_cacheKey);
      if (cacheData != null) {
        final Map<String, dynamic> data = json.decode(cacheData);
        _cache.addAll(data.map((key, value) => MapEntry(key, CacheEntry(
          value: value['value'],
          timestamp: DateTime.parse(value['timestamp']),
          maxAge: Duration(seconds: value['maxAge']),
          isPendingSync: value['isPendingSync'] ?? false,
        ))));
      }
    } catch (e) {
      debugPrint('Error loading cache from disk: $e');
    }
  }

  void _startPersistenceTimer() {
    _persistenceTimer?.cancel();
    _persistenceTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _persistToDisk();
    });
  }

  Future<void> _persistToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, json.encode(_cache.map((key, value) => MapEntry(key, value.toJson()))));
    } catch (e) {
      debugPrint('Error persisting cache to disk: $e');
    }
  }

  Future<T?> get<T>(String key) async {
    final entry = _cache[key];
    if (entry == null || entry.isExpired) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
      return null;
    }
    return entry.value as T;
  }

  Future<void> set(
    String key,
    dynamic value, {
    Duration? maxAge,
    bool isPendingSync = false,
  }) async {
    if (_cache.length >= _maxEntries) {
      final oldestKey = _cache.entries
          .reduce((a, b) => a.value.timestamp.isBefore(b.value.value.timestamp)
              ? a
              : b)
          .key;
      _cache.remove(oldestKey);
    }

    _cache[key] = CacheEntry(
      value: value,
      timestamp: DateTime.now(),
      maxAge: maxAge ?? _defaultMaxAge,
      isPendingSync: isPendingSync,
    );

    _cacheTimestamps[key] = DateTime.now();
    _controller.add(key);
    await _persistToDisk();
  }

  Future<List<Map<String, dynamic>>> getPendingActions() async {
    final actions = await _database.query('pending_actions');
    return actions.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> remove(String key) async {
    _cache.remove(key);
    _cacheTimestamps.remove(key);
    await _database.delete(
      'offline_cache',
      where: 'key = ?',
      whereArgs: [key],
    );
    _controller.add(key);
    await _persistToDisk();
  }

  Future<void> clear() async {
    _cache.clear();
    _cacheTimestamps.clear();
    await _database.delete('offline_cache');
    _controller.add('clear');
    await _persistToDisk();
  }

  bool _isCacheValid(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheDuration;
  }

  void dispose() {
    _persistenceTimer?.cancel();
    _syncTimer?.cancel();
    _connectivitySubscription?.cancel();
    _controller.close();
    _database.close();
  }
} 