import Model

extension HyperTrackData {
  func convertToPayload() -> Payload {
    return [
      Constant.ServerKeys.SignUp.companyNameKey: companyName,
      Constant.ServerKeys.SignUp.appGoalKey: appGoal,
      Constant.ServerKeys.SignUp.appDeviceCountKey: appDeviceCount,
      Constant.ServerKeys.SignUp.appProductStateKey: appProductState
    ]
  }
}
