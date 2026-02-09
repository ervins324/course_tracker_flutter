class Video {
  final String videoId;
  final String title;
  final Duration duration;
  final bool isWatched;

  Video({
    required this.videoId,
    required this.title,
    required this.duration,
    this.isWatched = false,
  });

  Video copyWith({bool? isWatched}) {
    return Video(
      videoId: videoId,
      title: title,
      duration: duration,
      isWatched: isWatched ?? this.isWatched,
    );
  }
}
