import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../features/authentication/presentation/pages/login_page.dart';
import '../features/authentication/presentation/pages/signup_page.dart';
import '../features/authentication/presentation/pages/otp_page.dart';
import '../features/authentication/presentation/pages/complete_profile_page.dart';
import '../features/authentication/presentation/pages/lawyer_onboarding_page.dart';
import '../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../features/admin/presentation/pages/lawyer_verification_page.dart';
import '../features/admin/presentation/pages/payment_management_page.dart';
import '../features/lawyers/presentation/pages/lawyers_list_page.dart';
import '../features/lawyers/presentation/pages/lawyer_details_page.dart';
import '../features/lawyers/presentation/pages/lawyer_setup_page.dart';
import '../features/lawyers/presentation/pages/lawyer_pending_page.dart';
import '../features/lawyers/presentation/pages/lawyer_dashboard_page.dart';
import '../features/lawyers/presentation/pages/lawyer_profile_edit_page.dart';
import '../features/bookings/presentation/pages/create_booking_page.dart';
import '../features/bookings/presentation/pages/bookings_list_page.dart';
import '../features/bookings/presentation/pages/booking_details_page.dart';
import '../features/chat/presentation/pages/chat_page.dart';
import '../features/payments/presentation/pages/payment_upload_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/profile/presentation/pages/notification_settings_page.dart';
import '../features/profile/presentation/pages/payment_methods_page.dart';
import '../features/profile/presentation/pages/app_settings_page.dart';
import '../features/profile/presentation/pages/help_center_page.dart';
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
      final isOnboardingLawyer = matchedLocation == '/lawyer-onboarding';
      final isPendingPage = matchedLocation == '/lawyer-pending';
      final isAdminPage = matchedLocation.startsWith('/admin') &&
          matchedLocation != '/admin-login';

      if (user != null) {
        debugPrint('--- AUTH SUCCESS ---');
        debugPrint('User: ${user.fullName ?? "No Name"}, Role: ${user.role}');
      }

      if (user == null) {
        if (isLoggingIn || isSigningUp || isOtp) return null;
        return '/login';
      }

      // توجيه الأدمن تلقائياً - الأولوية القصوى
      if (user.role == 'admin') {
        if (isCompletingProfile ||
            isOnboardingLawyer ||
            isLoggingIn ||
            isSigningUp) {
          return '/admin';
        }
        if (!isAdminPage) return '/admin';
        return null;
      }

      // توجيه المستخدم الجديد لإكمال بياناته (لغير الأدمن فقط)
      if (!user.isOnboardingComplete) {
        if (isCompletingProfile || isOnboardingLawyer) return null;
        return '/complete-profile';
      }

      // حماية صفحات الأدمن
      if (isAdminPage && user.role != 'admin') return '/';

      // توجيه المحامي غير الموثق
      if (user.role == 'lawyer' && !user.isVerified) {
        // التحقق مما إذا كان المحامي قد تم رفضه (أي لا يوجد له سجل في lawyer_profiles)
        // في هذه الحالة، سنوجهه لصفحة الإعداد ليعيد المحاولة بدلاً من صفحة الانتظار
        if (matchedLocation == '/lawyer-setup') return null;
        if (!isPendingPage) return '/lawyer-pending';
        return null;
      }

      // توجيه المستخدم المكتمل بعيداً عن صفحات الدخول والإكمال
      if (isLoggingIn ||
          isSigningUp ||
          isOtp ||
          (isCompletingProfile && user.isOnboardingComplete)) {
        // توجيه المحامي الموثق لصفحته الخاصة، والعميل للصفحة الرئيسية
        if (user.role == 'lawyer' && user.isVerified) {
          return '/lawyer-home'; // مسار لوحة تحكم المحامي
        }
        return '/';
      }

      // توجيه المحامي الموثق إذا حاول الدخول لصفحة قائمة المحامين (اختياري)
      if (matchedLocation == '/' && user.role == 'lawyer' && user.isVerified) {
        return '/lawyer-home';
      }

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
        path: '/lawyer-onboarding',
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>? ?? {};
          return LawyerOnboardingPage(
            fullName: extras['fullName'] ?? '',
            email: extras['email'] ?? '',
          );
        },
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) {
          final phone = state.extra as String? ?? '';
          return OtpPage(phone: phone);
        },
      ),
      GoRoute(
        path: '/lawyer-home',
        builder: (context, state) => const LawyerDashboardPage(),
      ),
      GoRoute(
        path: '/lawyer-profile-edit',
        builder: (context, state) => const LawyerProfileEditPage(),
      ),
      GoRoute(
        path: '/lawyer-setup',
        builder: (context, state) => const LawyerSetupPage(),
      ),
      GoRoute(
        path: '/lawyer-pending',
        builder: (context, state) => const LawyerPendingPage(),
      ),
      GoRoute(
        path: '/lawyer-details/:id',
        builder: (context, state) =>
            LawyerDetailsPage(profileId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/create-booking',
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>? ?? {};
          final lawyer = extras['lawyer'] as LawyerProfile?;
          if (lawyer == null) return const LawyersListPage();

          return CreateBookingPage(
            lawyer: lawyer,
            service: extras['service'],
            isCustom: extras['isCustom'] ?? false,
          );
        },
      ),
      GoRoute(
        path: '/bookings',
        builder: (context, state) => const BookingsListPage(),
      ),
      GoRoute(
        path: '/booking-details',
        builder: (context, state) {
          final booking = state.extra as Booking?;
          if (booking == null) return const BookingsListPage();
          return BookingDetailsPage(booking: booking);
        },
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
        path: '/payment-methods',
        builder: (context, state) => const PaymentMethodsPage(),
      ),
      GoRoute(
        path: '/app-settings',
        builder: (context, state) => const AppSettingsPage(),
      ),
      GoRoute(
        path: '/help-center',
        builder: (context, state) => const HelpCenterPage(),
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
