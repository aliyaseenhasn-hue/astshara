import '../entities/lawyer_profile.dart';

abstract class LawyersRepository {
  Future<List<LawyerProfile>> getLawyers();
  Future<LawyerProfile?> getLawyerProfile(String profileId);
  Future<void> updateLawyerProfile(LawyerProfile profile);
  Future<String> uploadDocument(String path, String fileName);
}
