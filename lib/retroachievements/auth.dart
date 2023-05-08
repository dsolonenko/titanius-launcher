/// Each RetroAchievements API call is uniquely authenticated
/// using a userName + API key combination. Your account's personal
/// Web API Key can be found on the Settings page.
class AuthObject {
  /// You or your app's exact username on the RetroAchievements.org website.
  /// For example, https://retroachievements.org/user/Scott would have a value
  /// of "Scott".
  String userName;

  /// This can be found in the "Keys" section of your Settings page on the
  /// RetroAchievements.org website. This is a 32-digit alphanumeric key
  /// that is case-sensitive.
  String webApiKey;

  AuthObject({required this.userName, required this.webApiKey});

  /// Accepts your RetroAchievements.org username and web API key. After
  /// receiving these inputs, the function returns you a value that can be
  /// used for the authentication parameter by any of the async calls in this
  /// library.
  ///
  /// Your account's personal Web API Key can be found on the Settings page
  /// of RetroAchievements.org. Do not use a Web API Key that is not associated
  /// with your account.
  ///
  /// @returns An `AuthObject` that you can pass to any of the API call functions.
  ///
  /// @example
  /// ```
  /// final authorization = buildAuthorization(
  ///   userName: 'Scott',
  ///   webApiKey: 'LtjCwW16nJI7cqOyPIQtXk8v1cfF0tmO',
  /// );
  /// ```
  factory AuthObject.buildAuthorization({required String userName, required String webApiKey}) {
    if (userName.isEmpty || webApiKey.isEmpty) {
      throw ArgumentError('''
      buildAuthorization() requires an object containing a
      userName and webApiKey. eg:

      final authorization = buildAuthorization(
        userName: 'myUserName',
        webApiKey: 'myWebApiKey',
      )
    ''');
    }

    return AuthObject(userName: userName, webApiKey: webApiKey);
  }
}


// This function simply returns what it's given, however the return
// value has the added benefit of type safety.
