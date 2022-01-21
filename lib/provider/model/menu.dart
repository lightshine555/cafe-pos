import 'package:flutter/foundation.dart';

import '../src.dart';

@immutable
class Menu extends Iterable<Dish> {
  late final List<Dish> _list;

  Menu([List<Dish>? fromList]) {
    _list = fromList ?? [];
  }

  void add(Dish dish) => _list.add(dish);

  void set(Dish dish) {
    _list[_list.indexOf(dish)]
      ..dish = dish.dish
      ..price = dish.price
      ..imgProvider = dish.imgProvider;
  }

  void remove(Dish dish) => _list.remove(dish);

  Menu.fromJson(Map<String, dynamic> json) : _list = json['list'];

  // will be called implicitly
  // ignore: unused_element
  Map<String, dynamic> toJson() => {'list': _list};

  @override
  Iterator<Dish> get iterator => _list.iterator;
}
