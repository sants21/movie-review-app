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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Movie Hub',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
            ),
            backgroundColor: Theme.of(context).colorScheme.surface,
          ),
          FutureBuilder<void>(
            future: _loadAllMovies,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading movies',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildListDelegate([
                  _buildMovieSection('🎯 Popular', popularMovies, 'popular'),
                  _buildMovieSection('⏳ Now Playing', nowPlayingMovies, 'now_playing'),
                  _buildMovieSection('📈 Top Rated', topRatedMovies, 'top_rated'),
                  const SizedBox(height: 20),
                ]),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMovieSection(String title, List<dynamic> movies, String section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: movies.length,
            itemBuilder: (context, index) {
              final movie = movies[index];
              final posterUrl = 'https://image.tmdb.org/t/p/w500${movie['poster_path']}';
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MovieDetailsScreen(
                        movieId: movie['id'], 
                        posterUrl: posterUrl,
                        heroTag: 'poster-${movie['id']}-$section',
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 140,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 4,
                          child: Hero(
                            tag: 'poster-${movie['id']}-$section',
                            child: Image.network(
                              posterUrl,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: Theme.of(context).colorScheme.surfaceVariant,
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Theme.of(context).colorScheme.surfaceVariant,
                                  child: Icon(
                                    Icons.movie,
                                    size: 48,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Flexible(
                                  child: Text(
                                    movie['title'],
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.star,
                                      size: 14,
                                      color: Colors.amber,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${movie['vote_average']?.toStringAsFixed(1) ?? 'N/A'}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}
