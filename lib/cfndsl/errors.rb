module CfnDsl
  # Keeps track of errors
  module Errors
    SOURCE_DIR = File.dirname(__FILE__)

    @errors = []

    def self.error(err, kaller)
      kaller = kaller.keep_if { |line| line !~ /^#{SOURCE_DIR}/ }

      m = kaller[0].match(/^.*?:\d+:/)
      err_loc = m ? m[0] : kaller[0]

      @errors.push(err_loc + ' ' + err)
    end

    def self.clear
      @errors = []
    end

    def self.errors
      @errors
    end

    def self.output_errors
      $stderr.puts "Errors: \n"
      $stderr.puts @errors.join("\n")
      $stderr.puts
    end

    def self.errors?
      !@errors.empty?
    end
  end
end
