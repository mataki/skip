class ConvertFromAntennasToNotices < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      Antenna.all.each do |antenna|
        antenna.antenna_items.each do |item|
          symbol_type, symbol_id = item.value.split(':')
          target = if symbol_type == "uid"
                     User.find_by_uid(symbol_id)
                   elsif symbol_type == "gid"
                     Group.active.find_by_gid(symbol_id)
                   else
                     nil
                   end
          if target
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
