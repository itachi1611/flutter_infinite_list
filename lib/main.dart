import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:infinite_list/bloc_observer.dart';
import 'package:infinite_list/posts/bloc/bloc.dart';
import 'package:infinite_list/posts/widgets/widgets.dart';

void main() {
  Bloc.observer = SimpleBlocObserver();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Infinite Scroll',
        home: Scaffold(
          appBar: AppBar(
            title: Text('Posts'),
          ),
          body: BlocProvider(
            create: (context) =>
                PostBloc(httpClient: http.Client())..add(PostFetched()),
            child: HomePage(),
          ),
        ));
  }
}

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _HomePageState();
  }
}

class _HomePageState extends State<HomePage> {
  final _scrollController = ScrollController();
  final _scrollThreshold = 200.0;
  PostBloc _postBloc;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    //_postBloc = BlocProvider.of<PostBloc>(context);
    _postBloc = context.bloc<PostBloc>();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PostBloc, PostState>(
      // ignore: missing_return
      builder: (context, state) {
        assert(context != null);
        if(state is PostInitial) {
          return Center (
            child: CircularProgressIndicator(),
          );
        }
        if(state is PostFailure) {
          return Center(
            child: Text('Failed to fetch posts !'),
          );
        }
        if(state is PostSuccess) {
          if(state.posts.isEmpty) {
            return Center(
              child: Text('No more new posts !'),
            );
          }
          return ListView.builder(
            itemBuilder: (BuildContext context, int index) {
              return index >= state.posts.length
                  ? BottomLoader()
                  : PostWidget(post: state.posts[index]);
            },
            itemCount: state.hasReachedMax ? state.posts.length : state.posts.length + 1,
            controller: _scrollController,
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if(maxScroll - currentScroll <= _scrollThreshold) {
      _postBloc.add(PostFetched());
    }
  }
}
