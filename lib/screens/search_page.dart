import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../utilities/constants.dart';
import '../services/api_services.dart';
import 'movie_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  SearchPageState createState() => SearchPageState();
}

class SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final ApiServices apiServices = ApiServices();
  List<Map<String, dynamic>> searchResults = [];
  bool isLoading = false;
  bool hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) async {
    if (query.isEmpty) return;

    setState(() {
      isLoading = true;
      hasSearched = true;
    });

    try {
      searchResults = await apiServices.searchMovies(query);
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
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildSearchInput() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          filled: true,
          fillColor: onPrimaryColor,
          hintText: AppLocalizations.of(context)!.search,
          hintStyle: TextStyle(color: onSecondaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          suffixIcon: IconButton(
            icon: Icon(Icons.search, color: primaryColor),
            onPressed: () => _performSearch(_searchController.text),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        style: TextStyle(color: onSecondaryColor),
        onSubmitted: _performSearch,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 100,
            color: Colors.grey[300],
          ),
          SizedBox(height: 16),
          Text(
            hasSearched && searchResults.isEmpty 
              ? AppLocalizations.of(context)!.noMoviesFound 
              : AppLocalizations.of(context)!.searchForMovies,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovieListItem(Map<String, dynamic> movie, String? posterUrl) {
    return Column(
      children: [
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: posterUrl != null
                ? ClipRRect(
                    child: Image.network(
                      posterUrl,
                      width: 44,
                      height: 66,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.movie, size: 60);
                      },
                    )
                  )
                : Icon(Icons.movie, size: 60),
            title: Text(
              movie['title'],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              movie['release_date'] != null && movie['release_date'].length >= 4
                ? movie['release_date'].substring(0, 4)
                : AppLocalizations.of(context)!.releaseDateUnknown,
              style: TextStyle(color: Colors.grey[600]),
            ),
            trailing: Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MoviePage(movieId: movie['id']),
                ),
              );
            },
          ),
        ),
        Divider(color: Colors.grey),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.search),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildSearchInput(),
            ),
            if (isLoading)
              Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  ),
                ),
              )
            else if (searchResults.isEmpty)
              Expanded(child: _buildEmptyState())
            else
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  itemCount: searchResults.length,
                  itemBuilder: (context, index) {
                    final movie = searchResults[index];
                    return FutureBuilder<String?>(
                      future: movie['poster_path'] != null 
                        ? apiServices.fetchMoviePoster(movie['poster_path']) 
                        : Future.value(null),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return SizedBox.shrink();
                        }
                        return _buildMovieListItem(movie, snapshot.data);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
