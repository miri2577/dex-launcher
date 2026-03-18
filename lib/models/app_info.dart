import 'dart:typed_data';
import 'package:flutter/material.dart';

class AppInfo {
  final String name;
  final String packageName;
  final Uint8List? icon;
  final bool isSystemApp;
  final AppCategory category;
  bool isPinned;
  bool isOnDesktop;

  AppInfo({
    required this.name,
    required this.packageName,
    this.icon,
    this.isSystemApp = false,
    this.category = AppCategory.other,
    this.isPinned = false,
    this.isOnDesktop = true,
  });
}

enum AppCategory {
  game('Spiele', Icons.sports_esports),
  audio('Musik', Icons.music_note),
  video('Video', Icons.movie),
  social('Soziales', Icons.people),
  productivity('Produktivitaet', Icons.work),
  news('Nachrichten', Icons.newspaper),
  image('Fotos', Icons.photo),
  maps('Karten', Icons.map),
  other('Sonstige', Icons.apps);

  final String label;
  final IconData icon;
  const AppCategory(this.label, this.icon);

  static AppCategory fromAndroidCategory(int? value) {
    return switch (value) {
      0 => AppCategory.game,       // CATEGORY_GAME
      1 => AppCategory.audio,      // CATEGORY_AUDIO
      2 => AppCategory.video,      // CATEGORY_VIDEO
      3 => AppCategory.image,      // CATEGORY_IMAGE
      4 => AppCategory.social,     // CATEGORY_SOCIAL
      5 => AppCategory.news,       // CATEGORY_NEWS
      6 => AppCategory.maps,       // CATEGORY_MAPS
      7 => AppCategory.productivity, // CATEGORY_PRODUCTIVITY
      _ => AppCategory.other,
    };
  }
}

