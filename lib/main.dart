import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/onboarding.dart';
import 'screens/shell.dart';
import 'store.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = AppStore();
  await store.load();
  runApp(DepensesApp(store: store));
}

class DepensesApp extends StatefulWidget {
  final AppStore store;
  const DepensesApp({super.key, required this.store});

  @override
  State<DepensesApp> createState() => _DepensesAppState();
}

class _DepensesAppState extends State<DepensesApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Au retour dans l'app : nouvelles échéances du jour, statistiques à jour.
    if (state == AppLifecycleState.resumed) {
      widget.store.materialize(save: false);
      widget.store.commit();
    }
  }

  @override
  void didChangePlatformBrightness() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return StoreScope(
      store: widget.store,
      child: ListenableBuilder(
        listenable: widget.store,
        builder: (context, _) {
          final s = widget.store.settings;
          final platformDark =
              WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
          final dark = s.themeMode == 'dark' || (s.themeMode == 'auto' && platformDark);
          final t = Tk.resolve(style: s.style, dark: dark, palette: s.palette);
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: t.graphite ? t.bg : t.card,
              systemNavigationBarIconBrightness: dark ? Brightness.light : Brightness.dark,
            ),
            child: MaterialApp(
              title: 'Dépenses',
              debugShowCheckedModeBanner: false,
              theme: t.material(),
              locale: const Locale('fr', 'FR'),
              supportedLocales: const [Locale('fr', 'FR')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              builder: (context, child) => TkScope(tk: t, child: child!),
              home: widget.store.onboarded ? const Shell() : const Onboarding(),
            ),
          );
        },
      ),
    );
  }
}
