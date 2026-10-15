import 'package:art_gallary/core/storage/storage_registry.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

part 'artwork_model.freezed.dart';
part 'artwork_model.g.dart';

@freezed
@HiveType(typeId: StorageRegistry.artworkModelTypeId)
abstract class ArtworkModel with _$ArtworkModel {
  const ArtworkModel._();

  const factory ArtworkModel({
    @JsonKey(name: "id") @HiveField(0) String? id,
    @JsonKey(name: "author") @HiveField(1) String? author,
    @JsonKey(name: "width") @HiveField(2) int? width,
    @JsonKey(name: "height") @HiveField(3) int? height,
    @JsonKey(name: "url") @HiveField(4) String? url,
    @JsonKey(name: "download_url") @HiveField(5) String? downloadUrl,
    

    @Default(false)
    @JsonKey(includeFromJson: false, includeToJson: false)
    @HiveField(6)
    bool isSaved,
    
    @JsonKey(includeFromJson: false, includeToJson: false)
    @HiveField(7) String? localUrl,
  }) = _ArtworkModel;

  factory ArtworkModel.fromJson(Map<String, dynamic> json) =>
      _$ArtworkModelFromJson(json);
}
