Feature: アンテナの管理
  ユーザは、アンテナにユーザやグループを登録、管理できる

  Background:
    Given   言語は"ja-JP"
    And     "a_user"でログインする

  Scenario: ユーザのプロフィールページから新しいアンテナを作成してユーザを登録する
    When    ログインIDが"vimmer"でパスワードが"Password1"のあるユーザを作成する
    And     "vimmerユーザのプロフィールページ"にアクセスする
    And     新着時に通知リンクをクリックした状態にする
    And     "vimmerユーザのプロフィールページ"にアクセスする

    Then    "Stop a notification"と表示されていること

    When    "Stop a notification"リンクをクリックする

    Then    "新着時に通知"と表示されていること
