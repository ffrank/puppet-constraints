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

    describe "the resource parameter" do
      context "when munging values" do
        it "should return an array" do
          constraint = described_class.new(:name => 'foo', :resource => 'File["/tmp"]')
          expect(constraint[:resource]).to be_an Array
        end

        it "should parse strings into resources" do
          constraint = described_class.new(:name => 'foo', :resource => 'File["/tmp"]')
          expect(constraint[:resource][0]).to be_a Puppet::Resource
        end

        it "should accept resource references unchanged" do
          constraint = described_class.new(:name => 'foo', :resource => resource)
          expect(constraint[:resource][0]).to eq resource
        end

        it "should fail if the input is invalid" do
          expect {
            constraint = described_class.new(:name => 'foo', :resource => 'not a resource')
          }.to raise_error
        end
      end
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

    [ :allow, :forbid ].each do |param|
      describe "the #{param} parameter" do
        { "a hash with string values" => { 'ensure' => 'present' },
          "a hash with array values" => { 'ensure' => [ 'installed', 'latest' ] },
        }.each_pair do |description,value|
          it "should accept #{description}" do
            expect {
              described_class.new(:name => 'foo', :resource => resource,
                param => value).validate
            }.to_not raise_error
          end
        end

        { "a string" => 'present',
          "an array" => [ 'installed', 'latest' ],
          "a hash with more hash values" =>
            { 'ensure' => { 'allowed' => :true } },
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

    describe "the weak parameter" do
      it "should accept true and false values" do
        expect {
          described_class.new(:name => 'foo', :resource => resource,
            :weak => :true).validate
          described_class.new(:name => 'foo', :resource => resource,
            :weak => :false).validate
        }.to_not raise_error
      end
      it "should not accept non-boolean values" do
        [ :foo, 'bar', %w{foo bar}, { :foo => :bar } ].each do |value|
          expect {
            described_class.new(:name => 'foo', :resource => resource,
              :weak => value).validate
          }
        end
      end
    end

    context "when checking constraints" do
      let(:resources) do
        %w{/foo /bar /baz}.collect { |name|
          Puppet::Type.type(:file).new(:name => name, :ensure => :present)
        }
      end
      let(:refs) do
        resources.map { |res| Puppet::Resource.new(res.ref) }
      end
      subject do
        described_class.new(
          :name => 'foo',
          :resource => refs[0,1],
          :allow => { 'ensure' => 'present' },
        )
      end
      let(:catalog) { Puppet::Resource::Catalog.new }

      context "with missing resources" do
        before :each do
          catalog.add_resource(*resources[1,2])
          subject.stubs(:catalog).returns catalog
        end

        it "should raise an error" do
          expect { subject.pre_run_check }.to raise_error(/cannot be found/)
        end

        context "in weak mode" do
          subject do
            described_class.new(
              :name => 'foo',
              :resource => refs[0..1],
              :allow => { 'ensure' => 'present' },
              :weak => true,
            )
          end
          it "should not raise an error" do
            subject.pre_run_check
          end
          it "should check the resources that are found" do
            subject.expects(:check_black_and_white_lists).with(resources[1])
            subject.pre_run_check
          end
        end
      end

    end

  end
end
