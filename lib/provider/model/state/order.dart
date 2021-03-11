import '../../src.dart';

/// an data class to encapsulate the state of a node
class Order extends StateObject {
  int _id = -1;

  /// The incremental unique ID (for reporting), should be generated when [checkout]
  int get id => _id;
  set id(int orderID) {
    assert(orderID >= 0);
    _id = orderID;
  }

  /// The associated table id
  final int tableID;

  TableStatus status = TableStatus.empty;

  /// "soft-deleted", interactable only in [HistoryScreen]
  bool isDeleted;

  Order(this.tableID) : isDeleted = false;

  /// copy to a new instance (except [orderID])
  Order.copy(Order base)
      : tableID = base.tableID,
        isDeleted = base.isDeleted,
        status = base.status {
    lineItems = LineItemList.copy(base.lineItems);
    checkoutTime = base.checkoutTime;
    discountRate = base.discountRate;
  }

  Order.create({
    required this.tableID,
    required LineItemList lineItems,
    int orderID = -1,
    DateTime? checkoutTime,
    double discountRate = 1.0,
    this.status = TableStatus.empty,
    this.isDeleted = false,
  }) {
    assert(discountRate > 0.0 && discountRate <= 1.0);
    super.lineItems = lineItems;
    super.checkoutTime = checkoutTime ?? DateTime.parse('1999-01-01');
    super.discountRate = discountRate;
    if (orderID > -1) id = orderID;
  }

  Order.fromJson(Map<String, dynamic> json)
      : tableID = json['tableID'] ?? -1,
        _id = json['orderID'] ?? -1,
        isDeleted = json['isDeleted'] ?? false,
        super.create(
          LineItemList.fromJson(json['lineItems']),
          json['discountRate'],
          DateTime.parse(json['checkoutTime']),
        );

  Map<String, dynamic> toJson() {
    return {
      'tableID': tableID,
      'lineItems': activeLines.toJson(),
      'orderID': id,
      'checkoutTime': checkoutTime.toString(),
      'discountRate': discountRate,
      'isDeleted': isDeleted,
    };
  }

  @override
  String toString() => toJson().toString();
}
