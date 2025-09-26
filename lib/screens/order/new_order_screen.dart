import 'package:flutter/material.dart';
import 'package:dgis_mobile_sdk_full/dgis.dart' as sdk;
import '../../styles/app_colors.dart';
import '../../styles/app_text_styles.dart';
import '../../styles/app_spacing.dart';
import '../../services/order_service.dart';
import '../../services/websocket_service.dart';
import '../../widgets/custom_button.dart';

class NewOrderScreen extends StatefulWidget {
  final Map<String, dynamic> orderData;

  const NewOrderScreen({
    Key? key,
    required this.orderData,
  }) : super(key: key);

  @override
  State<NewOrderScreen> createState() => _NewOrderScreenState();
}

class _NewOrderScreenState extends State<NewOrderScreen> {
  final OrderService _orderService = OrderService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _orderService.setCurrentOrder(widget.orderData);
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _acceptOrder() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _orderService.acceptOrder(widget.orderData['id']);
      
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/order_execution');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка принятия заказа: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _rejectOrder() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _orderService.rejectOrder(widget.orderData['id']);
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка отклонения заказа: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Новый заказ',
          style: AppTextStyles.h2.copyWith(color: AppColors.surface),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOrderHeader(),
              SizedBox(height: AppSpacing.lg),
              _buildOrderDetails(),
              SizedBox(height: AppSpacing.lg),
              _buildClientInfo(),
              SizedBox(height: AppSpacing.lg),
              _buildRouteInfo(),
              SizedBox(height: AppSpacing.lg),
              _buildNotes(),
              const Spacer(),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderHeader() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Заказ №${widget.orderData['order_number'] ?? widget.orderData['id']}',
                style: AppTextStyles.h3.copyWith(color: AppColors.surface),
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                widget.orderData['tariff'] ?? 'Не указан',
                style: AppTextStyles.body.copyWith(color: AppColors.surface.withOpacity(0.8)),
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.xs),
            ),
            child: Text(
              '${widget.orderData['price']?.toStringAsFixed(0) ?? '0'} сом',
              style: AppTextStyles.h4.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetails() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Детали заказа',
            style: AppTextStyles.h4.copyWith(color: AppColors.text),
          ),
          SizedBox(height: AppSpacing.md),
          _buildDetailRow(
            'Откуда',
            widget.orderData['pickup_address'] ?? 'Не указано',
            Icons.location_on,
          ),
          SizedBox(height: AppSpacing.sm),
          _buildDetailRow(
            'Куда',
            widget.orderData['destination_address'] ?? 'Не указано',
            Icons.location_on,
          ),
          SizedBox(height: AppSpacing.sm),
          _buildDetailRow(
            'Расстояние',
            '${widget.orderData['distance']?.toStringAsFixed(1) ?? '0'} км',
            Icons.straighten,
          ),
          SizedBox(height: AppSpacing.sm),
          _buildDetailRow(
            'Время',
            '${widget.orderData['duration'] ?? 0} мин',
            Icons.access_time,
          ),
        ],
      ),
    );
  }

  Widget _buildClientInfo() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Информация о клиенте',
            style: AppTextStyles.h4.copyWith(color: AppColors.text),
          ),
          SizedBox(height: AppSpacing.md),
          _buildDetailRow(
            'Имя',
            widget.orderData['client_name'] ?? 'Не указано',
            Icons.person,
          ),
          SizedBox(height: AppSpacing.sm),
          _buildDetailRow(
            'Телефон',
            widget.orderData['client_phone'] ?? 'Не указано',
            Icons.phone,
          ),
          SizedBox(height: AppSpacing.sm),
          _buildDetailRow(
            'Оплата',
            widget.orderData['payment_method'] ?? 'Не указано',
            Icons.payment,
          ),
        ],
      ),
    );
  }

  Widget _buildRouteInfo() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Маршрут',
            style: AppTextStyles.h4.copyWith(color: AppColors.text),
          ),
          SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Icon(Icons.circle, color: AppColors.success, size: 12),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  widget.orderData['pickup_address'] ?? 'Точка А',
                  style: AppTextStyles.body.copyWith(color: AppColors.text),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          Container(
            margin: EdgeInsets.only(left: 5),
            height: 20,
            width: 2,
            color: AppColors.border,
          ),
          SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(Icons.circle, color: AppColors.error, size: 12),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  widget.orderData['destination_address'] ?? 'Точка Б',
                  style: AppTextStyles.body.copyWith(color: AppColors.text),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotes() {
    final notes = widget.orderData['notes'];
    if (notes == null || notes.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Примечания',
            style: AppTextStyles.h4.copyWith(color: AppColors.text),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            notes,
            style: AppTextStyles.body.copyWith(color: AppColors.text),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        SizedBox(width: AppSpacing.sm),
        Text(
          '$label: ',
          style: AppTextStyles.body.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.body.copyWith(color: AppColors.text),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        CustomButton(
          text: 'Принять заказ',
          onPressed: _isLoading ? null : _acceptOrder,
          backgroundColor: AppColors.success,
          textColor: AppColors.surface,
          isLoading: _isLoading,
        ),
        SizedBox(height: AppSpacing.sm),
        CustomButton(
          text: 'Отклонить заказ',
          onPressed: _isLoading ? null : _rejectOrder,
          backgroundColor: AppColors.error,
          textColor: AppColors.surface,
          isLoading: _isLoading,
        ),
      ],
    );
  }
}
