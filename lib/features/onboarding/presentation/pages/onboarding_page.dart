import 'package:circle_sync/utils/app_colors.dart';
import 'package:circle_sync/widgets/text_widgets.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

class OnboardingPage extends StatefulWidget {
  final VoidCallback onFinish;
  const OnboardingPage({super.key, required this.onFinish});

  @override
  _OnboardingPageState createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<_OnboardingPage> _pages = [
    _OnboardingPage(
      icon: Icons.safety_divider_outlined,
      title: 'Stay Close, Even When Apart',
      description:
          'Circle Sync lets you share your live location with trusted friends and family—so you always know everyone’s safe.',
    ),
    _OnboardingPage(
      icon: Icons.group_add,
      title: 'Create & Join Circles',
      description:
          'Set up private groups for your family, friends, or teammates. Only those you invite can see your circle.',
    ),
    _OnboardingPage(
      icon: Icons.notifications,
      title: 'Get Notified on Arrivals',
      description:
          'Define zones like “Home” or “Work”—we’ll alert everyone when someone enters or leaves.',
    ),
    _OnboardingPage(
      icon: Icons.play_arrow,
      title: 'Background Tracking',
      description:
          'With “Always Allow,” Circle Sync can keep sharing your location in the background—so your circle stays in sync without you having to reopen the app.',
    ),
    // _OnboardingPage(
    //   icon: Icons.warning,
    //   title: 'Instant Safety Alerts',
    //   description:
    //       'In emergencies, your circle can see your last known location—no delays, no manual check-ins.',
    // ),
    _OnboardingPage(
      icon: Icons.check_circle,
      title: 'Seamless Check-Ins',
      description:
          'Because location is always on, you never have to tap “Check In.” We’ll automatically update your circle when you move.',
    ),
    _OnboardingPage(
      icon: Icons.favorite,
      title: 'Peace of Mind for Everyone',
      description:
          'Your loved ones don’t need to keep asking “Where are you?”—Circle Sync tells them.',
    ),
    _OnboardingPage(
      icon: Icons.lock,
      title: 'Your Data, Your Rules',
      description:
          'You’re in full control—pause sharing anytime, delete location history, or leave a circle at any moment.',
    ),
    _OnboardingPage(
      icon: Icons.location_on,
      title: 'Enable Always Allow',
      description:
          'Let’s grant background location so Circle Sync can work its magic. Tap “Enable” and select “Always Allow” in the next screen.',
      isLast: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.babyBlueCard,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          page.icon,
                          size: 100,
                          color: AppColors.primaryBlue,
                        ),
                        const SizedBox(height: 32),
                        TextWidgets.mainBold(
                          title: page.title,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        TextWidgets.mainRegular(
                          title: page.description,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final isLast = _currentIndex == _pages.length - 1;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (!isLast)
            TextButton(
              onPressed: () {
                _pageController.jumpToPage(_pages.length - 1);
              },
              child: const Text('Skip'),
            ),
          Row(
            children: List.generate(
              _pages.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                width: _currentIndex == index ? 12 : 8,
                height: _currentIndex == index ? 12 : 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentIndex == index
                      ? Theme.of(context).primaryColor
                      : Colors.grey,
                ),
              ),
            ),
          ),
          isLast
              ? ElevatedButton(
                  onPressed: () async {
                    await _ensureAlwaysLocation();
                    widget.onFinish();
                  },
                  child: const Text('Enable Location'),
                )
              : ElevatedButton(
                  onPressed: () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: const Text('Next'),
                ),
        ],
      ),
    );
  }

  Future<bool> _ensureAlwaysLocation() async {
    // 1. Ensure services are enabled
    if (!await Geolocator.isLocationServiceEnabled()) {
      await Geolocator.openLocationSettings();
      return false;
    }
    // 2. Request WhenInUse
    var status = await Permission.locationWhenInUse.status;
    if (status != PermissionStatus.granted) {
      status = await Permission.locationWhenInUse.request();
      if (status != PermissionStatus.granted) {
        await openAppSettings();
        return false;
      }
    }
    // 3. Request Always
    status = await Permission.locationAlways.status;
    if (status != PermissionStatus.granted) {
      status = await Permission.locationAlways.request();
      if (status != PermissionStatus.granted) {
        await openAppSettings();
        return false;
      }
    }
    return true;
  }
}

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  final bool isLast;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    this.isLast = false,
  });
}
