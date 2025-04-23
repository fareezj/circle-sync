import 'package:circle_sync/features/account/account_page.dart';
import 'package:circle_sync/features/circles/circles_page.dart';
import 'package:circle_sync/screens/map_page.dart';
import 'package:circle_sync/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final mainPageControllerProvider = Provider<PageController>((ref) {
  final controller = PageController(initialPage: 0);
  ref.onDispose(() => controller.dispose());
  return controller;
});

final transferPageIndexProvider = StateProvider<int>((ref) => 0);

class MainPage extends ConsumerStatefulWidget {
  const MainPage({super.key});

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage> {
  int _selectedIndex = 1;

  void _onChangedTab(int index) {
    setState(() {
      _selectedIndex = index;
      ref.read(mainPageControllerProvider).jumpToPage(index);
    });
  }

  void navigateToTransfer(int pageIndex) {
    ref.read(transferPageIndexProvider.notifier).state = pageIndex;
    _onChangedTab(1);
  }

  List<Widget> _screenList(BuildContext context, WidgetRef ref) {
    return <Widget>[
      const MapPage(),
      const CirclesPage(),
      const AccountPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final pageController = ref.watch(mainPageControllerProvider);

    return Scaffold(
      body: PageView(
        controller: pageController,
        onPageChanged: _onChangedTab,
        children: _screenList(context, ref),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColors.white,
        type: BottomNavigationBarType.fixed,
        unselectedItemColor: AppColors.textSecondary,
        unselectedLabelStyle: const TextStyle(
          fontSize: 12.0,
          fontFamily: 'Montserrat',
          color: AppColors.textSecondary,
        ),
        selectedLabelStyle: const TextStyle(
          fontSize: 12.0,
          fontFamily: 'Montserrat',
          color: AppColors.primaryBlue,
        ),
        showUnselectedLabels: true,
        showSelectedLabels: true,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'contacts',
            backgroundColor: Colors.white,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'account',
            backgroundColor: Colors.white,
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueGrey,
        onTap: _onChangedTab,
      ),
    );
  }
}
