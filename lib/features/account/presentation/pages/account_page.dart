import 'package:circle_sync/features/account/presentation/providers/account_providers.dart';
import 'package:circle_sync/utils/app_colors.dart';
import 'package:circle_sync/widgets/text_widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AccountPage extends ConsumerStatefulWidget {
  const AccountPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _AccountPageState();
}

class _AccountPageState extends ConsumerState<AccountPage> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(accountNotifierProvider.notifier).loadAccountDetails();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pageState = ref.watch(accountNotifierProvider);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                if (pageState.isLoading) ...[
                  CircularProgressIndicator()
                ] else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 38),
                    child: CircleAvatar(
                      radius: 40.0,
                      backgroundColor: AppColors.primaryYellow,
                      child: TextWidgets.mainBold(
                          title: pageState.name.isNotEmpty
                              ? pageState.name.substring(0, 2).toUpperCase()
                              : '',
                          fontSize: 24.0),
                    ),
                  ),
                  TextWidgets.mainBold(title: pageState.name),
                  SizedBox(height: 16.0),
                  TextWidgets.mainBold(title: pageState.email),
                  SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/permissionSettings'),
                    child: TextWidgets.mainSemiBold(
                        title: 'App permission', color: AppColors.primaryBlue),
                  ),
                  SizedBox(height: 50.0),
                  IconButton(
                    icon: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.logout,
                          color: AppColors.errorRed,
                        ),
                        SizedBox(width: 8.0),
                        TextWidgets.mainBold(
                          title: 'Logout',
                          color: AppColors.errorRed,
                        )
                      ],
                    ),
                    onPressed: () {
                      FirebaseAuth.instance.signOut();
                      Navigator.popAndPushNamed(context, '/login');
                    },
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}
