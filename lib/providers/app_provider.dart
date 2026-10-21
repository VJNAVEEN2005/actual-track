import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../data/local/db_helper.dart';
import '../data/models/account_model.dart';
import '../data/models/category_model.dart';
import '../data/models/schedule_model.dart';
import '../data/models/transaction_model.dart';
import '../data/repositories/expense_repository.dart';

class AppProvider extends ChangeNotifier {
  final ExpenseRepository _repository = ExpenseRepository();
  final Uuid _uuid = const Uuid();

  bool _isLoading = true;
  List<AccountModel> _accounts = [];
  List<CategoryModel> _categories = [];
  List<TransactionModel> _transactions = [];
  List<ScheduleModel> _schedules = [];

  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _selectedCalendarDay = DateTime.now();

  String _searchQuery = '';
  String? _selectedCategoryFilter;

  bool get isLoading => _isLoading;
  List<AccountModel> get accounts => _accounts;
  List<CategoryModel> get categories => _categories;
  List<TransactionModel> get transactions => _transactions;
  List<ScheduleModel> get schedules => _schedules;

  DateTime get selectedMonth => _selectedMonth;
  DateTime get selectedCalendarDay => _selectedCalendarDay;
  String get searchQuery => _searchQuery;
  String? get selectedCategoryFilter => _selectedCategoryFilter;

  String _geminiApiKey = '';
  String _geminiModel = 'gemini-3.8-flash';
  bool _aiVoiceEnabled = true;

  String get geminiApiKey => _geminiApiKey;
  bool get hasGeminiKey => _geminiApiKey.trim().isNotEmpty;
  String get geminiModel => _geminiModel;
  bool get aiVoiceEnabled => _aiVoiceEnabled;

  // --- DERIVED METRICS FOR SELECTED MONTH ---
  // Spendable liquid accounts (Checking, Savings, Cash, Credit) - excludes investments!
  double get liquidNetWorth {
    return _accounts
        .where((acc) => acc.type != 'investment')
        .fold(0.0, (sum, acc) => sum + acc.balance);
  }

  // Investment Portfolio (Off-budget / Tracking assets: Stocks, Mutual Funds, Crypto)
  double get totalInvestments {
    return _accounts
        .where((acc) => acc.type == 'investment')
        .fold(0.0, (sum, acc) => sum + acc.balance);
  }

  // Combined Total Net Worth (Liquid + Investments)
  double get totalNetWorth {
    return liquidNetWorth + totalInvestments;
  }

  bool _isTransferTx(TransactionModel tx) {
    return tx.categoryId == null &&
        (tx.payee.startsWith('Transfer to:') ||
            tx.payee.startsWith('Transfer from:') ||
            tx.payee.startsWith('Market Value Adjustment'));
  }

  double get monthlyInflow {
    return _transactions
        .where((tx) =>
            tx.isIncome &&
            !_isTransferTx(tx) &&
            tx.date.year == _selectedMonth.year &&
            tx.date.month == _selectedMonth.month)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  double get monthlyOutflow {
    return _transactions
        .where((tx) =>
            !tx.isIncome &&
            !_isTransferTx(tx) &&
            tx.date.year == _selectedMonth.year &&
            tx.date.month == _selectedMonth.month)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  double get totalBudgeted {
    return _categories.fold(0.0, (sum, cat) => sum + cat.budgeted);
  }

  // Actual Budget Zero-Based: Available to Budget = Inflow - Budgeted
  double get availableToBudget {
    final available = monthlyInflow - totalBudgeted;
    return available >= 0 ? available : 0.0;
  }

  Map<String, double> get categorySpendingBreakdown {
    final Map<String, double> breakdown = {};
    for (final cat in _categories) {
      if (cat.spent > 0) {
        breakdown[cat.name] = cat.spent;
      }
    }
    return breakdown;
  }

  List<TransactionModel> get filteredTransactions {
    return _transactions.where((tx) {
      final matchesMonth = tx.date.year == _selectedMonth.year &&
          tx.date.month == _selectedMonth.month;

      final matchesSearch = _searchQuery.isEmpty ||
          tx.payee.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (tx.notes?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

      final matchesCategory = _selectedCategoryFilter == null ||
          tx.categoryId == _selectedCategoryFilter;

      return matchesMonth && matchesSearch && matchesCategory;
    }).toList();
  }

  // --- CHART HELPERS ---
  List<double> get cumulativeWeeklyInflow {
    final weeks = [0.0, 0.0, 0.0, 0.0, 0.0];
    for (final tx in _transactions) {
      if (tx.date.year == _selectedMonth.year && tx.date.month == _selectedMonth.month) {
        if (tx.isIncome) {
          final day = tx.date.day;
          final w = (day - 1) ~/ 7;
          final idx = w.clamp(0, 4);
          weeks[idx] += tx.amount;
        }
      }
    }
    final result = <double>[];
    double running = 0.0;
    for (final val in weeks) {
      running += val;
      result.add(running);
    }
    return result;
  }

  List<double> get cumulativeWeeklyOutflow {
    final weeks = [0.0, 0.0, 0.0, 0.0, 0.0];
    for (final tx in _transactions) {
      if (tx.date.year == _selectedMonth.year && tx.date.month == _selectedMonth.month) {
        if (!tx.isIncome) {
          final day = tx.date.day;
          final w = (day - 1) ~/ 7;
          final idx = w.clamp(0, 4);
          weeks[idx] += tx.amount;
        }
      }
    }
    final result = <double>[];
    double running = 0.0;
    for (final val in weeks) {
      running += val;
      result.add(running);
    }
    return result;
  }

  // --- CALENDAR HELPERS ---
  List<TransactionModel> getTransactionsForDay(DateTime day) {
    return _transactions.where((tx) =>
        tx.date.year == day.year &&
        tx.date.month == day.month &&
        tx.date.day == day.day).toList();
  }

  List<ScheduleModel> getSchedulesForDay(DateTime day) {
    return _schedules.where((s) =>
        s.nextDate.year == day.year &&
        s.nextDate.month == day.month &&
        s.nextDate.day == day.day).toList();
  }

  bool hasActivityOnDay(DateTime day) {
    return getTransactionsForDay(day).isNotEmpty ||
        getSchedulesForDay(day).isNotEmpty;
  }

  void selectCalendarDay(DateTime day) {
    _selectedCalendarDay = day;
    notifyListeners();
  }

  // Month navigation
  void nextMonth() {
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
    notifyListeners();
  }

  void prevMonth() {
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
    notifyListeners();
  }

  void setMonth(DateTime month) {
    _selectedMonth = DateTime(month.year, month.month, 1);
    notifyListeners();
  }

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    _geminiApiKey = (await DbHelper.instance.getSetting('gemini_api_key')) ?? '';
    _geminiModel = (await DbHelper.instance.getSetting('gemini_model')) ?? 'gemini-3.8-flash';
    final voiceVal = await DbHelper.instance.getSetting('ai_voice_enabled');
    _aiVoiceEnabled = voiceVal == null ? true : voiceVal == 'true';

    await _repository.seedIfEmpty();
    await refreshData();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> setGeminiApiKey(String? key) async {
    _geminiApiKey = (key ?? '').trim();
    await DbHelper.instance.setSetting('gemini_api_key', _geminiApiKey);
    notifyListeners();
  }

  Future<void> setGeminiModel(String model) async {
    _geminiModel = model;
    await DbHelper.instance.setSetting('gemini_model', model);
    notifyListeners();
  }

  Future<void> setAiVoiceEnabled(bool enabled) async {
    _aiVoiceEnabled = enabled;
    await DbHelper.instance.setSetting('ai_voice_enabled', enabled ? 'true' : 'false');
    notifyListeners();
  }

  Future<void> refreshData() async {
    _accounts = await _repository.getAccounts();
    _categories = await _repository.getCategories();
    _transactions = await _repository.getTransactions();
    _schedules = await _repository.getSchedules();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategoryFilter(String? categoryId) {
    _selectedCategoryFilter = categoryId;
    notifyListeners();
  }

  // --- ACTIONS ---
  Future<void> addTransaction({
    required String payee,
    required double amount,
    required String accountId,
    String? categoryId,
    String? notes,
    required bool isIncome,
    DateTime? date,
  }) async {
    final newTx = TransactionModel(
      id: _uuid.v4(),
      date: date ?? DateTime.now(),
      payee: payee,
      amount: amount,
      accountId: accountId,
      categoryId: categoryId,
      notes: notes,
      isIncome: isIncome,
    );

    await _repository.insertTransaction(newTx);
    await refreshData();
  }

  Future<void> updateTransaction({
    required TransactionModel oldTx,
    required String payee,
    required double amount,
    required String accountId,
    String? categoryId,
    String? notes,
    required bool isIncome,
    required DateTime date,
  }) async {
    final updatedTx = TransactionModel(
      id: oldTx.id,
      date: date,
      payee: payee,
      amount: amount,
      accountId: accountId,
      categoryId: categoryId,
      notes: notes,
      isIncome: isIncome,
      isCleared: oldTx.isCleared,
    );

    await _repository.updateTransaction(oldTx, updatedTx);
    await refreshData();
  }

  Future<void> deleteTransaction(TransactionModel tx) async {
    await _repository.deleteTransaction(tx);
    await refreshData();
  }

  Future<void> toggleCleared(TransactionModel tx) async {
    await _repository.toggleTransactionCleared(tx.id, !tx.isCleared);
    await refreshData();
  }

  Future<void> addAccount({
    required String name,
    required String type,
    required double balance,
    required int colorValue,
    required int iconCode,
  }) async {
    final newAcc = AccountModel(
      id: _uuid.v4(),
      name: name,
      type: type,
      balance: balance,
      colorValue: colorValue,
      iconCode: iconCode,
    );

    await _repository.insertAccount(newAcc);
    await refreshData();
  }

  Future<void> updateAccountBalance(String accountId, double newBalance, {String? notes}) async {
    final index = _accounts.indexWhere((a) => a.id == accountId);
    if (index != -1) {
      final oldAcc = _accounts[index];
      final diff = newBalance - oldAcc.balance;
      final updated = oldAcc.copyWith(balance: newBalance);
      await _repository.updateAccount(updated);

      if (diff.abs() > 0.01) {
        final isGain = diff > 0;
        await _repository.insertTransaction(
          TransactionModel(
            id: _uuid.v4(),
            date: DateTime.now(),
            payee: 'Market Value Adjustment (${oldAcc.name})',
            amount: diff.abs(),
            accountId: accountId,
            categoryId: null,
            notes: notes ?? (isGain ? 'Market Appreciation / Gain' : 'Market Depreciation / Loss'),
            isIncome: isGain,
            isCleared: true,
          ),
        );
      }
      await refreshData();
    }
  }

  Future<void> transferBetweenAccounts({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    String? notes,
    DateTime? date,
  }) async {
    final fromAcc = getAccountById(fromAccountId);
    final toAcc = getAccountById(toAccountId);
    if (fromAcc == null || toAcc == null) return;

    final txDate = date ?? DateTime.now();

    final outflowTx = TransactionModel(
      id: _uuid.v4(),
      date: txDate,
      payee: 'Transfer to: ${toAcc.name}',
      amount: amount,
      accountId: fromAccountId,
      categoryId: null,
      notes: notes ?? 'Self Transfer',
      isIncome: false,
      isCleared: true,
    );

    final inflowTx = TransactionModel(
      id: _uuid.v4(),
      date: txDate,
      payee: 'Transfer from: ${fromAcc.name}',
      amount: amount,
      accountId: toAccountId,
      categoryId: null,
      notes: notes ?? 'Self Transfer',
      isIncome: true,
      isCleared: true,
    );

    await _repository.insertTransaction(outflowTx);
    await _repository.insertTransaction(inflowTx);
    await refreshData();
  }

  Future<void> addCategory({
    required String groupName,
    required String name,
    required double budgeted,
    required int colorValue,
    required int iconCode,
  }) async {
    final newCat = CategoryModel(
      id: _uuid.v4(),
      groupName: groupName,
      name: name,
      budgeted: budgeted,
      spent: 0.0,
      colorValue: colorValue,
      iconCode: iconCode,
    );

    await _repository.insertCategory(newCat);
    await refreshData();
  }

  Future<void> updateCategoryBudget(String categoryId, double newBudget) async {
    final index = _categories.indexWhere((c) => c.id == categoryId);
    if (index != -1) {
      final updated = _categories[index].copyWith(budgeted: newBudget);
      await _repository.updateCategory(updated);
      await refreshData();
    }
  }

  Future<void> updateCategory(CategoryModel updated) async {
    await _repository.updateCategory(updated);
    await refreshData();
  }

  Future<void> deleteCategory(String categoryId) async {
    await _repository.deleteCategory(categoryId);
    await refreshData();
  }

  // Schedules
  Future<void> addSchedule({
    required String name,
    required double amount,
    required String accountId,
    String? categoryId,
    required DateTime nextDate,
    required String frequency,
    required bool isIncome,
  }) async {
    final newSch = ScheduleModel(
      id: _uuid.v4(),
      name: name,
      amount: amount,
      accountId: accountId,
      categoryId: categoryId,
      nextDate: nextDate,
      frequency: frequency,
      isIncome: isIncome,
      isPaid: false,
    );

    await _repository.insertSchedule(newSch);
    await refreshData();
  }

  Future<void> deleteSchedule(String id) async {
    await _repository.deleteSchedule(id);
    await refreshData();
  }

  Future<void> postScheduleToLedger(ScheduleModel schedule) async {
    await addTransaction(
      payee: schedule.name,
      amount: schedule.amount,
      accountId: schedule.accountId,
      categoryId: schedule.categoryId,
      notes: 'Scheduled: ${schedule.frequency} auto-posted',
      isIncome: schedule.isIncome,
      date: schedule.nextDate,
    );

    // Advance next date by frequency
    DateTime next;
    if (schedule.frequency == 'monthly') {
      next = DateTime(schedule.nextDate.year, schedule.nextDate.month + 1, schedule.nextDate.day);
    } else if (schedule.frequency == 'weekly') {
      next = schedule.nextDate.add(const Duration(days: 7));
    } else if (schedule.frequency == 'yearly') {
      next = DateTime(schedule.nextDate.year + 1, schedule.nextDate.month, schedule.nextDate.day);
    } else {
      next = schedule.nextDate.add(const Duration(days: 14));
    }

    await _repository.updateSchedule(schedule.copyWith(
      nextDate: next,
      isPaid: true,
    ));
    await refreshData();
  }

  Future<void> clearAllData() async {
    await _repository.clearAllData();
    await refreshData();
  }

  Future<void> loadSampleData() async {
    await _repository.loadSampleData();
    await refreshData();
  }

  Future<String> exportBackup() async {
    return await _repository.exportBackupJson();
  }

  Future<void> importBackup(String jsonString) async {
    await _repository.importBackupJson(jsonString);
    await refreshData();
  }

  AccountModel? getAccountById(String id) {
    try {
      return _accounts.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  CategoryModel? getCategoryById(String? id) {
    if (id == null) return null;
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}
