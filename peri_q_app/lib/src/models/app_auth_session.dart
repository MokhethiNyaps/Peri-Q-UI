class AppAuthSession {
  const AppAuthSession({
    required this.hasSession,
    this.userId,
    this.email,
    this.isAnonymous = false,
    this.isAdmin = false,
    this.customerName,
    this.customerPhone,
  });

  const AppAuthSession.signedOut()
    : hasSession = false,
      userId = null,
      email = null,
      isAnonymous = false,
      isAdmin = false,
      customerName = null,
      customerPhone = null;

  final bool hasSession;
  final String? userId;
  final String? email;
  final bool isAnonymous;
  final bool isAdmin;
  final String? customerName;
  final String? customerPhone;

  AppAuthSession copyWith({
    bool? hasSession,
    String? userId,
    String? email,
    bool? isAnonymous,
    bool? isAdmin,
    String? customerName,
    String? customerPhone,
  }) {
    return AppAuthSession(
      hasSession: hasSession ?? this.hasSession,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      isAdmin: isAdmin ?? this.isAdmin,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
    );
  }
}
