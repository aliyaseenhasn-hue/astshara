import 'dart:typed_data';
import '../entities/lawyer_profile.dart';

abstract class LawyersRepository {
  Future<List<LawyerProfile>> getLawyers();
  Future<LawyerProfile?> getLawyerProfile(String profileId);
  Future<void> updateLawyerProfile(LawyerProfile profile);
  Future<String> uploadFile(Uint8List bytes, String fileName, String bucket);
  Future<void> requestSpecializationChange(List<String> newSpecs);
}
