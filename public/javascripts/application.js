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
        $('refresher').hide();
        $('indicator').show();
        var ado_get_title_url = relative_url_root + "/bookmark/ado_get_title";
        $j.ajax({
            type: "POST",
            url: ado_get_title_url,
            data: { url:url },
            success: function(request){
                if(request == ""){
                    alert("タイトルの取得ができませんでした");
                    return;
                }else{
                    $j('#'+target_id).val(request);
                }
            },
            complete: function(request){
                $('indicator').hide();
                $('refresher').show();
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
/*
 * 管理画面でアンテナの追加をする
 */
function addAntenna() {
    var antenna_name = $('add_antenna_name').value;
    if (antenna_name == "") {
        alert("アンテナ名は必須です");
        return false;
    }
    if (antenna_name.length > 10) {
        alert("アンテナ名は１０文字までです");
        return false;
    }

    var options = {
        evalScripts: true,
        parameters: "name="+antenna_name,
        onFailure: function(originalRequest){
            alert("通信に失敗しました");
        },
        onComplete: function(originalRequest) {
            $('add_antenna_name').value = "";
            new Effect.Highlight('antennas_list_container');
        }
    };
    var url = relative_url_root + "/mypage/add_antenna";
    url += ("?" + (new Date()).getTime());
    new Ajax.Updater('antennas_list_container', url, options);
}
function deleteAntenna(antenna_id) {
    if (!confirm('本当に削除しますか？')) {
        return;
    }

    var options = {
        evalScripts: true,
        parameters: "antenna_id="+antenna_id,
        onFailure: function(originalRequest){
            alert("通信に失敗しました");
        },
        onComplete: function(originalRequest) {
            new Effect.Highlight('antennas_list_container');
        }
    };
    var url = relative_url_root + "/mypage/delete_antenna";
    url += ("?" + (new Date()).getTime());
    new Ajax.Updater('antennas_list_container', url, options);
}
function deleteAntennaItem(antenna_id, antenna_item_id) {
    if (!confirm('本当に削除しますか？')) {
        return;
    }

    var options = {
        evalScripts: true,
        parameters: "antenna_id="+antenna_id + "&antenna_item_id="+antenna_item_id,
        onFailure: function(originalRequest){
            alert("通信に失敗しました");
        },
        onComplete: function(originalRequest) {
            new Effect.Highlight('antennas_list_container');
        }
    };
    var url = relative_url_root + "/mypage/delete_antenna_item";
    url += ("?" + (new Date()).getTime());
    new Ajax.Updater('antennas_list_container', url, options);
}
function sortAntenna(source_antenna_id, target_antenna_id) {

    var options = {
        evalScripts: true,
        parameters: "source_antenna_id="+source_antenna_id + "&target_antenna_id="+target_antenna_id,
        onFailure: function(originalRequest){
            alert("通信に失敗しました");
        },
        onComplete: function(originalRequest) {
            new Effect.Highlight('antennas_list_container');
        }
    };
    var url = relative_url_root + "/mypage/sort_antenna";
    url += ("?" + (new Date()).getTime());
    new Ajax.Updater('antennas_list_container', url, options);
}
function moveAntennaItem(antenna_id, antenna_item_id) {

    var options = {
        evalScripts: true,
        parameters: "antenna_id="+antenna_id + "&antenna_item_id="+antenna_item_id,
        onFailure: function(originalRequest){
            alert("通信に失敗しました");
        },
        onComplete: function(originalRequest) {
            new Effect.Highlight('antennas_list_container');
        }
    };
    var url = relative_url_root + "/mypage/move_antenna_item";
    url += ("?" + (new Date()).getTime());
    new Ajax.Updater('antennas_list_container', url, options);
}

function fitImageSize(id, max_width, max_height) {
    img = new Image();
    img.src = $(id).src;

    if (max_height > max_width) {
        if (img.width > max_width) {
            value = img.height / (img.width/max_width);
            if (value < 1)  { value = 1; }
            $(id).height = value;
            $(id).width = max_width;
        } else if (img.height > max_height) {
            value = img.width / (img.height/max_height);
            if (value < 1) { value = 1; }
            $(id).height = max_height;
            $(id).width = value;
        }
    } else {
        if (img.height >= max_height) {
            value = img.width / (img.height/max_height);
            if (value < 1) { value = 1; }
            $(id).height = max_height;
            $(id).width = value;
        } else if (img.width > max_width) {
            value = img.height / (img.width/max_width);
            if (value < 1)  { value = 1; }
            $(id).height = value;
            $(id).width = max_width;
        }
    }
}

/*
 * ログイン画面のクッキー保存と読み込み（2週間）
 */
function saveLoginData(){
    exp_days = 14;
    saveCookie('login_save', $('login_save').checked.toString(), exp_days);
    saveCookie('ssl_enable', $('ssl_enable_radio').checked.toString(), exp_days);
    return true;
}
function loadLoginData(){
    $('login_save').checked = eval(loadCookie('login_save'));
    if((ssl_enable = loadCookie('ssl_enable')) == "") ssl_enable = "false";
    $('ssl_enable_radio').checked = eval(ssl_enable);
    $('ssl_disable_radio').checked = !eval(ssl_enable);
    $('login_key').focus();
}
