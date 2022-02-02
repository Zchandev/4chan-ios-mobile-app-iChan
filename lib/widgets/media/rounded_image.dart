import 'package:flutter/cupertino.dart';

class RoundedImage extends StatelessWidget {
  const RoundedImage({
    Key key,
    this.image,
    this.border,
  }) : super(key: key);

  final ImageProvider image;
  final Border border;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        border: border,
        image: DecorationImage(
          image: image,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
