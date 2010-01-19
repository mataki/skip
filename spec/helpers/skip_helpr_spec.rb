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

require File.dirname(__FILE__) + '/../spec_helper'

describe SkipHelper, '#skip_jquery_include_tag' do
  it '指定したjqueryのライブラリのロードを行うこと' do
    source = 'jquery'
    path = 'jquery_js_path'
    helper.should_receive(:skip_jquery_path).and_return(path)
    helper.should_receive(:javascript_include_tag).with(path)
    helper.skip_jquery_include_tag source
  end
end

describe SkipHelper, '#skip_jquery_path' do
  describe 'productionの場合' do
    before do
      ENV.stub!('[]').with('RAILS_ENV').and_return('production')
    end
    describe 'jquery本体の場合' do
      it 'minifiedされたjquery本体へののパスが返却されること' do
        helper.skip_jquery_path('jquery').should == '/javascripts/skip/jquery/jquery.min.js'
      end
    end
    describe 'Jquery UIのuiプラグインの場合' do
      it 'minifiedされたJquery UIのuiプラグインへのパスが返却されること' do
        helper.skip_jquery_path('ui.core').should == '/javascripts/skip/jquery/ui/minified/ui.core.min.js'
      end
    end
    describe 'Jquery UIのeffectsプラグインの場合' do
      it 'minifiedされたJquery UIのeffectsプラグインへのパスが返却されること' do
        helper.skip_jquery_path('effects.core').should == '/javascripts/skip/jquery/ui/minified/effects.core.min.js'
      end
    end
    describe '通常のjqueryプラグインの場合' do
      it 'minifiedされたjquery pluginへのパスが返却されること' do
        helper.skip_jquery_path('foo').should == '/javascripts/skip/jquery/plugins/minified/foo.min.js'
      end
    end
  end
  describe 'developmentの場合' do
    before do
      ENV.stub!('[]').with('RAILS_ENV').and_return('development')
    end
    describe 'jquery本体の場合' do
      it 'jquery本体へののパスが返却されること' do
        helper.skip_jquery_path('jquery').should == '/javascripts/skip/jquery/jquery.js'
      end
    end
    describe 'Jquery UIのuiプラグインの場合' do
      it 'Jquery UIのuiプラグインへのパスが返却されること' do
        helper.skip_jquery_path('ui.core').should == '/javascripts/skip/jquery/ui/ui.core.js'
      end
    end
    describe 'Jquery UIのeffectsプラグインの場合' do
      it 'Jquery UIのeffectsプラグインへのパスが返却されること' do
        helper.skip_jquery_path('effects.core').should == '/javascripts/skip/jquery/ui/effects.core.js'
      end
    end
    describe '通常のjqueryプラグインの場合' do
      it 'jquery pluginへのパスが返却されること' do
        helper.skip_jquery_path('foo').should == '/javascripts/skip/jquery/plugins/foo.js'
      end
    end
  end
end
