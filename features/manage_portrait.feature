Feature: 一般ユーザが自身のプロフィール画像を管理する
  一般ユーザとしてプロフィール画像の管理を行いたい

  Background:
    Given   言語は"ja-JP"
    And     "a_user"でログインする

  Scenario: プロフィール画像変更画面を初期表示する
    Given   マイページを表示する
    And     "自分の管理"リンクをクリックする
    And     "プロフィール画像変更"リンクをクリックする

    Then    "画像サイズは、64kbまでです。"と表示されていること

  Scenario: プロフィール画像を新規にアップロード/更新/削除に成功する
    Given   マイページを表示する
    And     "自分の管理"リンクをクリックする
    And     "プロフィール画像変更"リンクをクリックする

    When    "ファイル"としてファイル"spec/fixtures/data/profile.png"をContent-Type"image/png"として添付する
    And     "アップロード"ボタンをクリックする

    Then    flashメッセージに"画像を変更しました"と表示されていること

    When    "ファイル"としてファイル"spec/fixtures/data/profile.png"をContent-Type"image/png"として添付する
    And     "アップロード"ボタンをクリックする

    Then    flashメッセージに"画像を変更しました"と表示されていること

    When    "削除"リンクをDELETEクリックする
    Then    flashメッセージに"画像を削除しました"と表示されていること

  Scenario: プロフィール画像のサイズが大きすぎてアップロードに失敗する
    Given   マイページを表示する
    And     "自分の管理"リンクをクリックする
    And     "プロフィール画像変更"リンクをクリックする

    When    "ファイル"としてファイル"spec/fixtures/data/too_large_profile.png"をContent-Type"image/png"として添付する
    And     "アップロード"ボタンをクリックする

    Then    flashメッセージに" ファイルサイズが大きすぎます。"と表示されていること
