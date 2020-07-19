import AWSMobileClient

extension AWSMobileClientError {
  var message: String {
    switch self {
      case let .aliasExists(message),
           let .badRequest(message),
           let .codeDeliveryFailure(message),
           let .codeMismatch(message),
           let .cognitoIdentityPoolNotConfigured(message),
           let .deviceNotRemembered(message),
           let .errorLoadingPage(message),
           let .expiredCode(message),
           let .expiredRefreshToken(message),
           let .federationProviderExists(message),
           let .groupExists(message),
           let .guestAccessNotAllowed(message),
           let .idTokenAndAcceessTokenNotIssued(message),
           let .idTokenNotIssued(message),
           let .identityIdUnavailable(message),
           let .internalError(message),
           let .invalidConfiguration(message),
           let .invalidLambdaResponse(message),
           let .invalidOAuthFlow(message),
           let .invalidParameter(message),
           let .invalidPassword(message),
           let .invalidState(message),
           let .invalidUserPoolConfiguration(message),
           let .limitExceeded(message),
           let .mfaMethodNotFound(message),
           let .notAuthorized(message),
           let .notSignedIn(message),
           let .passwordResetRequired(message),
           let .resourceNotFound(message),
           let .scopeDoesNotExist(message),
           let .securityFailed(message),
           let .softwareTokenMFANotFound(message),
           let .tooManyFailedAttempts(message),
           let .tooManyRequests(message),
           let .unableToSignIn(message),
           let .unexpectedLambda(message),
           let .unknown(message),
           let .userCancelledSignIn(message),
           let .userLambdaValidation(message),
           let .userNotConfirmed(message),
           let .userNotFound(message),
           let .userPoolNotConfigured(message),
           let .usernameExists(message):
        return message
    }
  }
}
