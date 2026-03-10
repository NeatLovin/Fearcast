import 'package:flutter/material.dart';
import 'movie_page.dart';
import '../utilities/drawer_menu.dart';
import '../services/api_services.dart';
import '../services/firestore_services.dart';
import '../utilities/constants.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LikesPage extends StatefulWidget {
  const LikesPage({super.key});

  @override
  LikesPageState createState() => LikesPageState();
}

class LikesPageState extends State<LikesPage> {
  final ApiServices apiServices = ApiServices();
  final FirestoreServices firestoreServices = FirestoreServices();
  List<Map<String, dynamic>> likedMovies = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLikedMovies();
  }

  Future<void> _fetchLikedMovies() async {
    try {
      final List<String>? likedMovieIds = await firestoreServices.fetchUserLikes();
      if (likedMovieIds != null) {
        for (String movieId in likedMovieIds) {
          final movieDetails = await apiServices.fetchMovieDetails(int.parse(movieId), 'en-US');
          if (movieDetails.isNotEmpty) {
            likedMovies.add(movieDetails);
          }
        }
      }
    } catch (e) {
      return;
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.likes),
        backgroundColor: primaryColor,
      ),
      drawer: const DrawerMenu(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: likedMovies.isEmpty
                  ? Center(child: Text(AppLocalizations.of(context)!.noMoviesFound))
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        childAspectRatio: 0.65,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4,
                      ),
                      itemCount: likedMovies.length,
                      itemBuilder: (context, index) {
                        return _buildMovieCard(context, likedMovies[index]);
                      },
                    ),
            ),
    );
  }

  Widget _buildMovieCard(BuildContext context, Map<String, dynamic> movie) {
    final String? posterPath = movie['poster_path'];
    final int movieId = movie['id'];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MoviePage(movieId: movieId),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: posterPath != null
            ? Image.network(
                'https://image.tmdb.org/t/p/w200$posterPath',
                fit: BoxFit.cover,
              )
            : const SizedBox(
                width: 100,
                height: 150,
                child: Center(child: Text('No Image')),
              ),
      ),
    );
  }
}
