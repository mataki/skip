class SkipDefaultData
  DEFAULT_HOBBIES = ["映画鑑賞",
                     "スポーツ",
                     "スポーツ観戦",
                     "読書",
                     "お酒",
                     "ショッピング",
                     "ファッション",
                     "旅行",
                     "音楽鑑賞",
                     "カラオケ",
                     "習いごと",
                     "語学",
                     "料理",
                     "ドライブ",
                     "グルメ",
                     "アウトドア",
                     "マンガ",
                     "テレビ",
                     "ゲーム",
                     "インターネット",
                     "ギャンブル",
                     "ペット",
                     "美容",
                     "ねること"]

  def self.data_is_empty?
    Tag.count == 0 && Group.count == 0 && UserProfileMasterCategory.count == 0 && UserProfileMaster.count == 0
  end

  # FIXME #25 国際化の方針を決めた後、国際化対応する。
  def self.load
    raise 'Any data is already loaded' unless data_is_empty?
    ActiveRecord::Base.transaction do
      # tags
      %w(質問 解決 重要 連絡).each { |name| Tag.create! :name => name, :tag_type => "SYSTEM" }
      %w(日記 書評 オフ ネタ ニュース).each { |name| Tag.create! :name => name, :tag_type => "STANDARD" }

      # group_categories
      GroupCategory.create! :code => 'BIZ', :name => '業務利用のグループ', :icon => 'page_word', :description => 'プロジェクト内など、業務で利用する場合に選択してください。', :initial_selected => 1
      GroupCategory.create! :code => 'OFF', :name => '業務以外のグループ', :icon => 'ipod', :description => '趣味などざっくばらんな話題で利用する場合に選択してください。', :initial_selected => 0

      # user_profile_master_categories, user_profile_masters
      base_category = UserProfileMasterCategory.create! :name => '基本情報', :sort_order => 10, :description => ''
      base_category.user_profile_masters.create! :name => '連絡先',   :input_type => 'text_field', :sort_order => 10, :option_values => '', :description => ''
      base_category.user_profile_masters.create! :name => '自己紹介', :input_type => 'rich_text',  :sort_order => 20, :option_values => '', :description => '現在の業務や今までの仕事、興味や関心のある事柄などについて書いてください。'

      other_category = UserProfileMasterCategory.create! :name => 'その他', :sort_order => 20, :description => '入力は必須ではありません。'
      other_category.user_profile_masters.create! :name => '性別',      :input_type => 'radio',             :sort_order => 10, :option_values => '男性,女性', :description => ''
      other_category.user_profile_masters.create! :name => '入社年度',  :input_type => 'year_select',       :sort_order => 20, :option_values => '1960-',     :description => ''
      other_category.user_profile_masters.create! :name => '誕生日',    :input_type => 'datepicker',        :sort_order => 30, :option_values => '',          :description => ''
      other_category.user_profile_masters.create! :name => '出身地',    :input_type => 'prefecture_select', :sort_order => 40, :option_values => '',          :description => ''
      other_category.user_profile_masters.create! :name => '出身校',    :input_type => 'appendable_select', :sort_order => 50, :option_values => '',          :description => 'xx大学などの大体の内容で構いません。(同窓生がわかる程度)'
      other_category.user_profile_masters.create! :name => '趣味',      :input_type => 'check_box',         :sort_order => 60, :option_values => DEFAULT_HOBBIES.join(','), :description => ''
      other_category.user_profile_masters.create! :name => 'オフの私',  :input_type => 'rich_text',         :sort_order => 70, :option_values => '',          :description => '趣味の詳しい内容や、休日の過ごし方など、オフのあなたを少しだけ教えて下さい。'
    end
  end
end
