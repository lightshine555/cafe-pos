import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'journal_list.dart';
import 'add_new_entry_button.dart';
import 'date_picker.dart';
import '../../common/common.dart';
import '../../provider/supplier/inventory_journal_supplier.dart';

class InventoryJournalScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _LeadingTitle(),
        bottomOpacity: 0.5,
        actions: [
          // fix the text size of the "current date"
          Theme(
            data: Theme.of(context).copyWith(
              textTheme: Theme.of(context).textTheme.copyWith(
                    bodyText1: GoogleFonts.eczar(fontSize: 20),
                  ),
            ),
            child: DatePicker(),
          ),
        ],
      ),
      body: InventoryJournalList(),
      floatingActionButton: AddNewEntryButton(),
    );
  }
}

class _LeadingTitle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<InventorySupplier>(context);
    final price = provider.sumAmount;
    final range = provider.selectedRange;
    return Wrap(
      direction: Axis.vertical,
      children: [
        Text(
          '${Money.format(price)}',
          style: TextStyle(
            color: Colors.lightGreen,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        Text(
          '(${Common.extractYYYYMMDD2(range.start)} - ${Common.extractYYYYMMDD2(range.end)})',
          style: Theme.of(context).textTheme.caption,
        ),
      ],
    );
  }
}
