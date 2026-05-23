import 'package:auto_route/auto_route.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:minimumz/common/extensions/extensions.dart';
import 'package:minimumz/data/data.dart';
import 'package:minimumz/di/di.dart';
import 'package:minimumz/presentation/components/index.dart';

import '../../common/colors.dart';

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
  int _rating = 3;
  bool _loading = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
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
                          hintStyle:
                              TextStyle(color: ColorConstant.manatee),
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
