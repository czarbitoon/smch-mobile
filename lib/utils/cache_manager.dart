import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;

class CacheEntry {
  final dynamic data;
  final DateTime timestamp;
  final Duration maxAge;
  final bool isPendingSync;

  CacheEntry({
    required this.data,
    required this.timestamp,
    required this.maxAge,
    this.isPendingSync = false,
  });

  bool get isExpired => DateTime.now().difference(timestamp) > maxAge;

  Map<String, dynamic> toJson() => {
    'data': data,
    'timestamp': timestamp.toIso8601String(),
    'maxAge': maxAge.inSeconds,
    'isPendingSync': isPendingSync,
  };

  factory CacheEntry.fromJson(Map<String, dynamic> json) {
    return CacheEntry(
      data: json['data'],
      timestamp: DateTime.parse(json['timestamp']),
      maxAge: Duration(seconds: json['maxAge']),
      isPendingSync: json['isPendingSync'] ?? false,
    );
  }
}

class CacheManager {
  static const int _maxEntries = 1000; // Increased for offline support
  static const Duration _defaultMaxAge = Duration(days: 7); // Increased for offline support
  final Map<String, CacheEntry> _cache = {};
  final _controller = StreamController<String>.broadcast();
  Timer? _persistenceTimer;
  Timer? _syncTimer;
  bool _initialized = false;
  late Database _database;
  final _connectivity = Connectivity();
  StreamSubscription? _connectivitySubscription;

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

  Future<void> _persistToDisk() async {
    try {
      final batch = _database.batch();
      
      _cache.forEach((key, value) {
        if (!value.isExpired) {
          batch.insert(
            'offline_cache',
            {
              'key': key,
              'data': json.encode(value.toJson()),
              'timestamp': value.timestamp.toIso8601String(),
              'max_age': value.maxAge.inSeconds,
              'is_pending_sync': value.isPendingSync ? 1 : 0,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });

      await batch.commit(noResult: true);
    } catch (e) {
      debugPrint('Error persisting cache to disk: $e');
    }
  }

  Future<T?> get<T>(String key) async {
    final entry = _cache[key];
    if (entry == null || entry.isExpired) {
      _cache.remove(key);
      return null;
    }
    return entry.data as T;
  }

  Future<void> set(
    String key,
    dynamic value, {
    Duration? maxAge,
    bool isPendingSync = false,
  }) async {
    if (_cache.length >= _maxEntries) {
      final oldestKey = _cache.entries
          .reduce((a, b) => a.value.timestamp.isBefore(b.value.timestamp)
              ? a
              : b)
          .key;
      _cache.remove(oldestKey);
    }

    _cache[key] = CacheEntry(
      data: value,
      timestamp: DateTime.now(),
      maxAge: maxAge ?? _defaultMaxAge,
      isPendingSync: isPendingSync,
    );

    _controller.add(key);
    await _persistToDisk();
  }

  Future<List<Map<String, dynamic>>> getPendingActions() async {
    final actions = await _database.query('pending_actions');
    return actions.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> remove(String key) async {
    _cache.remove(key);
    await _database.delete(
      'offline_cache',
      where: 'key = ?',
      whereArgs: [key],
    );
    _controller.add(key);
  }

  Future<void> clear() async {
    _cache.clear();
    await _database.delete('offline_cache');
    _controller.add('clear');
  }

  void dispose() {
    _persistenceTimer?.cancel();
    _syncTimer?.cancel();
    _connectivitySubscription?.cancel();
    _controller.close();
    _database.close();
  }
} 