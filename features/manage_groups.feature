Feature: グループの管理
  グループは、SKIPのグループを管理できる

  Background:
    Given   言語は"ja-JP"
    And     "a_user"でログインする

  Scenario: ユーザとしてグループの新規作成に成功する
    Given   "マイページ"にアクセスする
    And     "#globalnavi"中の"グループ"リンクをクリックする
    And     "グループの新規作成"リンクをクリックする

    When    "グループID"に"alice_group"と入力する
    And     "名称"に"アリスグループ"と入力する
    And     "説明"に"アリス専用"と入力する
    And     "全体に公開"を選択する
    And     "作成"ボタンをクリックする

    Then    flashメッセージに"グループが正しく作成されました。"と表示されていること

  Scenario: ユーザとしてグループの新規作成に失敗する

