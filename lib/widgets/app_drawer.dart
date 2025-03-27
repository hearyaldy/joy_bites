import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../utils/constants.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;
    return Drawer(
      child: ListView(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(user?.userMetadata?['full_name'] ?? 'Guest'),
            accountEmail: Text(user?.email ?? 'No Email'),
            currentAccountPicture: CircleAvatar(
              backgroundImage: user?.userMetadata?['avatar_url'] != null &&
                      user!.userMetadata!['avatar_url'].toString().startsWith('http')
                  ? NetworkImage(user.userMetadata!['avatar_url'])
                  : AssetImage(user?.userMetadata?['avatar_url'] ?? 'assets/avatars/avatar_1.png')
                      as ImageProvider,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text("Home"),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          // Add additional drawer items here as needed.
        ],
      ),
    );
  }
}
