require 'time'

Plugin.create :backup do
  time = nil
  admin_user = "Hogehoge"
  mc_map_path = "/path/to/EjectCraft"
  ssh_cmd = "ssh -i /home/hoge/.ssh/id_ed25519"
  ssh_dest = "hoge@another.server"
  ssh_dest_dir = "minecraft/"

  defevent :update_map, prototype: [Pluggaloid::COLLECT]
  defevent :server_raw_output, prototype: [Symbol, Pluggaloid::STREAM]

  collection(:update_map) do |mutation|
    subscribe(:server_raw_output, :stdout).each do |line|
      case line
      when %r<\A\[\d{2}:\d{2}:\d{2}\] \[Server thread/INFO\]: <(\w+)> update map\Z>
        Plugin.call(:update_map, $1)
      end
    end
  end

  on_minute do
    time = Time.now
    if time.hour == 9 and time.min == 0
      Plugin.call(:update_map, admin_user)
    end
  end

  on_update_map do |called_by|
    puts "#{called_by} requests update map."
    if called_by == admin_user
      Thread.new {
        puts "Called update map!"
        Plugin.call(:minecraft_say, "Syncing map data to webserver")
        Plugin.call(:minecraft_save_off)
        system("rsync -a --delete -e \"#{ssh_cmd}\" #{mc_map_path} #{ssh_dest}:#{ssh_dest_dir}")
        Plugin.call(:minecraft_save_on)
        Plugin.call(:minecraft_say, "Sync map data successfully.")
      }
   end
  end

end
