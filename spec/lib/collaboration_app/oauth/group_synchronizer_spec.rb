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

require File.dirname(__FILE__) + '/../../../spec_helper'

describe CollaborationApp::Oauth::GroupSynchronizer, '#sync' do
  before do
    @synchronizer = CollaborationApp::Oauth::GroupSynchronizer.new 'wiki'
    @client = stub(SkipEmbedded::RpService::Client, :key => 'key', :secret => 'secret')
    @synchronizer.should_receive(:client).and_return(@client)
  end
  it 'CollaborationApp::Oauth::Service#sync_groupsが実行されること' do
    synchronize_groups = [
      ["vim_study", "vim_study", "Vim勉強会", ["http://localhost:3000/id/boob", "http://localhost:3000/id/alice"]],
      ["emacs_study", "emacs_study", "Emacs勉強会", ["http://localhost:3000/id/boob"]]
    ]
    Group.should_receive(:synchronize_groups).and_return(synchronize_groups)
    @client.should_receive(:sync_groups).with(synchronize_groups)
    @synchronizer.sync
  end
end
