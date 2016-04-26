CloudFormation do
  Output('IP', 'Foo')
  Output('IP2') do
    Value 'Foo'
    Description 'Moo'
  end
end
