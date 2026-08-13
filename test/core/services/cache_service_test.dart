import 'package:ai_chat/core/services/cache_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late CacheService cache;

  setUp(() => cache = CacheService());

  tearDown(() => cache.clear());

  group('CacheService.put/get', () {
    test('stores and retrieves a value within TTL', () {
      cache.put<String>('k', 'v', ttl: const Duration(minutes: 1));
      expect(cache.get<String>('k'), 'v');
      expect(cache.containsKey('k'), isTrue);
    });

    test('returns null for absent key', () {
      expect(cache.get<String>('missing'), isNull);
      expect(cache.containsKey('missing'), isFalse);
    });

    test('overwrites existing key', () {
      cache.put<int>('k', 1, ttl: const Duration(minutes: 1));
      cache.put<int>('k', 2, ttl: const Duration(minutes: 1));
      expect(cache.get<int>('k'), 2);
    });

    test('returns null for type mismatch', () {
      cache.put<String>('k', 'v', ttl: const Duration(minutes: 1));
      expect(cache.get<int>('k'), isNull);
    });
  });

  group('CacheService expiration', () {
    test('expired entry is removed on read and reports absent', () async {
      cache.put<String>('k', 'v', ttl: const Duration(milliseconds: 5));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(cache.get<String>('k'), isNull);
      expect(cache.containsKey('k'), isFalse);
    });

    test('remainingTtl is null for absent/expired', () {
      expect(cache.remainingTtl('missing'), isNull);
    });

    test('remainingTtl is positive for live entry', () {
      cache.put<String>('k', 'v', ttl: const Duration(minutes: 5));
      expect(cache.remainingTtl('k')?.inSeconds, lessThanOrEqualTo(300));
    });
  });

  group('CacheService removal', () {
    test('remove deletes a single key', () {
      cache.put<String>('k', 'v', ttl: const Duration(minutes: 1));
      cache.remove('k');
      expect(cache.containsKey('k'), isFalse);
    });

    test('removeByPrefix deletes all matching keys only', () {
      cache.put<String>('conv.1', 'a', ttl: const Duration(minutes: 1));
      cache.put<String>('conv.2', 'b', ttl: const Duration(minutes: 1));
      cache.put<String>('other', 'c', ttl: const Duration(minutes: 1));
      cache.removeByPrefix('conv.');
      expect(cache.containsKey('conv.1'), isFalse);
      expect(cache.containsKey('conv.2'), isFalse);
      expect(cache.get<String>('other'), 'c');
    });
  });

  group('CacheService clear/evictExpired', () {
    test('clear empties the store', () {
      cache.put<String>('k', 'v', ttl: const Duration(minutes: 1));
      cache.clear();
      expect(cache.containsKey('k'), isFalse);
    });

    test('evictExpired removes only expired entries', () async {
      cache.put<String>('live', 'v', ttl: const Duration(minutes: 1));
      cache.put<String>('dead', 'v', ttl: const Duration(milliseconds: 5));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      cache.evictExpired();
      expect(cache.containsKey('live'), isTrue);
      expect(cache.containsKey('dead'), isFalse);
    });
  });
}
