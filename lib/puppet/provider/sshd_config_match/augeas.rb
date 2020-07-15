# coding: utf-8
# Alternative Augeas-based providers for Puppet
#
# Copyright (c) 2015 Raphaël Pinson
# Licensed under the Apache License, Version 2.0

raise("Missing augeasproviders_core dependency") if Puppet::Type.type(:augeasprovider).nil?
Puppet::Type.type(:sshd_config_match).provide(:augeas, :parent => Puppet::Type.type(:augeasprovider).provider(:default)) do
  desc "Uses Augeas API to update an sshd_config Match group"

  default_file { '/etc/ssh/sshd_config' }

  lens { 'Sshd.lns' }

  confine :feature => :augeas

  def self.static_path(resource)
    path = "$target/Match[count(Condition/*)=#{resource[:condition].keys.size}]"
    resource[:condition].each do |c, v|
      path += "[Condition/#{c}='#{v}']"
    end
    path
  end

  def self.path(resource)
    path = "$target/*"
    path += "[label()=~regexp('match', 'i') and *[label()=~regexp('condition', 'i') and count(*)=#{resource[:condition].keys.size}]"
    resource[:condition].each do |c, v|
      path += "[*[label()=~regexp('#{c}', 'i')]='#{v}']"
    end
    path += "]"
  end

  resource_path do |resource|
    self.path(resource)
  end

  def self.instances
    augopen do |aug,path|
      resources = []
      search_path = "$target/*[label()=~regexp('match', 'i')]/*[label()=~regexp('condition', 'i')]"

      aug.match("#{search_path}").each do |hpath|
        conditions = []
        aug.match("#{hpath}/*").each do |cpath|
          c = path_label(aug, cpath)
          next if c.start_with?("#")

          conditions << "#{c} #{aug.get(cpath)}"
        end
        condition = conditions.join(' ')

        resources << new({
          :ensure    => :present,
          :name      => "#{condition} in #{target}",
          :condition => condition,
        })
      end
      resources
    end
  end

  POS_ALIASES = {
    'first match' => 'Match[1]',
    'last match'  => 'Match[last()]',
  }

  def self.position_path(position)
    if POS_ALIASES.include? position[:match]
      POS_ALIASES[position[:match]]
    else
      match_a = position[:match].split
      path({
        :condition => Hash[*match_a],
      })
    end
  end

  def self.in_position?(aug, resource)
    position = resource[:position]
    return unless position
    if position[:before]
      path = "$resource[following-sibling::#{position_path(position)}]"
    else
      path = "$resource[preceding-sibling::#{position_path(position)}]"
    end

    !aug.match(path).empty?
  end

  def in_position?
    augopen do |aug|
      self.class.in_position?(aug, resource)
    end
  end

  def self.position!(aug, resource)
    position = resource[:position]
    path = position_path(position)

    aug.insert(path, 'Match', position[:before])
    aug.mv('$resource', '$target/Match[count(*)=0]')
  end

  def position!
    augopen! do |aug|
      self.class.position!(aug, resource)
    end
  end

  def create
    augopen! do |aug|
      path = self.class.static_path(resource)
      aug.defnode('resource', path, nil)
      resource[:condition].each do |c, v|
        aug.set("$resource/Condition/#{c}", v)
      end
      aug.clear("$resource/Settings")

      self.class.position!(aug, resource) \
        if !self.class.in_position?(aug, resource) and resource[:position]

      # At least one entry is mandatory (in the lens at least)
      self.comment = resource[:comment]
    end
  end

  def comment
    augopen do |aug|
      comment = aug.get("$resource/Settings/#comment[1]")
      comment.sub!(/^#{resource[:name]}:\s*/i, "") if comment
      comment || ""
    end
  end

  def comment=(value)
    augopen! do |aug|
      cmtnode = "$resource/Settings/#comment[1]"

      if aug.match(cmtnode).empty?
        if aug.match("$resource/Settings/*").any?
          # Insert before first entry
          aug.insert("$resource/Settings/*[1]", "#comment", true)
        end
      end

      aug.set(cmtnode, "#{resource[:name]}: #{resource[:comment]}")
    end
  end
end
