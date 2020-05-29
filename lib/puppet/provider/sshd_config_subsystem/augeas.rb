# coding: utf-8
# Alternative Augeas-based providers for Puppet
#
# Copyright (c) 2012 Raphaël Pinson
# Licensed under the Apache License, Version 2.0

raise("Missing augeasproviders_core dependency") if Puppet::Type.type(:augeasprovider).nil?
Puppet::Type.type(:sshd_config_subsystem).provide(:augeas, :parent => Puppet::Type.type(:augeasprovider).provider(:default)) do
  desc "Uses Augeas API to update a Subsystem parameter in sshd_config."

  default_file { '/etc/ssh/sshd_config' }

  lens { 'Sshd.lns' }

  confine :feature => :augeas

  resource_path do |resource|
    "$target/*[label()=~regexp('Subsystem', 'i')]/#{resource[:name]}"
  end

  def self.instances
    augopen do |aug|
      aug.match("$target/Subsystem/*").map do |hpath|
        command = aug.get(hpath)
        new({
          :ensure  => :present,
          :name    => path_label(aug, hpath),
          :command => command
        }) if command
      end
    end
  end

  define_aug_method!(:create) do |aug, resource|
    key = resource[:name]
    unless aug.match("$target/Match").empty?
      aug.insert("$target/Match[1]", "Subsystem", true)
      aug.clear("$target/Subsystem[last()]/#{key}")
    end
    aug.set("$target/Subsystem/#{resource[:name]}", resource[:command])
  end

  define_aug_method!(:destroy) do |aug, resource|
    key = resource[:name]
    aug.rm("$target/*[label()=~regexp('Subsystem', 'i') and #{key}]")
  end

  attr_aug_accessor(:command, :label => :resource)

  def after_comment_node(resource)
    if resource[:ensure] == :unset
      if unset_seq?
        "@unset[*='#{resource[:name]}']"
      else
        "@unset[.='#{resource[:name]}']"
      end
    else
      resource[:name]
    end
  end

  def comment
    augopen do |aug|
      after_comment = after_comment_node(resource)
      comment = aug.get("$target/#comment[following-sibling::*[1][self::#{after_comment}]][. =~ regexp('#{resource[:name]}:.*')]")
      comment.sub!(/^#{resource[:name]}:\s*/, "") if comment
      comment || ""
    end
  end

  def comment=(value)
    augopen! do |aug|
      after_comment = after_comment_node(resource)
      cmtnode = "$target/#comment[following-sibling::*[1][self::#{after_comment}]][. =~ regexp('#{resource[:name]}:.*')]"
      if value.empty?
        aug.rm(cmtnode)
      else
        if aug.match(cmtnode).empty?
          aug.insert("$target/#{resource[:name]}", "#comment", true)
        end
        aug.set("$target/#comment[following-sibling::*[1][self::#{after_comment}]]",
                "#{resource[:name]}: #{resource[:comment]}")
      end
    end
  end
end
