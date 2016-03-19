CloudFormation do
  Condition('OneIsTest', FnEquals(Ref('One'), 'Test'))
end
