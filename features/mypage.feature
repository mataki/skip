Feature: マイページ
  ログインしているユーザへの情報をまとめて表示する

  Background:
    Given 言語は"ja-JP"
    And   "a_user"でログインする

  Scenario: マイページに表示されている記事のタグをクリックして、そのタグをつけられた記事を探す
    Given 以下のブログを書く:
        |user  |title            |tag|contents|
        |a_user|Railsの開発について|雑談|ほげほげ |
        |a_user|別の雑談          |雑談|ふがふが |
    When "マイページ"にアクセスする
    And "雑談"リンクをクリックする

    Then "別の雑談"と表示されていること

  Scenario: 質問を表示する
    Given 以下のブログを書く:
      |user  |title            |aim_type                                              |contents     |
      |a_user|Railsについて質問|質問 (マイページの「みんなからの質問」に表示されます) |わかりません |
      |a_user|Railsについて雑談|記事 (マイページの「新着記事」に表示されます)         |色々話そう   |

    When "マイページ"にアクセスする

    Then I should see "Railsについて質問" within "div#questions_wrapper"
    And I should not see "Railsについて質問" within "div#access_blogs"
    And I should see "Railsについて雑談" within "div#access_blogs"
    And I should not see "Railsについて質問" within "div#recent_blogs"
    And I should see "Railsについて雑談" within "div#recent_blogs"

  Scenario: お知らせを表示する
    Given お知らせ機能を有効にする
    And 以下のブログを書く:
      |user  |title                   |aim_type                                                     |contents        |
      |a_user|Railsについてお知らせ   |お知らせ (マイページの「あなたへのお知らせ」に表示されます)  |リリースします  |
      |a_user|jQueryについてお知らせ  |お知らせ (マイページの「あなたへのお知らせ」に表示されます)  |リリースします  |
      |a_user|Railsについて雑談       |記事 (マイページの「新着記事」に表示されます)                |色々話そう      |
    And 新着通知を作成バッチを実行する

    When "a_group_owned_user"でログインする
    And "マイページ"にアクセスする

    Then I should see "Railsについてお知らせ" within "div#messages_box"
    And I should not see "Railsについてお知らせ" within "div#access_blogs"
    And I should see "Railsについて雑談" within "div#access_blogs"
    And I should not see "Railsについてお知らせ" within "div#recent_blogs"
    And I should see "Railsについて雑談" within "div#recent_blogs"

    When "新着通知"リンクをクリックする

    Then I should see "Railsについてお知らせ"
    And I should not see "Railsについて雑談"

    When "マイページ"にアクセスする
    And "あなたへのお知らせ"リンクをクリックする

    Then I should see "Railsについてお知らせ"
    And I should not see "Railsについて雑談"

    When "Railsについてお知らせ"リンクをクリックする
    And "マイページ"にアクセスする

    When "あなたへのお知らせ"リンクをクリックする

    Then I should not see "Railsについてお知らせ"
    And I should not see "Railsについて雑談"

    When "[既に読んだ記事を表示]"リンクをクリックする

    Then I should see "Railsについてお知らせ"
    And I should not see "Railsについて雑談"

  Scenario: 新着通知(コメントの行方)の表示
    Given 以下のブログを書く:
      | user   | title        | aim_type |
      | alice  | 初めての記事 | 記事 (マイページの「新着記事」に表示されます)           |

    When "alice"でコメントを"1"回書く
    And "a_user"でコメントを"1"回書く
    And 新着通知を作成バッチを実行する
    And "alice"でログインする

    Then I should see "コメントの行方(1)" within "div.antenna"

  Scenario: 新着通知(ブクマの行方)の表示
    Given 以下のブログを書く:
      | user   | title        | aim_type |
      | alice  | 初めての記事 | 記事 (マイページの「新着記事」に表示されます)           |
    And "alice"で"1"つめのブログをブックマークする
    And "janet"で"1"つめのブログをブックマークする
    And 新着通知を作成バッチを実行する

    When "alice"でログインする

    Then I should see "ブクマの行方(1)" within "div.antenna"

  Scenario: 新着通知(ユーザ)の表示
    Given "a_user"で"alice"を新着通知に追加する
    And 以下のブログを書く:
      | user   | title        | aim_type |
      | alice  | 初めての記事 | 記事 (マイページの「新着記事」に表示されます)           |
    And 新着通知を作成バッチを実行する

    When "a_user"でログインする

    Then I should see "alice(1)" within "div.antenna"

  Scenario: 新着通知(グループ)の表示
    Given 以下のグループを作成する:
      |owner    |gid        |name         |waiting  |
      |alice    |vim_group  |VimGroup     |false    |
    And "a_user"が"vim_group"グループに参加する
    And 以下のフォーラムを書く:
      |user  |group       |title            |tag |contents|publication_type|
      |alice |vim_group   |雑談スレ         |雑談|ほげほげ|全体に公開      |
    And 新着通知を作成バッチを実行する

    When "a_user"でログインする

    Then I should see "VimGroup(1)" within "div.antenna"

  Scenario: タブ表示/並べて表示を切り替える
    Given   "a_user"でログインする

    When     "タブで表示"リンクをクリックする

    Then    "新着記事"と表示されていること

    When    "並べて表示"リンクをクリックする

    Then    "新着記事"と表示されていないこと

  Scenario: システムメッセージ(新着コメント)が表示される
    Given 以下のブログを書く:
      | user   | title        | aim_type |
      | a_user | あけおめ     | 記事 (マイページの「新着記事」に表示されます)           |

    When "a_group_owned_user"で"1"つめのブログにアクセスする
    And "コメントを書く"に"おめ"と入力する
    And "書き込み"ボタンをクリックする
    And "a_user"でログインする

    Then "あなたの記事[あけおめ]に新着コメントがあります！"と表示されていること

    When "あなたの記事[あけおめ]に新着コメントがあります！"リンクをクリックする
    And "マイページ"にアクセスする

    Then "あなたの記事[あけおめ]に新着コメントがあります！"と表示されていないこと

    Given 以下のフォーラムを書く:
      |user    |group       |title        |tag |contents|publication_type|
      |a_user  |vim_group   |雑談しよう   |雑談|ほげほげ|全体に公開      |

    When "a_group_owned_user"で"vim_group"グループのサマリページを開く
    And "フォーラム"リンクをクリックする
    And "雑談しよう"リンクをクリックする
    And "コメントを書く"に"こんにちは"と入力する
    And "書き込み"ボタンをクリックする
    And "a_user"でログインする

    Then "あなたの記事[雑談しよう]に新着コメントがあります！"と表示されていること

    When "あなたの記事[雑談しよう]に新着コメントがあります！"リンクをクリックする
    And "マイページ"にアクセスする

    Then "あなたの記事[雑談しよう]に新着コメントがあります！"と表示されていないこと

  Scenario: システムメッセージ(トラックバック)が表示される
    Given 以下のブログを書く:
      | user   | title        | aim_type |
      | a_user | あけおめ     | 記事 (マイページの「新着記事」に表示されます)           |

    When "a_group_owned_user"で"1"つめのブログにアクセスする
    And "[この記事を「話題」にして、新しいブログを書く]"リンクをクリックする
    And "Wikiテキスト"を選択する
    And "contents_hiki"に"コンテンツ"と入力する
    And "作成"ボタンをクリックする
    And "a_user"でログインする

    Then "あなたの記事を話題にした新着記事[あけおめ]があります！"と表示されていること

    When "あなたの記事を話題にした新着記事[あけおめ]があります！"リンクをクリックする
    And "マイページ"にアクセスする

    Then "あなたの記事を話題にした新着記事[あけおめ]があります！"と表示されていないこと

  Scenario: システムメッセージ(紹介文)が表示される
    Given 以下の紹介文を作成する:
      |from_user|comment      |to_user|
      |a_user   |Aliceです。  |alice  |

    When "alice"でログインする

    Then "あなたの紹介文が追加されました！"と表示されていること

    When "あなたの紹介文が追加されました！"リンクをクリックする
    And "マイページ"にアクセスする

    Then "あなたの紹介文が追加されました！"と表示されていないこと

  Scenario: システムメッセージ(質問の状態変更)が表示される
    Given 以下のブログを書く:
      | user   | title        | aim_type |
      | a_user | 初めての質問 | 質問 (マイページの「みんなからの質問」に表示されます)   |
    And "a_group_owned_user"でログインする
    And "初めての質問"という質問の公開状態を変更する

    When "a_user"でログインする

    Then "あなたの質問 [初めての質問] の公開状態が変更されました。"と表示されていること

    When "あなたの質問 [初めての質問] の公開状態が変更されました。"リンクをクリックする
    And "マイページ"にアクセスする

    Then "あなたの質問 [初めての質問] の公開状態が変更されました。"と表示されていないこと

  Scenario: システムメッセージ(管理グループへの参加)が表示される
    Given 以下のグループを作成する:
      |owner    |gid        |name         |waiting  |
      |alice    |vim_group  |VimGroup     |false    |
    And "a_user"が"vim_group"グループに参加する

    When "alice"でログインする

    Then "[VimGroup]に新しい参加者がいます!"と表示されていること

    When "[VimGroup]に新しい参加者がいます!"リンクをクリックする
    And "マイページ"にアクセスする

    Then "[VimGroup]に新しい参加者がいます!"と表示されていないこと

  Scenario: システムメッセージ(管理グループからの退会)が表示される
    Given 以下のグループを作成する:
      |owner    |gid        |name         |waiting  |
      |alice    |vim_group  |VimGroup     |false    |
    And "a_user"が"vim_group"グループに参加する
    And "a_user"が"vim_group"グループを退会する

    When "alice"でログインする

    Then "a_userさんが[VimGroup]から退会しました。"と表示されていること

    When "a_userさんが[VimGroup]から退会しました。"リンクをクリックする
    And "マイページ"にアクセスする

    Then "a_userさんが[VimGroup]から退会しました。"と表示されていないこと

  Scenario: システムメッセージ(グループへの参加承認)が表示される
    Given 以下のグループを作成する:
      |owner    |gid        |name         |waiting  |
      |alice    |vim_group  |VimGroup     |true     |
    And "a_user"が"vim_group"グループに参加する

    #========================================
    # グループ管理者側
    #========================================
    When "alice"でログインする

    Then "[VimGroup]に承認待ちのユーザがいます!"と表示されていること

    When "[VimGroup]に承認待ちのユーザがいます!"リンクをクリックする

    # 承認画面に遷移
    Then "参加許可"と表示されていること

    When "マイページ"にアクセスする

    # クリックで消えない
    Then "[VimGroup]に承認待ちのユーザがいます!"と表示されていること

    # 承認すると消える
    When "alice"で"a_user"の"vim_group"グループへの参加を承認する
    And "マイページ"にアクセスする

    Then "[VimGroup]に承認待ちのユーザがいます!"と表示されていないこと

    #========================================
    # グループ参加申請者側
    #========================================
    When "a_user"でログインする

    Then "[VimGroup]への参加が承認されました。"と表示されていること

    When "[VimGroup]への参加が承認されました。"リンクをクリックする
    And "マイページ"にアクセスする

    Then "[VimGroup]への参加が承認されました。"と表示されていないこと

  Scenario: システムメッセージ(グループへの参加棄却)が表示される
    Given 以下のグループを作成する:
      |owner    |gid        |name         |waiting  |
      |alice    |vim_group  |VimGroup     |true     |
    And "a_user"が"vim_group"グループに参加する

    #========================================
    # グループ管理者側
    #========================================
    When "alice"で"a_user"の"vim_group"グループへの参加を棄却する
    And "マイページ"にアクセスする

    Then "[VimGroup]に承認待ちのユーザがいます!"と表示されていないこと

    #========================================
    # グループ参加申請者側
    #========================================
    When "a_user"でログインする

    Then "[VimGroup]への参加が棄却されました。"と表示されていること

    When "[VimGroup]への参加が棄却されました。"リンクをクリックする
    And "マイページ"にアクセスする

    Then "[VimGroup]への参加が棄却されました。"と表示されていないこと

  Scenario: システムメッセージ(グループへの強制参加)が表示される
    Given 以下のグループを作成する:
      |owner    |gid        |name         |waiting  |
      |alice    |vim_group  |VimGroup     |true     |
    And "alice"で"a_user"を"vim_group"グループへ強制参加させる

    When "a_user"でログインする

    Then "[VimGroup]に参加することになりました。"と表示されていること

    When "[VimGroup]に参加することになりました。"リンクをクリックする
    And "マイページ"にアクセスする

    Then "[VimGroup]に参加することになりました。"と表示されていないこと

  Scenario: システムメッセージ(グループからの強制退会)が表示される
    Given 以下のグループを作成する:
      |owner    |gid        |name         |waiting  |
      |alice    |vim_group  |VimGroup     |false    |
    And "a_user"が"vim_group"グループに参加する
    And "alice"で"a_user"を"vim_group"グループから強制退会させる

    When "a_user"でログインする

    Then "[VimGroup]を強制退会しました。"と表示されていること

    When "[VimGroup]を強制退会しました。"リンクをクリックする
    And "マイページ"にアクセスする

    Then "[VimGroup]を強制退会しました。"と表示されていないこと
