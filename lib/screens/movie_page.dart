import 'package:flutter/material.dart';
import 'viewing_page.dart';
import '../services/api_services.dart';
import '../utilities/constants.dart';
import '../services/jumpscare_services.dart';
import '../services/firestore_services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MoviePage extends StatefulWidget {
  final int movieId;

  const MoviePage({super.key, required this.movieId});

  @override
  MoviePageState createState() => MoviePageState();
}

class MoviePageState extends State<MoviePage> with SingleTickerProviderStateMixin {
  final ApiServices apiService = ApiServices();
  final JumpscareServices _jumpscareServices = JumpscareServices();
  final FirestoreServices firestoreServices = FirestoreServices();
  late AnimationController _heartAnimationController;
  late Animation<double> _heartAnimation;
  Map<String, dynamic>? movie;
  bool isLoading = true;
  bool isOverlayVisible = false;
  bool isLiked = false;
  int totalJumpscares = 0;
  double scaresPerHour = 0.0;
  bool isExpanded = false;
  bool requiresReadMore = false;
  String? language;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    language = Localizations.localeOf(context).languageCode;
    _fetchMovieDetails();
  }

  @override
  void initState() {
    super.initState();
    _checkIfLiked();

    _heartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _heartAnimation = Tween<double>(begin: 1, end: 1.3).animate(
      CurvedAnimation(
        parent: _heartAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _heartAnimationController.dispose();
    super.dispose();
  }

  Future<void> _fetchMovieDetails() async {
    try {
      final movieDetailsData = await apiService.fetchMovieDetails(widget.movieId, language!);
      final movieCreditsData = await apiService.fetchMovieCredits(widget.movieId);

      String director = 'N/A';
      final crew = movieCreditsData['crew'] as List<dynamic>;
      for (var member in crew) {
        if (member['job'] == 'Director') {
          director = member['name'];
          break;
        }
      }

      setState(() {
        movie = {
          ...movieDetailsData,
          'director': director,
          'vote_average': movieDetailsData['vote_average'],
          'vote_count': movieDetailsData['vote_count'],
        };
        isLoading = false;
        if (movie!['overview'] != null && movie!['overview'].length > 450) {
          requiresReadMore = true;
        }
      });

      _fetchJumpscareStats();
    } catch (e) {
      return;
    }
  }

  Future<void> _fetchJumpscareStats() async {
    final JumpscareServices jumpscareServices = JumpscareServices();
    totalJumpscares = await jumpscareServices.getTotalJumpscares(widget.movieId);
    if (movie != null && movie!['runtime'] != null && movie!['runtime'] > 0) {
      scaresPerHour = (totalJumpscares / movie!['runtime']) * 60;
    }
    setState(() {});
  }

  Future<void> _checkIfLiked() async {
    final List<String>? likedMovieIds = await firestoreServices.fetchUserLikes();
    if (likedMovieIds != null && likedMovieIds.contains(widget.movieId.toString())) {
      setState(() {
        isLiked = true;
      });
    }
  }

  Future<void> _toggleLike() async {
    await _heartAnimationController.forward();
    await _heartAnimationController.reverse();

    if (isLiked) {
      await firestoreServices.dislikeMovie(widget.movieId);
    } else {
      await firestoreServices.likeMovie(widget.movieId);
    }
    setState(() {
      isLiked = !isLiked;
    });
  }

  void _showOverlay() {
    setState(() {
      isOverlayVisible = true;
    });
  }

  void _hideOverlay() {
    setState(() {
      isOverlayVisible = false;
    });
  }

  void _navigateToViewingPage(String mode) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ViewingPage(
          mode: mode,
          posterPath: movie!['poster_path'],
          movieLength: movie!['runtime'] * 60,
          movieId: widget.movieId,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          
          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );
          
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  Widget buildCircularButton(BuildContext context, String text, Color backgroundColor, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: FloatingActionButton.extended(
        onPressed: onPressed,
        backgroundColor: backgroundColor,
        shape: const CircleBorder(),
        label: Text(
          text,
          style: const TextStyle(fontSize: 14, color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceColor,
      body: Stack(
        children: [
          if (isLoading)
            const Center(child: CircularProgressIndicator(color: errorColor))
          else
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 250,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(
                          'https://image.tmdb.org/t/p/w780${movie!['backdrop_path']}',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                movie!['title'] ?? '',
                                style: TextStyle(
                                  color: errorColor,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!.directedBy,
                                    style: TextStyle(
                                      color: onSurfaceColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      movie!['director'] ?? 'N/A',
                                      style: TextStyle(
                                        color: onSurfaceColor,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text(
                                    movie!['release_date'] != null && movie!['release_date'].length >= 4
                                        ? movie!['release_date']!.substring(0, 4)
                                        : 'TBD',
                                    style: TextStyle(
                                      color: onSurfaceColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    '${movie!['runtime']} mins',
                                    style: TextStyle(
                                      color: onSurfaceColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                movie!['tagline'] ?? 'No tagline available',
                                style: TextStyle(
                                  color: onSurfaceColor.withOpacity(0.7),
                                  fontSize: 16,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          height: 150,
                          width: 100,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: NetworkImage(
                                'https://image.tmdb.org/t/p/w200${movie!['poster_path']}',
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        RichText(
                          text: TextSpan(
                            text: isExpanded || !requiresReadMore
                                ? movie!['overview']
                                : movie!['overview']!.substring(0, 450) + '...',
                            style: TextStyle(
                              color: onSurfaceColor.withOpacity(0.7),
                              fontSize: 14,
                            ),
                            children: requiresReadMore
                                ? [
                                    TextSpan(
                                      text: isExpanded
                                          ? AppLocalizations.of(context)!.showLess
                                          : AppLocalizations.of(context)!.readMore,
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          setState(() {
                                            isExpanded = !isExpanded;
                                          });
                                        },
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: List.generate(5, (index) {
                                    return Icon(
                                      index < (movie!['vote_average'] / 2).round()
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: errorColor,
                                      size: 40,
                                    );
                                  }),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  children: [
                                    Text(
                                      '${(movie!['vote_average'] / 2).toStringAsFixed(1)}',
                                      style: TextStyle(
                                        color: errorColor,
                                        fontSize: 32,
                                      ),
                                    ),
                                    Text(
                                      '${movie!['vote_count']} ${AppLocalizations.of(context)!.votes}',
                                      style: TextStyle(
                                        color: onSurfaceColor,
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Divider(
                              color: primaryColor,
                              thickness: 2,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.totalJumpscares,
                                  style: TextStyle(
                                    color: onSurfaceColor,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  '$totalJumpscares',
                                  style: TextStyle(
                                    color: errorColor,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w300,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.scaresPerHour,
                                  style: TextStyle(
                                    color: onSurfaceColor,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  scaresPerHour.toStringAsFixed(2),
                                  style: TextStyle(
                                    color: errorColor,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w300,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppBar(
              backgroundColor: transparentColor,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              actions: [
                ScaleTransition(
                  scale: _heartAnimation,
                  child: IconButton(
                    icon: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? errorColor : null,
                    ),
                    onPressed: () async {
                      await _toggleLike();
                      await _jumpscareServices.logActivity(
                        widget.movieId,
                        isLiked ? 'like' : 'dislike',
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          if (isOverlayVisible)
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 300),
              tween: Tween<double>(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return GestureDetector(
                  onTap: _hideOverlay,
                  child: Container(
                    color: Colors.black.withOpacity(0.8 * value),
                    child: Stack(
                      children: [
                        Positioned(
                          bottom: 88 * value,
                          right: 16,
                          left: 16,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Transform.translate(
                                offset: Offset(0, 50 * (1 - value)),
                                child: Opacity(
                                  opacity: value,
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: FloatingActionButton.extended(
                                      onPressed: () {
                                        _hideOverlay();
                                        _navigateToViewingPage('Fearful');
                                      },
                                      backgroundColor: secondaryColor,
                                      label: Text(
                                        AppLocalizations.of(context)!.fearful,
                                        style: TextStyle(
                                          color: onSecondaryColor,
                                          fontSize: 17,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Transform.translate(
                                offset: Offset(0, 50 * (1 - value)),
                                child: Opacity(
                                  opacity: value,
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: FloatingActionButton.extended(
                                      onPressed: () {
                                        _hideOverlay();
                                        _navigateToViewingPage('Scary');
                                      },
                                      backgroundColor: errorColor,
                                      label: Text(
                                        AppLocalizations.of(context)!.scary,
                                        style: TextStyle(
                                          color: onPrimaryColor,
                                          fontSize: 17,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SizedBox(
        width: MediaQuery.of(context).size.width - 32,
        child: FloatingActionButton.extended(
          onPressed: _showOverlay,
          backgroundColor: primaryColor,
          label: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppLocalizations.of(context)!.startWatching,
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
