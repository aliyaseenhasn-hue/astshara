import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:astshara/core/config/supabase_config.dart';
import '../features/authentication/presentation/pages/login_page.dart';
import '../features/authentication/presentation/pages/signup_page.dart';
import '../features/authentication/presentation/pages/otp_page.dart';
import '../features/authentication/presentation/pages/complete_profile_page.dart';
import '../features/authentication/presentation/pages/lawyer_onboarding_page.dart';
import '../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../features/admin/presentation/pages/lawyer_verification_page.dart';
import '../features/admin/presentation/pages/payment_management_page.dart';
import '../features/admin/presentation/pages/specialization_change_requests_page.dart';
import '../features/lawyers/presentation/pages/lawyers_list_page.dart';
import '../features/lawyers/presentation/pages/lawyer_details_page.dart';
import '../features/lawyers/presentation/pages/lawyer_setup_page.dart';
import '../features/lawyers/presentation/pages/lawyer_pending_page.dart';
import '../features/lawyers/presentation/pages/lawyer_dashboard_page.dart';
import '../features/lawyers/presentation/pages/lawyer_profile_edit_page.dart';
import '../features/lawyers/presentation/pages/lawyer_availability_page.dart';
import '../features/lawyers/presentation/pages/specialization_change_page.dart';
import '../features/bookings/presentation/pages/create_booking_page.dart';
import '../features/bookings/presentation/pages/bookings_list_page.dart';
import '../features/bookings/presentation/pages/booking_details_page.dart';
import '../features/bookings/presentation/pages/manual_payment_page.dart';
import '../features/bookings/presentation/pages/manual_payment_required_page.dart';
import '../features/chat/presentation/pages/chat_page.dart';
import '../features/payments/presentation/pages/payment_upload_page.dart';
import '../features/payments/presentation/pages/payment_result_page.dart';
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
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _subscription;
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

Future<bool> _lawyerHasPendingManualPayment() async {
  try {
    final authUser = SupabaseConfig.client.auth.currentUser;
    if (authUser == null) return false;

    final profile = await SupabaseConfig.client
        .from('profiles')
        .select('id')
        .eq('auth_id', authUser.id)
        .maybeSingle();
    final profileId = profile?['id'] as String?;
    if (profileId == null) return false;

    final pending = await SupabaseConfig.client
        .from('bookings')
        .select('id')
        .eq('lawyer_id', profileId)
        .eq('manual_payment_required', true)
        .isFilter('manual_received_at', null)
        .inFilter('status', ['بانتظار التأكيد', 'قيد مراجعة المحامي'])
        .limit(1)
        .maybeSingle();

    return pending != null;
  } catch (_) {
    // A temporary read failure must not lock the lawyer out of the app.
    return false;
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
    redirect: (context, state) async {
      final user = authState.valueOrNull;
      final location = state.matchedLocation;
      final login = location == '/login' || location == '/admin-login';
      final signup = location == '/signup';
      final otp = location == '/otp';
      final complete = location == '/complete-profile';
      final onboarding = location == '/lawyer-onboarding';
      final pending = location == '/lawyer-pending';
      final paymentResult = location == '/payment-result';
      final manualPaymentGate = location == '/manual-payment-required';
      final manualPayment = location == '/manual-payment';
      final admin = location.startsWith('/admin') && location != '/admin-login';
      final isClient = user?.role == 'user' || user?.role == 'client';
      final clientOnlyBooking = location == '/create-booking';

      if (paymentResult) return null;
      if (user == null) return (login || signup || otp) ? null : '/login';

      if (user.role == 'admin') {
        if (complete || onboarding || login || signup) return '/admin';
        return admin ? null : '/admin';
      }

      if (!user.isOnboardingComplete) {
        return (complete || onboarding) ? null : '/complete-profile';
      }

      if (admin && user.role != 'admin') return '/';
      if (clientOnlyBooking && !isClient) {
        return user.role == 'lawyer' ? '/lawyer-home' : '/';
      }

      if (user.role == 'lawyer') {
        if (!user.isVerified) {
          return location == '/lawyer-setup' || pending ? null : '/lawyer-pending';
        }

        if (!manualPaymentGate && !manualPayment) {
          final hasPendingManualPayment = await _lawyerHasPendingManualPayment();
          if (hasPendingManualPayment) return '/manual-payment-required';
        }
      }

      if (login || signup || otp || (complete && user.isOnboardingComplete)) {
        return user.role == 'lawyer' && user.isVerified ? '/lawyer-home' : '/';
      }
      if (location == '/' && user.role == 'lawyer' && user.isVerified) {
        return '/lawyer-home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (c, s) => const LoginPage()),
      GoRoute(path: '/admin-login', builder: (c, s) => const LoginPage(isAdminLogin: true)),
      GoRoute(path: '/signup', builder: (c, s) => const SignupPage()),
      GoRoute(path: '/complete-profile', builder: (c, s) => const CompleteProfilePage()),
      GoRoute(
        path: '/lawyer-onboarding',
        builder: (c, s) {
          final e = s.extra as Map<String, dynamic>? ?? {};
          return LawyerOnboardingPage(fullName: e['fullName'] ?? '', email: e['email'] ?? '');
        },
      ),
      GoRoute(path: '/otp', builder: (c, s) => OtpPage(phone: s.extra as String? ?? '')),
      GoRoute(path: '/lawyer-home', builder: (c, s) => const LawyerDashboardPage()),
      GoRoute(path: '/lawyer-profile-edit', builder: (c, s) => const LawyerProfileEditPage()),
      GoRoute(path: '/lawyer-availability', builder: (c, s) => const LawyerAvailabilityPage()),
      GoRoute(path: '/lawyer-specialization-change', builder: (c, s) => const SpecializationChangePage()),
      GoRoute(path: '/lawyer-setup', builder: (c, s) => const LawyerSetupPage()),
      GoRoute(path: '/lawyer-pending', builder: (c, s) => const LawyerPendingPage()),
      GoRoute(path: '/lawyer-details/:id', builder: (c, s) => LawyerDetailsPage(profileId: s.pathParameters['id']!)),
      GoRoute(
        path: '/create-booking',
        builder: (c, s) {
          final e = s.extra as Map<String, dynamic>?;
          final lawyer = e?['lawyer'] as LawyerProfile?;
          if (lawyer == null) {
            return const Scaffold(body: Center(child: Text('تعذر فتح صفحة الحجز. يرجى العودة إلى ملف المحامي والمحاولة مرة أخرى.')));
          }
          return CreateBookingPage(lawyer: lawyer, service: e?['service'], isCustom: e?['isCustom'] == true);
        },
      ),
      GoRoute(path: '/bookings', builder: (c, s) => const BookingsListPage()),
      GoRoute(
        path: '/booking-details',
        builder: (c, s) {
          final b = s.extra as Booking?;
          return b == null ? const BookingsListPage() : BookingDetailsPage(booking: b);
        },
      ),
      GoRoute(
        path: '/manual-payment-required',
        builder: (c, s) => const ManualPaymentRequiredPage(),
      ),
      GoRoute(
        path: '/manual-payment',
        builder: (c, s) {
          final b = s.extra as Booking?;
          return b == null ? const ManualPaymentRequiredPage() : ManualPaymentPage(booking: b);
        },
      ),
      GoRoute(path: '/chat/:id', builder: (c, s) => ChatPage(conversationId: s.pathParameters['id']!)),
      GoRoute(
        path: '/upload-payment',
        builder: (c, s) {
          final b = s.extra as Booking?;
          return b == null ? const BookingsListPage() : PaymentUploadPage(booking: b);
        },
      ),
      GoRoute(path: '/payment-result', builder: (c, s) => PaymentResultPage(status: s.uri.queryParameters['status'], bookingId: s.uri.queryParameters['booking_id'])),
      GoRoute(path: '/profile', builder: (c, s) => const ProfilePage()),
      GoRoute(path: '/notification-settings', builder: (c, s) => const NotificationSettingsPage()),
      GoRoute(path: '/payment-methods', builder: (c, s) => const PaymentMethodsPage()),
      GoRoute(path: '/app-settings', builder: (c, s) => const AppSettingsPage()),
      GoRoute(path: '/help-center', builder: (c, s) => const HelpCenterPage()),
      GoRoute(
        path: '/admin',
        builder: (c, s) => const AdminDashboardPage(),
        routes: [
          GoRoute(path: 'lawyer-verifications', builder: (c, s) => const LawyerVerificationPage()),
          GoRoute(path: 'payments', builder: (c, s) => const PaymentManagementPage()),
          GoRoute(path: 'specialization-change-requests', builder: (c, s) => const SpecializationChangeRequestsPage()),
        ],
      ),
      GoRoute(path: '/', builder: (c, s) => const LawyersListPage()),
    ],
  );
}
