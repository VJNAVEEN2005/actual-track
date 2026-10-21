import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/sync/sync_engine.dart';
import 'core/theme/app_theme.dart';
import 'data/local/db_helper.dart';
import 'presentation/widgets/responsive_scaffold.dart';
import 'providers/app_provider.dart';
import 'providers/navigation_provider.dart';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    FlutterError.onError = (FlutterErrorDetails details) {
      File('d:/project/Expence Tracker/flutter_error.log').writeAsStringSync(
        '${details.exceptionAsString()}\n${details.stack}\n',
        mode: FileMode.append,
      );
    };

    DbHelper.initializeFfi();

    runApp(const ActualExpenseApp());
  }, (error, stack) {
    File('d:/project/Expence Tracker/crash.log').writeAsStringSync(
      '$error\n$stack\n',
      mode: FileMode.append,
    );
  });
}

class ActualExpenseApp extends StatelessWidget {
  const ActualExpenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => AppProvider()..init()),
        ChangeNotifierProvider.value(value: SyncEngine.instance..init()),
      ],
      child: MaterialApp(
        title: 'Actual Track - Expense & Budget',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const ResponsiveScaffold(),
      ),
    );
  }
}
