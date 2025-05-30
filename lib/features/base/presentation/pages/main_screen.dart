import 'package:circle_sync/features/account/presentation/pages/account_page.dart';
import 'package:circle_sync/features/map/presentation/pages/map_page.dart';
import 'package:circle_sync/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MainPage extends ConsumerStatefulWidget {
  const MainPage({super.key});

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage> {
  late final PageController _pageController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onChangedTab(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onChangedTab,
        children: const [
          MapPage(),
          AccountPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColors.white,
        type: BottomNavigationBarType.fixed,
        unselectedItemColor: AppColors.textSecondary,
        selectedItemColor: Colors.blueGrey,
        showUnselectedLabels: true,
        showSelectedLabels: true,
        currentIndex: _selectedIndex,
        onTap: _onChangedTab,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'account',
          ),
        ],
      ),
    );
  }
}
