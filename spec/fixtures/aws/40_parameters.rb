CloudFormation do
  Parameter('One') do
    Type 'String'
    Default 'Test'
    MaxLength 15
    MaxValue 15
    AllowedValues %w(one two)
  end
end
