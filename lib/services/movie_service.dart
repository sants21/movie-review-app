import 'dart:convert';
import 'package:http/http.dart' as http;

class MovieService {
  final String _apiKey = '04a28b177ce15913cc9a0883e2bd6c4f';
  final String _baseUrl = 'https://api.themoviedb.org/3';

  Future<List<dynamic>> fetchPopularMovies() async {
    return _fetchMovies('$_baseUrl/movie/popular?api_key=$_apiKey');
  }

  Future<List<dynamic>> fetchNowPlayingMovies() async {
    return _fetchMovies('$_baseUrl/movie/now_playing?api_key=$_apiKey');
  }

  Future<List<dynamic>> fetchTopRatedMovies() async {
    return _fetchMovies('$_baseUrl/movie/top_rated?api_key=$_apiKey');
  }

  Future<List<dynamic>> fetchUpcomingMovies() async {
    return _fetchMovies('$_baseUrl/movie/upcoming?api_key=$_apiKey');
  }

  Future<List<dynamic>> fetchTrendingWeekly() async {
    return _fetchMovies('$_baseUrl/trending/movie/week?api_key=$_apiKey');
  }

  Future<Map<String, dynamic>> fetchMovieDetails(int movieId) async {
    final url = '$_baseUrl/movie/$movieId?api_key=$_apiKey';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load movie details');
    }
  }

  Future<List<Map<String, dynamic>>> fetchMovieCast(int movieId) async {
    final url = '$_baseUrl/movie/$movieId/credits?api_key=$_apiKey';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['cast']);
    } else {
      throw Exception('Failed to load cast');
    }
  }

  Future<String?> fetchMovieCertification(int movieId) async {
    final url = '$_baseUrl/movie/$movieId/release_dates?api_key=$_apiKey';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results = data['results'];

      for (var country in results) {
        if (country['iso_3166_1'] == 'TH') {
          for (var release in country['release_dates']) {
            final cert = release['certification'];
            if (cert != null && cert.toString().isNotEmpty) {
              return cert;
            }
          }
        }
      }
    }

    return null;
  }

  Future<List<dynamic>> fetchSimilarMovies(int movieId) async {
    final url = '$_baseUrl/movie/$movieId/similar?api_key=$_apiKey';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['results'];
    } else {
      throw Exception('Failed to load similar movies');
    }
  }

  Future<List<dynamic>> _fetchMovies(String url) async {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['results'];
    } else {
      throw Exception('Failed to fetch movies');
    }
  }
}
