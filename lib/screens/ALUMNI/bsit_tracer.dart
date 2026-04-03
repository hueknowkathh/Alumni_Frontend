import 'package:flutter/material.dart';

import 'tracer_form_page.dart';

class BSITTracerPage extends StatelessWidget {
  const BSITTracerPage({super.key, required this.userId, this.controller});

  final int userId;
  final TracerFormPageController? controller;

  @override
  Widget build(BuildContext context) {
    return TracerFormPage(
      userId: userId,
      programCode: 'BSIT',
      controller: controller,
    );
  }
}
