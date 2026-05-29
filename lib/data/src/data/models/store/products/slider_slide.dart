class SliderSlide {
  const SliderSlide({
    required this.id,
    this.image,
    this.caption1,
    this.caption2,
    this.callToActionText,
    this.callToActionUrl,
    this.position,
  });

  final int id;
  final String? image;
  final String? caption1;
  final String? caption2;
  final String? callToActionText;
  final String? callToActionUrl;
  final int? position;

  factory SliderSlide.fromJson(Map<String, dynamic> json) => SliderSlide(
        id: json['id'] as int,
        image: json['image'] as String?,
        caption1: json['caption_1'] as String?,
        caption2: json['caption_2'] as String?,
        callToActionText: json['call_to_action_text'] as String?,
        callToActionUrl: json['call_to_action_url'] as String?,
        position: json['position'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'image': image,
        'caption_1': caption1,
        'caption_2': caption2,
        'call_to_action_text': callToActionText,
        'call_to_action_url': callToActionUrl,
        'position': position,
      };
}
