import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:minimumz/common/colors.dart';
import 'package:minimumz/common/extensions/extensions.dart';
import 'package:minimumz/data/data.dart';
import 'package:minimumz/di/di.dart';
import 'package:minimumz/presentation/components/index.dart';

@RoutePage()
class AddReviewScreen extends StatefulWidget {
  const AddReviewScreen({super.key, required this.productId});

  final String productId;

  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentCtrl = TextEditingController();
  final _picker = ImagePicker();
  int _rating = 3;
  bool _loading = false;
  final List<XFile> _images = [];

  static const int _maxImages = 5;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final remaining = _maxImages - _images.length;
    if (remaining <= 0) return;

    final picked = await _picker.pickMultiImage(imageQuality: 80);
    if (picked.isEmpty) return;

    setState(() {
      _images.addAll(picked.take(remaining));
    });
  }

  Future<void> _pickFromCamera() async {
    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (photo == null) return;
    if (_images.length >= _maxImages) return;
    setState(() => _images.add(photo));
  }

  void _removeImage(int index) => setState(() => _images.removeAt(index));

  void _showPickerDialog() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(context.l10n.gallery),
              onTap: () {
                Navigator.pop(ctx);
                _pickImages();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(context.l10n.camera),
              onTap: () {
                Navigator.pop(ctx);
                _pickFromCamera();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await getIt<DataStore>().reviews.create(
            productId: widget.productId,
            reviewerName: '',
            comment: _commentCtrl.text.trim(),
            rating: _rating,
            imagePaths: _images.map((f) => f.path).toList(),
          );
      if (mounted) {
        context.router.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.reviewSubmitted)),
        );
      }
    } catch (e) {
      if (mounted) {
        final status = e is DioException ? e.response?.statusCode : null;
        final msg = status == 401
            ? context.l10n.loginToReview
            : status == 403
                ? context.l10n.mustPurchaseToReview
                : context.l10n.failedToSubmitReview;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const inputBorder = OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10.0)),
        borderSide: BorderSide(width: 0, color: Colors.transparent));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: context.theme.appBarTheme.systemOverlayStyle!,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          appBar: CustomAppBar(title: context.l10n.addReview),
          bottomNavigationBar: BottomNavButton(
            label: _loading ? context.l10n.submitting : context.l10n.submitReview,
            onTap: _loading ? () {} : _submit,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 25.0),
                      Text(context.l10n.describeExperience,
                          style: context.bodyLargeW500),
                      const SizedBox(height: 10.0),
                      TextFormField(
                        controller: _commentCtrl,
                        minLines: 5,
                        maxLines: null,
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(
                          filled: true,
                          isDense: true,
                          hintText: context.l10n.describeExperience,
                          border: inputBorder,
                          enabledBorder: inputBorder,
                          focusedBorder: inputBorder,
                          hintStyle: TextStyle(color: ColorConstant.manatee),
                          fillColor: context.theme.cardColor,
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? context.l10n.commentRequired
                                : null,
                      ),
                      const SizedBox(height: 20.0),
                      Text(context.l10n.ratingTitle, style: context.bodyLargeW500),
                      const SizedBox(height: 10.0),
                      Center(
                        child: RatingBar.builder(
                          initialRating: _rating.toDouble(),
                          minRating: 1,
                          direction: Axis.horizontal,
                          allowHalfRating: false,
                          itemCount: 5,
                          itemBuilder: (context, _) => const Icon(
                            Icons.star,
                            color: Colors.amber,
                          ),
                          onRatingUpdate: (rating) =>
                              setState(() => _rating = rating.round()),
                        ),
                      ),
                      const SizedBox(height: 24.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(context.l10n.photos, style: context.bodyLargeW500),
                          Text(
                            '${_images.length}/$_maxImages',
                            style: context.bodySmall
                                ?.copyWith(color: ColorConstant.manatee),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 90,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _images.length + (_images.length < _maxImages ? 1 : 0),
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            if (index == _images.length) {
                              return GestureDetector(
                                onTap: _showPickerDialog,
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: context.theme.cardColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: ColorConstant.primary.withValues(alpha: 0.3),
                                      style: BorderStyle.solid,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_photo_alternate_outlined,
                                          color: ColorConstant.primary, size: 26),
                                      const SizedBox(height: 4),
                                      Text(
                                        context.l10n.addPhoto,
                                        style: context.bodyExtraSmall?.copyWith(
                                            color: ColorConstant.primary),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    File(_images[index].path),
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(index),
                                    child: Container(
                                      width: 22,
                                      height: 22,
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close,
                                          color: Colors.white, size: 14),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
