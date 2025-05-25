class AccountPageModel {
  final bool isLoading;
  final String email;
  final String name;

  AccountPageModel({
    required this.isLoading,
    required this.email,
    required this.name,
  });

  AccountPageModel.initial()
      : isLoading = false,
        email = '',
        name = '';

  AccountPageModel copyWith({
    bool? isLoading,
    String? email,
    String? name,
  }) {
    return AccountPageModel(
      isLoading: isLoading ?? this.isLoading,
      email: email ?? this.email,
      name: name ?? this.name,
    );
  }
}
