#! /usr/bin/env ruby
require 'spec_helper'

constraint = Puppet::Type.type(:constraint)

describe constraint do
  let(:resource) { Puppet::Resource.new('File[foo]') }

  describe "when initializing" do
    it "should fail if no resource is specified" do
      expect {
        described_class.new(:name => 'foo').validate
      }.to raise_error(Puppet::Error, /resource/)
    end

    it "should fail if a specified resource is no valid reference" do
      expect {
        described_class.new(:name => 'foo', :resource => '').validate
      }.to raise_error(Puppet::Error, /resource/)
    end

    it "should succeed if the properties parameter is missing" do
      expect {
        described_class.new(:name => 'foo', :resource => resource ).validate
      }.to_not raise_error
    end

    context "the properties param" do
      { "a simple name/value hash" => { 'ensure' => 'present' },
        "a simple name/array hash" => { 'ensure' => [ 'installed', 'latest' ] },
        "a name/allow/value hash" => { 'ensure' => { 'allowed' => 'present' } },
        "a name/allow/array hash" => { 'ensure' => { 'allowed' => [ 'installed', 'latest' ] } },
        "a name/forbid/value hash" => { 'ensure' => { 'forbidden' => 'present' } },
        "a name/forbid/array hash" => { 'ensure' => { 'forbidden' => [ 'installed', 'latest' ] } },
      }.each_pair do |description,value|
        it "should accept #{description}" do
          expect {
            described_class.new(:name => 'foo', :resource => resource,
              :properties => value).validate
          }.to_not raise_error
        end
      end

      { "a string" => 'present',
        "an array" => [ 'installed', 'latest' ],
        "a nested hash with more than two levels" =>
          { 'ensure' => { 'allowed' => { 'foo' => 'bar' } } },
        "a nesed hash with 2nd level keys other than allowed/forbidden" =>
          { 'ensure' => { 'undecided' => 'latest' } },
      }.each_pair do |description,value|
        it "should not accept #{description}" do
          expect {
            described_class.new(:name => 'foo', :resource => resource,
              :properties => value).validate
          }.to raise_error
        end
      end

    end
  end
end
