import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'popular_page.dart';
import '../services/authentication_services.dart';
import '../utilities/constants.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;

  void _toggleLoading() {
    setState(() {
      _isLoading = !_isLoading;
    });
  }

  Future<void> _register() async {
    String email = emailController.text;
    String username = usernameController.text;
    String password = passwordController.text;

    if (email.isEmpty || username.isEmpty || password.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Please fill in all fields',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: errorColor,
        textColor: secondaryColor,
        fontSize: 16.0,
      );
      return;
    }

    _toggleLoading();

    try {
      User? user = await AuthenticationServices().registerWithEmailPassword(
        email,
        password,
        username,
      );
      if (user != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PopularPage()),
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: e.toString(),
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: errorColor,
        textColor: secondaryColor,
        fontSize: 16.0,
      );
    } finally {
      _toggleLoading();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('img/auth-background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Card(
            color: Colors.black87,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: BorderSide(color: primaryColor, width: 2),
            ),
            elevation: 10,
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 48, bottom: 48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations.of(context)!.joinTheFear,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: emailController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.email,
                      labelStyle: TextStyle(color: errorColor),
                      filled: true,
                      fillColor: transparentColor,
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: errorColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: errorColor),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: usernameController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.username,
                      labelStyle: TextStyle(color: errorColor),
                      filled: true,
                      fillColor: transparentColor,
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: errorColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: errorColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.password,
                      labelStyle: TextStyle(color: errorColor),
                      filled: true,
                      fillColor: transparentColor,
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: errorColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: errorColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(300, 60),
                      backgroundColor: primaryColor,
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : Text(
                            AppLocalizations.of(context)!.register,
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
