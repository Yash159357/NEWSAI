import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:newsai/controller/services/news_services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shimmer/shimmer.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:newsai/controller/bloc/news_scroll_bloc.dart';
import 'package:newsai/controller/bloc/news_scroll_event.dart';
import 'package:newsai/controller/bloc/news_scroll_state.dart';
import 'package:newsai/controller/bloc/bookmark_bloc.dart';
import 'package:newsai/controller/bloc/bookmark_state.dart';
import 'package:newsai/controller/bloc/bookmark_event.dart';
import 'package:newsai/models/article_model.dart';
import 'package:newsai/models/news_category.dart';

class HomeScreen extends StatelessWidget {
  final NewsCategory category;

  const HomeScreen({super.key, this.category = NewsCategory.general});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: RepositoryProvider.of<NewsService>(context), // Explicitly provide NewsService
      child: BlocProvider(
        create: (context) => NewsBloc(
          newsService: RepositoryProvider.of<NewsService>(context)
        )..add(FetchInitialNews(category: category)),
        child: Scaffold(body: _HomeScreenContent(category: category)),
      ),
    );
  }
}

class _HomeScreenContent extends StatelessWidget {
  final NewsCategory category;
  const _HomeScreenContent({this.category = NewsCategory.general});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<NewsBloc, NewsState>(
        buildWhen: (previous, current) {
          // Only rebuild if category matches
          if (current is NewsLoaded) {
            return current.category == category;
          }
          return true;
        },
        builder: (context, state) {
          if (state is NewsLoading) {
            return _buildLoadingShimmer();
          } else if (state is NewsLoaded) {
            return _buildNewsSwiper(context, state.articles);
          } else if (state is NewsError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  state.message,
                  style: const TextStyle(fontSize: 18, color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildNewsSwiper(BuildContext context, List<Article> articles) {
    return Stack(
      children: [
        CardSwiper(
          cardsCount: articles.length,
          cardBuilder: (context, index, horizontalOffset, verticalOffset) {
            final article = articles[index];
            return GestureDetector(
              onHorizontalDragEnd: (details) {
                // Right to left swipe (open SidePage)
                if (details.primaryVelocity! > 5) {
                  context.goNamed('sidepage');
                }

                if (details.primaryVelocity! < -5) {
                  _launchArticleUrl(article.url, context);
                }
              },
              behavior: HitTestBehavior.opaque,

              child: _NewsCard(article: article),
            );
          },

          onSwipe: (previousIndex, currentIndex, direction) {
            if (currentIndex != null && currentIndex >= articles.length - 3) {
              context.read<NewsBloc>().add(
                FetchNextPage(currentIndex, category),
              );
            }
            return true;
          },
          allowedSwipeDirection: const AllowedSwipeDirection.only(up: true),
          duration: const Duration(milliseconds: 400),
          scale: 1.0,
          padding: EdgeInsets.zero,
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                const Text(
                  'Brevity',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        color: Color.fromRGBO(0, 0, 0, 0.5),
                        offset: Offset(2.0, 2.0),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.info_outline, color: Colors.white),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingShimmer() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.8,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      },
    );
  }

  void _showAppInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Luminai'),
        content: const Text(
          'Stay informed with AI-curated news\nSwipe vertically to browse\nSwipe left to open article'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchArticleUrl(String url, BuildContext context) async {
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open article: $e')));
    }
  }
}

class _NewsCard extends StatelessWidget {
  final Article article;
  const _NewsCard({required this.article});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.3),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: article.urlToImage,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: Colors.grey[200]),
              errorWidget:
                  (context, url, error) => Container(
                    color: const Color.fromRGBO(128, 128, 128, 0.8),
                    child: const Icon(
                      Icons.broken_image,
                      color: Colors.white54,
                    ),
                  ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    const Color.fromARGB(230, 4, 4, 4),
                    Colors.transparent,
                  ],
                  stops: const [0.1, 0.7],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(68, 138, 255, 0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          article.sourceName.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const Gap(12),
                      Text(
                        DateFormat(
                          'MMM dd, y • h:mm a',
                        ).format(article.publishedAt),
                        style: TextStyle(
                          color: Colors.white.withAlpha(229),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const Gap(20),
                  _TappableHeadline(title: article.title, article: article),
                  const Gap(16),
                  Text(
                    article.description,
                    style: TextStyle(
                      color: Colors.white.withAlpha(229),
                      fontSize: 16,
                      height: 1.4,
                    ),
                    maxLines: 7,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(24),
                  Row(
                    children: [
                      const Icon(
                        Icons.arrow_upward_rounded,
                        color: Color.fromRGBO(255, 255, 255, 0.7),
                        size: 24,
                      ),
                      const Gap(8),
                      Text(
                        'Swipe to continue',
                        style: TextStyle(
                          color: Colors.white.withAlpha(204),
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(
                          Icons.open_in_new_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed:
                            () => _launchArticleUrl(article.url, context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchArticleUrl(String url, BuildContext context) async {
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open article: $e')));
    }
  }
}

class _TappableHeadline extends StatelessWidget {
  final String title;
  final Article article;
  const _TappableHeadline({required this.title, required this.article});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookmarkBloc, BookmarkState>(
      builder: (context, state) {        
        final isBookmarked = state is BookmarksLoaded 
            ? state.bookmarks.any((a) => a.url == article.url)
            : false;
        return GestureDetector(
          onTap: () => context.read<BookmarkBloc>().add(ToggleBookmarkEvent(article)),
          child: Text(
            title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isBookmarked ? Colors.blue : Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      },
    );
  }
}
