import 'package:flutter/material.dart';

/// Colored pill showing an order/fulfillment/payment status value.
class OrderStatusChip extends StatelessWidget {
  const OrderStatusChip(this.value, {super.key});
  final String value;

  static const _colors = {
    'completed': Colors.green,
    'fulfilled': Colors.green,
    'captured': Colors.green,
    'shipped': Colors.green,
    'processing': Color(0xFF1976D2),
    'awaiting': Color(0xFF1976D2),
    'pending': Colors.orange,
    'pending_payment': Colors.orange,
    'not_fulfilled': Colors.orange,
    'not_paid': Colors.orange,
    'partially_fulfilled': Colors.orange,
    'on_hold': Colors.orange,
    'canceled': Colors.red,
    'refunded': Color(0xFF7B1FA2),
    'partially_refunded': Color(0xFF7B1FA2),
    'returned': Color(0xFF7B1FA2),
  };

  String _label() => value
      .split('_')
      .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  @override
  Widget build(BuildContext context) {
    final color = _colors[value.toLowerCase()] ?? Colors.blueGrey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _label(),
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
