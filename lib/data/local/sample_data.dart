import 'package:flutter/material.dart';
import '../models/account_model.dart';
import '../models/category_model.dart';
import '../models/schedule_model.dart';
import '../models/transaction_model.dart';

class SampleData {
  static List<AccountModel> get accounts => [
        AccountModel(
          id: 'acc_salary',
          name: 'HDFC Salary Checking',
          type: 'checking',
          balance: 65400.00,
          colorValue: Colors.blue.toARGB32(),
          iconCode: Icons.account_balance_outlined.codePoint,
        ),
        AccountModel(
          id: 'acc_savings',
          name: 'SBI High-Yield Savings',
          type: 'savings',
          balance: 145000.00,
          colorValue: Colors.green.toARGB32(),
          iconCode: Icons.savings_outlined.codePoint,
        ),
        AccountModel(
          id: 'acc_invest',
          name: 'Zerodha / Mutual Funds',
          type: 'investment',
          balance: 84500.00,
          colorValue: Colors.purple.toARGB32(),
          iconCode: Icons.trending_up_outlined.codePoint,
        ),
        AccountModel(
          id: 'acc_cash',
          name: 'Cash Wallet',
          type: 'cash',
          balance: 3200.00,
          colorValue: Colors.orange.toARGB32(),
          iconCode: Icons.wallet_outlined.codePoint,
        ),
      ];

  static List<CategoryModel> get categories => [
        // Essentials
        CategoryModel(
          id: 'cat_rent',
          groupName: 'Essentials',
          name: 'House Rent / EMI',
          budgeted: 25000.00,
          spent: 25000.00,
          colorValue: Colors.indigo.toARGB32(),
          iconCode: Icons.home_outlined.codePoint,
        ),
        CategoryModel(
          id: 'cat_groceries',
          groupName: 'Essentials',
          name: 'Groceries & Household',
          budgeted: 12000.00,
          spent: 8450.00,
          colorValue: Colors.teal.toARGB32(),
          iconCode: Icons.shopping_basket_outlined.codePoint,
        ),
        CategoryModel(
          id: 'cat_utilities',
          groupName: 'Essentials',
          name: 'Electricity, Gas & WiFi',
          budgeted: 4500.00,
          spent: 3200.00,
          colorValue: Colors.blueGrey.toARGB32(),
          iconCode: Icons.bolt_outlined.codePoint,
        ),
        CategoryModel(
          id: 'cat_fuel',
          groupName: 'Essentials',
          name: 'Fuel & Commute',
          budgeted: 6000.00,
          spent: 4100.00,
          colorValue: Colors.deepOrange.toARGB32(),
          iconCode: Icons.directions_car_outlined.codePoint,
        ),

        // Lifestyle
        CategoryModel(
          id: 'cat_dining',
          groupName: 'Lifestyle',
          name: 'Dining & Swiggy/Zomato',
          budgeted: 7000.00,
          spent: 4850.00,
          colorValue: Colors.amber.toARGB32(),
          iconCode: Icons.restaurant_outlined.codePoint,
        ),
        CategoryModel(
          id: 'cat_subs',
          groupName: 'Lifestyle',
          name: 'OTT & Subscriptions',
          budgeted: 2500.00,
          spent: 1499.00,
          colorValue: Colors.cyan.toARGB32(),
          iconCode: Icons.devices_outlined.codePoint,
        ),
        CategoryModel(
          id: 'cat_shopping',
          groupName: 'Lifestyle',
          name: 'Shopping & Apparel',
          budgeted: 8000.00,
          spent: 3500.00,
          colorValue: Colors.pink.toARGB32(),
          iconCode: Icons.shopping_bag_outlined.codePoint,
        ),

        // Health & Wellness
        CategoryModel(
          id: 'cat_health',
          groupName: 'Health & Wellness',
          name: 'Medical & Pharmacy',
          budgeted: 3000.00,
          spent: 1200.00,
          colorValue: Colors.redAccent.toARGB32(),
          iconCode: Icons.medical_services_outlined.codePoint,
        ),
        CategoryModel(
          id: 'cat_gym',
          groupName: 'Health & Wellness',
          name: 'Gym & Fitness',
          budgeted: 2500.00,
          spent: 2500.00,
          colorValue: Colors.deepPurple.toARGB32(),
          iconCode: Icons.fitness_center_outlined.codePoint,
        ),

        // Savings & Investments
        CategoryModel(
          id: 'cat_sip',
          groupName: 'Savings & Goals',
          name: 'SIP / Mutual Funds',
          budgeted: 15000.00,
          spent: 15000.00,
          colorValue: Colors.green.toARGB32(),
          iconCode: Icons.trending_up_outlined.codePoint,
        ),
        CategoryModel(
          id: 'cat_travel',
          groupName: 'Savings & Goals',
          name: 'Vacation & Travel Fund',
          budgeted: 10000.00,
          spent: 4000.00,
          colorValue: Colors.lightBlue.toARGB32(),
          iconCode: Icons.flight_takeoff_outlined.codePoint,
        ),
      ];

  static List<TransactionModel> get transactions {
    final now = DateTime.now();
    return [
      TransactionModel(
        id: 'tx_1',
        date: now.subtract(const Duration(hours: 3)),
        payee: 'Swiggy Gourmet Feast',
        amount: 1240.00,
        accountId: 'acc_salary',
        categoryId: 'cat_dining',
        notes: 'Weekend dinner with family',
        isIncome: false,
      ),
      TransactionModel(
        id: 'tx_2',
        date: now.subtract(const Duration(days: 1)),
        payee: 'Nature Basket Supermarket',
        amount: 3450.00,
        accountId: 'acc_salary',
        categoryId: 'cat_groceries',
        notes: 'Monthly grocery staples',
        isIncome: false,
      ),
      TransactionModel(
        id: 'tx_3',
        date: now.subtract(const Duration(days: 2)),
        payee: 'TechCorp India Monthly Salary',
        amount: 95000.00,
        accountId: 'acc_salary',
        categoryId: null,
        notes: 'Direct corporate payroll credit',
        isIncome: true,
      ),
      TransactionModel(
        id: 'tx_4',
        date: now.subtract(const Duration(days: 3)),
        payee: 'HPCL Petrol Pump Fuel',
        amount: 2200.00,
        accountId: 'acc_salary',
        categoryId: 'cat_fuel',
        notes: 'Car tank refill',
        isIncome: false,
      ),
      TransactionModel(
        id: 'tx_5',
        date: now.subtract(const Duration(days: 4)),
        payee: 'Consulting Client Fee',
        amount: 35000.00,
        accountId: 'acc_savings',
        categoryId: null,
        notes: 'Architectural design milestone payout',
        isIncome: true,
      ),
      TransactionModel(
        id: 'tx_6',
        date: now.subtract(const Duration(days: 5)),
        payee: 'Zerodha Index Fund SIP',
        amount: 15000.00,
        accountId: 'acc_salary',
        categoryId: 'cat_sip',
        notes: 'Nifty 50 automated recurring investment',
        isIncome: false,
      ),
      TransactionModel(
        id: 'tx_7',
        date: now.subtract(const Duration(days: 6)),
        payee: 'Apartment Society Rent Transfer',
        amount: 25000.00,
        accountId: 'acc_salary',
        categoryId: 'cat_rent',
        notes: 'NEFT monthly house rent',
        isIncome: false,
      ),
      TransactionModel(
        id: 'tx_8',
        date: now.subtract(const Duration(days: 7)),
        payee: 'ACT Fibernet Broadband',
        amount: 1199.00,
        accountId: 'acc_salary',
        categoryId: 'cat_utilities',
        notes: 'High-speed home internet bill',
        isIncome: false,
      ),
    ];
  }

  static List<ScheduleModel> get schedules {
    final now = DateTime.now();
    return [
      ScheduleModel(
        id: 'sch_rent',
        name: 'House Rent & Maintenance',
        amount: 25000.00,
        accountId: 'acc_salary',
        categoryId: 'cat_rent',
        nextDate: DateTime(now.year, now.month + 1, 1),
        frequency: 'monthly',
        isIncome: false,
        isPaid: false,
      ),
      ScheduleModel(
        id: 'sch_sip',
        name: 'Nifty 50 Index Fund SIP',
        amount: 15000.00,
        accountId: 'acc_salary',
        categoryId: 'cat_sip',
        nextDate: DateTime(now.year, now.month, 10),
        frequency: 'monthly',
        isIncome: false,
        isPaid: true,
      ),
      ScheduleModel(
        id: 'sch_wifi',
        name: 'ACT Fibernet Fiber Broadband',
        amount: 1199.00,
        accountId: 'acc_salary',
        categoryId: 'cat_utilities',
        nextDate: DateTime(now.year, now.month, 25),
        frequency: 'monthly',
        isIncome: false,
        isPaid: false,
      ),
      ScheduleModel(
        id: 'sch_netflix',
        name: 'Netflix Premium 4K + Spotify',
        amount: 848.00,
        accountId: 'acc_salary',
        categoryId: 'cat_subs',
        nextDate: DateTime(now.year, now.month, 28),
        frequency: 'monthly',
        isIncome: false,
        isPaid: false,
      ),
      ScheduleModel(
        id: 'sch_salary',
        name: 'TechCorp India Monthly Salary',
        amount: 95000.00,
        accountId: 'acc_salary',
        categoryId: null,
        nextDate: DateTime(now.year, now.month, 30),
        frequency: 'monthly',
        isIncome: true,
        isPaid: false,
      ),
    ];
  }
}
