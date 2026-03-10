import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:flutter/gestures.dart';
import '../utilities/drawer_menu.dart';
import '../utilities/constants.dart';
import '../services/firestore_services.dart';
import '../services/jumpscare_services.dart';
import '../screens/movie_page.dart';
import '../services/api_services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? userId;
  String? username;
  String? pfp;
  String? createdAt;
  bool isLoading = true;
  bool isFetchingActivities = true;
  List<Map<String, dynamic>> activities = [];
  Map<int, String> movieTitles = {};

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser!.uid;
    FirestoreServices().fetchUserData().then((data) {
      if (data != null) {
        setState(() {
          username = data['username'];
          pfp = data['pfp'];
          createdAt = DateFormat('MMMM yyyy').format(data['createdAt'].toDate());
          isLoading = false;
        });
        fetchActivities(userId!).then((_) {
          setState(() {
            isFetchingActivities = false;
          });
        });
      } else {
        setState(() {
          isLoading = false;
          isFetchingActivities = false;
        });
      }
    }).catchError((error) {
      setState(() {
        isLoading = false;
        isFetchingActivities = false;
      });
    });
  }

  Future<void> fetchActivities(String uid) async {
    final fetchedActivities = await JumpscareServices().getUserActivities(uid);
    for (var activity in fetchedActivities) {
      int movieId = activity['movieId'];
      if (!movieTitles.containsKey(movieId)) {
        final movieDetails = await ApiServices().fetchMovieDetails(movieId, 'en-US');
        movieTitles[movieId] = movieDetails['title'] ?? '*$movieId*';
      }
    }
    setState(() {
      activities = fetchedActivities;
      isFetchingActivities = false;
    });
  }

  Future<void> _changeProfilePicture() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedImage = await picker.pickImage(source: ImageSource.gallery,);

    if (pickedImage != null) {
      final imageBytes = await pickedImage.readAsBytes();
      final encodedImage = base64Encode(imageBytes);

      try {
        await FirestoreServices().updateProfilePicture(encodedImage);
        setState(() {
          pfp = encodedImage;
        });
      } catch (error) {
        Fluttertoast.showToast(
          msg: "Error updating profile picture : $error",
          backgroundColor: errorColor,
          textColor: onPrimaryColor,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(username ?? AppLocalizations.of(context)!.profile),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      drawer: const DrawerMenu(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: _changeProfilePicture,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: errorColor,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: errorColor.withOpacity(0.3),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: FirestoreServices().buildProfilePicture(pfp, 80),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          username ?? AppLocalizations.of(context)!.unknownUser,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: onPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: errorColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                color: errorColor,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${AppLocalizations.of(context)!.joined} $createdAt',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: errorColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.local_activity, color: errorColor),
                            const SizedBox(width: 8),
                            Text(
                              '${AppLocalizations.of(context)!.activity} (${activities.length})',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: onPrimaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        isFetchingActivities
                            ? const Center(child: CircularProgressIndicator())
                            : activities.isEmpty
                                ? Center(
                                    child: Column(
                                      children: [
                                        Icon(Icons.movie_outlined, 
                                          size: 48, 
                                          color: onPrimaryColor.withOpacity(0.5)
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          AppLocalizations.of(context)!.noActivityYet,
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: onPrimaryColor.withOpacity(0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Column(
                                    children: activities.map((activity) {
                                      String actionText = _getActionText(activity['actionType']);
                                      return Card(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        color: Colors.black.withOpacity(0.3),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          side: BorderSide(
                                            color: errorColor.withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: ListTile(
                                          contentPadding: const EdgeInsets.all(16),
                                          title: RichText(
                                            text: TextSpan(
                                              children: [
                                                TextSpan(
                                                  text: actionText,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: onPrimaryColor.withOpacity(0.9),
                                                  ),
                                                ),
                                                TextSpan(
                                                  text: movieTitles[activity['movieId']],
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    color: errorColor,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  recognizer: TapGestureRecognizer()
                                                    ..onTap = () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) => MoviePage(movieId: activity['movieId']),
                                                        ),
                                                      );
                                                    },
                                                ),
                                              ],
                                            ),
                                          ),
                                          subtitle: Padding(
                                            padding: const EdgeInsets.only(top: 8),
                                            child: Text(
                                              'at ${activity['logAt'].toDate().toString().substring(0, 16)}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: onPrimaryColor.withOpacity(0.6),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _getActionText(String actionType) {
    switch (actionType) {
      case 'watch':
        return AppLocalizations.of(context)!.youWatched;
      case 'addJs':
        return AppLocalizations.of(context)!.youAddedJumpscare;
      case 'downvoteJs':
        return AppLocalizations.of(context)!.youDownvotedJumpscare;
      case 'upvoteJs':
        return AppLocalizations.of(context)!.youUpvotedJumpscare;
      case 'removeJs':
        return AppLocalizations.of(context)!.youRemovedJumpscare;
      case 'updateJs':
        return AppLocalizations.of(context)!.youUpdatedJumpscare;
      case 'like':
        return AppLocalizations.of(context)!.youLiked;
      case 'dislike':
        return AppLocalizations.of(context)!.youDisliked;
      default:
        return AppLocalizations.of(context)!.youDidSomething;
    }
  }
}
