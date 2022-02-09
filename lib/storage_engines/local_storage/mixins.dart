part of 'local_storage.dart';

typedef _JsonMap = Map<String, dynamic>;

mixin _ReadableImpl<T> implements Readable<T> {
  lib.LocalStorage get ls;

  static const int sequenceStart = 1;

  /// dummy key to retrieve all data
  String? fixedKeyString;

  /// How the date key is stored as string
  String _getKeyString(QueryKey key) {
    if (fixedKeyString != null) return fixedKeyString!;
    throw UnimplementedError(
        '_getKeyString() must be implemented if `_fixedKeyString` is not specified');
  }

  /// Return the field that is used as the key from [T]
  QueryKey _getKeyFromObject(T value);

  final _factories = <Type, Function>{
    Order: (_JsonMap json) => Order.fromJson(json),
    Journal: (_JsonMap json) => Journal.fromJson(json),
    Dish: (_JsonMap json) => Dish.fromJson(json),
  };

  Future<List<T>> _get(QueryKey key) async {
    List<dynamic>? storageData = ls.getItem(_getKeyString(key));
    if (storageData == null) return [];
    return storageData.map((obj) {
      // LocalStorage keeps a cache of dynamic types, storageData can be
      // fix-typed already by the second read, I hate 'dynamic' type
      if (obj is T) return obj;
      return _factories[T]!(obj) as T;
    }).toList();
  }

  @override
  Future<List<T>> get([QueryKey? start, QueryKey? end]) async {
    if (start != null && end == null) {
      return _get(start);
    }

    if (start == null && end == null) {
      assert(fixedKeyString != null, 'fixedKeyString must be overriden for `get()` to work');
      return _get(fixedKeyString!);
    }

    assert(end.runtimeType == start.runtimeType);

    List<Future<List<T>>> _f;
    if (start is DateTime && end is DateTime) {
      _f = [
        for (int i = 0; i < end.difference(start).inDays + 1; i++)
          _get(DateTime(start.year, start.month, start.day + i))
      ];
    } else if (start is num && end is num) {
      _f = [for (int i = 0; i < end - start + 1; i++) _get(start + i)];
    } else {
      throw '[get]: unknown QueryKey type';
    }
    return (await Future.wait(_f)).expand((e) => e).toList();
  }
}

mixin _InsertableImpl<T> on _ReadableImpl<T> implements Insertable<T> {
  /// The incrementing sequence key
  String get _idHighkey;

  Future<int> _nextUID() async {
    // if empty, starts from 1
    int current = ls.getItem(_idHighkey) ?? (_ReadableImpl.sequenceStart - 1);
    await ls.setItem(_idHighkey, ++current);
    return current;
  }

  @override
  Future<T> insert(T value) async {
    final key = _getKeyString(_getKeyFromObject(value));
    _JsonMap objectWithID;

    try {
      objectWithID = {
        ...(value as dynamic).toJson(),
        ...{'ID': await _nextUID()},
      };
    } on NoSuchMethodError {
      debugPrint('toJson() is not implemented on ${T.runtimeType}');
      rethrow;
    }

    var list = ls.getItem(key);
    if (list != null) {
      list.add(objectWithID);
    } else {
      list = [objectWithID];
    }
    await ls.setItem(key, list);
    return _factories[T]!(objectWithID) as T;
  }
}

mixin _UpdatableImpl<T> on _ReadableImpl<T> implements Updatable<T> {
  @override
  Future<void> update(T value) async {
    final keyObj = _getKeyFromObject(value);
    final key = _getKeyString(keyObj);

    List<T> list = await _get(key);
    if (list.isNotEmpty) {
      final idx = list.indexWhere(
        (e) => _getKeyFromObject(e).compareTo(keyObj) == 0,
      );
      list[idx] = value;
      return ls.setItem(key, list);
    }
  }
}

mixin _DeletableImpl<T> on _ReadableImpl<T> implements Deletable<T> {
  @override
  Future<void> delete(T value) async {
    final keyObj = _getKeyFromObject(value);
    final key = _getKeyString(keyObj);

    List<T> list = await _get(keyObj);
    list.removeWhere((e) => _getKeyFromObject(e).compareTo(keyObj) == 0);
    return ls.setItem(key, list);
  }
}
