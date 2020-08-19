import 'dart:async';
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import 'package:http/http.dart' as http;
import 'package:rxdart/rxdart.dart';

import 'package:infinite_list/posts/posts.dart';

part 'post_event.dart';
part 'post_state.dart';

class PostBloc extends Bloc<PostEvent, PostState> {
  final http.Client httpClient;

  PostBloc({@required this.httpClient}) : super(PostInitial());

  // Overriding transform allows us to transform the Stream before mapEventToState is called.
  // This allows for operations like distinct(), debounceTime(), etc... to be applied.
  @override
  Stream<Transition<PostEvent, PostState>> transformEvents(Stream<PostEvent> events, transitionFn) {
    return super.transformEvents(
        events.debounceTime(const Duration(microseconds: 500)), 
        transitionFn
    );
  }

  @override
  Stream<PostState> mapEventToState(PostEvent event) async* {
    final currentState = state;

    if (event is PostFetched && !_hasReachedMax(currentState)) {
      try {
        if (currentState is PostInitial) {
          final posts = await _fetchPosts(0, 20);
          yield PostSuccess(posts: posts, hasReachedMax: false);
          return;
        }
        if (currentState is PostSuccess) {
          final posts = await _fetchPosts(currentState.posts.length, 20);
          yield posts.isEmpty
              ? currentState.copyWith(posts: posts, hasReachedMax: true)
              : PostSuccess(
                  posts: currentState.posts + posts, hasReachedMax: false);
        }
      } on Exception {
        yield PostFailure();
      }
    }
  }

  bool _hasReachedMax(PostState state) =>
      state is PostSuccess && state.hasReachedMax;

  Future<List<Post>> _fetchPosts(int startIndex, int limit) async{
    final response = await httpClient.get(
        'https://jsonplaceholder.typicode.com/posts?_start=$startIndex&_limit=$limit'
    );
    if(response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      return data.map((e) {
        return Post(
          id: e['id'] as int,
          title: e['title'] as String,
          body: e['body'] as String,
        );
      }).toList();
    } else {
      throw Exception('Error fetching posts !');
    }
  }
}
