import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../styles/app_colors.dart';
import '../../styles/app_text_styles.dart';
import '../../styles/app_spacing.dart';
import '../../services/balance_service.dart';
import '../../models/balance_models.dart';

class BalanceScreen extends StatefulWidget {
  const BalanceScreen({super.key});

  @override
  State<BalanceScreen> createState() => _BalanceScreenState();
}

class _BalanceScreenState extends State<BalanceScreen> {
  String _selectedFilter = 'За все время';
  BalanceData? _balanceData;
  TransactionList? _transactions;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Future.wait([
        _loadBalance(),
        _loadTransactions(),
      ]);
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка загрузки данных: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadBalance() async {
    final result = await BalanceService.instance.getDriverBalance();
    if (result['success'] && mounted) {
      setState(() {
        _balanceData = BalanceData.fromJson(result['data']);
      });
    } else if (mounted) {
      setState(() {
        _errorMessage = result['error'] ?? 'Ошибка загрузки баланса';
      });
    }
  }

  Future<void> _loadTransactions() async {
    String filter = 'all';
    if (_selectedFilter == 'Заказы за неделю') {
      filter = 'week';
    }

    final result = await BalanceService.instance.getDriverTransactions(filter: filter);
    if (result['success'] && mounted) {
      setState(() {
        _transactions = TransactionList.fromJson(result['data']);
      });
    } else if (mounted) {
      setState(() {
        _errorMessage = result['error'] ?? 'Ошибка загрузки транзакций';
      });
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(true),
        icon: const Icon(
          Icons.arrow_back_ios,
          color: AppColors.textPrimary,
        ),
      ),
      title: Text(
        'Баланс',
        style: AppTextStyles.h2,
      ),
      centerTitle: true,
      actions: [
        IconButton(
          onPressed: _showFilterBottomSheet,
          icon: const Icon(
            Icons.filter_list,
            color: AppColors.textPrimary,
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _errorMessage!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              _buildBalanceCard(),
              const SizedBox(height: AppSpacing.lg),
              _buildTransactionsList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    final balance = _balanceData?.currentBalance ?? 0.0;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '${balance.toStringAsFixed(0)} сом',
            style: GoogleFonts.montserrat(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          if (_balanceData != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Обновлено: ${_formatLastUpdated(_balanceData!.lastUpdated)}',
              style: AppTextStyles.caption,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    if (_transactions == null || _transactions!.transactions.isEmpty) {
      String message;
      switch (_selectedFilter) {
        case 'За все время':
          message = 'У вас нет транзакций за все время';
          break;
        case 'Заказы за неделю':
          message = 'У вас нет заказов за эту неделю';
          break;
        default:
          message = 'У вас нет транзакций за последнее время';
      }

      return Expanded(
        child: Center(
          child: Text(
            message,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        itemCount: _transactions!.transactions.length,
        itemBuilder: (context, index) {
          final transaction = _transactions!.transactions[index];
          return _buildTransactionItem(transaction);
        },
      ),
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getTransactionColor(transaction.type).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              _getTransactionIcon(transaction.type),
              color: _getTransactionColor(transaction.type),
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getTransactionTitle(transaction),
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  transaction.formattedDate,
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          if (transaction.type.toLowerCase() != 'topup' && transaction.type.toLowerCase() != 'пополнение')
            Text(
              transaction.formattedAmount,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: transaction.amount >= 0 ? AppColors.success : AppColors.error,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterBottomSheet() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppSpacing.borderRadius),
          topRight: Radius.circular(AppSpacing.borderRadius),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          _buildFilterOption('За все время', _selectedFilter == 'За все время'),
          const Divider(height: 1, color: AppColors.divider),
          _buildFilterOption('Заказы за неделю', _selectedFilter == 'Заказы за неделю'),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  Widget _buildFilterOption(String title, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = title;
        });
        _loadTransactions();
        Navigator.of(context).pop();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.bodyLarge,
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check,
                color: AppColors.textPrimary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFilterBottomSheet(),
    );
  }

  String _formatLastUpdated(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'только что';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} мин. назад';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ч. назад';
    } else {
      return '${difference.inDays} дн. назад';
    }
  }

  Color _getTransactionColor(String type) {
    switch (type.toLowerCase()) {
      case 'order':
      case 'заказ':
        return AppColors.primary;
      case 'topup':
      case 'пополнение':
        return AppColors.success;
      case 'withdrawal':
      case 'вывод':
        return AppColors.warning;
      case 'bonus':
      case 'бонус':
        return AppColors.secondary;
      case 'commission':
      case 'комиссия':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getTransactionIcon(String type) {
    switch (type.toLowerCase()) {
      case 'order':
      case 'заказ':
        return Icons.local_taxi;
      case 'topup':
      case 'пополнение':
        return Icons.add_circle;
      case 'withdrawal':
      case 'вывод':
        return Icons.remove_circle;
      case 'bonus':
      case 'бонус':
        return Icons.card_giftcard;
      case 'commission':
      case 'комиссия':
        return Icons.percent;
      default:
        return Icons.receipt;
    }
  }

  String _getTransactionTitle(Transaction transaction) {
    switch (transaction.type.toLowerCase()) {
      case 'topup':
      case 'пополнение':
        return 'Пополнение баланса: ${transaction.formattedAmount}';
      case 'order':
      case 'заказ':
        return 'Заказ #${transaction.orderId ?? transaction.id}';
      case 'commission':
      case 'комиссия':
        return 'Комиссия сервиса';
      case 'withdrawal':
      case 'вывод':
        return 'Вывод средств';
      case 'bonus':
      case 'бонус':
        return 'Бонус';
      default:
        return transaction.typeDisplayName;
    }
  }
}
