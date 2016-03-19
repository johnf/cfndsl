CloudFormation do
  Output('IP', 'Foo')
  Output('IP2') do
    Value 'Foo'
    Description 'Moo'
  end

  EC2_Instance('MyInstance') do
    ImageId 'ami-14341342'
  end
end
