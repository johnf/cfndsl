CloudFormation do
  # Output('IP', FnJoin('', ['arn:aws:iam::', Ref('AWS::AccountId'), ':user/${aws:username}']))
  Output('IP', FnJoin('', ['arn:aws:iam::', 1234, ':user/${aws:username}']))
end
