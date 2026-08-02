import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../features/authentication/presentation/pages/login_page.dart';
import '../features/authentication/presentation/pages/signup_page.dart';
import '../features/authentication/presentation/pages/otp_page.dart';
import '../features/authentication/presentation/pages/complete_profile_page.dart';
import '../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../features/admin/presentation/pages/lawyer_verification_page.dart';
import '../features/admin/presentation/pages/payment_management_page.dart';
import '../features/lawyers/presentation/pages/lawyers_list_page.dart';
import '../features/lawyers/presentation/pages/lawyer_details_page.dart';
import '../features/lawyers/presentation/pages/lawyer_setup_page.dart';
import '../features/bookings/presentation/pages/create_booking_page.dart';
import '../features/bookings/presentation/pages/bookings_list_page.dart';
import '../features/chat/presentation/pages/chat_page.dart';
import '../features/payments/presentation/pages/payment_upload_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/profile/presentation/pages/notification_settings_page.dart';
import '../features/bookings/domain/entities/booking.dart';
import '../features/lawyers/domain/entities/lawyer_profile.dart';
import '../features/authentication/presentation/providers/auth_provider.dart';

part 'router.g.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

@riverpod
GoRouter router(RouterRef ref) {
  final authState = ref.watch(authStateChangesProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(
      ref.watch(authRepositoryProvider).authStateChanges(),
    ),
    redirect: (context, state) {
      final user = authState.valueOrNull;

      final matchedLocation = state.matchedLocation;

      final isLoggingIn =
          matchedLocation == '/login' || matchedLocation == '/admin-login';
      final isSigningUp = matchedLocation == '/signup';
      final isOtp = matchedLocation == '/otp';
      final isCompletingProfile = matchedLocation == '/complete-profile';
      final isAdminPage = matchedLocation.startsWith('/admin') &&
          matchedLocation != '/admin-login';

      if (user != null) {
        debugPrint('--- AUTH SUCCESS ---');
        debugPrint(
            'User: ${user.fullName ?? "No Name"}, Role: ${user.role ?? "No Role"}');
      }

      if (user == null) {
        if (isLoggingIn || isSigningUp || isOtp) return null;
        return '/login';
      }

      // توجيه الأدمن تلقائياً إلى لوحة التحكم فور دخوله
      if ((user.role ?? 'user') == 'admin') {
        debugPrint(' - Redirecting Admin to /admin');
        if (!isAdminPage) return '/admin';
        return null;
      }

      // توجيه المستخدم الجديد لإكمال بياناته (فقط إذا لم يكن أدمن)
      if ((user.role ?? 'user') != 'admin' &&
          (user.fullName == null || user.fullName!.isEmpty) &&
          !isCompletingProfile) {
        return '/complete-profile';
      }

      if (isAdminPage && (user.role ?? 'user') != 'admin') {
        return '/';
      }

      if ((user.role ?? 'user') == 'lawyer' &&
          !user.isVerified &&
          matchedLocation != '/lawyer-setup' &&
          !isCompletingProfile) {
        return '/lawyer-setup';
      }

      if (isLoggingIn ||
          isSigningUp ||
          isOtp ||
          (isCompletingProfile &&
              user.fullName != null &&
              user.fullName!.isNotEmpty)) return '/';

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/admin-login',
        builder: (context, state) => const LoginPage(isAdminLogin: true),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupPage(),
      ),
      GoRoute(
        path: '/complete-profile',
        builder: (context, state) => const CompleteProfilePage(),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) {
          final phone = state.extra as String? ?? '';
          return OtpPage(phone: phone);
        },
      ),
      GoRoute(
        path: '/lawyer-setup',
        builder: (context, state) => const LawyerSetupPage(),
      ),
      GoRoute(
        path: '/lawyer-details/:id',
        builder: (context, state) =>
            LawyerDetailsPage(profileId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/create-booking',
        builder: (context, state) {
          final lawyer = state.extra as LawyerProfile?;
          if (lawyer == null) return const LawyersListPage();
          return CreateBookingPage(lawyer: lawyer);
        },
      ),
      GoRoute(
        path: '/bookings',
        builder: (context, state) => const BookingsListPage(),
      ),
      GoRoute(
        path: '/chat/:id',
        builder: (context, state) =>
            ChatPage(conversationId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/upload-payment',
        builder: (context, state) {
          final booking = state.extra as Booking?;
          if (booking == null) return const BookingsListPage();
          return PaymentUploadPage(booking: booking);
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: '/notification-settings',
        builder: (context, state) => const NotificationSettingsPage(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardPage(),
        routes: [
          GoRoute(
            path: 'lawyer-verifications',
            builder: (context, state) => const LawyerVerificationPage(),
          ),
          GoRoute(
            path: 'payments',
            builder: (context, state) => const PaymentManagementPage(),
          ),
        ],
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const LawyersListPage(),
      ),
    ],
  );
}
