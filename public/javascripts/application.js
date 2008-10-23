$j(function(){
    // キャッシュによってajaxアクションが動作しないケースがあるのでキャッシュしない設定にしておく
    $j.ajaxSetup({ ifModified: false, cache: false });
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
     * 感応型のヘルプバー表示をさせる
     * sensitive_selecter : 感知するselecter / appeared_selecter : 表示させるID
     */
    toggleMouseOver = function(sensitive_selecter, appeared_selecter){
        $j(sensitive_selecter)
        .hover(function() {
            $j(appeared_selecter).show();
        },function() {
            $j(appeared_selecter).hide();
        });
    }

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

    /*
     * アンテナのローディング
     */
    loadAntenna = function(){
        $j.ajax({
            url: relative_url_root + '/mypage/ado_antennas/',
            complete: function(request) {
                $j('#antennas').html(request.responseText);
                fnLoadPngs();
            }
        });
    }

    /*
     * 共有ファイルのダウンロード時にダウンロード数を増やす
     */
    $j('.share_file_download_link')
    .click(function(){
        var shareFileId = this.id.split('_')[4];
        $j('#download_count_'+shareFileId).html(eval($j('#download_count_'+shareFileId).html()) + 1);
    });


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

});

///----------------------------------------------------------------------------------------
///  これ以降は、prototype.js 利用関数
///----------------------------------------------------------------------------------------
/*
 * 現在時刻をセレクトボックスにセットする
 */
function setCurrentDatetime(obj_name, property_name) {
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

/* -------------------------------------------------- */

function fitImageSize(id, max_width, max_height) {
    img = new Image();
    img.src = $j('#' + id).attr('src');

    if (max_height > max_width) {
        if (img.width > max_width) {
            value = img.height / (img.width/max_width);
            if (value < 1)  { value = 1; }
            $j('#' + id).attr({ height: value, width: max_width });
        } else if (img.height > max_height) {
            value = img.width / (img.height/max_height);
            if (value < 1) { value = 1; }
            $j('#' + id).attr({ height: max_height, width: value });
        }
    } else {
        if (img.height >= max_height) {
            value = img.width / (img.height/max_height);
            if (value < 1) { value = 1; }
            $j('#' + id).attr({ height: max_height, width: value });
        } else if (img.width > max_width) {
            value = img.height / (img.width/max_width);
            if (value < 1)  { value = 1; }
            $j('#' + id).attr({ height: value, width: max_width });
        }
    }
}

/*
 * ログイン画面のクッキー保存と読み込み（2週間）
 */
function saveLoginData(){
    exp_days = 14;
    saveCookie('login_save', $j('#login_save').attr('checked').toString(), exp_days);
    if($j('#ssl_enable_radio')[0] != undefined){
        saveCookie('ssl_enable', $j('#ssl_enable_radio').attr('checked').toString(), exp_days);
    }
    return true;
}
