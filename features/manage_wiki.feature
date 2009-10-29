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
    Then    ページのタブメニューが表示されていること


  Scenario: Wikiのナビゲーションのテストをする
    Given   "マイページ"にアクセスする
    And     "Wiki"リンクをクリックする

    Then    "関連ページ"と表示されていること
    Then    "リンク元"と表示されていないこと
    Then    "ページを追加する"と表示されていること
    Then    "[このページを削除する]"と表示されていないこと

    When    "セカンドページ"リンクをクリックする

    Then    "セカンドページ"と表示されていること
    Then    "関連ページ"と表示されていること
    Then    "フォースページ"と表示されていること
    Then    "リンク元ページ"と表示されていること
    Then    "トップページ"と表示されていること
    Then    "ページを追加する"と表示されていること
    Then    "[このページを削除する]"と表示されていること

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

