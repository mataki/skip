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

    When    "マイページ"にアクセスする
    And     "ブックマーク"リンクをクリックする
    And     URLが"http://test.host/"で文字列が"タイトル1"のリンクが存在すること
    And     "コメント1"と表示されていること
    And     URLが"http://test.host/%27%3Cscript%3Ealert(1)%3C/script%3E%27"で文字列が"タイトル2"のリンクが存在すること
    And     "シングルクオート"と表示されていること

  Scenario: ブックマークの詳細画面を表示する
  Scenario: ブッマークの編集をする
  Scenario: ブックマークを削除する

  Scenario: 自分のユーザ毎のブックマーク一覧を表示する
    Given   以下のブックマークのリストを登録している:
            |url              |title   |comment |
            |http://test.host/|タイトル1|コメント1|
            |http://test.host/'<script>alert(1)</script>'|タイトル2|シングルクオート|

    When    "マイページ"にアクセスする
    And     "#tab_menu"中の"ブックマーク"リンクをクリックする

    # 以下のstepは、リンクがあるかどうかだけのチェック
    Then    "スターを付ける"リンクをクリックする
    And     "タイトル1"と表示されていること
    And     "コメント1"と表示されていること
    And     "タイトル2"と表示されていること
    And     "シングルクオート"と表示されていること

  Scenario: 他人のユーザ毎のブックマーク一覧を表示する
    Given   以下のブックマークのリストを登録している:
            |url              |title   |comment |
            |http://test.host/|タイトル1|コメント1|
            |http://test.host/'<script>alert(1)</script>'|タイトル2|シングルクオート|

    When    "a_group_owned_user"でログインする
    And     "a_userユーザのプロフィールページ"にアクセスする
    And     "#tab_menu"中の"ブックマーク"リンクをクリックする

    Then    "スターを付ける"と表示されていないこと
    And     "タイトル1"と表示されていること
    And     "コメント1"と表示されていること
    And     "タイトル2"と表示されていること
    And     "シングルクオート"と表示されていること

