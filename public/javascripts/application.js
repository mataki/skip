$j(function(){
    // キャッシュによってajaxアクションが動作しないケースがあるのでキャッシュしない設定にしておく
    $j.ajaxSetup({
        ifModified: false,
        cache: false,
        error: function(event) {
            alert("通信に失敗しました");
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
    }

    $j(document).appendClickForToggleTag();

    $j.fn.shareFileUploader = function(config) {
        var root = $j(this);
        var message = config["message"];

        var insertToRichEditor = function(elem){
            FCKeditorAPI.GetInstance('contents_richtext').InsertElement(elem.get(0));
        };

        var insertToHikiEditor = function(text){
            $j("#contents_hiki").val($j("#contents_hiki").val() + text);
        };

        var insertLink = function(data){
            var filename = data['file_name'];
            var src = data['src'];
            return $j("<span>").text(message["insert_link_label"]).addClass("insert_link link pointer").click(function(){
                if($j('#editor_mode_richtext:checked').length > 0){
                    insertToRichEditor($j("<a>").text(filename).attr("href", src));
                } else if($j('#editor_mode_hiki:checked').length > 0) {
                    insertToHikiEditor('\n[file:' + filename + ']');
                }
            });
        };

        var insertImageLink = function(data){
            var filename = data['file_name'];
            var src = data['src'];
            return $j("<span>").text(message["insert_image_link_label"]).addClass("insert_link link pointer").click(function(){
                if($j('#editor_mode_richtext:checked').length > 0){
                    var img = $j("<img />").attr("src", src).attr("alt", filename).addClass('pointer');
                    insertToRichEditor(img);
                } else if($j('#editor_mode_hiki:checked').length > 0) {
                    insertToHikiEditor('\n{{' + filename + ',240,}}');
                }
            });
        };

        var insertImage = function(data){
            var filename = data['file_name'];
            var src = data['src'];
            if(src){
                var img = $j("<img />").attr("src", src).attr("alt", filename).addClass('pointer');
                return img.clone().attr("width", 200).click(function(){
                    if($j('#editor_mode_richtext:checked').length > 0){
                        insertToRichEditor(img);
                    } else if($j('#editor_mode_hiki:checked').length > 0) {
                        insertToHikiEditor('\n{{' + filename + ',240,}}');
                    }
                });
            }else{
                return $j("<span>").text(filename.substr(0,16));
            }
        };

        var shareFileToTableHeader = function() {
            var tr = $j('<tr>');
            tr.append($j('<th>').text(message['share_files']['thumbnail']));
            return tr;
        };

        var shareFileToTableRow = function(data){
            var tr = $j("<tr>");
            tr.append($j("<td class='thumbnail'>").append(insertImage(data)));
            var insertTd = $j("<td class='insert'>");
            insertTd.append(insertLink(data));
            if(data['file_type'] == 'image')
                insertTd.append(insertImageLink(data));
            tr.append(insertTd);
            return tr;
        };

        var loadShareFiles = function(palette, url, label) {
            if(!url) return;
            $j.getJSON(url, function(data, stat){
                if(data.length == 0) return;
                var thead = $j('<thead>');
                thead.append(shareFileToTableHeader());
                var tbody = $j("<tbody>");
                $j.each(data, function(_num_, share_file){
                    tbody.append(shareFileToTableRow(share_file));
                });
                palette.append(
                    $j("<table>")
                    .append($j("<caption>").text(label))
                    .append(thead)
                    .append(tbody)
                );
            });
        };

        var hideUploader = function(){
            root.hide();
            $j('span.share_file_uploader').one('click', onLoad);
        };

        var uploaderButton = function(conf) {
            conf["callback"] = reloadUploader

            return $j("<div class='share_file upload' />").append(
                $j("<span class='operation link pointer'>")
                .text(message["upload_share_file"])
                .one("click", function(){ $j(this).hide().parent().iframeUploader(conf) })
            )
        };

        var reloadUploader = function(){
            root.find("table").remove();
            loadShareFiles(root.find("div.share_files"), config["share_files_url"], message["share_files"]["title"]);
        };

        var onLoad = function() {
            root.empty().attr("class", "enabled").draggable({handle: 'div.title_bar'}).append(
                $j('<div class="title_bar move">').append(
                    $j("<h3>").text(message["title"])
                ).append(
                    $j("<div class='operation'>").append(
                        $j("<span class='reload link pointer'>").text(message["reload"]).click(reloadUploader)
                    ).append(
                        $j("<span class='close link pointer'>").text(message["close"]).click(hideUploader)
                    )
                )
            ).append(
                $j("<div style='clear: both;'/>")
            ).append(
                uploaderButton(config["uploader"])
            ).append($j("<div class='share_files' />")).show();

            loadShareFiles(root.find("div.share_files"), config["share_files_url"], message["share_files"]["title"]);
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
    }
    hideCategoryBox = function() {
        $j('#category_box:visible').slideUp();
    }

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
            error: function(event){
                alert("通信に失敗しました");
            }
        });
    }

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
    }

    fitImageSize = function(jObj, max_width, max_height) {
        var img = new Image();
        img.src = jObj.attr('src');

        if (max_height > max_width) {
            if (img.width > max_width) {
                value = img.height / (img.width/max_width);
                if (value < 1)  { value = 1; }
                jObj.attr({ height: value, width: max_width });
            } else if (img.height > max_height) {
                value = img.width / (img.height/max_height);
                if (value < 1) { value = 1; }
                jObj.attr({ height: max_height, width: value });
            }
        } else {
            if (img.height >= max_height) {
                value = img.width / (img.height/max_height);
                if (value < 1) { value = 1; }
                jObj.attr({ height: max_height, width: value });
            } else if (img.width > max_width) {
                value = img.height / (img.width/max_width);
                if (value < 1)  { value = 1; }
                jObj.attr({ height: value, width: max_width });
            }
        }
    }

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
    }
});

