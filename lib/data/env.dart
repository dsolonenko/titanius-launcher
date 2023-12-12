import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied()
abstract class Env {
  @EnviedField(varName: 'SSDEVID', obfuscate: true)
  static final String devId = _Env.devId;
  @EnviedField(varName: 'SSDEVPWD', obfuscate: true)
  static final String devPassword = _Env.devPassword;
  @EnviedField(varName: 'SSAPPNAME', obfuscate: true)
  static final String appName = _Env.appName;
}
