class SkipDefaultData
  include GetText
  bindtextdomain("skip", { :path => File.join(RAILS_ROOT, "locale")})

  def self.data_is_empty?
    Tag.count == 0 && Group.count == 0 && UserProfileMasterCategory.count == 0 && UserProfileMaster.count == 0
  end

  def self.load lang = nil
    # TODO 強引に追加してるためもっとシンプルにしたい。別に切り分けた方がよい??
    if Page.count == 0
      load_page lang
      return unless data_is_empty?
    end

    raise 'Any data is already loaded' unless data_is_empty?
    lang = I18n.locale = lang.blank? ? default_language.to_sym : lang.to_sym

    ActiveRecord::Base.transaction do
      load_db lang
      load_html lang
    end
  end

  def self.load_db lang = nil
    # tags
    [_('Diary'), _('Book Review'), _('Off Time'), _('Story'), _('News')].each { |name| Tag.create! :name => name, :tag_type => "STANDARD" }

    # group_categories
    GroupCategory.create! :code => 'BIZ', :name => _('Business'), :icon => 'page_word', :description => _('For business usage such as project management etc.'), :initial_selected => 1
    GroupCategory.create! :code => 'OFF', :name => _('Off-time'), :icon => 'ipod',      :description => _('For off-time activeties.'), :initial_selected => 0

    # user_profile_master_categories, user_profile_masters
    base_category = UserProfileMasterCategory.create! :name => _('Basic Information'), :sort_order => 10, :description => ''
    base_category.user_profile_masters.create! :name => _('Contact Information'), :input_type => 'text_field', :sort_order => 10, :option_values => '', :description => ''
    base_category.user_profile_masters.create! :name => _('Self Introduction'),   :input_type => 'rich_text',  :sort_order => 20, :option_values => '', :description => _('Write about your current and past jobs, your interests and concerns.')

  end

  def self.load_html lang = nil
    %w(default_about_this_site default_rules).each do |content_name|
      open(RAILS_ROOT + "/locale/#{lang}/html/#{content_name}.html") do |source|
        contents = source.read
        open(RAILS_ROOT + "/public/custom/#{content_name}.html", 'w') { |f| f.write(contents) }
        open(RAILS_ROOT + "/public/custom/#{content_name.sub('default_', '')}.html", 'w') { |f| f.write(contents) }
      end
    end
  end

  def self.load_page lang=nil
    p = Page.new(:title=>'トップページ')
    content = <<-EOS
Wikiのファーストページです。
こちらから誰でも自由にページの作成や編集が可能です。
    EOS
    p.edit(content, User.new)
    p.save
  end

  def self.sexes
    [_('Male'), _('Female')].join(',')
  end

  def self.default_hobbies
    [_("Watching Movies"), _("Playing Sports"), _("Watching Sports"), _("Reading"), _("Drinking"), _("Shopping"), _("Fashion"), _("Traveling"), _("Music Appreciation"), _("Karaoke"), _("Enrichment Lessons"), _("Linguistics"), _("Cooking"), _("Driving"), _("Gourmet"), _("Outdoor"), _("Comics"), _("TV"), _("Games"), _("Internet"), _("Gamble"), _("Pets"), _("Cosmetics"), _("Sleeping")].join(',')
  end

  def self.default_language
    'ja'
  end

  def self.valid_languages
    %w(ja en)
  end
end
