# -*- coding: utf-8 -*-
require 'date'

Plugin.create :continuous_login do
  defevent :active_players, prototype: [Pluggaloid::COLLECT]

  save_file = File.join(__dir__, 'count.dat')
  counter = FileTest.exist?(save_file) ? Marshal.load(File.open(save_file, &:read)) : {}
  @last_check = Date.today.freeze

  subscribe(:active_players__add).each do |name|
    Plugin.call(:scan_continuous_login_bonus, name)
  end

  def rich_text(text, context=binding)
    case text
    when String
      Hashie::Mash.new(text: text, italic: 0).to_mcjson(context).to_s
    when Hash
      text = {italic: 0, **text} unless text[:italic]
      text.to_mcjson(context).to_s
    end
  end

  def daily_check(tomorrow)
    tomorrow.freeze
    Delayer.new(delay: tomorrow.to_time) do
      if tomorrow != @last_check
        @last_check = tomorrow
        collect(:active_players).each do |player_name|
          Plugin.call(:scan_continuous_login_bonus, player_name)
        end
      end
      daily_check(tomorrow + 1)
    end
  end
  daily_check(Date.today + 1)

  on_scan_continuous_login_bonus do |name|
    counter[name] ||= {last: Date.today - 1, count: 0}
    if Date.today != counter[name][:last]
      counter[name][:last] = Date.today
      counter[name][:count] += 1
      Plugin.call(:give_continuous_login_bonus, name, counter[name][:count])
    elsif ENV['DEBUG'].to_i != 0
      Plugin.call(:give_continuous_login_bonus, name, counter[name][:count])
    end
    File.open(save_file, 'wb') do |out|
      Marshal.dump(counter, out)
    end
  end

  on_give_continuous_login_bonus do |name, days|
    lore = "#{Time.now.year}/#{Time.now.month}/#{Time.now.day} 通算ログインボーナス\n#{days}日ログイン記念に#{name}がもらった"
    case
    when (days % 31) == 0
      Plugin.call(:giftbox_keep_stack,
                  name,
                  "#{days}日記念！ダイヤのクワをプレゼント",
                  MinecraftItem::Stack.new(
                    MinecraftItem::Item.new(:diamond_hoe,
                                            tag: NBT.build(
                                              {
                                                display: {
                                                  Name: 'ダイヤのクワ',
                                                  Lore: lore
                                                }
                                              })
                                           ),
                    1)
                 )
    when (days % 17) == 0
      Plugin.call(:giftbox_keep_stack,
                  name,
                  "#{days}日記念！マインカートをプレゼント",
                  MinecraftItem::Stack.new(
                    MinecraftItem::Item.new(:minecart,
                                            tag: NBT.build(
                                              {
                                                display: {
                                                  Lore: "#{lore}\nteocraft全線では駅乗降車場所への\nマインカート放置は禁止されています"
                                                }
                                              })
                                           ),
                    1)
                 )
    when (days % 7) == 0
      food = Matsuya.order.gsub(/[　（）]/, '　'=>'', '（'=>'(', '）'=>')')
      Plugin.call(:giftbox_keep_stack,
                  name,
                  "#{days}日記念！#{food}をプレゼント",
                  MinecraftItem::Stack.new(
                    MinecraftItem::Item.new(:rabbit_stew,
                                            tag: NBT.build({ display: { Name: food.to_s, Lore: lore }})),
                    1)
                 )
      Plugin.call(:giftbox_keep_stack,
                  name,
                  nil,
                  MinecraftItem::Stack.new(
                    MinecraftItem::Item.new(:mushroom_stew,
                                            tag: NBT.build({display: { Name: '味噌汁', Lore: lore }})),
                    1)
                 )
    when (days % 5) == 0
      Plugin.call(:giftbox_keep_stack,
                  name,
                  "#{days}日記念！経験値ボトルをプレゼント",
                  MinecraftItem::Stack.new(MinecraftItem::Item.new(:experience_bottle), 1))
    else
      Plugin.call(:giftbox_keep_stack,
                  name,
                  "ログイン#{days}日目！棒をプレゼント",
                  MinecraftItem::Stack.new(MinecraftItem::Item.new(:stick), 1))
    end
  end
end
