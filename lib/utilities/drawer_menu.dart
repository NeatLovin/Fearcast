import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../screens/home_page.dart';
import '../screens/popular_page.dart';
import '../screens/profile_page.dart';
import '../screens/search_page.dart';
import '../screens/settings_page.dart';
import '../screens/likes_page.dart';
import '../services/authentication_services.dart';
import '../services/firestore_services.dart';
import 'constants.dart';

class DrawerMenu extends StatefulWidget {
  const DrawerMenu({super.key});

  @override
  State<DrawerMenu> createState() => _DrawerMenuState();
}

class _DrawerMenuState extends State<DrawerMenu> {
  String? username;
  String? pfp;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    FirestoreServices().fetchUserData().then((data) {
      if (data != null) {
        setState(() {
          username = data['username'];
          pfp = data['pfp'];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: const BoxDecoration(
              color: primaryColor,
            ),
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FirestoreServices().buildProfilePicture(pfp, 40),
                      Text(
                        username ?? 'User',
                        style: const TextStyle(
                          color: onPrimaryColor,
                          fontSize: 24,
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(
              Icons.home,
              size: 28,
            ),
            title: Text(
              localizations.popular,
              style: const TextStyle(fontSize: 18),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PopularPage()),
              );
            },
          ),
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(
              Icons.search,
              size: 28,
            ),
            title: Text(
              localizations.search,
              style: const TextStyle(fontSize: 18),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchPage()),
              );
            },
          ),
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(
              Icons.person,
              size: 28,
            ),
            title: Text(
              localizations.profile,
              style: const TextStyle(fontSize: 18),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(
              Icons.favorite,
              size: 28,
            ),
            title: Text(
              localizations.likes,
              style: const TextStyle(fontSize: 18),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LikesPage()),
              );
            },
          ),
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(
              Icons.settings,
              size: 28,
            ),
            title: Text(
              localizations.settings,
              style: const TextStyle(fontSize: 18),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(
              Icons.exit_to_app,
              color: errorColor,
              size: 28,
            ),
            title: Text(
              localizations.signOut,
              style: const TextStyle(
                color: errorColor,
                fontSize: 18,
              ),
            ),
            onTap: () async {
              await AuthenticationServices().signOut();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                );
              }
            },
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
