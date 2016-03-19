require 'spec_helper'

describe CfnDsl do
  filenames = Pathname.glob("#{File.dirname(__FILE__)}/fixtures/aws/*.rb")
  filenames.each do |filename|
    it "Processes #{filename}" do
      json_filename = filename.sub(/\.rb$/, '.json')
      json = json_filename.read
      json_data = JSON.parse(json)

      cfndsl_data = CfnDsl.eval_file_with_extras(filename.to_s) || {}
      cfndsl_json_data = JSON.parse(cfndsl_data.to_json)

      expect(cfndsl_json_data).to eq(json_data)
    end
  end
end
