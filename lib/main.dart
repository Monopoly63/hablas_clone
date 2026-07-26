import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/native_bridge/virtual_engine_bridge.dart';
import 'features/app_picker/domain/app_picker_repository.dart';
import 'features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ─── 120fps: System UI Configuration ───────────────────────────────
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: AppTheme.oledBlack,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Enable smooth animations at high FPS
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ─── Initialize Hive for persistence ────────────────────────────────
  await Hive.initFlutter();

  runApp(const HablasVirtualStudio());
}

class HablasVirtualStudio extends StatelessWidget {
  const HablasVirtualStudio({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<VirtualEngineBridge>(create: (_) => VirtualEngineBridge()),
        RepositoryProvider<AppPickerRepository>(
          create: (ctx) => AppPickerRepository(engine: ctx.read<VirtualEngineBridge>()),
        ),
      ],
      child: BlocProvider(
        create: (ctx) => DashboardBloc(appPickerRepository: ctx.read<AppPickerRepository>()),
        child: MaterialApp(
          title: 'Hablas Clone',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.buildDarkTheme(),
          // 120fps: Reduce animation durations for snappier feel
          themeMode: ThemeMode.dark,
          home: const DashboardScreen(),
        ),
      ),
    );
  }
}
