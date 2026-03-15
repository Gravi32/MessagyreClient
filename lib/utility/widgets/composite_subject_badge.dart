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
      dimension: size + 1.5,
      child: Stack(
        children: [
          ClipPath(
            clipper: _LeftHalfClipper(),
            child: Padding(padding: EdgeInsets.all(1.5), child: SubjectBadge(subject: compositeSubject.firstSubject.value, size: size)),
          ),
          ClipPath(
            clipper: _RightHalfClipper(),
            child: Padding(padding: EdgeInsets.all(1.5), child: SubjectBadge(subject: compositeSubject.secondSubject.value, size: size)),
          ),
        ],
      ),
    );
  }
}

class _LeftHalfClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()..addRect(Rect.fromLTWH(0, 0, size.width / 2, size.height));
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _RightHalfClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()..addRect(Rect.fromLTWH(size.width / 2, 0, size.width / 2, size.height));
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
