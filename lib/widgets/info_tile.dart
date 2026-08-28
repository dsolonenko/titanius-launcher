import 'package:flutter/material.dart';

class InfoTile extends StatelessWidget {
  final String title;
  final String subtitle;

  const InfoTile({super.key, required this.title, required this.subtitle});

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
  final int columnCount;

  const InfoTiles({super.key, required this.children, this.columnCount = 3});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const spacing = 8.0;
        final tileWidth =
            (constraints.maxWidth - spacing * (columnCount - 1)) / columnCount;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children
              .map(
                (e) => Container(
                  width: tileWidth,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  child: e,
                ),
              )
              .toList(),
        );
      },
    );
  }
}
