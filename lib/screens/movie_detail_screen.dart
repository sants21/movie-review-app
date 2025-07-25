import 'package:flutter/material.dart';
import '../services/movie_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth/login_screen.dart';

class MovieDetailsScreen extends StatefulWidget {
  final int movieId;
  final String posterUrl;
  final String heroTag;

  const MovieDetailsScreen({
    super.key,
    required this.movieId,
    required this.posterUrl,
    required this.heroTag,
  });

  @override
  State<MovieDetailsScreen> createState() => _MovieDetailsScreenState();
}

class _MovieDetailsScreenState extends State<MovieDetailsScreen> {
  final MovieService _movieService = MovieService();
  Map<String, dynamic>? movieData;
  bool isLoading = true;
  String errorMessage = '';
  List<Map<String, dynamic>>? cast;
  String? certification;
  List<dynamic>? similar;
  bool isInWatchlist = false;
  bool isWatched = false;

  @override
  void initState() {
    super.initState();
    _loadMovieDetails();
    _checkMovieStatus();
  }

  Future<void> _checkMovieStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userId = user.uid;
    final movieId = widget.movieId.toString();

    try {
      // Check watchlist status
      final watchlistDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('watchlist')
          .doc(movieId)
          .get();

      // Check watched status
      final watchedDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('watched')
          .doc(movieId)
          .get();

      if (mounted) {
        setState(() {
          isInWatchlist = watchlistDoc.exists;
          isWatched = watchedDoc.exists;
        });
      }
    } catch (e) {
      print('Error checking movie status: $e');
    }
  }

  Future<void> _loadMovieDetails() async {
    try {
      final data = await _movieService.fetchMovieDetails(widget.movieId);
      final castData = await _movieService.fetchMovieCast(widget.movieId);
      final cert = await _movieService.fetchMovieCertification(widget.movieId);
      final similarMovies = await _movieService.fetchSimilarMovies(widget.movieId);
      if (!mounted) return;
      setState(() {
        movieData = data;
        cast = castData.take(10).toList();
        certification = cert;
        similar = similarMovies.take(10).toList();
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> addToWatchlist(Map<String, dynamic> movieData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        _showLoginPrompt('add movies to your watchlist');
      }
      return;
    }

    try {
      final userId = user.uid;
      final movieId = movieData['id'].toString();
      
      // Check if movie is already in watchlist
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('watchlist')
          .doc(movieId);
      
      final docSnapshot = await docRef.get();
      
      if (docSnapshot.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Movie already in watchlist')),
          );
        }
        return;
      }

      // Add movie to watchlist with timestamp
      await docRef.set({
        ...movieData,
        'addedAt': FieldValue.serverTimestamp(),
        'posterUrl': widget.posterUrl, // Include poster URL for easy display
      });

      if (mounted) {
        setState(() {
          isInWatchlist = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Added to watchlist!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding to watchlist: $e')),
        );
      }
    }
  }

  Future<void> markAsWatched(Map<String, dynamic> movieData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        _showLoginPrompt('mark movies as watched');
      }
      return;
    }

    try {
      final userId = user.uid;
      final movieId = movieData['id'].toString();
      
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('watched')
          .doc(movieId);
      
      final docSnapshot = await docRef.get();
      
      if (docSnapshot.exists) {
        // Movie is already watched, so unmark it
        await docRef.delete();
        
        if (mounted) {
          setState(() {
            isWatched = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unmarked as watched'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Add movie to watched collection with timestamp
      await docRef.set({
        ...movieData,
        'watchedAt': FieldValue.serverTimestamp(),
        'posterUrl': widget.posterUrl,
      });

      // Remove from watchlist if it exists
      final watchlistDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('watchlist')
          .doc(movieId);
      
      final watchlistDoc = await watchlistDocRef.get();
      if (watchlistDoc.exists) {
        await watchlistDocRef.delete();
      }

      if (mounted) {
        setState(() {
          isWatched = true;
          isInWatchlist = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Marked as watched!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error marking as watched: $e')),
        );
      }
    }
  }

  void _showLoginPrompt(String action) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Login Required'),
          content: Text('Please log in to $action.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: const Text('Login'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || errorMessage.isNotEmpty) {
      return Scaffold(
        body: Center(
          child: isLoading
              ? const CircularProgressIndicator()
              : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, color: Theme.of(context).colorScheme.error, size: 64),
              const SizedBox(height: 16),
              Text('Error loading movie details', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(errorMessage, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 500,
            backgroundColor: Theme.of(context).colorScheme.surface,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  isInWatchlist ? Icons.bookmark : Icons.bookmark_add_outlined,
                  color: isInWatchlist ? Colors.blue : null,
                ),
                tooltip: isInWatchlist ? 'In Watchlist' : 'Add to Watchlist',
                onPressed: () {
                  addToWatchlist(movieData!);
                },
              ),
              IconButton(
                icon: Icon(
                  isWatched ? Icons.check_circle : Icons.check_circle_outline,
                  color: isWatched ? Colors.green : null,
                ),
                tooltip: isWatched ? 'Watched' : 'Mark as Watched',
                onPressed: () {
                  markAsWatched(movieData!);
                },
              ),
            ],
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                final collapsed = constraints.maxHeight <= kToolbarHeight + MediaQuery.of(context).padding.top + 20;
                return FlexibleSpaceBar(
                  title: collapsed
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          constraints: const BoxConstraints(maxWidth: 200),
                          child: Text(
                            movieData?['title'] ?? '',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        )
                      : null,
                  centerTitle: true,
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: widget.heroTag,
                        child: Image.network(
                          widget.posterUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey,
                            child: const Icon(Icons.movie, size: 100),
                          ),
                        ),
                      ),
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black87],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 24,
                        left: 16,
                        right: 16,
                        child: Text(
                          movieData?['title'] ?? '',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            shadows: const [
                              Shadow(offset: Offset(0, 1), blurRadius: 4, color: Colors.black),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoSection(),
                  const SizedBox(height: 24),
                  if (movieData!['genres'] != null && movieData!['genres'].isNotEmpty) _buildGenresSection(),
                  if (movieData!['genres'] != null && movieData!['genres'].isNotEmpty) const SizedBox(height: 24),
                  _buildOverviewSection(),
                  const SizedBox(height: 24),
                  if (cast != null && cast!.isNotEmpty) _buildCastSection(),
                  const SizedBox(height: 24),
                  if (similar != null && similar!.isNotEmpty) _buildSimilarMoviesSection(),
                  const SizedBox(height: 24),
                  _buildReviewsSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calendar_today, size: 16),
              const SizedBox(width: 4),
              Text(
                movieData!['release_date'] ?? 'Unknown',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        if (movieData!['runtime'] != null && movieData!['runtime'] > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.access_time, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${movieData!['runtime']} min',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        if (certification != null && certification!.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              certification!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  Widget _buildOverviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Overview', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          movieData!['overview'] ?? 'No overview available',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
        ),
      ],
    );
  }

  Widget _buildCastSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cast', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: cast!.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final actor = cast![index];
              final profilePath = actor['profile_path'];
              final imageUrl = profilePath != null
                  ? 'https://image.tmdb.org/t/p/w185$profilePath'
                  : null;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: imageUrl != null
                        ? Image.network(imageUrl, width: 70, height: 70, fit: BoxFit.cover)
                        : Container(
                      width: 70,
                      height: 70,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      child: const Icon(Icons.person, size: 30),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 70,
                    child: Text(
                      actor['name'] ?? '',
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSimilarMoviesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Similar Movies', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: similar!.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final movie = similar![index];
              final posterPath = movie['poster_path'];
              final posterUrl = posterPath != null
                  ? 'https://image.tmdb.org/t/p/w342$posterPath'
                  : null;
              return GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MovieDetailsScreen(
                        movieId: movie['id'],
                        posterUrl: posterUrl ?? '',
                        heroTag: 'similar-${movie['id']}',
                      ),
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Hero(
                      tag: 'similar-${movie['id']}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: posterUrl != null
                            ? Image.network(posterUrl, width: 120, height: 180, fit: BoxFit.cover)
                            : Container(
                          width: 120,
                          height: 180,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          child: const Icon(Icons.movie, size: 40),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 120,
                      child: Text(
                        movie['title'] ?? '',
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGenresSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Genres', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: movieData!['genres'].map<Widget>((genre) {
            return Chip(
              label: Text(
                genre['name'],
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
              ),
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildReviewsSection() {
    final user = FirebaseAuth.instance.currentUser;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Reviews',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (user != null)
              ElevatedButton.icon(
                onPressed: () => _showWriteReviewDialog(),
                icon: const Icon(Icons.rate_review, size: 16),
                label: const Text('Write Review'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              )
            else
              TextButton.icon(
                onPressed: () => _showLoginPrompt('write reviews'),
                icon: const Icon(Icons.rate_review, size: 16),
                label: const Text('Write Review'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('reviews')
              .where('movieId', isEqualTo: widget.movieId)
              .orderBy('createdAt', descending: true)
              .limit(10)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading reviews',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              );
            }

            final reviews = snapshot.data?.docs ?? [];

            if (reviews.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.rate_review_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No reviews yet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Be the first to share your thoughts!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: reviews.map((reviewDoc) {
                final reviewData = reviewDoc.data() as Map<String, dynamic>;
                return _buildReviewCard(reviewData, reviewDoc.id);
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> reviewData, String reviewId) {
    final user = FirebaseAuth.instance.currentUser;
    final isMyReview = user?.uid == reviewData['userId'];
    final rating = reviewData['rating'] as num? ?? 0;
    final createdAt = reviewData['createdAt'] as Timestamp?;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  _getFirstLetter(reviewData['userName'] as String? ?? 'U'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reviewData['userName'] ?? 'Anonymous',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (createdAt != null)
                      Text(
                        _formatDate(createdAt.toDate()),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    size: 16,
                    color: Colors.amber,
                  );
                }),
              ),
              if (isMyReview) ...[
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 16),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditReviewDialog(reviewData, reviewId);
                    } else if (value == 'delete') {
                      _deleteReview(reviewId);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            reviewData['reviewText'] ?? '',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }

  String _getFirstLetter(String name) {
    if (name.isEmpty) return 'U';
    return name.substring(0, 1).toUpperCase();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  void _showWriteReviewDialog() {
    _showReviewDialog();
  }

  void _showEditReviewDialog(Map<String, dynamic> reviewData, String reviewId) {
    _showReviewDialog(
      existingReview: reviewData,
      reviewId: reviewId,
    );
  }

  void _showReviewDialog({Map<String, dynamic>? existingReview, String? reviewId}) {
    final reviewController = TextEditingController(text: existingReview?['reviewText'] ?? '');
    int selectedRating = existingReview?['rating']?.toInt() ?? 5;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(existingReview != null ? 'Edit Review' : 'Write Review'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Rate this movie:',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () => setState(() => selectedRating = index + 1),
                          child: Icon(
                            index < selectedRating ? Icons.star : Icons.star_border,
                            size: 32,
                            color: Colors.amber,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: reviewController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Share your thoughts about this movie...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final reviewText = reviewController.text.trim();
                    if (reviewText.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please write a review')),
                      );
                      return;
                    }
                    
                    Navigator.of(context).pop();
                    
                    if (existingReview != null && reviewId != null) {
                      await _updateReview(reviewId, reviewText, selectedRating);
                    } else {
                      await _submitReview(reviewText, selectedRating);
                    }
                  },
                  child: Text(existingReview != null ? 'Update' : 'Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitReview(String reviewText, int rating) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('reviews').add({
        'movieId': widget.movieId,
        'userId': user.uid,
        'userName': user.displayName ?? user.email ?? 'Anonymous',
        'reviewText': reviewText,
        'rating': rating,
        'createdAt': FieldValue.serverTimestamp(),
        'movieTitle': movieData?['title'] ?? '',
        'posterUrl': widget.posterUrl,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting review: $e')),
        );
      }
    }
  }

  Future<void> _updateReview(String reviewId, String reviewText, int rating) async {
    try {
      await FirebaseFirestore.instance.collection('reviews').doc(reviewId).update({
        'reviewText': reviewText,
        'rating': rating,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating review: $e')),
        );
      }
    }
  }

  Future<void> _deleteReview(String reviewId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Review'),
        content: const Text('Are you sure you want to delete your review?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance.collection('reviews').doc(reviewId).delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Review deleted successfully'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting review: $e')),
          );
        }
      }
    }
  }
}