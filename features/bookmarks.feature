Feature: ブックマークの管理
  ユーザは、SKIPの内外のファイルをブックマークすることができる

  Background:
    Given   言語は"ja-JP"
    And     "a_user"でログインする

  Scenario: ブックマークレットでブックマークを登録する
    When   ブックマークレットのページをURL"http://test.host/"で表示する
    Then   "http://test.host/"と表示されていること

    When   "タイトル"に"タイトル1"と入力する
    And    "コメント"に"コメント1"と入力する
    And    "保存"ボタンをクリックする
    Then    "success"と表示されること

  Scenario: ブックマークレットで半端なマルチバイトのURLのブックマークを登録する
    When    ブックマークレットのページをURL"http://test.host/%c0aaa"で表示する
    Then    flashメッセージに"URLの形式が不正です。"と表示されていること

  Scenario: ブックマークレットでシングルクオートのURLのブックマークを登録する
    When    ブックマークレットのページをURL"http://test.host/'<script>alert(1)</script>'"で表示する
    Then    URLが"http://test.host/%27%3Cscript%3Ealert(1)%3C/script%3E%27"で文字列が"http://test.host/%27%3Cscript%3Ealert(1)%3C/script%3E%27"のリンクが存在すること

    When   "タイトル"に"タイトル2"と入力する
    And    "コメント"に"コメント2"と入力する
    And    "保存"ボタンをクリックする
    Then    "success"と表示されること

  Scenario: ブックマーク一覧画面を見る
    Given   以下のブックマークのリストを登録している:
            |url              |title   |comment |
            |http://test.host/|タイトル1|コメント1|
            |http://test.host/'<script>alert(1)</script>'|タイトル2|シングルクオート|

    When    マイページを表示する
    And     "ブックマーク"リンクをクリックする
    And     URLが"http://test.host/"で文字列が"タイトル1"のリンクが存在すること
    And     "コメント1"と表示されていること
    And     URLが"http://test.host/%27%3Cscript%3Ealert(1)%3C/script%3E%27"で文字列が"タイトル2"のリンクが存在すること
    And     "シングルクオート"と表示されていること

  Scenario: ブックマーク一覧(全体)ページからブックマークを登録する
    Given  全体からのブックマーク検索画面を表示する

    When   "url"に"http://test.host/"と入力する
    And    "ブックマークする"ボタンをクリックする
    Then   "ブックマークコメント"と表示されること

    When   "タイトル"に"Vim"と入力する
    And    "タグ"に"ruby,rails"と入力する
    And    "コメント"に"キーボード"と入力する
    And    "保存"ボタンをクリックする
    Then    "success"と表示されること

  Scenario: ブックマークの詳細画面を表示する
  Scenario: ブッマークの編集をする
  Scenario: ブックマークを削除する

