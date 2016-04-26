CloudFormation do
  # Resource('MyInstance') do
  #   Type 'AWS::EC2::Instance'
  #   Property('ImageId', 'ami-14341342')
  # end

  EC2_Instance('MyInstance') do
    ImageId 'ami-14341342'
  end
end
