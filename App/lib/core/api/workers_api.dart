import 'package:handy_app/core/api/api_client.dart';
import 'package:handy_app/features/reviews/domain/worker_rating_summary.dart';
import 'package:handy_app/features/worker/domain/worker_public_details.dart';

class WorkersApi {
  WorkersApi({required ApiClient client}) : _client = client;

  final ApiClient _client;

  Future<List<WorkerRatingSummary>> loadWorkerRatingSummaries(
    List<String> workerIds,
  ) async {
    if (workerIds.isEmpty) {
      return const [];
    }

    final rows = await _client.postList(
      '/v1/workers/ratings/summary',
      body: {'worker_ids': workerIds},
    );

    return rows
        .map(WorkerRatingSummary.fromJson)
        .toList(growable: false);
  }

  Future<WorkerPublicDetails> loadWorkerPublicDetails(String workerId) async {
    final row = await _client.getObject('/v1/workers/$workerId');
    return WorkerPublicDetails.fromJson(row);
  }
}
