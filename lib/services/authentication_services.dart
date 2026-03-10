import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../utilities/constants.dart';

class AuthenticationServices {

  Future<User?> signInWithEmailPassword(String email, String password) async {
    try {
      UserCredential result = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      User? user = result.user;
      return user;
    } catch (e) {
      String errorMessage = _extractErrorMessage(e.toString());
      Fluttertoast.showToast(
        msg: errorMessage,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: errorColor,
        textColor: secondaryColor,
        fontSize: 16.0
      );
      return null;
    }
  }

  Future<User?> registerWithEmailPassword(String email, String password, String username) async {
    try {
      String normalizedUsername = username.toLowerCase();

      bool isUsernameAvailable = await checkUsernameAvailability(normalizedUsername);
      if (!isUsernameAvailable) {
        throw 'Username is already taken';
      }

      UserCredential result = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
      User? user = result.user;

      await addUserData(user!.uid, username, normalizedUsername);
      return user;
    } catch (e) {
      String errorMessage = _extractErrorMessage(e.toString());
      Fluttertoast.showToast(
        msg: errorMessage,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        backgroundColor: errorColor,
        textColor: secondaryColor,
        fontSize: 16.0
      );
      return null;
    }
  }

  String _extractErrorMessage(String? message) {
    if (message == null) return 'An unknown error occurred';
    final RegExp regex = RegExp(r'\[(.*?)\]');
    return message.replaceAll(regex, '').trim();
  }

  Future<void> addUserData(String uid, String username, String normalizedUsername) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'pfp' : 'img/default-pfp.jpg',
        'username': username,
        'normalizedUsername': normalizedUsername,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('users').doc(uid).collection('likes').doc('0').set({});
    } catch (e) {
      return;
    }
  }

  Future<bool> checkUsernameAvailability(String normalizedUsername) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('normalizedUsername', isEqualTo: normalizedUsername)
          .get();
 
      return querySnapshot.docs.isEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      return await FirebaseAuth.instance.signOut();
    } catch (e) {
      return;
    }
  }
}