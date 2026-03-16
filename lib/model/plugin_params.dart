class PluginParams {
  String? cropTitle;
  String? cropBlackWhiteTitle;
  String? cropResetTitle;
  bool? fromGallery;
  int? maxImageGallery;
  PluginParams({
    this.cropTitle,
    this.cropBlackWhiteTitle,
    this.cropResetTitle,
    this.fromGallery,
    this.maxImageGallery,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'crop_title': cropTitle,
      'crop_black_white_title': cropBlackWhiteTitle,
      'crop_reset_title': cropResetTitle,
      'from_gallery': fromGallery,
      'max_image_gallery': maxImageGallery,
    };
  }
}
