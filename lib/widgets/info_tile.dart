import 'package:flutter/material.dart';

class InfoTile extends StatelessWidget {
  final String title;
  final String subtitle;

  const InfoTile({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title),
        Text(subtitle, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}

class InfoTiles extends StatelessWidget {
  final List<InfoTile> children;

  const InfoTiles({
    super.key,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double tileWidth = constraints.maxWidth / 3;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: children
              .map((e) => Container(
                    width: tileWidth,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: e,
                  ))
              .toList(),
        );
      },
    );
  }
}
