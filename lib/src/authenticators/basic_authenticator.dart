import 'dart:convert';
import 'dart:io';

import 'package:restio/src/authenticator.dart';
import 'package:restio/src/challenge.dart';
import 'package:restio/src/request.dart';
import 'package:restio/src/response.dart';

class BasicAuthenticator implements Authenticator {
  final String username;
  final String password;

  const BasicAuthenticator({
    this.username,
    this.password,
  });

  @override
  Future<Request> authenticate(Response response) async {
    final headers = response.request.headers;

    // Verifica se o retorno é causado por um proxy.
    final isProxy = response.code == HttpStatus.proxyAuthenticationRequired;

    if (!isProxy && headers.has(HttpHeaders.authorizationHeader)) {
      return null;
    }

    if (isProxy && headers.has(HttpHeaders.proxyAuthorizationHeader)) {
      return null;
    }

    // Não é obrigatório um challenge!
    for (final challenge in response.challenges) {
      if (challenge.isBasic) {
        return _authenticate(challenge, response.request, isProxy);
      }
    }

    return _authenticate(null, response.request, isProxy);
  }

  Request _authenticate(
    Challenge challenge,
    Request originalRequest,
    bool isProxy,
  ) {
    final headerName = isProxy
        ? HttpHeaders.proxyAuthorizationHeader
        : HttpHeaders.authorizationHeader;

    return originalRequest.copyWith(
      headers: originalRequest.headers
          .builder()
          .set(
            headerName,
            header(username, password, encoding: challenge?.encoding),
          )
          .build(),
    );
  }

  static String header(
    String username,
    String password, {
    Encoding encoding,
  }) {
    encoding ??= utf8;
    final usernameAndPassword = '$username:$password';
    final hash = base64.encode(encoding.encode(usernameAndPassword));
    return 'Basic $hash';
  }

  @override
  List<Object> get props => [username, password];
}
