import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/database/models/composite_subjects/composite_subject.dart';
import 'package:messagyre_client/utility/widgets/subject_badge.dart';

/// The badges of the sub-subjects side by side, one vertical slice each (two or three)
class CompositeSubjectBadge extends StatelessWidget {
  final CompositeSubject compositeSubject;
  final double size;

  const CompositeSubjectBadge({super.key, required this.compositeSubject, this.size = 36});

  @override
  Widget build(BuildContext context) {
    final subjects = compositeSubject.subjects;
    final count = subjects.isEmpty ? 1 : subjects.length;

    return SizedBox.square(
      dimension: size,
      child: ClipRRect(
        borderRadius: .circular(size / 3.6),
        child: Stack(
          children: [
            if (subjects.isEmpty) SubjectBadge(subject: null, size: size),
            for (var index = 0; index < subjects.length; index++)
              ClipRect(
                clipper: _SliceClipper(index, count),
                child: SubjectBadge(subject: subjects[index], size: size),
              ),
          ],
        ),
      ),
    );
  }
}

class _SliceClipper extends CustomClipper<Rect> {
  final int index, count;
  _SliceClipper(this.index, this.count);

  @override
  Rect getClip(Size size) => Rect.fromLTWH(size.width * index / count, 0, size.width / count, size.height);

  @override
  bool shouldReclip(covariant _SliceClipper oldClipper) => oldClipper.index != index || oldClipper.count != count;
}
