Feature: グループの管理
  グループは、SKIPのグループを管理できる

  Background:
    Given   言語は"ja-JP"
    And     "a_user"でログインする

  Scenario: ユーザとしてグループの新規作成に成功する
    Given   "マイページ"にアクセスする
    And     "グループを作る"リンクをクリックする

    When    "グループID"に"alice_group"と入力する
    And     "名称"に"アリスグループ"と入力する
    And     "説明"に"アリス専用"と入力する
    And     "全体に公開"を選択する
    And     "投稿時にメールも送信する"をチェックする
    And     "作成"ボタンをクリックする

    Then    flashメッセージに"グループが正しく作成されました。"と表示されていること

  Scenario: ユーザとして承認が不要なグループに参加することが出来る
    Given 以下のグループを作成する:
      |owner    |gid        |name         |waiting  |
      |alice    |vim_group  |VimGroup     |false    |

    When "a_user"でログインする
    And "vim_groupグループのトップページ"にアクセスする
    And "参加する"リンクをクリックする

    Then flashメッセージに"グループに参加しました。"と表示されていること

  Scenario: ユーザとして承認が必要なグループに参加することが出来る
    Given 以下のグループを作成する:
      |owner    |gid        |name         |waiting  |
      |alice    |vim_group  |VimGroup     |true     |

    When "a_user"でログインする
    And "vim_groupグループのトップページ"にアクセスする
    And "参加する"リンクをクリックする

    Then flashメッセージに"参加申し込みをしました。承認されるのをお待ちください。"と表示されていること

  Scenario: ユーザとして参加中のグループから退会することが出来る
    Given 以下のグループを作成する:
      |owner    |gid        |name         |waiting  |
      |alice    |vim_group  |VimGroup     |false    |
    And "a_user"が"vim_group"グループに参加する

    When "a_user"でログインする
    And "vim_groupグループのトップページ"にアクセスする
    And "退会する"リンクをクリックする

    Then flashメッセージに"退会しました。"と表示されていること

  Scenario: グループ管理者として参加申請中のユーザを承認することが出来る
  Scenario: グループ管理者として参加申請中のユーザを棄却することが出来る

  Scenario: グループ管理者としてユーザを強制参加させることが出来る
    Given 以下のグループを作成する:
      |owner    |gid        |name         |waiting  |
      |alice    |rails      |Rails        |false    |
      |kenji    |vim_group  |VimGroup     |false    |
    And "johji"がユーザ登録する

    When "alice"でログインする
    And "railsグループのトップページ"にアクセスする
    And "管理"リンクをクリックする
    And "参加者管理"リンクをクリックする
    And "symbol"に"uid:johji"と入力する
    And "参加者に追加"ボタンをクリックする
    Then flashメッセージに"johjiさんを参加者に追加しました。"と表示されていること
    And "johji"と表示されていること

    When "alice"でログインする
    And "railsグループのトップページ"にアクセスする
    And "管理"リンクをクリックする
    And "参加者管理"リンクをクリックする
    And "symbol"に"uid:johji"と入力する
    And "参加者に追加"ボタンをクリックする
    Then flashメッセージに"johjiさんは既に参加済み/参加申請済みです。"と表示されていること

    When "symbol"に"uid:not_exist_user"と入力する
    And "参加者に追加"ボタンをクリックする

    Then flashメッセージに"ユーザ・グループの選択が正しくありません。"と表示されていること

    When "symbol"に"gid:vim_group"と入力する
    And "参加者に追加"ボタンをクリックする
    Then flashメッセージに"VimGroupの参加者をこのグループの参加者に追加しました。"と表示されていること

    When "symbol"に"gid:not_exist_group"と入力する
    And "参加者に追加"ボタンをクリックする
    Then flashメッセージに"ユーザ・グループの選択が正しくありません。"と表示されていること

  Scenario: グループ管理者としてユーザを強制退会させることが出来る
    Given 以下のグループを作成する:
      |owner    |gid        |name         |waiting  |
      |alice    |vim_group  |VimGroup     |false    |
    And "a_user"が"vim_group"グループに参加する

    When "alice"でログインする
    And "vim_groupグループのトップページ"にアクセスする
    And "管理"リンクをクリックする
    And "参加者管理"リンクをクリックする
    And "[強制退会させる]"リンクをクリックする

    Then flashメッセージに"a_userさんをこのグループの参加者から削除しました。"と表示されていること

  Scenario: グループ未参加時のアクション表示
    Given 以下のグループを作成する:
      |owner    |gid        |name         |waiting  |
      |alice    |vim_group  |VimGroup     |false    |

    When "a_user"でログインする
    And "vim_groupグループのトップページ"にアクセスする

    Then "参加する"と表示されていること
    And "新着時に通知"と表示されていること
    And "記事を書く"と表示されていないこと
    And "お知らせを書く"と表示されていないこと
    And "質問を書く"と表示されていないこと
    And "ファイルをアップ"と表示されていないこと
    And "退会する"と表示されていないこと

  Scenario: グループ参加時のアクション表示
    Given 以下のグループを作成する:
      |owner    |gid        |name         |waiting  |
      |alice    |vim_group  |VimGroup     |false    |
    And "a_user"が"vim_group"グループに参加する

    When "a_user"でログインする
    And "vim_groupグループのトップページ"にアクセスする

    Then "参加する"と表示されていないこと
    And "新着時に通知"と表示されていないこと
    And "記事を書く"と表示されていること
    And "お知らせを書く"と表示されていること
    And "質問を書く"と表示されていること
    And "ファイルをアップ"と表示されていること
    And "退会する"と表示されていること
