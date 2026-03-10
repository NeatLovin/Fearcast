import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiServices {
  static const String _apiKey = String.fromEnvironment('TMDB_API_KEY');

  void _ensureApiKeyConfigured() {
    if (_apiKey.isEmpty) {
      throw StateError('TMDB_API_KEY is not configured.');
    }
  }

  Future<List<Map<String, dynamic>>> fetchHorrorMovies(String sortBy) async {
    _ensureApiKeyConfigured();
    final url = Uri.parse(
      'https://api.themoviedb.org/3/discover/movie?api_key=$_apiKey&language=en-US&sort_by=$sortBy&with_genres=27',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final movies = data['results'] as List;
        
        return movies
            .map((movie) => {
                  'id': movie['id'],
                  'poster_path': movie['poster_path'],
                })
            .toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
  
  Future<Map<String, dynamic>> fetchMovieDetails(int movieId, String language) async {
    _ensureApiKeyConfigured();
    final url = Uri.parse(
      'https://api.themoviedb.org/3/movie/$movieId?api_key=$_apiKey&language=$language',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          ...data,
          'vote_average': data['vote_average'],
          'vote_count': data['vote_count'],
        };
      } else {
        return {};
      }
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, dynamic>> fetchMovieCredits(int movieId) async {
    _ensureApiKeyConfigured();
    final url = Uri.parse(
      'https://api.themoviedb.org/3/movie/$movieId/credits?api_key=$_apiKey&language=en-US',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {};
      }
    } catch (e) {
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> searchMovies(String query) async {
    _ensureApiKeyConfigured();
    final url = Uri.parse(
      'https://api.themoviedb.org/3/search/movie?api_key=$_apiKey&language=en-US&query=$query',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final movies = data['results'] as List;

        return movies
            .where((movie) => movie['genre_ids'].contains(27))
            .map((movie) => {
                  'id': movie['id'],
                  'title': movie['title'],
                  'release_date': movie['release_date'],
                  'poster_path': movie['poster_path'],
                })
            .toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  Future<String?> fetchMoviePoster(String posterPath) async {
    final url = Uri.parse('https://image.tmdb.org/t/p/w92$posterPath');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return url.toString();
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}
