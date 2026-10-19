import 'package:flutter/widgets.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

// LEARN (package usage / single source of truth):
// Every icon the app uses is named ONCE here. Screens say AppIcons.heart,
// never PhosphorIconsRegular.heart. If a name changes in a package update (or
// you decide to swap icon packs), you edit this one file.
//
// Style convention:
//   Regular -> default / inactive
//   Fill    -> active / selected (selected tab, favorited heart)
//
// If `flutter analyze` says an icon name does not exist, look the name up in
// the Phosphor gallery (phosphoricons.com) and fix it only in this file.
abstract final class AppIcons {
  // Navigation
  static const IconData characters = PhosphorIconsRegular.users;
  static const IconData charactersFill = PhosphorIconsFill.users;
  static const IconData explore = PhosphorIconsRegular.compass;
  static const IconData exploreFill = PhosphorIconsFill.compass;
  static const IconData planet = PhosphorIconsRegular.planet;
  static const IconData planetFill = PhosphorIconsFill.planet;
  static const IconData favorites = PhosphorIconsRegular.heart;
  static const IconData favoritesFill = PhosphorIconsFill.heart;
  static const IconData settings = PhosphorIconsRegular.gearSix;

  // Actions
  static const IconData search = PhosphorIconsRegular.magnifyingGlass;
  static const IconData close = PhosphorIconsRegular.x;
  static const IconData sort = PhosphorIconsRegular.sortAscending;
  static const IconData grid = PhosphorIconsRegular.squaresFour;
  static const IconData list = PhosphorIconsRegular.listBullets;
  static const IconData retry = PhosphorIconsRegular.arrowsClockwise;
  static const IconData caretRight = PhosphorIconsRegular.caretRight;
  static const IconData translate = PhosphorIconsRegular.translate;
  static const IconData lock = PhosphorIconsRegular.lock;
  static const IconData filter = PhosphorIconsRegular.funnel;
  static const IconData filterClear = PhosphorIconsRegular.funnelX;

  // Favorites
  static const IconData heart = PhosphorIconsRegular.heart;
  static const IconData heartFill = PhosphorIconsFill.heart;

  // Power / ki
  static const IconData ki = PhosphorIconsFill.lightning;
  static const IconData trendUp = PhosphorIconsRegular.trendUp;

  // Categories (race + affiliation)
  static const IconData flame = PhosphorIconsFill.flame;
  static const IconData leaf = PhosphorIconsFill.leaf;
  static const IconData shield = PhosphorIconsFill.shield;
  static const IconData skull = PhosphorIconsFill.skull;
  static const IconData flag = PhosphorIconsFill.flag;
  static const IconData star = PhosphorIconsFill.star;
  static const IconData medal = PhosphorIconsFill.medal;
  static const IconData crown = PhosphorIconsFill.crown;
  static const IconData sparkle = PhosphorIconsFill.sparkle;
  static const IconData robot = PhosphorIconsFill.robot;
  static const IconData ghost = PhosphorIconsFill.ghost;
  static const IconData user = PhosphorIconsFill.user;
  static const IconData question = PhosphorIconsFill.question;

  // Gender
  static const IconData male = PhosphorIconsRegular.genderMale;
  static const IconData female = PhosphorIconsRegular.genderFemale;
  static const IconData neuter = PhosphorIconsRegular.genderNeuter;

  // Planets
  static const IconData globe = PhosphorIconsRegular.globeHemisphereWest;
  static const IconData destroyed = PhosphorIconsFill.fire;

  // Status
  static const IconData offline = PhosphorIconsRegular.wifiSlash;
  static const IconData error = PhosphorIconsRegular.warningCircle;
  static const IconData imageBroken = PhosphorIconsRegular.imageBroken;
  static const IconData empty = PhosphorIconsRegular.magnifyingGlass;

  // Settings
  static const IconData themeSystem = PhosphorIconsRegular.circleHalf;
  static const IconData themeLight = PhosphorIconsRegular.sun;
  static const IconData themeDark = PhosphorIconsRegular.moon;
  static const IconData palette = PhosphorIconsRegular.palette;
  static const IconData animation = PhosphorIconsRegular.magicWand;
  static const IconData density = PhosphorIconsRegular.rows;
  static const IconData share = PhosphorIconsRegular.export;
  static const IconData importFile = PhosphorIconsRegular.downloadSimple;
  static const IconData delete = PhosphorIconsRegular.trash;
  static const IconData memory = PhosphorIconsRegular.memory;
  static const IconData storage = PhosphorIconsRegular.database;
  static const IconData info = PhosphorIconsRegular.info;
  static const IconData privacy = PhosphorIconsRegular.shieldCheck;
  static const IconData reset = PhosphorIconsRegular.arrowCounterClockwise;
  static const IconData textSize = PhosphorIconsRegular.textAa;
  static const IconData contrast = PhosphorIconsRegular.circleHalfTilt;
  static const IconData cloudOk = PhosphorIconsRegular.cloudCheck;
  static const IconData cloudOff = PhosphorIconsRegular.cloudSlash;
  static const IconData battery = PhosphorIconsRegular.batteryHigh;
  static const IconData batterySaver = PhosphorIconsRegular.batteryLow;
}