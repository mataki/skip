$j(function(){
    // キャッシュによってajaxアクションが動作しないケースがあるのでキャッシュしない設定にしておく
    $j.ajaxSetup({
        ifModified: false,
        cache: false,
        error: function(request) {
            if(request.responseText == ''){
                alert("通信に失敗しました。");
            } else {
                alert(request.responseText);
            }
        }
    });

    $j('span.ss_help').cluetip({
        splitTitle: '|',
        dropShadow: false,
        cluetipClass: 'jtip',
        arrows: true
    });

    /*
     * jQueryオブジェクトをHighlightする
     */
    $j.fn.highlight = function(color) {
        var afterColor = '#ffffff';
        if( color != undefined ) {
            afterColor = color;
        }
        return this
        .css({ backgroundColor:"#ffffbb" })
        .animate({ backgroundColor:afterColor }, 300);
    };

    /*
     * ロールオーバーで虫眼鏡画像を表示させる
     */
    $j.fn.zoomable = function() {
        return this.hover(
            function() {
                //alert('zoom!!')
                var img = $j(this).find('img')[0];
                var span = $j(document.createElement("span"))
                .css( { position: 'absolute',
                        top: img.offsetTop + "px",
                        left: img.offsetLeft + "px",
                        width: img.offsetWidth + "px",
                        height: img.offsetHeight + "px" } )
                .addClass('image_over');
                $j(this).prepend(span);
            },
            function() {
                $j(this).find('.image_over').remove();
            }
        );
    };

    /*
     * タグの表示非表示
     */
    $j.fn.appendClickForToggleTag = function() {
        this
        .find('.tag_open')
        .click(function(){
            $j(this).hide().next().show().parent().highlight();
            return false;
        });

        this
        .find('.tag_close')
        .click(function(){
            $j(this).parent().hide().prev().show().parent().highlight();
            return false;
        });
        return this;
    };
    $j(document).appendClickForToggleTag();


    /*
     * セレクトボックスのリンクナビゲーション
     */
    $j('select.select_navi').dropdownNavigation();


    /*
     * プロフィール画像のサイズ調整
     */
    $j('img.fit_image').fitimage({ placeholder: relative_url_root + '/images/skip/jquery/fitimage/spacer.gif' });

    /*
     * カレンダーのロード
     */
    var loadCalendar = function(year, month, url){
        $j.ajax({
            url: url,
            data: { year : year , month : month },
            success: function(html) {
               $j('#calendar').html(html);
               $j('#calendar_body').highlight();
            },
            complete: function(request) {
                setupLoadCalendar(url);
            }
        });
    };

    var unbindLoadCalendar = function() {
        $j('#prev_month_link').unbind('click');
        $j('#next_month_link').unbind('click');
    };

    var bindLoadCalendar = function(url) {
        // カレンダーの前月、次月リンククリック時のajaxアクション
        $j('#prev_month_link')
        .click(function() {
            loadCalendar($j(this).attr('year'), $j(this).attr('month'), url);
            return false;
        });

        $j('#next_month_link')
        .click(function() {
            loadCalendar($j(this).attr('year'), $j(this).attr('month'), url);
            return false;
        });
    };

    /*
     * カレンダーのロードをセットアップ
     */
    setupLoadCalendar = function(url) {
        unbindLoadCalendar();
        bindLoadCalendar(url);
    };

    /*
     * 記事を未読/既読状態にする
     */
    changeReadState = function(entryId, isRead, authenticityToken){
        var changeReadStateURL = relative_url_root + "/mypage/change_read_state";
        $j.ajax({
            type: 'POST',
            url: changeReadStateURL,
            data: { board_entry_id: entryId,
                    read: isRead,
                    authenticity_token: authenticityToken },
            success: function(msg) {
                $j("#flash_message").trigger("notice", msg);
            }
        });
    };

    /*
     * 記事作成/編集でのファイルアップローダー
     */
    $j.fn.shareFileUploader = function(config) {
        var root = $j(this);
        var message = config["message"];

        var insertToRichEditor = function(elem){
            CKEDITOR.instances.contents_richtext.insertHtml(elem.wrap('<span></span>').parent().html());
        };

        var insertToHikiEditor = function(text){
            $j("#contents_hiki").val($j("#contents_hiki").val() + text);
        };

        var insertLink = function(data){
            var filename = data['file_name'];
            var src = data['src'];
            return $j("<span></span>").text(message["insert_link_label"]).addClass("insert_link link pointer").click(function(){
                if($j('#editor_mode_richtext:checked').length > 0){
                    insertToRichEditor($j("<a></a>").text(filename).attr("href", src));
                } else if($j('#editor_mode_hiki:checked').length > 0) {
                    insertToHikiEditor('\n[file:' + filename + ']');
                }
            });
        };

        var insertImageLink = function(data){
            var filename = data['file_name'];
            var src = data['src'];
            return $j("<span></span>").text(message["insert_image_link_label"]).addClass("insert_link link pointer").click(function(){
                if($j('#editor_mode_richtext:checked').length > 0){
                    var img = $j("<img></img>").attr("src", src).attr("alt", filename).addClass('pointer');
                    insertToRichEditor(img);
                } else if($j('#editor_mode_hiki:checked').length > 0) {
                    insertToHikiEditor('\n{{' + filename + ',240,}}');
                }
            });
        };

        var insertThumbnail = function(data){
            var filename = data['file_name'];
            var extension = filename.toLowerCase().split('.')[1];
            if($j.inArray(extension, config['image_extensions']) >= 0) {
                var src = data['src'];
                if(src){
                    var img = $j("<img></img>").attr("src", src).attr("alt", filename).addClass('pointer');
                    return img.clone().attr("width", 200).click(function(){
                        if($j('#editor_mode_richtext:checked').length > 0){
                            insertToRichEditor(img);
                        } else if($j('#editor_mode_hiki:checked').length > 0) {
                            insertToHikiEditor('\n{{' + filename + ',240,}}');
                        }
                    });
                }else{
                    return $j("<span></span>").text(filename.substr(0,32));
                }
            } else {
                return $j("<span></span>").text(filename.substr(0,32));
            }
        };

        var shareFileToTableHeader = function() {
            var tr = $j('<tr></tr>');
            tr.append($j('<th></th>').text(message['share_files']['thumbnail']));
            tr.append($j('<th></th>'));
            return tr;
        };

        var shareFileToTableRow = function(data){
            var tr = $j("<tr></tr>");
            tr.append($j("<td class='thumbnail'></td>").append(insertThumbnail(data)));
            var insertTd = $j("<td class='insert'></td>");
            insertTd.append(insertLink(data));
            if(data['file_type'] == 'image')
                insertTd.append(insertImageLink(data));
            tr.append(insertTd);
            return tr;
        };

        var paginate = function(pages, labels){
            var paginate_actions = $j('<div class="paginate"></div>');
            paginate_actions.append($j('<span class="info"></span>').text(pages['current'] + '/' + pages['last'] + 'page'));
            if(pages['previous'] != null){
                paginate_actions.append(
                    $j('<span class="first_link link pointer"></span>').text(labels['first']).click(function() {
                        loadShareFiles(root.find("div.share_files"), config["share_files_url"], {page: pages['first']}, message["share_files"]);
                    })
                );
                paginate_actions.append(
                    $j('<span class="previous_link link pointer"></span>').text(labels['previous']).click(function() {
                        loadShareFiles(root.find("div.share_files"), config["share_files_url"], {page: pages['previous']}, message["share_files"]);
                    })
                );
            }
            if(pages['next'] != null){
                paginate_actions.append(
                    $j('<span class="next_link link pointer"></span>').text(labels['next']).click(function() {
                        loadShareFiles(root.find("div.share_files"), config["share_files_url"], {page: pages['next']}, message["share_files"]);
                    })
                );
                paginate_actions.append(
                    $j('<span class="last_link link pointer"></span>').text(labels['last']).click(function() {
                        loadShareFiles(root.find("div.share_files"), config["share_files_url"], {page: pages['last']}, message["share_files"]);
                    })
                );
            }
            return paginate_actions;
        };

        var loadShareFiles = function(palette, url, requestData, labels) {
            palette.empty();
            if(!url) return;
            $j.getJSON(url, requestData, function(data, stat){
                var share_files = data['share_files'];
                if(share_files.length == 0) return;
                var thead = $j('<thead></thead>');
                thead.append(shareFileToTableHeader());
                var tbody = $j("<tbody></tbody>");
                $j.each(share_files, function(_num_, share_file){
                    tbody.append(shareFileToTableRow(share_file));
                });
                palette.append(
                    paginate(data['pages'], labels)
                ).append(
                    $j("<table></table>")
                    .append($j("<caption></caption>").text(labels['title']))
                    .append(thead)
                    .append(tbody)
                ).append(
                    paginate(data['pages'], labels)
                );
            });
        };

        var hideUploader = function(){
            root.hide();
            $j('span.share_file_uploader').one('click', onLoad);
        };

        var uploaderButton = function(conf) {
            conf["callback"] = onComplete;

            return $j("<div class='share_file upload'></div>").append(
                $j("<span class='operation link pointer'></span>")
                .text(message["upload_share_file"])
                .one("click", function(){ $j(this).hide().parent().iframeUploader(conf); })
            );
        };

        var reloadUploader = function(){
            loadShareFiles(root.find("div.share_files"), config["share_files_url"], {}, message["share_files"]);
        };

        var refreshMessage = function(response){
            if(response != '') {
                $j('div#share_file_uploader div.messages').html(response).show();
            } else {
                $j('div#share_file_uploader div.messages').hide();
            }
        };

        var onComplete = function(targetIFrame){
            var doc = targetIFrame.get(0).contentDocument ? targetIFrame.get(0).contentDocument : targetIFrame.get(0).contentWindow.document;
            var response = doc.body.innerHTML;

            refreshMessage(response);
            reloadUploader();
        };

        var onLoad = function() {
            root.empty().attr("class", "enabled").draggable({handle: 'div.title_bar'}).append(
                $j('<div class="title_bar move"></div>').append(
                    $j("<h3></h3>").text(message["title"])
                ).append(
                    $j("<div class='operation'></div>").append(
                        $j("<span class='reload link pointer'></span>").append("<span class='ss_sprite ss_arrow_rotate_clockwise'>&nbsp;</span>").append(message["reload"]).click(reloadUploader)
                    ).append(
                        $j("<span class='close link pointer'></span>").append("<span class='ss_sprite ss_cross close'>&nbsp;</span>").append(message["close"]).click(hideUploader)
                    )
                )
            ).append(
                $j("<div style='clear: both;'></div>")
            ).append(
                $j('<div class="messages invisible"></div>')
            ).append(
                uploaderButton(config["uploader"])
            ).append($j("<div class='share_files'></did>")).show();

            loadShareFiles(root.find("div.share_files"), config["share_files_url"], {}, message["share_files"]);
        };
        $j('span.share_file_uploader').one('click', onLoad);
    };

    /*
     * 共有ファイルのダウンロード時にダウンロード数を増やす
     */
    $j('.share_file_download_link')
    .click(function(){
        var shareFileId = this.id.split('_')[4];
        $j('#download_count_'+shareFileId).html(eval($j('#download_count_'+shareFileId).html()) + 1);
    });

    /*
     * 共有ファイルのダウンロードリンク押下時はauthenticity_tokenを付加した
     * formのsubmit処理にする
     */
    setupShareFileDownloadLink = function(){
        $j('.share_file_download_link')
        .click(function() {
            $j('#share_file_download_form_' + this.id.split('_')[4]).submit();
            return false;
        });
    };

    /*
     * ブログなどの編集画面でタグの候補を表示・非表示
     */
    showCategoryBox = function() {
        $j('#category_box:hidden').slideDown();
    };
    hideCategoryBox = function() {
        $j('#category_box:visible').slideUp();
    };

    /*
     * ブックマークのタイトルを取得する
     */
    reloadTitle = function(url, target_id) {
        $j('#refresher').hide();
        $j('#indicator').show();
        var ado_get_title_url = relative_url_root + "/bookmark/ado_get_title";
        $j.ajax({
            type: "POST",
            url: ado_get_title_url,
            data: { url:url, authenticity_token: $j('#authenticity_token').val() },
            success: function(request){
                if(request == ""){
                    alert("タイトルの取得ができませんでした");
                    return;
                }else{
                    $j('#'+target_id).val(request);
                }
            },
            complete: function(request){
                $j('#indicator').hide();
                $j('#refresher').show();
            },
            error: function(request){
                alert(request.responseText);
            }
        });
    };

    /*
     * jTaggingで利用するタグリストを生成して返す。引数のtagsはタグの配列
     */
    createTagsLink = function(tags) {
        var text = '';
        $j.each(tags, function() {
            text += '<a href="#" onclick="return false;" style="margin-right: 3px;">' + this.toString() + '</a>';
        });
        return text;
    };

    /*
     * 現在時刻をセレクトボックスにセットする
     */
    setCurrentDatetime = function(obj_name, property_name) {
        var currentDatetime = new Date();

        var year_obj = document.getElementsByName(obj_name + '[' + property_name + '(1i)]');
        var month_obj = document.getElementsByName(obj_name + '[' + property_name + '(2i)]');
        var date_obj = document.getElementsByName(obj_name + '[' + property_name + '(3i)]');
        var hour_obj = document.getElementsByName(obj_name + '[' + property_name + '(4i)]');
        var minute_obj = document.getElementsByName(obj_name + '[' + property_name + '(5i)]');

        year_obj[0].value = currentDatetime.getFullYear();
        month_obj[0].value = currentDatetime.getMonth() + 1;
        date_obj[0].value = currentDatetime.getDate();

        var currentHour = currentDatetime.getHours();
        if (currentHour < 10) currentHour = "0" + currentHour;
        hour_obj[0].value = currentHour;

        var currentMinute = currentDatetime.getMinutes();
        if (currentMinute < 10) currentMinute = "0" + currentMinute;
        minute_obj[0].value = currentMinute;
    };

    /*
     * ログイン画面のクッキー保存と読み込み（2週間）
     */
    saveLoginData = function(){
        exp_days = 14;
        saveCookie('login_save', $j('#login_save').attr('checked').toString(), exp_days);
        if($j('#ssl_enable_radio')[0] != undefined){
            saveCookie('ssl_enable', $j('#ssl_enable_radio').attr('checked').toString(), exp_days);
        }
        return true;
    };
});

