Feature: 紹介文の管理
  ユーザが任意のユーザに対する紹介文を作成/更新できる

  Background:
    Given 言語は"ja-JP"

  Scenario: 紹介文を作成/更新する
    Given ログインIDが"alice"でパスワードが"Password1"のあるユーザを作成する

    When "a_user"でログインする
    And "aliceユーザのプロフィールページ"にアクセスする
    And "みんなに紹介する"リンクをクリックする
    And "作成"ボタンをクリックする
    # TODO 紹介文に直す
    Then "紹介した人を入力してください。"と表示されること

    When "chain_comment"に"アリスを紹介します。"と入力する
    And "作成"ボタンをクリックする

    Then flashメッセージに"紹介文を作成しました"と表示されていること
    And "アリスを紹介します。"と表示されていること

    When "alice"でログインする

    Then "あなたの紹介文が追加されました！"と表示されていること

  Scenario: 紹介文を更新する
    Given 以下の紹介文を作成する:
      |from_user|comment      |to_user|
      |a_user   |Aliceです。  |alice  |

    When "a_user"でログインする
    And "aliceユーザのプロフィールページ"にアクセスする
    And "紹介文の変更"リンクをクリックする
    And "chain_comment"に"アリスを宜しくお願いします。"と入力する
    And "更新"ボタンをクリックする

    Then flashメッセージに"紹介文を更新しました"と表示されていること
    And "アリスを宜しくお願いします。"と表示されていること

  Scenario: 紹介文を削除する
    Given 以下の紹介文を作成する:
      |from_user|comment      |to_user|
      |a_user   |Aliceです。  |alice  |

    When "a_user"でログインする
    And "aliceユーザのプロフィールページ"にアクセスする
    And "紹介文の変更"リンクをクリックする
    And "[削除]"リンクをクリックする

    Then flashメッセージに"紹介文を削除しました"と表示されていること


