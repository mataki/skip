class ConvertFromAntennasToNotices < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      Antenna.all.each do |antenna|
        antenna.antenna_items.each do |item|
          if target = BoardEntry.owner(item.value)
            Notice.create! :user_id => antenna.user_id, :target_id => target.id, :target_type => target.class.name
            p "successed antenna_id:#{antenna.id}, antenna_item_id:#{item.id}"
          else
            p "skipped antenna_id:#{antenna.id}, antenna_item_id:#{item.id}"
          end
        end
      end
      drop_table :antennas
      drop_table :antenna_items
    end
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end

  class ::AntennaItem < ActiveRecord::Base
  end

  class ::Antenna < ActiveRecord::Base
    belongs_to :user
    has_many :antenna_items
  end
end
