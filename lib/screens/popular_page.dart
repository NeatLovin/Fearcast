import 'package:flutter/material.dart';
import 'movie_page.dart';
import '../utilities/drawer_menu.dart';
import '../services/api_services.dart';
import '../utilities/constants.dart';
import 'search_page.dart';
import '../services/jumpscare_services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PopularPage extends StatefulWidget {
  const PopularPage({super.key});

  @override
  PopularPageState createState() => PopularPageState();
}

class PopularPageState extends State<PopularPage> {
  final ApiServices apiServices = ApiServices();
  final JumpscareServices jumpscareServices = JumpscareServices();
  List<Map<String, dynamic>> popularHorrorMovies = [];
  List<Map<String, dynamic>> highScareMovies = [];
  List<Map<String, dynamic>> mostVotedMovies = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHorrorMovies();
  }

  Future<void> _fetchHorrorMovies() async {
    try {
      await Future.wait([
        apiServices.fetchHorrorMovies('popularity.desc').then((movies) => popularHorrorMovies = movies),
        jumpscareServices.getMoviesSortedByJumpscares().then((movies) async {
          for (var movie in movies) {
            final movieDetails = await apiServices.fetchMovieDetails(movie['movieId'], 'en-US');
            if (movieDetails.isNotEmpty) {
              highScareMovies.add(movieDetails);
            } else {
              return;
            }
          }
        }),
        apiServices.fetchHorrorMovies('vote_count.desc').then((movies) => mostVotedMovies = movies),
      ]);
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
        title: Text(AppLocalizations.of(context)!.popular),
        backgroundColor: primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchPage()),
              );
            },
          ),
        ],
      ),
      drawer: const DrawerMenu(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView(
                children: [
                  const SizedBox(height: 8),
                  _buildCategorySection(AppLocalizations.of(context)!.popularThisWeek, popularHorrorMovies),
                  const SizedBox(height: 16),
                  _buildCategorySection(AppLocalizations.of(context)!.mostScaresPerHour, highScareMovies),
                  const SizedBox(height: 16),
                  _buildCategorySection(AppLocalizations.of(context)!.mostVoted, mostVotedMovies),
                ],
              ),
            ),
    );
  }

  Widget _buildCategorySection(String title, List<Map<String, dynamic>> movies) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        SizedBox(
          height: 180,
          child: movies.isEmpty
              ? const Center(child: Text('No movies found'))
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: movies.length,
                  itemBuilder: (context, index) {
                    return _buildMovieCard(context, movies[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMovieCard(BuildContext context, Map<String, dynamic> movie) {
    final String? posterPath = movie['poster_path'];
    final int? movieId = movie['id'];

    if (movieId == null) {
      return const SizedBox(
        width: 120,
        height: 180,
        child: Center(child: Text('ERROR')),
      );
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MoviePage(movieId: movieId),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: posterPath != null
              ? Image.network(
                  'https://image.tmdb.org/t/p/w200$posterPath',
                  width: 120,
                  fit: BoxFit.cover,
                )
              : const SizedBox(
                  width: 120,
                  height: 180,
                  child: Center(child: Text('No Image')),
                ),
        ),
      ),
    );
  }
}
