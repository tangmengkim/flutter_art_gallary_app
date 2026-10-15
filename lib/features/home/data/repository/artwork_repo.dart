import 'package:art_gallary/core/constants/api_constants.dart';
import 'package:art_gallary/features/home/data/models/artwork_model.dart';
import 'package:art_gallary/http/base_dio.dart';
import 'package:art_gallary/http/base_response.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'artwork_repo.g.dart';

@RestApi()
abstract class ArtworkApiClient {
  factory ArtworkApiClient({Dio? dio}) {
    final targetDio = dio ?? BaseDio.instance;
    return _ArtworkApiClient(targetDio);
  }

  // @GET(ApiConstants.employeeList)
  // @Extra({'unwrap': false}) 
  // Future<BaseResponse<EmployeeListModel>> getEmployeeList(
  //   @Queries() Map<String, dynamic> queries,
  // );
  
  @GET(ApiConstants.artList)
  Future<List<ArtworkModel>> getArtworkList(@Queries() Map<String, dynamic> queries);
  
  @GET(ApiConstants.artDetail)
  Future<ArtworkModel> getArtworkDetail(@Path('id') String id);

}

@riverpod
ArtworkRepository artworkRepository(Ref ref) => ArtworkRepository();

class ArtworkRepository {
  final ArtworkApiClient _apiClient;

  ArtworkRepository([ArtworkApiClient? apiClient]) 
      : _apiClient = apiClient ?? ArtworkApiClient();

  Future<List<ArtworkModel>> getArtList({required Map<String, dynamic> queries}) async => _apiClient.getArtworkList(queries);
  

  Future<ArtworkModel> getArtDetail({required String id}) async => _apiClient.getArtworkDetail(id);
    
}
