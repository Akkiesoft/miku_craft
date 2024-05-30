require 'time'
Plugin.create :log_gc do
  time = nil
  on_minute do
    time = Time.now
    if time.hour == 9 and time.min == 0
      system("find /home/akkie/miku_craft/logs -name '*.log.gz' -mtime +30 -delete")
    end
  end
end
