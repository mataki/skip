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
    And     "作成"ボタンをクリックする

    Then    flashメッセージに"グループが正しく作成されました。"と表示されていること

  Scenario: ユーザとしてグループの新規作成に失敗する

  Scenario: グループ管理者は、参加者を追加することができる
    Given "a_user"で"rails"というグループを作成する

    When  "管理"リンクをクリックする
    And   "参加者管理"リンクをクリックする
    And   "symbol"に"uid:100003"と入力する
    And   "参加者に追加"ボタンをクリックする
    Then  flashメッセージに"a_group_owned_userさんを参加者に追加し、連絡の掲示板を作成しました。"と表示されていること
    And   "a_group_owned_user"と表示されていること

    When  "symbol"に"uid:100003"と入力する
    And   "参加者に追加"ボタンをクリックする
    Then  flashメッセージに"a_group_owned_userさんは既に参加済み/参加申請済みです。"と表示されていること

    When  "symbol"に"uid:not_exist_user"と入力する
    And   "参加者に追加"ボタンをクリックする

    Then  flashメッセージに"ユーザ・グループの選択が正しくありません。"と表示されていること

    When  "symbol"に"gid:a_protected_group1"と入力する
    And   "参加者に追加"ボタンをクリックする
    Then  flashメッセージに"a_protected_group1のメンバーを参加者に追加し、連絡の掲示板を作成しました。"と表示されていること

    When  "symbol"に"gid:not_exist_group"と入力する
    And   "参加者に追加"ボタンをクリックする
    Then  flashメッセージに"ユーザ・グループの選択が正しくありません。"と表示されていること
