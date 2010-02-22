# If you should run cucumber test, you have to config for config/initial_settings.yml.([:wiki][:use]->true)
# withinでidの中の要素を指定できる

Feature: Wikiの管理
  ユーザは、Wikiに対して自由に作成や編集ができる

  Background:
    Given   言語は"ja-JP"
    And     "a_user"でログインする
    And     Wiki機能を有効にする

  Scenario: Wikiへアクセスする
    Given   "マイページ"にアクセスする
    And     "Wiki"リンクをクリックする

    Then    "トップページ"と表示されていること

  Scenario: Wikiのナビゲーションのテストをする
    Given   "マイページ"にアクセスする
    And     "Wiki"リンクをクリックする

    Then    "関連ページ"と表示されていること
    Then    "リンク元"と表示されていないこと
    Then    "ページを追加する"と表示されていること
    Then    "[編集]"と表示されていること

    When    "セカンドページ"リンクをクリックする

    Then    "セカンドページ"と表示されていること
    Then    "関連ページ"と表示されていること
    Then    "[編集]"と表示されていること
    Then    "フォースページ"と表示されていること
    Then    "リンク元ページ"と表示されていること
    Then    "トップページ"と表示されていること
    Then    "ページを追加する"と表示されていること

  Scenario: 新規ページを作成する
    Given   "Wikiトップページ"にアクセスする
    And     "pagename"に"次のページ"と入力する
    And     "作成"ボタンをクリックする

    Then    flashメッセージに"'次のページ'が作成されました。"と表示されていること
    Then    "関連ページ"と表示されていること

    When    "次のページ"リンクをクリックする

    Then    "リンク元ページ"と表示されていること
    Then    "トップページ"と表示されていること

  Scenario: 存在しているページ名を追加しようとするとエラーが発生する
    Given   "Wikiトップページ"にアクセスする
    And     "pagename"に"セカンドページ"と入力する
    And     "作成"ボタンをクリックする

    Then    flashメッセージに"Titleはすでに存在します。"と表示されていること

  Scenario: ページの編集を行う
    Given   "Wikiトップページ"にアクセスする

    And     "[編集]"リンクをクリックする
    And     "chapter_content"に"テストページを更新するします"と入力する
    And     "ページを更新する"ボタンをクリックする

    Then    flashメッセージに"'トップページ'が更新されました。"と表示されていること
    Then    "テストページを更新するします"と表示されていること


  Scenario: 更新情報の表示を確認する
    Given   "Wikiトップページ"にアクセスする
    And     "pagename"に"次のページ"と入力する
    And     "作成"ボタンをクリックする
    And     "次のページ"リンクをクリックする

    Then    "Last-modified:"と表示されること
    Then    "a_user"と表示されること

  Scenario: 履歴の管理
    Given   "Wikiトップページ"にアクセスする

    Then    "履歴"と表示されること

    And     "履歴"リンクをクリックする

    Then    "編集履歴"と表示されること

    When    "Wikiトップページ"にアクセスする
    And     "[編集]"リンクをクリックする
    And     "chapter_content"に"テストページを更新するします"と入力する
    And     "ページを更新する"ボタンをクリックする
    And     "[編集]"リンクをクリックする
    And     "chapter_content"に"hogehoge"と入力する
    And     "ページを更新する"ボタンをクリックする
    And     "履歴"リンクをクリックする

    Then    "前"と表示されていること
    Then    "次"と表示されていること

    And     "次"リンクをクリックする
    Then    "変更点"と表示されていること

    When    "Wikiトップページ"にアクセスする
    And     "履歴"リンクをクリックする
    And     "リビジョン1を表示"リンクをクリックする

    Then    "hogehoge"と表示されていないこと

  Scenario: ページの削除
    Given   "Wikiトップページ"にアクセスする

    And     "[削除]"と表示されていないこと

    Then    "セカンドページ"リンクをクリックする
    And     "[削除]"と表示されていること

    Then    "[削除]"リンクをクリックする
    And    flashメッセージに"'セカンドページ'の削除が完了しました。"と表示されていること
    And     "[編集]"と表示されていないこと
    And     "[削除]"と表示されていないこと
    And     "[復旧する]"と表示されていること

    Then    "[復旧する]"リンクをクリックする
    And    flashメッセージに"'セカンドページ'の復旧が完了しました。"と表示されていること
    And     "[編集]"と表示されていること
    And     "[削除]"と表示されていること

  Scenario: Chapterを追加する
    Given   "Wikiトップページ"にアクセスする
    And     "[編集]"リンクをクリックする
    And     "chapter_content"に"テストページを更新するします"と入力する
    And     "ページを更新する"ボタンをクリックする
    And    "[追加する]"リンクをクリックする

    And     "chapter_content"に"ほげほげ"と入力する
    And     "ページを更新する"ボタンをクリックする

    Then    "ほげほげ"と表示されていること
    Then    flashメッセージに"'トップページ'が更新されました。"と表示されていること
    Then    "テストページを更新するします"と表示されていること

  Scenario: ファイルを添付する
    Given   ペンディング"Ajaxなので手動でテストする"


