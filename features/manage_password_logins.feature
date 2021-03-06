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

Feature: パスワードでログインする
  あるユーザとして、SKIPにログインしたい

  Background:
    Given   言語は"ja-JP"

  Scenario: ログイン画面を表示する
    Given   ログインページを表示している

    Then    "ログイン"と表示されていること

  Scenario: ログインに成功する
    Given   ログインIDが"111111"でパスワードが"Password1"のあるユーザを作成する
    And     ログインページを表示している

    When    "ログインID"に"111111"と入力する
    And     "パスワード"に"Password1"と入力する
    And     "ログイン"ボタンをクリックする

    Then    "マイページ"と表示されていること

  Scenario: パスワード間違いによりログインに失敗する
    Given   ログインIDが"111111"でパスワードが"Password1"のあるユーザを作成する
    And     ログインページを表示している

    When    "ログインID"に"111111"と入力する
    And     "パスワード"に"hogehoge"と入力する
    And     "ログイン"ボタンをクリックする

    Then    flashメッセージに"ログインに失敗しました。"と表示されていること

  Scenario: アカウントがロックされていることによりログインに失敗する
    Given   ログインIDが"111111"でパスワードが"Password1"のあるユーザを作成する
    And     あるユーザはロックされている
    And     ログインページを表示している

    When    "ログインID"に"111111"と入力する
    And     "パスワード"に"Password1"と入力する
    And     "ログイン"ボタンをクリックする

    Then    flashメッセージに"パスワードが無効になっています。再設定を行なってください。"と表示されていること
