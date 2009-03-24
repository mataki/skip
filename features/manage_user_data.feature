Feature: マイページのメールアドレス管理
  メールアドレスをマイページから変更したい

  Scenario: メールアドレスの変更を申請する
    Given   言語は"ja-JP"
    And     メール機能を有効にする
    And     ログインIDが"111111"でパスワードが"Password1"のユーザを作成する
    And     ログインページを表示している

    When    "ログインID"に"111111"と入力する
    And     "パスワード"に"Password1"と入力する
    And     "ログイン"ボタンをクリックする

    And     "自分の管理"リンクをクリックする
    And     "メールアドレス変更"リンクをクリックする
    And     "applied_email_email"に"Test_User@example.com"と入力する
    And     "申請"ボタンをクリックする

    Then    "メールアドレス変更の申請を受け付けました。メールをご確認ください。"と表示されていること
    And     メールが"test_user@example.com"宛に送信されていること
