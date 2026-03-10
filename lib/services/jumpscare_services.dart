import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class JumpscareServices {
  Future<void> addJumpscare(int movieId, String description, String time) async {
    try {
      await FirebaseFirestore.instance.collection('jumpscares').doc().set({
        'movieId': movieId,
        'description': description,
        'timestamp': time,
        'score': 1,
        'userId': FirebaseAuth.instance.currentUser!.uid,
        'addedAt': FieldValue.serverTimestamp(),
      });
      await logActivity(movieId, 'addJs');
    } catch (e) {
      return;
    }
  }

  Future<void> removeJumpscare(String jumpscareId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('jumpscares').doc(jumpscareId).get();
      final movieId = doc['movieId'];
      await FirebaseFirestore.instance.collection('jumpscares').doc(jumpscareId).delete();
      await logActivity(movieId, 'removeJs');
    } catch (e) {
      return;
    }
  }

  Future<void> updateJumpscare(String jumpscareId, String description, String time) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('jumpscares').doc(jumpscareId).get();
      final movieId = doc['movieId'];
      await FirebaseFirestore.instance.collection('jumpscares').doc(jumpscareId).update({
        'description': description,
        'timestamp': time,
      });
      await logActivity(movieId, 'updateJs');
    } catch (e) {
      return;
    }
  }

  Future<List<Map<String, dynamic>>> getJumpcaresByMovieId(int movieId) async {
  try {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('jumpscares')
        .where('movieId', isEqualTo: movieId)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        ...data,
        'id': doc.id, 
      };
    }).toList();
  } catch (e) {
    return [];
  }
}

  Future<int> getTotalJumpscares(int movieId) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('jumpscares')
          .where('movieId', isEqualTo: movieId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  Future<void> updateScore(String jumpscareId, int delta) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('jumpscares').doc(jumpscareId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          throw Exception("Jumpscare with ID $jumpscareId does not exist.");
        }

        final currentScore = snapshot['score'] ?? 1;
        final newScore = currentScore + delta;
        final movieId = snapshot['movieId'];

        if (newScore < 0) {
          transaction.delete(docRef);
        } else {
          transaction.update(docRef, {'score': newScore});
        }

        final actionType = delta > 0 ? 'upvoteJs' : 'downvoteJs';
        await logActivity(movieId, actionType);
      });
    } catch (e) {
      return;
    }
  }

  Future<void> logActivity(int movieId, String actionType) async {
    try {
      await FirebaseFirestore.instance.collection('activities').doc().set({
        'logAt': FieldValue.serverTimestamp(),
        'movieId': movieId,
        'actionType': actionType,
        'userId': FirebaseAuth.instance.currentUser!.uid,
      });
    } catch (e) {
      return;
    }
  }

  Future<List<Map<String, dynamic>>> getUserActivities(String userId) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('activities')
          .where('userId', isEqualTo: userId)
          .orderBy('logAt', descending: true)
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          ...data,
          'id': doc.id,
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getMoviesSortedByJumpscares() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('jumpscares').get();
      Map<int, int> jumpscareCount = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final movieId = data['movieId'] as int;
        jumpscareCount[movieId] = (jumpscareCount[movieId] ?? 0) + 1;
      }

      List<Map<String, dynamic>> sortedMovies = jumpscareCount.entries
          .map((entry) => {'movieId': entry.key, 'jumpscareCount': entry.value})
          .toList();

      sortedMovies.sort((a, b) => b['jumpscareCount'].compareTo(a['jumpscareCount']));

      return sortedMovies;
    } catch (e) {
      return [];
    }
  }
}