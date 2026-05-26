import 'package:flutter/material.dart';

import '../../../../constants.dart';

class OnbordingContent extends StatelessWidget {
  const OnbordingContent({
    super.key,
    this.isTextOnTop = false,
    required this.title,
    required this.description,
    required this.image,
  });

  final bool isTextOnTop;
  final String title, description, image;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(),
        Image.asset('assets/ecomarket/png/ecomarket-logo-primary.png', height: 54),
        const SizedBox(height: defaultPadding),
        if (isTextOnTop) OnbordTitleDescription(title: title, description: description),
        if (isTextOnTop) const Spacer(),
        Image.asset(image, height: 250),
        const Spacer(),
        if (!isTextOnTop) OnbordTitleDescription(title: title, description: description),
        const Spacer(),
      ],
    );
  }
}

class OnbordTitleDescription extends StatelessWidget {
  const OnbordTitleDescription({
    super.key,
    required this.title,
    required this.description,
  });

  final String title, description;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: defaultPadding),
        Text(description, textAlign: TextAlign.center),
      ],
    );
  }
}
