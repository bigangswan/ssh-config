#!/usr/bin/env ruby

# TODO load ~/.ssh/config only by default, switch for all
# TODO pass custom config file


class SshConfig

  def initialize(host)
    @host = host
  end

  # Returns an array of locations of OpenSSH configuration files
  # to parse by default.
  def default_files
    %w(~/.ssh/config /etc/ssh_config /etc/ssh/ssh_config)
  end

  # Load the OpenSSH configuration settings in the given +file+ for the
  # given +host+. If +settings+ is given, the options are merged into
  # that hash, with existing values taking precedence over newly parsed
  # ones. Returns a hash containing the OpenSSH options. (See
  # #translate for how to convert the OpenSSH options into Net::SSH
  # options.)
  def load(path, host, settings={})
    file = File.expand_path(path)
    return settings unless File.readable?(file)

    globals = {}
    matched_host = nil
    multi_host = []
    seen_host = false
    IO.foreach(file) do |line|
      next if line =~ /^\s*(?:#.*)?$/

      if line =~ /^\s*(\S+)\s*=(.*)$/
        key, value = $1, $2
      else
        key, value = line.strip.split(/\s+/, 2)
      end

      # silently ignore malformed entries
      next if value.nil?

      value = $1 if value =~ /^"(.*)"$/

      if key == 'Host'
        # Support "Host host1 host2 hostN".
        # See http://github.com/net-ssh/net-ssh/issues#issue/6
        multi_host = value.to_s.split(/\s+/)
        matched_host = multi_host.select { |h| host =~ pattern2regex(h) }.first
        seen_host = true
      elsif !seen_host
        if key == 'IdentityFile'
          (globals[key] ||= []) << value
        else
          globals[key] = value unless settings.key?(key)
        end
      elsif !matched_host.nil?
        if key == 'IdentityFile'
          (settings[key] ||= []) << value
        else
          settings[key] = value unless settings.key?(key)
        end
      end
    end

    settings = globals.merge(settings) if globals

    return settings
  end

  def print
    result.map { |k, v| "#{k}\t#{v}" }.sort.join("\n")
  end

  def pretty_print
    longest = result.keys.map {|k| k.length}.max
    result.map do |key, value| 
      sprintf("%-#{longest}s\t%s", key, value)
    end.sort.join("\n")
  end

  def result
    config = []
    default_files.reverse.each do |file|
      config << load(file, @host)
    end

    s = {}
    Hash[*config.map{|_|_.to_a}.flatten].each do |key,value|
      s[key] = value
    end
    s
  end

  private

    # Converts an ssh_config pattern into a regex for matching against
    # host names.
    def pattern2regex(pattern)
      pattern = "^" + pattern.to_s.gsub(/\./, "\\.").
        gsub(/\?/, '.').
        gsub(/([+\/])/, '\\\\\\0').
        gsub(/\*/, '.*') + "$"
      Regexp.new(pattern, true)
    end

    # Converts the given size into an integer number of bytes.
    def interpret_size(size)
      case size
      when /k$/i then size.to_i * 1024
      when /m$/i then size.to_i * 1024 * 1024
      when /g$/i then size.to_i * 1024 * 1024 * 1024
      else size.to_i
      end
    end
end

