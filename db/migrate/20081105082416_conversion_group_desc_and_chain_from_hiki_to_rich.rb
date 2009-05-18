class ConversionGroupDescAndChainFromHikiToRich < ActiveRecord::Migration
  def self.up
    Chain.all.each do |chain|
      chain.comment = convert_to_rich_from_hiki(chain.comment)
      chain.save(false)
    end
    Group.all.each do |group|
      group.description = convert_to_rich_from_hiki(group.description)
      group.save(false)
    end
  end

  def self.down
    # N/A
  end

private
  def self.convert_to_rich_from_hiki(content)
    return "" if content.blank?
    hiki_html = HikiDoc.new(content, Regexp.new(SkipEmbedded::InitialSettings['not_blank_link_re'])).to_html
    return hiki_html.gsub("<big>","<span style=\"font-size: xx-large; \"><strong>").gsub("</big>","</strong></span>")
  end
end
