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

    $j.extend({
      getUrlVars: function(url_or_href){
        var vars = [], hash;
        var hashes = url_or_href.slice(url_or_href.indexOf('?') + 1).split('&');
        for(var i = 0; i < hashes.length; i++)
        {
          hash = hashes[i].split('=');
          vars.push(hash[0]);
          vars[hash[0]] = hash[1];
        }
        return vars;
      },
      getUrlVar: function(url_or_href, name){
        return $j.getUrlVars(url_or_href)[name];
      }
    });
});

