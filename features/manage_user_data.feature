# SKIP(Social Knowledge & Innovation Platform)
# Copyright (C) 2008-2010 TIS Inc.
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

Feature: 自分の管理
  メールアドレスなどを自分に関する情報を変更できるページ

  Background:
    Given   言語は"ja-JP"

  Scenario: メールアドレスの変更を申請する
    Given   メール機能を有効にする
    And     ログインIDが"111111"でパスワードが"Password1"のあるユーザでログインする

    And     "自分の管理"リンクをクリックする
    And     "メールアドレス変更"リンクをクリックする
    And     "applied_email_email"に"Test_User@example.com"と入力する
    And     "申請"ボタンをクリックする

    Then    flashメッセージに"メールアドレス変更の申請を受け付けました。メールをご確認ください。"と表示されていること
    And     メールが"test_user@example.com"宛に送信されていること

#  TODO 機能が完全に削除されたら以下も消す
#  Scenario: マイページのカレンダー表示/非表示をカスタマイズする
#    Given   "a_user"でログインする
#
#    When    "自分の管理"リンクをクリックする
#    And     "画面デザインの変更"リンクをクリックする
#    And     "カレンダーを表示しない"を選択する
#    And     "変更"ボタンをクリックする
#    And     "マイページ"にアクセスする
#
#    Then    "[今日]"と表示されていないこと
#
#    When    "自分の管理"リンクをクリックする
#    And     "画面デザインの変更"リンクをクリックする
#    And     "カレンダーを表示する"を選択する
#    And     "変更"ボタンをクリックする
#    And     "マイページ"にアクセスする
#
#    Then    "[今日]"と表示されていること
