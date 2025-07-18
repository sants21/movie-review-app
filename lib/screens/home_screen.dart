import 'package:flutter/material.dart';
import '../services/movie_service.dart';
import 'movie_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  final MovieService _movieService = MovieService();

  Future<void>? _loadAllMovies;
  List<dynamic> popularMovies = [];
  List<dynamic> nowPlayingMovies = [];
  List<dynamic> topRatedMovies = [];

  @override
  void initState() {
    super.initState();
    _loadAllMovies = _fetchAllMoviesOnce();
  }

  Future<void> _fetchAllMoviesOnce() async {
    popularMovies = await _movieService.fetchPopularMovies();
    nowPlayingMovies = await _movieService.fetchNowPlayingMovies();
    topRatedMovies = await _movieService.fetchTopRatedMovies();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // for AutomaticKeepAliveClientMixin

    return Scaffold(
      appBar: AppBar(title: const Text('Movie Hub')),
      body: FutureBuilder<void>(
        future: _loadAllMovies,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading movies: ${snapshot.error}'));
          }
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMovieSection('🎯 Popular', popularMovies),
                _buildMovieSection('⏳ Now Playing', nowPlayingMovies),
                _buildMovieSection('📈 Top Rated', topRatedMovies),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMovieSection(String title, List<dynamic> movies) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: movies.length,
            itemBuilder: (context, index) {
              final movie = movies[index];
              final posterUrl = 'https://image.tmdb.org/t/p/w500${movie['poster_path']}';
              Hero(
                tag: 'poster-${movie['id']}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(posterUrl, fit: BoxFit.cover),
                ),
              );
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MovieDetailsScreen(movieId: movie['id'], posterUrl: posterUrl),
                    ),
                  );
                },
                child: Container(
                  width: 130,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(posterUrl, fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        movie['title'],
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}
