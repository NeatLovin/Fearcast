import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:convert';

class FirestoreServices {
  Future<String?> getCurrentUid() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      return user!.uid;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchUserData() async {
    try {
      final String? currentUid = await getCurrentUid();

      final DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        if (data.isNotEmpty) {
          return data;
        }
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<String?> fetchUsername() async {
    try {
      final Map<String, dynamic>? userData = await fetchUserData();
      return userData?['username'] as String?;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, String?>?> fetchUsernameById(String userId) async {
    try {
      final DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        return {
          'username': data['username'] as String?,
          'pfp': data['pfp'] as String?
        };
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<List<String>?> fetchUserLikes() async {
    try {
      final String? currentUid = await getCurrentUid();
      final QuerySnapshot likesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUid)
          .collection('likes')
          .get();

      if (likesSnapshot.docs.isNotEmpty) {
        return likesSnapshot.docs.map((doc) => doc.id).toList();
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<void> likeMovie(int movieId) async {
    try {
      final String? currentUid = await getCurrentUid();
      if (currentUid != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUid)
            .collection('likes')
            .doc(movieId.toString())
            .set({});
      }
    } catch (e) {
      return;
    }
  }

  Future<void> dislikeMovie(int movieId) async {
    try {
      final String? currentUid = await getCurrentUid();
      if (currentUid != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUid)
            .collection('likes')
            .doc(movieId.toString())
            .delete();
      }
    } catch (e) {
      return;
    }
  }

  Widget buildProfilePicture(String? base64Image, double size) {
    if (base64Image == null) {
      return CircleAvatar(
        radius: size,
        backgroundImage: const AssetImage('img/default-pfp.jpg'),
      );
    }

    try {
      Uint8List imageBytes = base64Decode(base64Image);
      return CircleAvatar(
        radius: size,
        backgroundImage: MemoryImage(imageBytes),
      );
    } catch (e) {
      return CircleAvatar(
        radius: size,
        backgroundImage: const AssetImage('img/default-pfp.jpg'),
      );
    }
  }

  Future<void> updateProfilePicture(String base64Image) async {
    final String? currentUid = await getCurrentUid();

    await FirebaseFirestore.instance.collection('users').doc(currentUid).update({
      'pfp': base64Image,
    });
  }
}
