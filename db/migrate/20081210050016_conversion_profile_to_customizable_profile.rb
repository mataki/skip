class ConversionProfileToCustomizableProfile < ActiveRecord::Migration
  MAN = 1; WOMAN = 2;
  GENDER = {
     MAN   => '男性',
     WOMAN => '女性'
  }

  A = 1; B = 2; AB = 3; O = 4;
  BLOOD = {
     A   => 'Ａ型',
     B   => 'Ｂ型',
     AB  => 'ＡＢ型',
     O   => 'Ｏ型'
  }

  TODOUHUKEN = {
    1  => '北海道',
    2  => '青森県',
    3  => '岩手県',
    4  => '宮城県',
    5  => '秋田県',
    6  => '山形県',
    7  => '福島県',
    8  => '茨城県',
    9  => '栃木県',
    10 => '群馬県',
    11 => '埼玉県',
    12 => '千葉県',
    13 => '東京都',
    14 => '神奈川県',
    15 => '新潟県',
    16 => '富山県',
    17 => '石川県',
    18 => '福井県',
    19 => '山梨県',
    20 => '長野県',
    21 => '岐阜県',
    22 => '静岡県',
    23 => '愛知県',
    24 => '三重県',
    25 => '滋賀県',
    26 => '京都府',
    27 => '大阪府',
    28 => '兵庫県',
    29 => '奈良県',
    30 => '和歌山県',
    31 => '鳥取県',
    32 => '島根県',
    33 => '岡山県',
    34 => '広島県',
    35 => '山口県',
    36 => '徳島県',
    37 => '香川県',
    38 => '愛媛県',
    39 => '高知県',
    40 => '福岡県',
    41 => '佐賀県',
    42 => '長崎県',
    43 => '熊本県',
    44 => '大分県',
    45 => '宮崎県',
    46 => '鹿児島県',
    47 => '沖縄県'
  }

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
                     "ねること",
                    ]
  def self.up
    if UserProfile.count > 0
      UserProfileMasterCategory.transaction do
        # 基本情報のマスタを作成
        basic_info = UserProfileMasterCategory.create!(:name => '基本情報', :description => '', :sort_order => 10)
        extension = UserProfileMaster.create!(:user_profile_master_category_id => basic_info.id, :name => '連絡先', :input_type => 'text_field', :sort_order => 10, :option_values => '', :description => '')
        self_introduction = UserProfileMaster.create!(:user_profile_master_category_id => basic_info.id, :name => '自己紹介', :input_type => 'rich_text', :sort_order => 20, :option_values => '', :description => '現在の業務や今までの仕事、興味や関心のある事柄などについて書いてください')

        # 属性情報のマスタを作成
        extra_info  = UserProfileMasterCategory.create!(:name => '属性情報', :description => '(入力は必須ではありません)', :sort_order => 20)
        gender_type = UserProfileMaster.create!(:user_profile_master_category_id => extra_info.id, :name => '性別',     :input_type => 'radio',             :sort_order => 10, :option_values => '男性,女性', :description => '')
        join_year   = UserProfileMaster.create!(:user_profile_master_category_id => extra_info.id, :name => '入社年度', :input_type => 'year_select',       :sort_order => 20, :option_values => '1960-', :description => '')
        birth_date  = UserProfileMaster.create!(:user_profile_master_category_id => extra_info.id, :name => '誕生日',   :input_type => 'datepicker',        :sort_order => 30, :option_values => '', :description => '')
        blood_type  = UserProfileMaster.create!(:user_profile_master_category_id => extra_info.id, :name => '血液型',   :input_type => 'radio',             :sort_order => 40, :option_values => 'Ａ型,Ｂ型,ＡＢ型,Ｏ型', :description => '')
        hometown    = UserProfileMaster.create!(:user_profile_master_category_id => extra_info.id, :name => '出身地',   :input_type => 'prefecture_select', :sort_order => 50, :option_values => '', :description => '')
        alma_mater  = UserProfileMaster.create!(:user_profile_master_category_id => extra_info.id, :name => '出身校',   :input_type => 'appendable_select', :sort_order => 60, :option_values => '', :description => 'xx大学などの大体の内容で構いません(同窓生がわかる程度)')
        address1    = UserProfileMaster.create!(:user_profile_master_category_id => extra_info.id, :name => '現住所1',  :input_type => 'prefecture_select', :sort_order => 70, :option_values => '', :description => '')
        address2    = UserProfileMaster.create!(:user_profile_master_category_id => extra_info.id, :name => '現住所2',  :input_type => 'appendable_select', :sort_order => 80, :option_values => '', :description => 'xx区などの大体の内容で構いません(ご近所さんがわかる程度)')

        # オフ情報のマスタを作成
        off_info = UserProfileMasterCategory.create!(:name => 'オフ情報', :description => '(入力は必須ではありません)', :sort_order => 30)
        hobby = UserProfileMaster.create!(:user_profile_master_category_id => off_info.id, :name => '趣味', :input_type => 'check_box', :sort_order => 10, :option_values => DEFAULT_HOBBIES.join(','), :description => '')
        introduction = UserProfileMaster.create!(:user_profile_master_category_id => off_info.id, :name => 'オフの私', :input_type => 'rich_text', :sort_order => 20, :option_values => '', :description => '趣味の詳しい内容や、休日の過ごし方など、オフのあなたを少しだけ教えて下さい')

        # 旧プロフィールデータの移行を行う。
        UserProfile.all.each do |profile|
          user_id = profile.user_id
          # 基本情報の移行
          Admin::UserProfileValue.create!(:user_id => user_id, :user_profile_master_id => extension.id, :value => profile.extension.blank? ? "" : profile.extension)
          Admin::UserProfileValue.create!(:user_id => user_id, :user_profile_master_id => self_introduction.id, :value => profile.self_introduction.blank? ? "" : profile.self_introduction)

          # 非公開の属性情報とオフ情報は移行しない
          if profile.disclosure
            # 属性情報の移行
            Admin::UserProfileValue.create!(:user_id => user_id, :user_profile_master_id => gender_type.id,  :value => profile.gender_type.blank? ? "" : GENDER[profile.gender_type])
            Admin::UserProfileValue.create!(:user_id => user_id, :user_profile_master_id => join_year.id,    :value => profile.join_year.blank? ? "" : profile.join_year.to_s)
            begin
              Admin::UserProfileValue.create!(:user_id => user_id, :user_profile_master_id => birth_date.id,   :value => (profile.birth_month.blank? || profile.birth_day.blank?) ? "" : "#{profile.birth_month}/#{profile.birth_day}")
            rescue ActiveRecord::RecordInvalid
              Admin::UserProfileValue.create!(:user_id => user_id, :user_profile_master_id => birth_date.id,   :value => "")
            end
            Admin::UserProfileValue.create!(:user_id => user_id, :user_profile_master_id => blood_type.id,   :value => profile.blood_type.blank? ? "" : BLOOD[profile.blood_type])
            Admin::UserProfileValue.create!(:user_id => user_id, :user_profile_master_id => hometown.id,     :value => profile.hometown.blank? ? "" : TODOUHUKEN[profile.hometown])
            Admin::UserProfileValue.create!(:user_id => user_id, :user_profile_master_id => alma_mater.id,   :value => profile.alma_mater.blank? ? "" : profile.alma_mater)
            Admin::UserProfileValue.create!(:user_id => user_id, :user_profile_master_id => address1.id,     :value => profile.address_1.blank? ? "" : TODOUHUKEN[profile.address_1])
            Admin::UserProfileValue.create!(:user_id => user_id, :user_profile_master_id => address2.id,     :value => profile.address_2.blank? ? "" : profile.address_2)

            # オフ情報の移行
            Admin::UserProfileValue.create!(:user_id => user_id, :user_profile_master_id => hobby.id,        :value => profile.hobby.blank? ? "" : profile.hobby.split(','))
            Admin::UserProfileValue.create!(:user_id => user_id, :user_profile_master_id => introduction.id, :value => profile.introduction.blank? ? "" : profile.introduction)
          end
        end
      end
    end
  end

  def self.down
  end

  class UserProfile < ActiveRecord::Base
  end
end

