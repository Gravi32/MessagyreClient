import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/database/models/composite_subjects/composite_subject.dart';
import 'package:messagyre_client/utility/widgets/subject_badge.dart';

class CompositeSubjectBadge extends StatelessWidget {
  final CompositeSubject compositeSubject;
  final double size;

  const CompositeSubjectBadge({super.key, required this.compositeSubject, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: ClipRRect(
        borderRadius: .circular(size / 3.6),
        child: Stack(
          children: [
            Align(
              alignment: .centerLeft,
              child: ClipRect(
                clipper: _LeftHalfClipper(),
                child: SubjectBadge(subject: compositeSubject.firstSubject.value, size: size),
              ),
            ),
            Align(
              alignment: .centerRight,
              child: ClipRect(
                clipper: _RightHalfClipper(),
                child: SubjectBadge(subject: compositeSubject.secondSubject.value, size: size),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeftHalfClipper extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width / 2, size.height);
  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) => false;
}

class _RightHalfClipper extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) => Rect.fromLTWH(size.width / 2, 0, size.width / 2, size.height);
  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) => false;
}
