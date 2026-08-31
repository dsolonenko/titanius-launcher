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
    3909243194,
    3646500267,
    1891449474,
    2815767878,
    1225681270,
    2151258160,
    1400904570,
    3567183079,
  ];

  static const List<int> _envieddatadevId = <int>[
    3909243209,
    3646500292,
    1891449582,
    2815767849,
    1225681179,
    2151258207,
    1400904468,
    3567182988,
  ];

  static final String devId = String.fromCharCodes(
    List<int>.generate(
      _envieddatadevId.length,
      (int i) => i,
      growable: false,
    ).map((int i) => _envieddatadevId[i] ^ _enviedkeydevId[i]),
  );

  static const List<int> _enviedkeydevPassword = <int>[
    261041811,
    964228391,
    1986174087,
    3586486354,
    403771059,
    2109941750,
    1799458359,
    3295207691,
    4110835150,
    1883650833,
    1249356140,
  ];

  static const List<int> _envieddatadevPassword = <int>[
    261041906,
    964228435,
    1986174154,
    3586486307,
    403771011,
    2109941664,
    1799458429,
    3295207800,
    4110835100,
    1883650921,
    1249356121,
  ];

  static final String devPassword = String.fromCharCodes(
    List<int>.generate(
      _envieddatadevPassword.length,
      (int i) => i,
      growable: false,
    ).map((int i) => _envieddatadevPassword[i] ^ _enviedkeydevPassword[i]),
  );

  static const List<int> _enviedkeyappName = <int>[
    3160250704,
    3883550855,
    3795991206,
    1890113262,
    1828128788,
    35408886,
    2962026788,
    526792734,
  ];

  static const List<int> _envieddataappName = <int>[
    3160250628,
    3883550958,
    3795991250,
    1890113167,
    1828128890,
    35408799,
    2962026833,
    526792813,
  ];

  static final String appName = String.fromCharCodes(
    List<int>.generate(
      _envieddataappName.length,
      (int i) => i,
      growable: false,
    ).map((int i) => _envieddataappName[i] ^ _enviedkeyappName[i]),
  );
}
