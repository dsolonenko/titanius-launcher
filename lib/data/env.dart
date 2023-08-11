import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied()
abstract class Env {
  @EnviedField(varName: 'SSDEVID', obfuscate: true)
  static final devId = _Env.devId;
  @EnviedField(varName: 'SSDEVPWD', obfuscate: true)
  static final devPassword = _Env.devPassword;
  @EnviedField(varName: 'SSAPPNAME', obfuscate: true)
  static final appName = _Env.appName;
}
