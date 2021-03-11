import 'package:flutter/material.dart';

import './bottom_navbar.dart';
import './item_list.dart';
import '../../theme/rally.dart';
import '../../provider/src.dart';

class DetailsScreen extends StatelessWidget {
  final TableModel order;
  final String? fromHeroTag;
  final String fromScreen;

  DetailsScreen(this.order, {this.fromHeroTag, required this.fromScreen});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavBar(order, fromScreen: fromScreen, fromHeroTag: fromHeroTag),
      floatingActionButton: fromScreen == 'history'
          ? FloatingActionButton(
              onPressed: () {
                order.checkoutPrintClear(context: context);
                Navigator.pop(context);
              },
              elevation: 4.0,
              backgroundColor: RallyColors.buttonColor,
              child: Icon(Icons.print_sharp),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: ItemList(order, fromScreen: fromScreen),
    );
  }
}
