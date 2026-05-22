import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:minimumz/blocs/auth/authentication_bloc.dart';
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
  late final TextEditingController _nameCtrl;
  final _commentCtrl = TextEditingController();
  int _rating = 3;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthenticationBloc>().state;
    final customer = authState.maybeMap(
      loggedIn: (s) => s.customer,
      orElse: () => null,
    );
    final prefillName = customer != null
        ? '${customer.firstName ?? ''} ${customer.lastName ?? ''}'.trim()
        : '';
    _nameCtrl = TextEditingController(text: prefillName);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await getIt<DataStore>().reviews.create(
            productId: widget.productId,
            reviewerName: _nameCtrl.text.trim(),
            comment: _commentCtrl.text.trim(),
            rating: _rating,
          );
      if (mounted) {
        context.router.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Review submitted! It will appear after approval.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit review. Try again.')),
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
          appBar: const CustomAppBar(title: 'Add Review'),
          bottomNavigationBar: BottomNavButton(
            label: _loading ? 'Submitting...' : 'Submit Review',
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
                      Text('Name', style: context.bodyLargeW500),
                      const SizedBox(height: 10.0),
                      TextFormField(
                        controller: _nameCtrl,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          filled: true,
                          isDense: true,
                          hintText: 'Your name',
                          border: inputBorder,
                          enabledBorder: inputBorder,
                          focusedBorder: inputBorder,
                          hintStyle:
                              TextStyle(color: ColorConstant.manatee),
                          fillColor: context.theme.cardColor,
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Name is required'
                                : null,
                      ),
                      const SizedBox(height: 20.0),
                      Text('Your experience',
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
                          hintText: 'Describe your experience...',
                          border: inputBorder,
                          enabledBorder: inputBorder,
                          focusedBorder: inputBorder,
                          hintStyle:
                              TextStyle(color: ColorConstant.manatee),
                          fillColor: context.theme.cardColor,
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Comment is required'
                                : null,
                      ),
                      const SizedBox(height: 20.0),
                      Text('Rating', style: context.bodyLargeW500),
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
