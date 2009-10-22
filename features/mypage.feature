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

  Scenario: 質問を表示する
    Given 以下のブログを書く:
      |user  |title            |aim_type  |contents     |
      |a_user|Railsについて質問|質問      |わかりません |
      |a_user|Railsについて雑談|記事      |色々話そう   |

    When "マイページ"にアクセスする

    Then I should see "Railsについて質問" within "div#questions"
    And I should not see "Railsについて質問" within "div#access_blogs"
    And I should see "Railsについて雑談" within "div#access_blogs"
    And I should see "Railsについて質問" within "div#recent_blogs"
    And I should see "Railsについて雑談" within "div#recent_blogs"

  Scenario: お知らせを表示する
    Given 以下のブログを書く:
      |user  |title                 |aim_type  |contents        |
      |a_user|Railsについてお知らせ |お知らせ  |リリースします  |
      |a_user|Railsについて雑談     |記事      |色々話そう      |
    And 新着通知を作成バッチを実行する

    When "a_group_owned_user"でログインする
    And "マイページ"にアクセスする

    Then I should see "Railsについてお知らせ" within "div#message"
    And I should not see "Railsについてお知らせ" within "div#access_blogs"
    And I should see "Railsについて雑談" within "div#access_blogs"
    And I should see "Railsについてお知らせ" within "div#recent_blogs"
    And I should see "Railsについて雑談" within "div#recent_blogs"
    And I should see "あなたへのお知らせ(1)" within "div.box_space.antenna"

    When "新着通知"リンクをクリックする

    Then I should see "Railsについてお知らせ"
    And I should not see "Railsについて雑談"

    When "マイページ"にアクセスする
    And "あなたへのお知らせ"リンクをクリックする

    Then I should see "Railsについてお知らせ"
    And I should not see "Railsについて雑談"

    When "Railsについてお知らせ"リンクをクリックする
    And "マイページ"にアクセスする

    Then I should see "あなたへのお知らせ(0)" within "div.box_space.antenna"

    When "あなたへのお知らせ"リンクをクリックする

    Then I should not see "Railsについてお知らせ"
    And I should not see "Railsについて雑談"

    When "[既に読んだ記事を表示]"リンクをクリックする

    Then I should see "Railsについてお知らせ"
    And I should not see "Railsについて雑談"
