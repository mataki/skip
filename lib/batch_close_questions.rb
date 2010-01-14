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

require File.expand_path(File.dirname(__FILE__) + "/batch_base")
require 'fileutils'

class BatchCloseQuestions < BatchBase

  def self.execute options
    check_days_ago = options[:check_days_ago].to_i
    checkpoint = Date.today - check_days_ago

    BoardEntry.update_all('hide = 1', 
                          ["board_entries.aim_type = 'question' AND board_entries.created_on < ? AND board_entries.hide = 0", checkpoint])
  end
end

# 本日よりnum日以前に投稿された質問文を強制的にクローズする(updated_onを参照する)
check_days_ago = Admin::Setting.close_question_limit.to_s || "30"
if check_days_ago.index(/[0-9]+/)
  BatchCloseQuestions.execution({ :check_days_ago => check_days_ago }) unless RAILS_ENV == 'test'
else
  BatchCloseQuestions::log_error "数値以外の引数が指定されています。"
end
