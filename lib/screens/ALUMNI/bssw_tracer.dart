import 'package:flutter/material.dart';

import 'tracer_form_page.dart';

class BSSWTracerPage extends StatelessWidget {
  const BSSWTracerPage({super.key, required this.userId, this.controller});

  final int userId;
  final TracerFormPageController? controller;

  @override
  Widget build(BuildContext context) {
    return TracerFormPage(
      userId: userId,
      programCode: 'BSSW',
      controller: controller,
    );
  }
}
