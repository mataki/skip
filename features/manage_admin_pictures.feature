Feature: 管理者がプロフィール画像を管理する
  管理者としてプロフィール画像の管理を行いたい

  Background:
    Given   言語は"ja-JP"
    And     "a_user"でログインする

  Scenario: プロフィール画像一覧を初期表示する
    Given   "マイページ"にアクセスする
    And     "システムの管理"リンクをクリックする
    And     "データ管理"リンクをクリックする

    When    "プロフィール画像一覧"リンクをクリックする

    Then    "プロフィール画像一覧"と表示されていること

  Scenario: プロフィール画像を新規にアップロード/更新/削除する
    Given   "プロフィール画像一覧"にアクセスする
    And     "新規"リンクをクリックする

    When    "ファイル"としてファイル"spec/fixtures/data/profile.png"をContent-Type"image/png"として添付する
    And     "アップロード"ボタンをクリックする

    Then    flashメッセージに"プロフィール画像の作成に成功しました。"と表示されていること

    When    "編集"リンクをクリックする
    And     "ファイル"としてファイル"spec/fixtures/data/profile.png"をContent-Type"image/png"として添付する
    And     "アップロード"ボタンをクリックする

    Then    flashメッセージに"プロフィール画像の更新に成功しました。"と表示されていること

    When    "削除"リンクをクリックする
    Then    flashメッセージに"プロフィール画像を削除しました。"と表示されていること

