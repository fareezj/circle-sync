import 'dart:io';

import 'package:circle_sync/features/circles/data/models/circle_model.dart';
import 'package:circle_sync/features/map/data/models/map_models.dart';
import 'package:circle_sync/models/circle_model.dart';
import 'package:circle_sync/models/post_model.dart';
import 'package:circle_sync/models/user.dart';
import 'package:latlong2/latlong.dart';

class MapPageState {
  final List<PlacesModel> placeList;
  final bool useSimulation;
  final bool isLoading;
  final String currentCircleId;
  final bool hasCircle;
  final List<CircleModel> joinedCircles;
  final String? circleName;
  final List<CircleMembersModel> circleMembers;
  final CircleMembersModel? selectedMember;
  final CircleMembersModel? currentUser;
  final PostModel? selectedPost;
  final bool isSharingLocation;
  final LatLng? selectedPlace;
  final LatLng? currentLocation;
  final LatLng? destinationLocation;
  final List<LatLng> osrmRoutePoints;
  final List<LatLng> trackingPoints;
  final Map<String, UserLocationInfo> otherUsersLocations;
  final Map<String, PostModel> originalPosts;
  final Map<String, PostModel> posts;
  final int selectedChipItem;
  final bool isLocationAlwaysAllowed;
  final File? chosenPostImage;
  final DateTime selectedDate;
  final CircleModel? selectedCircle;

  MapPageState({
    required this.isLoading,
    required this.placeList,
    this.selectedMember,
    this.selectedPost,
    this.currentUser,
    this.useSimulation = false,
    this.currentCircleId = '',
    this.hasCircle = false,
    this.joinedCircles = const [],
    this.circleName,
    this.circleMembers = const [],
    this.isSharingLocation = false,
    this.selectedPlace,
    this.currentLocation,
    this.destinationLocation,
    this.osrmRoutePoints = const [],
    this.trackingPoints = const [],
    this.otherUsersLocations = const {},
    this.originalPosts = const {},
    this.posts = const {},
    this.selectedChipItem = 0,
    this.isLocationAlwaysAllowed = false,
    this.chosenPostImage,
    required this.selectedDate,
    this.selectedCircle,
  });
  factory MapPageState.initial() {
    return MapPageState(
      isLoading: false,
      placeList: [],
      useSimulation: false,
      currentCircleId: '',
      hasCircle: false,
      joinedCircles: [],
      selectedMember: null,
      selectedPost: null,
      currentUser: null,
      circleName: null,
      circleMembers: [],
      isSharingLocation: false,
      selectedPlace: null,
      currentLocation: null,
      destinationLocation: null,
      osrmRoutePoints: [],
      trackingPoints: [],
      otherUsersLocations: {},
      originalPosts: {},
      posts: {},
      selectedChipItem: 0,
      isLocationAlwaysAllowed: false,
      chosenPostImage: null,
      selectedCircle: null,
      selectedDate: DateTime.now(),
    );
  }
  MapPageState copyWith({
    List<PlacesModel>? placeList,
    bool? isLoading,
    bool? useSimulation,
    List<CircleModel>? joinedCircles,
    String? currentCircleId,
    bool? hasCircle,
    String? circleName,
    List<CircleMembersModel>? circleMembers,
    CircleMembersModel? selectedMember,
    PostModel? selectedPost,
    CircleMembersModel? currentUser,
    bool? isSharingLocation,
    LatLng? selectedPlace,
    LatLng? currentLocation,
    LatLng? destinationLocation,
    List<LatLng>? osrmRoutePoints,
    List<LatLng>? trackingPoints,
    Map<String, UserLocationInfo>? otherUsersLocations,
    Map<String, PostModel>? originalPosts,
    Map<String, PostModel>? posts,
    int? selectedChipItem,
    bool? isLocationAlwaysAllowed,
    File? chosenPostImage,
    DateTime? selectedDate,
    CircleModel? selectedCircle,
  }) {
    return MapPageState(
      isLoading: isLoading ?? this.isLoading,
      placeList: placeList ?? this.placeList,
      selectedMember: selectedMember ?? this.selectedMember,
      currentUser: currentUser ?? this.currentUser,
      useSimulation: useSimulation ?? this.useSimulation,
      currentCircleId: currentCircleId ?? this.currentCircleId,
      hasCircle: hasCircle ?? this.hasCircle,
      joinedCircles: joinedCircles ?? this.joinedCircles,
      circleName: circleName ?? this.circleName,
      circleMembers: circleMembers ?? this.circleMembers,
      isSharingLocation: isSharingLocation ?? this.isSharingLocation,
      selectedPlace: selectedPlace ?? this.selectedPlace,
      selectedPost: selectedPost ?? this.selectedPost,
      currentLocation: currentLocation ?? this.currentLocation,
      destinationLocation: destinationLocation ?? this.destinationLocation,
      osrmRoutePoints: osrmRoutePoints ?? this.osrmRoutePoints,
      trackingPoints: trackingPoints ?? this.trackingPoints,
      otherUsersLocations: otherUsersLocations ?? this.otherUsersLocations,
      originalPosts: originalPosts ?? this.originalPosts,
      posts: posts ?? this.posts,
      chosenPostImage: chosenPostImage ?? this.chosenPostImage,
      selectedChipItem: selectedChipItem ?? this.selectedChipItem,
      isLocationAlwaysAllowed:
          isLocationAlwaysAllowed ?? this.isLocationAlwaysAllowed,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedCircle: selectedCircle ?? this.selectedCircle,
    );
  }
}
