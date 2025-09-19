import 'package:flutter/material.dart';
import '../../models/order_model.dart';
import '../../styles/app_theme.dart';
import '../../styles/app_colors.dart';

class OrderNotificationScreen extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const OrderNotificationScreen({
    super.key,
    required this.order,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black54,
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.local_taxi,
                    color: AppColors.primary,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Новый заказ',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          order.orderNumber,
                          style: TextStyle(
                            fontSize: 14,
                            color: const Color(0xFF264b47),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildInfoRow(Icons.person, 'Клиент', order.clientName),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.phone, 'Телефон', order.clientPhone),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.location_on, 'Откуда', order.pickupAddress),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.flag, 'Куда', order.destinationAddress),
              if (order.notes != null && order.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildInfoRow(Icons.note, 'Примечания', order.notes!),
              ],
              const SizedBox(height: 8),
              _buildInfoRow(Icons.attach_money, 'Сумма', '${order.price} сом'),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onDecline,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Отклонить'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onAccept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Принять'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: const Color(0xFF264b47),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 14),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                TextSpan(
                  text: value,
                  style: TextStyle(
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
