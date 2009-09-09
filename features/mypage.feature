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
    And "[雑談]"リンクをクリックする

    Then "別の雑談"と表示されていること
