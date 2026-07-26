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

  // ─── System UI Configuration ────────────────────────────────────────
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: AppTheme.oledBlack,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ─── Initialize Hive for local persistence ──────────────────────────
  await Hive.initFlutter();

  // ─── Launch App ─────────────────────────────────────────────────────
  runApp(const HablasVirtualStudio());
}

class HablasVirtualStudio extends StatelessWidget {
  const HablasVirtualStudio({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<VirtualEngineBridge>(
          create: (_) => VirtualEngineBridge(),
        ),
        RepositoryProvider<AppPickerRepository>(
          create: (context) => AppPickerRepository(
            engine: context.read<VirtualEngineBridge>(),
          ),
        ),
      ],
      child: BlocProvider(
        create: (context) => DashboardBloc(
          appPickerRepository: context.read<AppPickerRepository>(),
        ),
        child: MaterialApp(
          title: 'Hablas Virtual Studio',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.buildDarkTheme(),
          home: const DashboardScreen(),
        ),
      ),
    );
  }
}
