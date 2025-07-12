import 'dart:convert';
import 'package:http/http.dart' as http;

class MovieService {
  final String _apiKey = '04a28b177ce15913cc9a0883e2bd6c4f';
  final String _baseUrl = 'https://api.themoviedb.org/3';

  Future<List<dynamic>> fetchPopularMovies() async {
    final response = await http.get(Uri.parse('$_baseUrl/movie/popular?api_key=$_apiKey'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['results'];
    } else {
      throw Exception('Failed to load movies');
    }
  }

  Future<List<dynamic>> searchMovies(String query) async {
    final response = await http.get(Uri.parse(
        '$_baseUrl/search/movie?api_key=$_apiKey&query=$query'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['results'];
    } else {
      throw Exception('Search failed');
    }
  }
}
