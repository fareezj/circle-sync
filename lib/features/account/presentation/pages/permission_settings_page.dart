import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsSettingsPage extends StatefulWidget {
  const PermissionsSettingsPage({super.key});

  @override
  _PermissionsSettingsPageState createState() =>
      _PermissionsSettingsPageState();
}

class _PermissionsSettingsPageState extends State<PermissionsSettingsPage>
    with WidgetsBindingObserver {
  // 1. List out exactly the permissions your app cares about:
  final List<Permission> _trackedPermissions = [
    Permission.locationWhenInUse,
    Permission.locationAlways,
    Permission.notification, // Android 13+ & iOS
    // …add any other perms you request
  ];

  // 2. Keep a map of current statuses:
  Map<Permission, PermissionStatus> _statuses = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshStatuses();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 3. If the user flips back from Settings, re-query on resume:
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshStatuses();
    }
  }

  Future<void> _refreshStatuses() async {
    final statuses = <Permission, PermissionStatus>{};
    for (final perm in _trackedPermissions) {
      statuses[perm] = await perm.status;
    }
    setState(() => _statuses = statuses);
  }

  String _prettyName(Permission perm) {
    switch (perm) {
      case Permission.locationWhenInUse:
        return 'Location (In Use)';
      case Permission.locationAlways:
        return 'Location (Always)';
      case Permission.notification:
        return 'Notifications';
      default:
        return perm.toString().split('.').last;
    }
  }

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      appBar: AppBar(title: Text('App Permissions')),
      body: RefreshIndicator(
        onRefresh: _refreshStatuses,
        child: ListView.separated(
          physics: AlwaysScrollableScrollPhysics(),
          itemCount: _trackedPermissions.length,
          separatorBuilder: (_, __) => Divider(),
          itemBuilder: (_, i) {
            final perm = _trackedPermissions[i];
            final status = _statuses[perm] ?? PermissionStatus.denied;
            return ListTile(
              title: Text(_prettyName(perm)),
              subtitle: Text(status.toString().split('.').last),
              trailing: _buildActionButton(perm, status),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionButton(Permission perm, PermissionStatus status) {
    // If permanently denied, send them to Settings:
    if (status == PermissionStatus.permanentlyDenied ||
        status == PermissionStatus.restricted) {
      return TextButton(
        onPressed: openAppSettings,
        child: Text('Open Settings'),
      );
    }
    // Otherwise let them tap to (re-)request:
    return TextButton(
      onPressed: () async {
        final newStatus = await perm.request();
        setState(() => _statuses[perm] = newStatus);
      },
      child: Text(status.isGranted ? 'Granted' : 'Request'),
    );
  }
}
