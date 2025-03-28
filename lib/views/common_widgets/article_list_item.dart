import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:newsai/controller/bloc/bookmark_bloc.dart';
import 'package:newsai/controller/bloc/bookmark_event.dart';
import 'package:newsai/controller/bloc/bookmark_state.dart';
import 'package:newsai/models/article_model.dart';

class ArticleListItem extends StatelessWidget {
  final Article article;
  final VoidCallback onTap;
  final bool showBookmark;

  const ArticleListItem({
    super.key,
    required this.article,
    required this.onTap,
    this.showBookmark = true,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      margin: EdgeInsets.symmetric(vertical: screenSize.height * 0.011),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            // Image Section
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: CachedNetworkImage(
                imageUrl: article.urlToImage,
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.grey[800]),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[700],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
            
            // Text Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.sourceName.toUpperCase(),
                      style: TextStyle(
                        color: Colors.blue[400],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color.fromARGB(221, 249, 249, 249),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('MMM dd, y • h:mm a').format(article.publishedAt),
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Bookmark/Remove Button
            if (showBookmark)
              BlocBuilder<BookmarkBloc, BookmarkState>(
                builder: (context, state) {
                  final isBookmarked = state is BookmarksLoaded &&
                      state.bookmarks.any((a) => a.url == article.url);
                  
                  return IconButton(
                    icon: Icon(
                      isBookmarked ? Icons.bookmark : Icons.bookmark_add_outlined,
                      color: isBookmarked ? Colors.blue[400] : Colors.grey[400],
                    ),
                    onPressed: () => context
                        .read<BookmarkBloc>()
                        .add(ToggleBookmarkEvent(article)),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}