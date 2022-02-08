import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:localstorage/localstorage.dart' as lib;

import '../common/common.dart';
import '../provider/src.dart';
import 'connection_interface.dart';

class LocalStorage implements DatabaseConnectionInterface {
  final lib.LocalStorage ls;

  LocalStorage(String name, [String? path, Map<String, dynamic>? initialData])
      : ls = lib.LocalStorage(name, path, initialData);

  //---Order---

  @override
  Future<List<Order>> get(DateTime day) async {
    List<dynamic>? storageData = ls.getItem(Common.extractYYYYMMDD(day));
    if (storageData == null) return [];
    return storageData.map((i) => Order.fromJson(i)).toList();
  }

  @override
  Future<List<Order>> getRange(DateTime start, DateTime end) async {
    return (await Future.wait([
      for (int i = 0; i < end.difference(start).inDays; i++)
        get(DateTime(start.year, start.month, start.day + i))
    ]))
        .expand((e) => e)
        .toList();
  }

  @override
  Future<void> insert(Order order) async {
    final checkoutTime = Common.extractYYYYMMDD(order.checkoutTime);
    final orderWithID = {
      ...order.toJson(),
      ...{'orderID': await _nextUID()},
    };

    // current orders of the day that have been saved
    // if this is first order then create it as an List
    var orders = ls.getItem(checkoutTime);
    if (orders != null) {
      orders.add(orderWithID);
    } else {
      orders = [orderWithID];
    }
    return ls.setItem(checkoutTime, orders);
  }

  @override
  Future<void> delete(DateTime day, int orderID) async {
    final orders = await get(day);
    await ls.setItem(
        Common.extractYYYYMMDD(day),
        orders.map((e) {
          if (e.id == orderID) {
            return {
              ...e.toJson(),
              ...{'isDeleted': true}
            };
          }
          return e.toJson();
        }).toList());
    return;
  }

  @override
  Future<bool> open() => ls.ready;

  @override
  Future<void> close() async {
    ls.dispose();
    await Future.delayed(const Duration(milliseconds: 200));
  }

  @override
  Future<void> destroy() => ls.clear();

  @override
  Future<void> truncate() => ls.clear();

  //---Menu---

  @override
  Future<Menu?> getMenu() async {
    var storageData = ls.getItem('menu');
    if (storageData == null) {
      if (kDebugMode) {
        print('\x1B[94mmenu not found in localstorage\x1B[0m');
      }
      return null;
    }
    return Menu.fromJson(storageData);
  }

  @override
  Future<void> setMenu({Menu? menu, Dish? dish, bool isDelete = false}) {
    if (menu == null) throw '[localstorage] setMenu() is only supported with `menu` parameter';
    // to set items to local storage
    return ls.setItem('menu', menu);
  }

//---Node---

  Future<int> _nextUID() async {
    // if empty, starts from 1
    int current = ls.getItem('order_id_highkey') ?? 0;
    await ls.setItem('order_id_highkey', ++current);
    return current;
  }

  @override
  Future<List<int>> tableIDs() async {
    final List<dynamic> l = ls.getItem('table_list') ?? [];
    return l.cast<int>();
  }

  @override
  Future<int> addTable() async {
    final list = await tableIDs();
    final nextID = list.fold<int>(0, max) + 1;
    list.add(nextID);
    await ls.setItem('table_list', list);
    return nextID;
  }

  @override
  Future<void> removeTable(int tableID) async {
    final list = await tableIDs();
    list.remove(tableID);
    await ls.setItem('table_list', list);
    return;
  }

  @override
  Future<void> setCoordinate(int tableID, double x, double y) {
    return Future.wait(
      [ls.setItem('${tableID}_coord_x', x), ls.setItem('${tableID}_coord_y', y)],
      eagerError: true,
    );
  }

  @override
  Future<double> getX(int tableID) async {
    return ls.getItem('${tableID}_coord_x') ?? 0;
  }

  @override
  Future<double> getY(int tableID) {
    return ls.getItem('${tableID}_coord_y') ?? 0;
  }

  //---Journal---

  @override
  Future<List<Journal>> getJournal(DateTime day) async {
    List<dynamic>? storageData = ls.getItem('j${Common.extractYYYYMMDD(day)}');
    if (storageData == null) return [];
    return storageData.map((i) => Journal.fromJson(i)).toList();
  }

  @override
  Future<List<Journal>> getJournals(DateTime start, DateTime end) async {
    return (await Future.wait([
      for (int i = 0; i < end.difference(start).inDays; i++)
        getJournal(DateTime(start.year, start.month, start.day + i))
    ]))
        .expand((dailyJournal) => dailyJournal)
        .toList();
  }

  @override
  Future<void> insertJournal(Journal journal) async {
    final dateTime = Common.extractYYYYMMDD(journal.dateTime);
    final journalWithID = {
      ...journal.toJson(),
      ...{'journalID': await _nextUID()}, // too lazy to make new key...
    };

    var journals = ls.getItem('j$dateTime');
    if (journals != null) {
      journals.add(journalWithID);
    } else {
      journals = [journalWithID];
    }
    return ls.setItem('j$dateTime', journals);
  }
}
