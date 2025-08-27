import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/performance_monitoring_service.dart';

/// Lazy loading list view with pagination
class LazyLoadingListView<T> extends StatefulWidget {
  final Future<List<T>> Function(int page, int limit) onLoadMore;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Widget? Function(BuildContext context)? emptyBuilder;
  final Widget? Function(BuildContext context)? errorBuilder;
  final Widget? Function(BuildContext context)? loadingBuilder;
  final int pageSize;
  final String? performanceTag;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;

  const LazyLoadingListView({
    super.key,
    required this.onLoadMore,
    required this.itemBuilder,
    this.emptyBuilder,
    this.errorBuilder,
    this.loadingBuilder,
    this.pageSize = 20,
    this.performanceTag,
    this.shrinkWrap = false,
    this.physics,
    this.padding,
  });

  @override
  State<LazyLoadingListView<T>> createState() => _LazyLoadingListViewState<T>();
}

class _LazyLoadingListViewState<T> extends State<LazyLoadingListView<T>> {
  final List<T> _items = [];
  final ScrollController _scrollController = ScrollController();
  final PerformanceMonitoringService _performance = PerformanceMonitoringService();
  
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitialData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreData();
    }
  }

  Future<void> _loadInitialData() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    await _loadPage(0);
  }

  Future<void> _loadMoreData() async {
    if (_isLoading || !_hasMore) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    await _loadPage(_currentPage + 1);
  }

  Future<void> _loadPage(int page) async {
    final tag = widget.performanceTag ?? 'lazy_load_page_$page';
    _performance.startOperation(tag);
    
    try {
      final newItems = await widget.onLoadMore(page, widget.pageSize);
      
      setState(() {
        if (page == 0) {
          _items.clear();
        }
        _items.addAll(newItems);
        _currentPage = page;
        _hasMore = newItems.length == widget.pageSize;
        _isLoading = false;
        _error = null;
      });
      
      _performance.endOperation(tag, metadata: {
        'page': page,
        'items_loaded': newItems.length,
        'total_items': _items.length,
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      
      _performance.endOperation(tag, metadata: {
        'page': page,
        'error': e.toString(),
      });
    }
  }

  Future<void> _refresh() async {
    _currentPage = 0;
    _hasMore = true;
    await _loadInitialData();
  }

  Widget _buildLoadingIndicator() {
    if (widget.loadingBuilder != null) {
      return widget.loadingBuilder!(context) ?? const SizedBox.shrink();
    }
    
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildError() {
    if (widget.errorBuilder != null) {
      return widget.errorBuilder!(context) ?? const SizedBox.shrink();
    }
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading data',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error occurred',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refresh,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    if (widget.emptyBuilder != null) {
      return widget.emptyBuilder!(context) ?? const SizedBox.shrink();
    }
    
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('No items found'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && _items.isEmpty) {
      return _buildError();
    }

    if (_isLoading && _items.isEmpty) {
      return _buildLoadingIndicator();
    }

    if (_items.isEmpty) {
      return _buildEmpty();
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        controller: _scrollController,
        shrinkWrap: widget.shrinkWrap,
        physics: widget.physics,
        padding: widget.padding,
        itemCount: _items.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _items.length) {
            // Loading indicator for more items
            return _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : const SizedBox.shrink();
          }

          return widget.itemBuilder(context, _items[index], index);
        },
      ),
    );
  }
}

/// Lazy loading grid view with pagination
class LazyLoadingGridView<T> extends StatefulWidget {
  final Future<List<T>> Function(int page, int limit) onLoadMore;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Widget? Function(BuildContext context)? emptyBuilder;
  final Widget? Function(BuildContext context)? errorBuilder;
  final Widget? Function(BuildContext context)? loadingBuilder;
  final int pageSize;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
  final String? performanceTag;
  final EdgeInsetsGeometry? padding;

  const LazyLoadingGridView({
    super.key,
    required this.onLoadMore,
    required this.itemBuilder,
    this.emptyBuilder,
    this.errorBuilder,
    this.loadingBuilder,
    this.pageSize = 20,
    this.crossAxisCount = 2,
    this.mainAxisSpacing = 8.0,
    this.crossAxisSpacing = 8.0,
    this.childAspectRatio = 1.0,
    this.performanceTag,
    this.padding,
  });

  @override
  State<LazyLoadingGridView<T>> createState() => _LazyLoadingGridViewState<T>();
}

class _LazyLoadingGridViewState<T> extends State<LazyLoadingGridView<T>> {
  final List<T> _items = [];
  final ScrollController _scrollController = ScrollController();
  final PerformanceMonitoringService _performance = PerformanceMonitoringService();
  
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitialData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreData();
    }
  }

  Future<void> _loadInitialData() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    await _loadPage(0);
  }

  Future<void> _loadMoreData() async {
    if (_isLoading || !_hasMore) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    await _loadPage(_currentPage + 1);
  }

  Future<void> _loadPage(int page) async {
    final tag = widget.performanceTag ?? 'lazy_grid_page_$page';
    _performance.startOperation(tag);
    
    try {
      final newItems = await widget.onLoadMore(page, widget.pageSize);
      
      setState(() {
        if (page == 0) {
          _items.clear();
        }
        _items.addAll(newItems);
        _currentPage = page;
        _hasMore = newItems.length == widget.pageSize;
        _isLoading = false;
        _error = null;
      });
      
      _performance.endOperation(tag, metadata: {
        'page': page,
        'items_loaded': newItems.length,
        'total_items': _items.length,
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      
      _performance.endOperation(tag, metadata: {
        'page': page,
        'error': e.toString(),
      });
    }
  }

  Future<void> _refresh() async {
    _currentPage = 0;
    _hasMore = true;
    await _loadInitialData();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && _items.isEmpty) {
      return _buildError();
    }

    if (_isLoading && _items.isEmpty) {
      return _buildLoadingIndicator();
    }

    if (_items.isEmpty) {
      return _buildEmpty();
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: GridView.builder(
        controller: _scrollController,
        padding: widget.padding,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: widget.crossAxisCount,
          mainAxisSpacing: widget.mainAxisSpacing,
          crossAxisSpacing: widget.crossAxisSpacing,
          childAspectRatio: widget.childAspectRatio,
        ),
        itemCount: _items.length + (_hasMore && _isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _items.length) {
            // Loading indicator spans across all columns
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return widget.itemBuilder(context, _items[index], index);
        },
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    if (widget.loadingBuilder != null) {
      return widget.loadingBuilder!(context) ?? const SizedBox.shrink();
    }
    
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildError() {
    if (widget.errorBuilder != null) {
      return widget.errorBuilder!(context) ?? const SizedBox.shrink();
    }
    
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error loading data',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _refresh,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    if (widget.emptyBuilder != null) {
      return widget.emptyBuilder!(context) ?? const SizedBox.shrink();
    }
    
    return const Center(
      child: Text('No items found'),
    );
  }
}

/// Lazy loading tab view for better performance
class LazyTabView extends StatefulWidget {
  final List<Tab> tabs;
  final List<Widget Function()> tabBuilders;
  final TabController? controller;

  const LazyTabView({
    super.key,
    required this.tabs,
    required this.tabBuilders,
    this.controller,
  });

  @override
  State<LazyTabView> createState() => _LazyTabViewState();
}

class _LazyTabViewState extends State<LazyTabView>
    with TickerProviderStateMixin {
  late TabController _controller;
  final Map<int, Widget> _cachedTabs = {};
  final PerformanceMonitoringService _performance = PerformanceMonitoringService();

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? 
        TabController(length: widget.tabs.length, vsync: this);
    _controller.addListener(_onTabChanged);
    
    // Build initial tab
    _buildTab(0);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onTabChanged() {
    if (_controller.indexIsChanging) {
      _buildTab(_controller.index);
    }
  }

  void _buildTab(int index) {
    if (_cachedTabs.containsKey(index)) return;
    
    final tag = 'build_tab_$index';
    _performance.startOperation(tag);
    
    try {
      final tabWidget = widget.tabBuilders[index]();
      setState(() {
        _cachedTabs[index] = tabWidget;
      });
      
      _performance.endOperation(tag, metadata: {
        'tab_index': index,
        'cached_tabs_count': _cachedTabs.length,
      });
    } catch (e) {
      _performance.endOperation(tag, metadata: {
        'tab_index': index,
        'error': e.toString(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _controller,
          tabs: widget.tabs,
        ),
        Expanded(
          child: TabBarView(
            controller: _controller,
            children: List.generate(widget.tabs.length, (index) {
              return _cachedTabs[index] ?? 
                  const Center(child: CircularProgressIndicator());
            }),
          ),
        ),
      ],
    );
  }
}

/// Lazy image widget with fade-in and error handling
class LazyImage extends StatefulWidget {
  final String? imageUrl;
  final String? localPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Duration fadeInDuration;

  const LazyImage({
    super.key,
    this.imageUrl,
    this.localPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.fadeInDuration = const Duration(milliseconds: 300),
  });

  @override
  State<LazyImage> createState() => _LazyImageState();
}

class _LazyImageState extends State<LazyImage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final PerformanceMonitoringService _performance = PerformanceMonitoringService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.fadeInDuration,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onImageLoaded() {
    _animationController.forward();
  }

  Widget _buildPlaceholder() {
    return widget.placeholder ?? 
        Container(
          width: widget.width,
          height: widget.height,
          color: Colors.grey[200],
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
  }

  Widget _buildError() {
    return widget.errorWidget ?? 
        Container(
          width: widget.width,
          height: widget.height,
          color: Colors.grey[300],
          child: const Icon(Icons.error_outline, color: Colors.grey),
        );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrl != null) {
      return Image.network(
        widget.imageUrl!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            _onImageLoaded();
            return FadeTransition(
              opacity: _fadeAnimation,
              child: child,
            );
          }
          return _buildPlaceholder();
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildError();
        },
      );
    } else if (widget.localPath != null) {
      return FadeInImage(
        placeholder: MemoryImage(Uint8List(0)),
        image: FileImage(File(widget.localPath!)),
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        fadeInDuration: widget.fadeInDuration,
        imageErrorBuilder: (context, error, stackTrace) => _buildError(),
      );
    }

    return _buildError();
  }
}

/// Provider for lazy loading state management
final lazyLoadingStateProvider = StateNotifierProvider.family<
    LazyLoadingNotifier, LazyLoadingState, String>((ref, key) {
  return LazyLoadingNotifier();
});

class LazyLoadingNotifier extends StateNotifier<LazyLoadingState> {
  LazyLoadingNotifier() : super(const LazyLoadingState());

  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  void setError(String? error) {
    state = state.copyWith(error: error, isLoading: false);
  }

  void setHasMore(bool hasMore) {
    state = state.copyWith(hasMore: hasMore);
  }

  void reset() {
    state = const LazyLoadingState();
  }
}

class LazyLoadingState {
  final bool isLoading;
  final String? error;
  final bool hasMore;

  const LazyLoadingState({
    this.isLoading = false,
    this.error,
    this.hasMore = true,
  });

  LazyLoadingState copyWith({
    bool? isLoading,
    String? error,
    bool? hasMore,
  }) {
    return LazyLoadingState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}