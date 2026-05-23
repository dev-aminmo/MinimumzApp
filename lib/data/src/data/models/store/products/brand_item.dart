class BrandItem {
  final String? id;
  final String? name;
  final String? slug;
  final String? logo;
  final String? banner;

  const BrandItem({this.id, this.name, this.slug, this.logo, this.banner});

  factory BrandItem.fromJson(Map<String, dynamic> json) => BrandItem(
        id: json['id']?.toString(),
        name: json['name'],
        slug: json['slug'],
        logo: json['logo'],
        banner: json['banner'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'logo': logo,
        'banner': banner,
      };
}
