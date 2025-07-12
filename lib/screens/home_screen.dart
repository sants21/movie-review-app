import 'package:flutter/material.dart';
import '../services/movie_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MovieService _movieService = MovieService();
  late Future<List<dynamic>> _movies;

  @override
  void initState() {
    super.initState();
    _movies = _movieService.fetchPopularMovies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Popular Movies')),
      body: FutureBuilder<List<dynamic>>(
        future: _movies,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final movies = snapshot.data!;
            return ListView.builder(
              itemCount: movies.length,
              itemBuilder: (context, index) {
                final movie = movies[index];
                final posterUrl = 'https://image.tmdb.org/t/p/w500${movie['poster_path']}';
                return ListTile(
                  leading: Image.network(posterUrl, width: 50, fit: BoxFit.cover),
                  title: Text(movie['title']),
                  subtitle: Text('Rating: ${movie['vote_average']}'),
                  onTap: () {
                    // TODO: Navigate to Movie Detail Screen
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}
