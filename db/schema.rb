# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of ActiveRecord to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 1) do

  create_table "accounts", :force => true do |t|
    t.string   "code",       :default => "", :null => false
    t.string   "name",       :default => "", :null => false
    t.string   "email"
    t.string   "section",    :default => "", :null => false
    t.string   "password",   :default => "", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "accounts", ["code"], :name => "index_accounts_on_code", :unique => true

  create_table "antenna_items", :force => true do |t|
    t.integer "antenna_id",                 :null => false
    t.string  "value_type", :default => "", :null => false
    t.string  "value",      :default => "", :null => false
  end

  create_table "antennas", :force => true do |t|
    t.integer "user_id",                  :null => false
    t.string  "name",     :default => "", :null => false
    t.integer "position"
  end

  create_table "applied_emails", :force => true do |t|
    t.datetime "created_on"
    t.integer  "user_id",                                     :null => false
    t.string   "onetime_code", :limit => 60,  :default => "", :null => false
    t.string   "email",        :limit => 100, :default => "", :null => false
  end

  create_table "board_entries", :force => true do |t|
    t.datetime "created_on"
    t.datetime "updated_on"
    t.string   "title",                      :limit => 100, :default => "",     :null => false
    t.text     "contents",                                  :default => "",     :null => false
    t.datetime "date",                                                          :null => false
    t.integer  "user_id",                                                       :null => false
    t.string   "category"
    t.string   "entry_type"
    t.boolean  "ignore_times",                              :default => false,  :null => false
    t.datetime "last_updated",                                                  :null => false
    t.integer  "user_entry_no",                                                 :null => false
    t.integer  "board_entry_comments_count",                :default => 0,      :null => false
    t.string   "symbol",                     :limit => 100, :default => "",     :null => false
    t.string   "editor_mode",                               :default => "hiki", :null => false
    t.integer  "lock_version",                              :default => 0,      :null => false
    t.string   "publication_type"
    t.string   "publication_symbols_value"
    t.integer  "entry_trackbacks_count",                    :default => 0,      :null => false
  end

  add_index "board_entries", ["symbol"], :name => "index_board_entries_on_symbol"
  add_index "board_entries", ["date"], :name => "index_board_entries_on_date"
  add_index "board_entries", ["user_id"], :name => "index_board_entries_on_user_id"

  create_table "board_entry_comments", :force => true do |t|
    t.datetime "created_on"
    t.datetime "updated_on"
    t.integer  "board_entry_id",                 :null => false
    t.text     "contents",       :default => "", :null => false
    t.integer  "user_id",                        :null => false
    t.integer  "parent_id"
  end

  add_index "board_entry_comments", ["board_entry_id"], :name => "index_board_entry_comments_on_board_entry_id"
  add_index "board_entry_comments", ["parent_id"], :name => "index_board_entry_comments_on_parent_id"

  create_table "board_entry_points", :force => true do |t|
    t.datetime "created_on"
    t.datetime "updated_on"
    t.integer  "board_entry_id",                    :null => false
    t.integer  "point",              :default => 0, :null => false
    t.integer  "access_count",       :default => 0, :null => false
    t.integer  "today_access_count", :default => 0, :null => false
  end

  add_index "board_entry_points", ["board_entry_id"], :name => "index_board_entry_points_on_board_entry_id"

  create_table "bookmark_comment_tags", :force => true do |t|
    t.datetime "created_on"
    t.integer  "bookmark_comment_id", :null => false
    t.integer  "tag_id",              :null => false
  end

  create_table "bookmark_comments", :force => true do |t|
    t.datetime "created_on"
    t.datetime "updated_on"
    t.integer  "bookmark_id",                    :null => false
    t.integer  "user_id",                        :null => false
    t.text     "comment",     :default => "",    :null => false
    t.boolean  "public",                         :null => false
    t.string   "tags"
    t.boolean  "stared",      :default => false, :null => false
  end

  create_table "bookmarks", :force => true do |t|
    t.datetime "created_on"
    t.datetime "updated_on"
    t.string   "url",                     :default => "", :null => false
    t.string   "title",                   :default => "", :null => false
    t.integer  "bookmark_comments_count", :default => 0,  :null => false
  end

  create_table "chains", :force => true do |t|
    t.datetime "created_on"
    t.datetime "updated_on"
    t.integer  "from_user_id",                                 :null => false
    t.integer  "to_user_id",                                   :null => false
    t.string   "comment",      :limit => 1000, :default => "", :null => false
  end

  create_table "entry_accesses", :force => true do |t|
    t.integer  "board_entry_id", :null => false
    t.integer  "visitor_id",     :null => false
    t.datetime "updated_on",     :null => false
  end

  add_index "entry_accesses", ["board_entry_id"], :name => "index_entry_accesses_on_board_entry_id"

  create_table "entry_editors", :force => true do |t|
    t.integer "board_entry_id",                 :null => false
    t.string  "symbol",         :default => "", :null => false
  end

  create_table "entry_publications", :force => true do |t|
    t.integer "board_entry_id",                 :null => false
    t.string  "symbol",         :default => "", :null => false
  end

  add_index "entry_publications", ["board_entry_id"], :name => "index_entry_publications_on_board_entry_id"
  add_index "entry_publications", ["symbol"], :name => "index_entry_publications_on_symbol"

  create_table "entry_tags", :force => true do |t|
    t.datetime "created_on"
    t.integer  "board_entry_id", :null => false
    t.integer  "tag_id",         :null => false
  end

  add_index "entry_tags", ["tag_id"], :name => "index_entry_tags_on_tag_id"
  add_index "entry_tags", ["board_entry_id"], :name => "index_entry_tags_on_board_entry_id"

  create_table "entry_trackbacks", :force => true do |t|
    t.datetime "updated_on"
    t.integer  "board_entry_id", :null => false
    t.integer  "tb_entry_id",    :null => false
  end

  create_table "group_participations", :force => true do |t|
    t.datetime "created_on"
    t.datetime "updated_on"
    t.integer  "user_id",                       :null => false
    t.integer  "group_id",                      :null => false
    t.boolean  "waiting",    :default => false, :null => false
    t.boolean  "owned",      :default => false, :null => false
    t.boolean  "favorite",   :default => true,  :null => false
  end

  create_table "groups", :force => true do |t|
    t.datetime "created_on"
    t.datetime "updated_on"
    t.string   "name",        :limit => 100, :default => "",    :null => false
    t.text     "description"
    t.boolean  "protected",                  :default => false, :null => false
    t.string   "gid",         :limit => 100, :default => "",    :null => false
    t.string   "category",    :limit => 50,  :default => "",    :null => false
  end

  add_index "groups", ["gid"], :name => "index_groups_on_gid", :unique => true

  create_table "mails", :force => true do |t|
    t.datetime "created_on"
    t.datetime "updated_on"
    t.string   "from_user_id",      :limit => 100,  :default => "",    :null => false
    t.integer  "user_entry_no",                                        :null => false
    t.string   "to_address",        :limit => 1000, :default => "",    :null => false
    t.boolean  "send_flag",                         :default => false, :null => false
    t.string   "title",             :limit => 100,  :default => "",    :null => false
    t.string   "to_address_name",   :limit => 200,  :default => "",    :null => false
    t.string   "to_address_symbol", :limit => 128,  :default => "",    :null => false
  end

  create_table "messages", :force => true do |t|
    t.datetime "created_on"
    t.integer  "user_id",                         :null => false
    t.string   "link_url",     :default => "",    :null => false
    t.string   "message",      :default => "",    :null => false
    t.string   "message_type", :default => "",    :null => false
    t.boolean  "send_flag",    :default => false, :null => false
  end

  create_table "pictures", :force => true do |t|
    t.datetime "created_on"
    t.datetime "updated_on"
    t.string   "name",         :limit => 200, :default => "", :null => false
    t.string   "content_type", :limit => 100, :default => "", :null => false
    t.binary   "data"
    t.integer  "user_id",                                     :null => false
  end

  add_index "pictures", ["user_id"], :name => "index_pictures_on_user_id"

  create_table "popular_bookmarks", :force => true do |t|
    t.datetime "created_on"
    t.date     "date",        :null => false
    t.integer  "bookmark_id", :null => false
    t.integer  "count",       :null => false
  end

  add_index "popular_bookmarks", ["bookmark_id"], :name => "index_popular_bookmarks_on_bookmark_id"
  add_index "popular_bookmarks", ["date"], :name => "index_popular_bookmarks_on_date"

  create_table "sessions", :force => true do |t|
    t.string   "sid",          :limit => 100, :default => "", :null => false
    t.string   "user_code",    :limit => 20,  :default => "", :null => false
    t.string   "user_name",    :limit => 200, :default => "", :null => false
    t.string   "user_email",   :limit => 100, :default => "", :null => false
    t.datetime "expire_date",                                 :null => false
    t.string   "user_section", :limit => 200, :default => "", :null => false
  end

  create_table "share_file_accesses", :force => true do |t|
    t.integer  "share_file_id", :null => false
    t.integer  "user_id",       :null => false
    t.datetime "created_at",    :null => false
  end

  add_index "share_file_accesses", ["share_file_id"], :name => "index_share_file_accesses_on_share_file_id"

  create_table "share_file_publications", :force => true do |t|
    t.integer "share_file_id",                                :null => false
    t.string  "symbol",        :limit => 100, :default => "", :null => false
  end

  create_table "share_file_tags", :force => true do |t|
    t.datetime "created_on"
    t.integer  "share_file_id", :null => false
    t.integer  "tag_id",        :null => false
  end

  create_table "share_files", :force => true do |t|
    t.string   "file_name",                 :limit => 500, :default => "", :null => false
    t.string   "owner_symbol",              :limit => 100, :default => "", :null => false
    t.text     "description"
    t.datetime "date"
    t.integer  "user_id",                                                  :null => false
    t.string   "category"
    t.integer  "total_count",                              :default => 0,  :null => false
    t.string   "content_type",                             :default => "", :null => false
    t.string   "publication_type",                         :default => "", :null => false
    t.string   "publication_symbols_value",                :default => ""
  end

  create_table "site_counts", :force => true do |t|
    t.datetime "created_on"
    t.integer  "total_user_count",     :null => false
    t.integer  "today_user_count",     :null => false
    t.integer  "total_blog_count",     :null => false
    t.integer  "today_blog_count",     :null => false
    t.integer  "writer_at_month",      :null => false
    t.integer  "user_access_at_month", :null => false
    t.integer  "write_users_all",      :null => false
    t.integer  "write_users_with_pvt", :null => false
    t.integer  "write_users_with_bbs", :null => false
    t.integer  "comment_users",        :null => false
    t.integer  "portrait_users",       :null => false
    t.integer  "profile_users",        :null => false
    t.integer  "custom_users",         :null => false
    t.integer  "active_users",         :null => false
  end

  create_table "tags", :force => true do |t|
    t.datetime "created_on"
    t.datetime "updated_on"
    t.string   "name",       :limit => 100, :default => "", :null => false
    t.string   "tag_type",   :limit => 16
  end

  add_index "tags", ["name"], :name => "index_tags_on_name"

  create_table "tracks", :force => true do |t|
    t.datetime "created_on"
    t.datetime "updated_on"
    t.integer  "user_id",    :null => false
    t.integer  "visitor_id", :null => false
  end

  add_index "tracks", ["user_id"], :name => "index_tracks_on_user_id"

  create_table "user_accesses", :force => true do |t|
    t.datetime "created_on"
    t.datetime "updated_on"
    t.integer  "user_id",                     :null => false
    t.datetime "last_access",                 :null => false
    t.integer  "access_count", :default => 0, :null => false
  end

  create_table "user_customs", :force => true do |t|
    t.integer "user_id",                       :null => false
    t.string  "theme",   :default => "silver", :null => false
  end

  create_table "user_message_unsubscribes", :force => true do |t|
    t.integer "user_id",                      :null => false
    t.string  "message_type", :default => "", :null => false
  end

  create_table "user_profiles", :force => true do |t|
    t.integer "user_id",                     :null => false
    t.integer "gender_type",  :limit => 2
    t.integer "join_year",    :limit => 4
    t.integer "birth_month",  :limit => 1
    t.integer "birth_day",    :limit => 1
    t.integer "blood_type",   :limit => 1
    t.integer "hometown",     :limit => 2
    t.string  "alma_mater",   :limit => 100
    t.integer "address_1",    :limit => 2
    t.string  "address_2",    :limit => 100
    t.text    "hobby"
    t.text    "introduction"
    t.boolean "disclosure",                  :null => false
  end

  create_table "user_readings", :force => true do |t|
    t.integer  "user_id",                           :null => false
    t.integer  "board_entry_id",                    :null => false
    t.boolean  "read",           :default => false, :null => false
    t.datetime "checked_on"
  end

  add_index "user_readings", ["user_id"], :name => "index_user_readings_on_user_id"
  add_index "user_readings", ["board_entry_id"], :name => "index_user_readings_on_board_entry_id"

  create_table "user_uids", :force => true do |t|
    t.integer "user_id",                                       :null => false
    t.string  "uid",      :limit => 100
    t.string  "uid_type",                :default => "MASTER", :null => false
  end

  add_index "user_uids", ["uid"], :name => "index_user_uids_on_uid", :unique => true
  add_index "user_uids", ["user_id"], :name => "index_user_uids_on_user_id"

  create_table "users", :force => true do |t|
    t.datetime "created_on"
    t.datetime "updated_on"
    t.string   "email",        :limit => 100, :default => "",    :null => false
    t.string   "name",         :limit => 200, :default => "",    :null => false
    t.string   "section",      :limit => 100, :default => "",    :null => false
    t.string   "extension",    :limit => 100
    t.text     "introduction"
    t.boolean  "retired",                     :default => false, :null => false
  end

end
