# -*- coding: utf-8 -*-
require 'open3'

Plugin.create :minecraft do
  mc_stdin = nil
  on_boot_server do
    mc_stdin, mc_stdout, mc_stderr, wait_thr = Open3.popen3('java -Xmx3072M -Xms3072M -jar minecraft_server.jar nogui log4j2.formatMsgNoLookups=true')

    stdout_thread = Thread.new do
      mc_stdout.each do |res|
        Plugin.call(:server_raw_output, :stdout, res) end end

    stderr_thread = Thread.new do
      mc_stderr.each do |res|
        Plugin.call(:server_raw_output, :stderr, res) end end

    Plugin.call(:minute)

    Thread.new {
      wait_thr.join
      [stdout_thread, stderr_thread].map(&:kill)
      [mc_stdin, mc_stdout, mc_stderr].map(&:close)
      Delayer.new{ exit 0 }
    }
  end

  on_minute do
    Thread.new {
      sleep 60
      Plugin.call(:minute)
    }
  end

  on_minecraft_execute do |user_name, command|
    Plugin.call :minecraft_run_command, "execute #{user_name} ~ ~ ~ #{command}"
  end

  on_minecraft_give_item do |user_name, item_name, count|
    Plugin.call :minecraft_run_command, "give #{user_name} #{item_name} #{count}"
  end

  on_minecraft_save_off do
    Plugin.call :minecraft_run_command, "save-off"
  end

  on_minecraft_save_on do
    Plugin.call :minecraft_run_command, "save-on"
  end

  on_minecraft_say do |message|
    Plugin.call :minecraft_run_command, "say #{message}"
  end

  on_minecraft_tell do |user_name, message|
    Plugin.call :minecraft_run_command, "tell #{user_name} #{message}"
  end

  on_minecraft_run_command do |command|
    mc_stdin.puts command
  end

  on_server_raw_output do |pipe, line|
    puts "#{pipe}: #{line}"
    case line
    when %r<\A\[\d{2}:\d{2}:\d{2}\] \[Server thread/INFO\]: (\w+) joined the game\Z>
      Plugin.call(:join_player, $1)
    when %r<\A\[\d{2}:\d{2}:\d{2}\] \[Server thread/INFO\]: (\w+) left the game\Z>
      Plugin.call(:left_player, $1)
    when %r<\A\[\d{2}:\d{2}:\d{2}\] \[Server thread/INFO\]: (\w+) fell from a high place\Z>
      Plugin.call(:die, $1)
    when %r<\A\[\d{2}:\d{2}:\d{2}\] \[Server thread/INFO\]: <(\w+)> update map\Z>
      Plugin.call(:update_map, $1)
    end
  end

  Plugin.call(:boot_server)
end
