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
    4208981493,
    2005790794,
    2293060383,
    729431486,
    286512365,
    1881295844,
    1790246829,
    2847537849,
  ];

  static const List<int> _envieddatadevId = <int>[
    4208981382,
    2005790757,
    2293060467,
    729431505,
    286512256,
    1881295755,
    1790246851,
    2847537874,
  ];

  static final String devId = String.fromCharCodes(
    List<int>.generate(
      _envieddatadevId.length,
      (int i) => i,
      growable: false,
    ).map((int i) => _envieddatadevId[i] ^ _enviedkeydevId[i]),
  );

  static const List<int> _enviedkeydevPassword = <int>[
    163505411,
    3883268846,
    2152138811,
    1434683355,
    3489566776,
    2803591604,
    3418567296,
    3234725076,
    1347832483,
    150328394,
    3911751874,
  ];

  static const List<int> _envieddatadevPassword = <int>[
    163505506,
    3883268762,
    2152138870,
    1434683306,
    3489566728,
    2803591650,
    3418567370,
    3234725031,
    1347832561,
    150328370,
    3911751927,
  ];

  static final String devPassword = String.fromCharCodes(
    List<int>.generate(
      _envieddatadevPassword.length,
      (int i) => i,
      growable: false,
    ).map((int i) => _envieddatadevPassword[i] ^ _enviedkeydevPassword[i]),
  );

  static const List<int> _enviedkeyappName = <int>[
    571221452,
    2417602802,
    3352526005,
    2254938144,
    3399225693,
    3051213296,
    1120715630,
    3261105627,
  ];

  static const List<int> _envieddataappName = <int>[
    571221400,
    2417602715,
    3352526017,
    2254938177,
    3399225651,
    3051213209,
    1120715547,
    3261105576,
  ];

  static final String appName = String.fromCharCodes(
    List<int>.generate(
      _envieddataappName.length,
      (int i) => i,
      growable: false,
    ).map((int i) => _envieddataappName[i] ^ _enviedkeyappName[i]),
  );
}
