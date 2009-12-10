# SKIP(Social Knowledge & Innovation Platform)
# Copyright (C) 2008 TIS Inc.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.

Feature: Wikiの管理
  ユーザは、Wikiに対して自由に作成や編集ができる

  Background:
    Given   言語は"ja-JP"
    And     "a_user"でログインする

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
    Then    "[編集する]"と表示されていること

    When    "セカンドページ"リンクをクリックする

    Then    "セカンドページ"と表示されていること
    Then    "関連ページ"と表示されていること
    Then    "[編集する]"と表示されていること
    Then    "フォースページ"と表示されていること
    Then    "リンク元ページ"と表示されていること
    Then    "トップページ"と表示されていること
    Then    "ページを追加する"と表示されていること


  Scenario: 新規ページを作成する
    Given   "Wikiトップページ"にアクセスする
    And     "タイトル"に"次のページ"と入力する
    And     "作成"ボタンをクリックする

    Then    flashメッセージに"'次のページ'が作成されました"と表示されていること
    Then    "関連ページ"と表示されていること

    When    "次のページ"リンクをクリックする

    Then    "リンク元ページ"と表示されていること
    Then    "トップページ"と表示されていること

  Scenario: 存在しているページ名を追加しようとするとエラーが発生する
    Given   "Wikiトップページ"にアクセスする
    And     "タイトル"に"セカンドページ"と入力する
    And     "作成"ボタンをクリックする

    Then    ペンディング"うまくうごかないため"
    Then    flashメッセージに"Titleはすでに存在します"と表示されていること

  Scenario: ページの編集を行う
    Given   "Wikiトップページ"にアクセスする

    And     "[編集する]"リンクをクリックする
    And     "history_content"に"テストページを更新します"と入力する
    And     "ページを更新"ボタンをクリックする

    Then    flashメッセージに"ページが更新されました"と表示されていること
    Then    "テストページを更新します"と表示されていること

  Scenario: 更新情報の表示を確認する
    Given   "Wikiトップページ"にアクセスする
    And     "タイトル"に"次のページ"と入力する
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
    And     "[編集する]"リンクをクリックする
    And     "history_content"に"テストページを更新します"と入力する
    And     "ページを更新"ボタンをクリックする
    And     "[編集する]"リンクをクリックする
    And     "history_content"に"ページ"と入力する
    And     "ページを更新"ボタンをクリックする
    And     "履歴"リンクをクリックする

    Then    "前"と表示されていること
    Then    "次"と表示されていること

    And     "次"リンクをクリックする
    Then    "変更点"と表示されていること



