import 'package:circle_sync/features/map/presentation/pages/widgets/add_circle_sheet.dart';
import 'package:circle_sync/features/map/presentation/pages/widgets/circle_list_sheet.dart';
import 'package:circle_sync/features/map/presentation/pages/widgets/join_circle_sheet.dart';
import 'package:circle_sync/models/circle_model.dart';
import 'package:flutter/material.dart';

final circleSheetNavKey = GlobalKey<NavigatorState>();

class CircleNavigationRouter extends StatelessWidget {
  final CircleSheetArgs circleListArgs;
  final AddCircleArgs addCircleArgs;
  final JoinCircleArgs joinCircleArgs;

  const CircleNavigationRouter({
    super.key,
    required this.circleListArgs,
    required this.addCircleArgs,
    required this.joinCircleArgs,
  });

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: circleSheetNavKey,
      onGenerateRoute: (RouteSettings settings) {
        Widget page;
        switch (settings.name) {
          case '/':
            page = CircleListSheet(args: circleListArgs);
            break;
          case '/add-circle':
            page = AddCircleSheet(args: addCircleArgs);
            break;
          case '/join-circle':
            page = JoinCircleSheet(args: joinCircleArgs);
            break;
          default:
            page = Center(child: Text('Unknown route: ${settings.name}'));
        }
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (ctx, anim, anim2) => page,
          transitionDuration: Duration(milliseconds: 0),
          transitionsBuilder: (_, anim, __, child) => SlideTransition(
            position: Tween(begin: Offset(1, 0), end: Offset.zero)
                .chain(CurveTween(curve: Curves.easeInOut))
                .animate(anim),
            child: child,
          ),
        );
      },
    );
  }
}

class CircleSheetArgs {
  final Function(CircleModel) onCircleTap;
  final List<CircleModel> circleList;

  CircleSheetArgs({required this.circleList, required this.onCircleTap});
}

class AddCircleArgs {
  final VoidCallback onAddedCircle;
  AddCircleArgs(this.onAddedCircle);
}

class JoinCircleArgs {
  final VoidCallback onJoinedCircle;
  JoinCircleArgs(this.onJoinedCircle);
}
