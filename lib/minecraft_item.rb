# frozen_string_literal: true

require 'json'

# アイテムタグ情報。
# display.Nameやdisplay.Lore内部はJSONにしなくても勝手にJSONにする
class MinecraftItem
  def initialize(id, tag: nil)
    @id = id.freeze
    @nbt = tag

    sanitize_name
    sanitize_lore
    sanitize_enchantments
  end

  # "item_id[component]{tag}" を返す
  def to_s
    "#{@id}#{snbt}"
  end

  # "{tag}" を返す
  def snbt
    @nbt.snbt
  end

  # アイテムの表示名を返す。
  # display.nameがあればそれを返す。何もなければidを返す。
  def item_name
    display_name_plain_text || id
  end

  # アイテム名を返す。
  # テキスト装飾は欠落する。
  # 例: "abc"
  def display_name_plain_text
    display_name
    name.map { |n| n['text'] }.join
  end

  # アイテム名を、リッチテキスト形式で返す。
  # JSONパース済みのArray<Hash>を返す。
  # 例: [{"text":"a","italic":false,"underlined":true},{"text":"b","italic":false,"strikethrough":true},{"text":"c","italic":false}]
  def display_name
    raw_name = @nbt.dig('display', 'Name')
    if raw_name
      name = JSON.parse(raw_name.to_s)
    end
  end

  def has_enchantment?
    
  end

  def has_attribute_modifiers?
    
  end

  private

  def sanitize_name
    # あー、ここで吸収できるならcampaign table書き換えなくてよかったかもなあ
    if name = @nbt.dig('display', 'Name')
      @nbt = @nbt.cow(['display', 'Name'], name.to_json)
    end
  end

  def sanitize_lore
    if lore = @nbt.dig('display', 'Lore')
      @nbt = @nbt.cow(['display', 'Lore'], NBT::NBTList.new(lore.to_enum.map(&:to_json)))
    end
  end

  # エンチャントレベル0のものがあったら削除する。
  def sanitize_enchantments
    if enchs = @nbt['Enchantments']
      updated = false
      filtered = enchs.to_enum.reject do |ench|
        updated = true if ench[:lvl] == 0
      end
      if updated
        @nbt = @nbt.cow(['Enchantments'], NBT::NBTList.new(filtered))
      end
    end
  end

end
