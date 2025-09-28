import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../styles/app_colors.dart';
import '../styles/app_text_styles.dart';
import '../styles/app_spacing.dart';
import '../widgets/custom_button.dart';

enum OrderWidgetState {
  newOrder,
  accepted,
  navigatingToA,
  arrivedAtA,
  navigatingToB,
  completed,
  insufficientBalance,
}

class OrderWidget extends StatefulWidget {
  final Map<String, dynamic> orderData;
  final OrderWidgetState state;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onArrivedAtClient;
  final VoidCallback? onStartTrip;
  final VoidCallback? onCompleted;
  final VoidCallback? onStartNavigationToA;
  final String? estimatedArrival;
  final String? currentStatus;
  final String? balanceErrorMessage;
  final double? requiredAmount;
  final double? currentBalance;

  const OrderWidget({
    super.key,
    required this.orderData,
    required this.state,
    this.onAccept,
    this.onReject,
    this.onArrivedAtClient,
    this.onStartTrip,
    this.onCompleted,
    this.onStartNavigationToA,
    this.estimatedArrival,
    this.currentStatus,
    this.balanceErrorMessage,
    this.requiredAmount,
    this.currentBalance,
  });

  @override
  State<OrderWidget> createState() => _OrderWidgetState();
}

class _OrderWidgetState extends State<OrderWidget> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _heightAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _heightAnimation = Tween<double>(
      begin: 0.0,
      end: 0.3,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final targetHeight = screenHeight * 0.3;

    return AnimatedBuilder(
      animation: _heightAnimation,
      builder: (context, child) {
        return Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            height: targetHeight,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: _buildContent(),
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDragHandle(),
          AppSpacing.verticalSpaceMedium,
          _buildOrderHeader(),
          AppSpacing.verticalSpaceMedium,
          _buildOrderDetails(),
          AppSpacing.verticalSpaceMedium,
          _buildClientInfo(),
          AppSpacing.verticalSpaceMedium,
          _buildRouteInfo(),
          AppSpacing.verticalSpaceMedium,
          _buildComment(),
          AppSpacing.verticalSpaceLarge,
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.divider,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildOrderHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Заказ №${widget.orderData['order_number'] ?? ''}',
                      style: AppTextStyles.h4.copyWith(
                        color: AppColors.surface,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    AppSpacing.verticalSpaceSmall,
                    Text(
                      _formatDate(widget.orderData['created_at']),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.surface.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${widget.orderData['price']?.toStringAsFixed(0) ?? '0'} сом',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.surface,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Детали заказа',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.normal,
            ),
          ),
          AppSpacing.verticalSpaceMedium,
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  icon: Icons.location_on,
                  iconColor: AppColors.success,
                  label: 'Откуда',
                  value: widget.orderData['pickup_address'] ?? '',
                ),
              ),
              AppSpacing.horizontalSpaceMedium,
              Expanded(
                child: _buildDetailItem(
                  icon: Icons.location_on,
                  iconColor: AppColors.error,
                  label: 'Куда',
                  value: widget.orderData['destination_address'] ?? '',
                ),
              ),
            ],
          ),
          AppSpacing.verticalSpaceMedium,
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  icon: Icons.straighten,
                  iconColor: AppColors.primary,
                  label: 'Расстояние',
                  value: '${widget.orderData['distance']?.toStringAsFixed(1) ?? '0.0'} км',
                ),
              ),
              AppSpacing.horizontalSpaceMedium,
              Expanded(
                child: _buildDetailItem(
                  icon: Icons.access_time,
                  iconColor: AppColors.primary,
                  label: 'Время',
                  value: '${widget.orderData['duration'] ?? 0} мин',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClientInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Информация о клиенте',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.normal,
            ),
          ),
          AppSpacing.verticalSpaceMedium,
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  icon: Icons.person,
                  iconColor: AppColors.primary,
                  label: 'Имя',
                  value: widget.orderData['client_name'] ?? '',
                ),
              ),
              AppSpacing.horizontalSpaceMedium,
              Expanded(
                child: _buildClickablePhoneItem(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClickablePhoneItem() {
    final phone = widget.orderData['client_phone'] ?? '';
    return GestureDetector(
      onTap: () => _makePhoneCall(phone),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.primaryWithOpacity05,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.phone,
              color: AppColors.primary,
              size: 16,
            ),
            AppSpacing.horizontalSpaceSmall,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Телефон',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  AppSpacing.verticalSpaceSmall,
                  Text(
                    phone,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.call,
              color: AppColors.primary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Маршрут',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.normal,
            ),
          ),
          AppSpacing.verticalSpaceMedium,
          Row(
            children: [
              Expanded(
                child: _buildRoutePoint(
                  color: AppColors.success,
                  label: 'Точка А',
                  address: widget.orderData['pickup_address'] ?? '',
                ),
              ),
              AppSpacing.horizontalSpaceMedium,
              Expanded(
                child: _buildRoutePoint(
                  color: AppColors.error,
                  label: 'Точка Б',
                  address: widget.orderData['destination_address'] ?? '',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComment() {
    final comment = widget.orderData['notes'];
    if (comment == null || comment.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Комментарий к заказу',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.normal,
            ),
          ),
          AppSpacing.verticalSpaceMedium,
          Text(
            comment,
            style: AppTextStyles.body.copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 16),
            AppSpacing.horizontalSpaceSmall,
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        AppSpacing.verticalSpaceSmall,
        Text(
          value,
          style: AppTextStyles.body.copyWith(
            color: AppColors.text,
            fontWeight: FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildRoutePoint({
    required Color color,
    required String label,
    required String address,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            AppSpacing.horizontalSpaceSmall,
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        AppSpacing.verticalSpaceSmall,
        Text(
          address,
          style: AppTextStyles.body.copyWith(
            color: AppColors.text,
            fontWeight: FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    switch (widget.state) {
      case OrderWidgetState.newOrder:
        return Column(
          children: [
            CustomButton(
              text: 'Принять заказ',
              onPressed: widget.onAccept,
              backgroundColor: AppColors.primary,
            ),
            AppSpacing.verticalSpaceSmall,
            CustomButton(
              text: 'Отклонить заказ',
              onPressed: widget.onReject,
              backgroundColor: AppColors.error,
            ),
          ],
        );
      
      case OrderWidgetState.accepted:
        return CustomButton(
          text: 'Начать навигацию к клиенту',
          onPressed: widget.onStartNavigationToA,
          backgroundColor: AppColors.primary,
        );
      
      case OrderWidgetState.navigatingToA:
        return CustomButton(
          text: 'Доехал до клиента',
          onPressed: widget.onArrivedAtClient,
          backgroundColor: AppColors.success,
        );
      
      case OrderWidgetState.arrivedAtA:
        return CustomButton(
          text: 'Начать поездку к точке Б',
          onPressed: widget.onStartTrip,
          backgroundColor: AppColors.success,
        );
      
      case OrderWidgetState.navigatingToB:
        return CustomButton(
          text: 'Отвез клиента',
          onPressed: widget.onCompleted,
          backgroundColor: AppColors.success,
        );
      
      case OrderWidgetState.completed:
        return CustomButton(
          text: 'Заказ завершен',
          onPressed: null,
          backgroundColor: AppColors.textSecondary,
        );
      
      case OrderWidgetState.insufficientBalance:
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Недостаточно средств',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.balanceErrorMessage ?? 'Недостаточно средств на балансе для принятия заказа',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                  if (widget.requiredAmount != null && widget.currentBalance != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Требуется:',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '${widget.requiredAmount!.toStringAsFixed(0)} сом',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Доступно:',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '${widget.currentBalance!.toStringAsFixed(0)} сом',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: 'Отклонить заказ',
              onPressed: widget.onReject,
              backgroundColor: AppColors.error,
            ),
          ],
        );
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    
    try {
      DateTime dateTime;
      if (date is String) {
        dateTime = DateTime.parse(date);
      } else if (date is DateTime) {
        dateTime = date;
      } else {
        return '';
      }
      
      return '${dateTime.day}.${dateTime.month}.${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) return;
    
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Не удалось совершить звонок на номер $phoneNumber'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при совершении звонка: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}