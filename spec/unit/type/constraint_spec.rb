#! /usr/bin/env ruby
require 'spec_helper'

constraint = Puppet::Type.type(:constraint)

describe constraint do
  describe "when initializing" do
    it "should fail if no resource is specified" do
      expect {
        described_class.new(:name => 'foo').validate
      }.to raise_error(Puppet::Error, /resource/)
      # Pending - this should not work either!
#      expect {
#        described_class.new(:name => 'foo', :resource => '').validate
#      }.to raise_error(Puppet::Error, /resource/)
    end

    it "should succeed if the properties parameter is missing" do
      expect {
        described_class.new(:name => 'foo', :resource => 'File[foo]').validate
      }.to_not raise_error
    end

    it "should fail if the properties parameter is not a hash" do
      expect {
        described_class.new(:name => 'foo', :resource => 'File[foo]', :properties => []).validate
      }.to raise_error(Puppet::Error, /hash/)
    end
  end
end
