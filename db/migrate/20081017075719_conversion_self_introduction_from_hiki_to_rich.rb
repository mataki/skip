class ConversionSelfIntroductionFromHikiToRich < ActiveRecord::Migration
  def self.up
    UserProfile.all.each do |profile|
      if hiki_row = profile.self_introduction
        hiki_html = HikiDoc.new(hiki_row, Regexp.new(SkipEmbedded::InitialSettings['not_blank_link_re'])).to_html
        profile.self_introduction = hiki_html.gsub("<big>","<span style=\"font-size: xx-large; \"><strong>").gsub("</big>","</strong></span>")
      end
      if hiki_row = profile.introduction
        hiki_html = HikiDoc.new(hiki_row, Regexp.new(SkipEmbedded::InitialSettings['not_blank_link_re'])).to_html
        profile.introduction = hiki_html.gsub("<big>","<span style=\"font-size: xx-large; \"><strong>").gsub("</big>","</strong></span>")
      end
      profile.save(false)
    end
  end

  def self.down
    # N/A
  end

  class UserProfile < ActiveRecord::Base
  end
end
