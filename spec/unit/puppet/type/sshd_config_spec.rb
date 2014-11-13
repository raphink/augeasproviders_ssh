#!/usr/bin/env rspec

require 'spec_helper'

sshd_config_type = Puppet::Type.type(:sshd_config)

describe sshd_config_type do
  context 'when setting parameters' do
    it 'should accept a name parameter' do
      resource = sshd_config_type.new :name => 'foo'
      resource[:name].should == 'foo'
    end

    it 'should accept a key parameter' do
      resource = sshd_config_type.new :name => 'foo', :key => 'bar'
      resource[:key].should == 'bar'
    end

    it 'should accept a value array parameter' do
      resource = sshd_config_type.new :name => 'MACs', :value => ['foo', 'bar']
      resource[:value].should == ['foo', 'bar']
    end

    it 'should accept a target parameter' do
      resource = sshd_config_type.new :name => 'foo', :target => '/foo/bar'
      resource[:target].should == '/foo/bar'
    end

    it 'should fail if target is not an absolute path' do
      expect {
        sshd_config_type.new :name => 'foo', :target => 'foo'
      }.to raise_error
    end

    it 'should accept a condition parameter' do
      resource = sshd_config_type.new :name => 'foo', :condition => 'Host example.net'
      resource[:condition].should == 'Host example.net'
    end
  end
end

