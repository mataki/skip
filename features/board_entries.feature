Feature: 記事コメントの管理
  ユーザは、記事にコメントをすることができる

  Background:
    Given   言語は"ja-JP"

  Scenario: ユーザとして空のコメントが登録できない
    Given   "a_user"でブログを書く
    When    "コメントを書く"に""と入力する
    And     "書き込み"ボタンをクリックする
    Then    "不正なパラメタです。"と表示されること

  Scenario: ユーザとして妥当なコメントが登録できる
    Given   "a_user"でブログを書く
    When    "コメントを書く"に"コメント"と入力する
    And     "書き込み"ボタンをクリックする
    Then    "新着"と表示されること
    And     "コメント"と表示されること

  Scenario: ユーザとしてGoodJobポイントを追加できる
    Given   "a_user"でブログを書く
    And     "a_group_owned_user"で"1"つめのブログにアクセスする
    When    "0 GoodJob"ボタンをクリックする
    Then    "1 GoodJob"と表示されること
