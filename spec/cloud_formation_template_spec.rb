require 'spec_helper'

describe CfnDsl::CloudFormationTemplate do
  it 'allows the format version to be set' do
    subject.AWSTemplateFormatVersion '2010-09-09'

    expect(subject.to_json).to eq('{"AWSTemplateFormatVersion":"2010-09-09"}')
  end

  it 'raises an exception for missing arguments' do
    expect do
      subject.AWSTemplateFormatVersion
    end.to raise_error(ArgumentError)
  end

  it 'supports allowed values' do
    expect do
      subject.AWSTemplateFormatVersion '2016-03-20'
    end.to raise_error(ArgumentError)
  end

  it 'supports strings with no allowed values' do
    subject.Description 'Test'

    expected = {
      'AWSTemplateFormatVersion' => '2010-09-09',
      'Description' => 'Test'
    }

    expect(JSON.parse(subject.to_json)).to eq(expected)
  end

  it 'creates a resource' do
    subject.EC2_Instance('MyInstance') do
      ImageId 'ami-12345678'
    end

    expected = {
      'AWSTemplateFormatVersion' => '2010-09-09',
      'Resources' => {
        'MyInstance' => {
          'Type' => 'AWS::EC2::Instance',
          'Properties' => {
            'ImageId' => 'ami-12345678'
          }
        }
      }
    }

    expect(JSON.parse(subject.to_json)).to eq(expected)
  end
end
