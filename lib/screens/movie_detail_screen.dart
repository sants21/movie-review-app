import 'package:flutter/material.dart';
import '../services/movie_service.dart';

class MovieDetailsScreen extends StatefulWidget {
  final int movieId;
  final String posterUrl;

  const MovieDetailsScreen({super.key, required this.movieId, required this.posterUrl});

  @override
  State<MovieDetailsScreen> createState() => _MovieDetailsScreenState();
}

class _MovieDetailsScreenState extends State<MovieDetailsScreen> {
  final MovieService _movieService = MovieService();
  Map<String, dynamic>? movieData;
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadMovieDetails();
  }

  Future<void> _loadMovieDetails() async {
    try {
      final data = await _movieService.fetchMovieDetails(widget.movieId);
      setState(() {
        movieData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }
  Widget get _heroPoster => Center(
    child: Hero(
      tag: 'poster-${widget.movieId}',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          widget.posterUrl,
          //width: 130,
          height: 300,
          fit: BoxFit.cover,
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (isLoading || errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: Column(
          children: [
            const SizedBox(height: 32), // same offset as final position
            _heroPoster,
            const SizedBox(height: 24),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Center(child: Text(errorMessage)),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(movieData!['title'])),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 32), // align with loading screen
            _heroPoster,
            const SizedBox(height: 16),
            Text(movieData!['title'], style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text("📅 ${movieData!['release_date']}"),
            Text("⭐ ${movieData!['vote_average']} / 10"),
            const SizedBox(height: 12),
            if (movieData!['genres'] != null)
              Wrap(
                spacing: 8,
                children: List<Widget>.from(movieData!['genres'].map(
                      (g) => Chip(label: Text(g['name'])),
                )),
              ),
            const SizedBox(height: 16),
            const Text(
                'Overview', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(movieData!['overview'] ?? 'No overview available'),
          ],
        ),
      ),
    );
  }
}
