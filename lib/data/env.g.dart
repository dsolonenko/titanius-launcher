// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'env.dart';

// **************************************************************************
// EnviedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
// generated_from: .env
final class _Env {
  static const List<int> _enviedkeydevId = <int>[
    2230350189,
    3035847127,
    3334220449,
    2871965099,
    2259554292,
    3745541111,
    47457554,
    4195405592,
  ];

  static const List<int> _envieddatadevId = <int>[
    2230350110,
    3035847096,
    3334220493,
    2871965124,
    2259554201,
    3745541016,
    47457660,
    4195405683,
  ];

  static final String devId = String.fromCharCodes(
    List<int>.generate(
      _envieddatadevId.length,
      (int i) => i,
      growable: false,
    ).map((int i) => _envieddatadevId[i] ^ _enviedkeydevId[i]),
  );

  static const List<int> _enviedkeydevPassword = <int>[
    3165786971,
    3760997121,
    1506301154,
    3198335212,
    2041476220,
    1323580035,
    1737679553,
    3113474949,
    1724424074,
    240348573,
    695116140,
  ];

  static const List<int> _envieddatadevPassword = <int>[
    3165786938,
    3760997237,
    1506301103,
    3198335133,
    2041476172,
    1323580117,
    1737679499,
    3113475062,
    1724424152,
    240348645,
    695116121,
  ];

  static final String devPassword = String.fromCharCodes(
    List<int>.generate(
      _envieddatadevPassword.length,
      (int i) => i,
      growable: false,
    ).map((int i) => _envieddatadevPassword[i] ^ _enviedkeydevPassword[i]),
  );

  static const List<int> _enviedkeyappName = <int>[
    3436352634,
    1841033730,
    423638568,
    768521715,
    2397593841,
    2368598978,
    4266334701,
    1382606949,
  ];

  static const List<int> _envieddataappName = <int>[
    3436352558,
    1841033835,
    423638620,
    768521618,
    2397593759,
    2368598955,
    4266334616,
    1382606870,
  ];

  static final String appName = String.fromCharCodes(
    List<int>.generate(
      _envieddataappName.length,
      (int i) => i,
      growable: false,
    ).map((int i) => _envieddataappName[i] ^ _enviedkeyappName[i]),
  );
}
