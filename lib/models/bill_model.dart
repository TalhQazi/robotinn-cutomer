class BillModel {
  final String id;
  final String orderId;
  final double amount;
  final double total;
  final double productPrice;
  final double shippingFee;
  final String status;
  final String? receiptImageUrl;
  final String? paymentProofImage;
  final String? adminNotes;
  final dynamic createdAt;

  BillModel({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.total,
    this.productPrice = 0.0,
    this.shippingFee = 0.0,
    this.status = 'submitted',
    this.receiptImageUrl,
    this.paymentProofImage,
    this.adminNotes,
    this.createdAt,
  });

  factory BillModel.fromOrderMap(Map<String, dynamic> orderData, String orderDocId) {
    final bill = orderData['bill'] is Map ? Map<String, dynamic>.from(orderData['bill']) : {};
    
    final pPrice = (bill['productPrice'] as num?)?.toDouble() ?? 0.0;
    final sFee = (bill['shippingFee'] as num?)?.toDouble() ?? 0.0;
    final bAmount = (bill['amount'] as num?)?.toDouble() ?? 0.0;
    final bTotal = (bill['total'] as num?)?.toDouble() ?? 0.0;
    final oTotal = (orderData['total'] as num?)?.toDouble() ?? 0.0;

    double resolvedAmount = 0.0;
    if (bAmount > 0) {
      resolvedAmount = bAmount;
    } else if (bTotal > 0) {
      resolvedAmount = bTotal;
    } else if ((pPrice + sFee) > 0) {
      resolvedAmount = pPrice + sFee;
    } else if (oTotal > 0) {
      resolvedAmount = oTotal;
    }

    return BillModel(
      id: orderDocId,
      orderId: orderData['orderId']?.toString() ?? orderDocId,
      amount: resolvedAmount,
      total: resolvedAmount,
      productPrice: pPrice,
      shippingFee: sFee,
      status: bill['status']?.toString() ?? 'submitted',
      receiptImageUrl: bill['receiptImageUrl']?.toString() ?? orderData['receiptUrl']?.toString(),
      paymentProofImage: bill['paymentProofImage']?.toString(),
      adminNotes: bill['adminNotes']?.toString(),
      createdAt: bill['submittedAt'] ?? orderData['createdAt'],
    );
  }
}
