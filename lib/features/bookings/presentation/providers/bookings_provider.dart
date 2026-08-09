import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:astshara/core/config/supabase_config.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../data/repositories/bookings_repository_impl.dart';
import '../../domain/entities/booking.dart';
import '../../domain/repositories/bookings_repository.dart';
part 'bookings_provider.g.dart';

class AvailableBookingSlot { final String id; final DateTime startsAt; const AvailableBookingSlot({required this.id, required this.startsAt}); }
@riverpod
BookingsRepository bookingsRepository(BookingsRepositoryRef ref) => BookingsRepositoryImpl(SupabaseConfig.client);
Future<String?> _getProfileId(String authUid) async { final row=await SupabaseConfig.client.from('profiles').select('id').eq('auth_id',authUid).maybeSingle(); return row?['id'] as String?; }
@riverpod
Future<List<Booking>> userBookings(UserBookingsRef ref) async { final user=ref.watch(authStateChangesProvider).value; if(user==null)return []; final id=await _getProfileId(user.id); if(id==null)return []; return ref.read(bookingsRepositoryProvider).getUserBookings(id); }
@riverpod
Future<List<Booking>> lawyerBookings(LawyerBookingsRef ref) async { final user=ref.watch(authStateChangesProvider).value; if(user==null)return []; final id=await _getProfileId(user.id); if(id==null)return []; return ref.read(bookingsRepositoryProvider).getLawyerBookings(id); }
final availableSlotsProvider=FutureProvider.family<List<AvailableBookingSlot>,String>((ref,lawyerId) async { final rows=await SupabaseConfig.client.from('lawyer_availability_slots').select('id, starts_at').eq('lawyer_id',lawyerId).eq('is_available',true).gt('starts_at',DateTime.now().toUtc().toIso8601String()).order('starts_at'); return (rows as List).map((row){final m=Map<String,dynamic>.from(row as Map);return AvailableBookingSlot(id:m['id'] as String,startsAt:DateTime.parse(m['starts_at'] as String).toLocal());}).toList(); });
final bookingDetailsProvider=FutureProvider.family<Map<String,dynamic>?,String>((ref,bookingId) async { final booking=await SupabaseConfig.client.from('bookings').select('user_id, consultation_type, consultation_mode, manual_payment_required, manual_received_amount, description, document_url, package_name, package_description, package_duration_minutes').eq('id',bookingId).maybeSingle(); if(booking==null)return null; final result=Map<String,dynamic>.from(booking); final profile=await SupabaseConfig.client.from('profiles').select('full_name').eq('id',booking['user_id']).maybeSingle(); result['client_name']=profile?['full_name']??'غير متوفر'; return result; });
final bookingClientNameProvider=FutureProvider.family<String?,String>((ref,bookingId) async { final result=await SupabaseConfig.client.rpc('get_booking_client_name',params:{'p_booking_id':bookingId}); if(result is List&&result.isNotEmpty){final row=Map<String,dynamic>.from(result.first as Map);final name=row['full_name']?.toString().trim();return name==null||name.isEmpty?null:name;} if(result is Map){final name=result['full_name']?.toString().trim();return name==null||name.isEmpty?null:name;} return null; });
final bookingContactProvider=FutureProvider.family<Map<String,dynamic>?,String>((ref,bookingId) async { final response=await SupabaseConfig.client.rpc('get_booking_contact_info',params:{'p_booking_id':bookingId}); if(response is List&&response.isNotEmpty)return Map<String,dynamic>.from(response.first as Map); return null; });
final bookingParticipantContactProvider=FutureProvider.family<Map<String,dynamic>?,String>((ref,bookingId) async { final response=await SupabaseConfig.client.rpc('get_booking_participant_contact_info',params:{'p_booking_id':bookingId}); if(response is List&&response.isNotEmpty)return Map<String,dynamic>.from(response.first as Map); return null; });

@riverpod
class BookingsController extends _$BookingsController {
  @override FutureOr<void> build() {}
  Future<Booking?> requestBooking({required String lawyerId,required DateTime scheduledAt,String? slotId,required String packageName,required String consultationType,String? description,dynamic documentBytes,String? documentName,String? consultationMode}) async {
    state=const AsyncLoading(); Booking? createdBooking;
    state=await AsyncValue.guard(() async { final user=ref.read(authStateChangesProvider).value; if(user==null)throw Exception('يجب تسجيل الدخول أولاً'); if(!(user.role=='user'||user.role=='client'))throw Exception('فقط طالب الخدمة يمكنه طلب حجز استشارة'); final repo=ref.read(bookingsRepositoryProvider); String? documentUrl; if(documentBytes!=null&&documentName!=null)documentUrl=await repo.uploadDocument(documentBytes,documentName); createdBooking=await repo.createBooking(lawyerId:lawyerId,scheduledAt:scheduledAt,slotId:slotId,packageName:packageName,consultationType:consultationType,description:description,documentUrl:documentUrl,consultationMode:consultationMode); ref.invalidate(userBookingsProvider); });
    return state.hasError?null:createdBooking;
  }
  Future<Booking?> recordManualPayment({required String bookingId,required double amount}) async { state=const AsyncLoading(); Booking? updated; state=await AsyncValue.guard(() async { updated=await ref.read(bookingsRepositoryProvider).recordManualPayment(bookingId,amount); ref.invalidate(lawyerBookingsProvider); ref.invalidate(userBookingsProvider); ref.invalidate(bookingDetailsProvider(bookingId)); }); return state.hasError?null:updated; }
}
