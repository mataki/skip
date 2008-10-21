/*
 * このjavascriptの前提条件としてvar platform_url_root
 * が定義されている必要があるので、skip_javascript_include_tagを通して利用すること
 */
/*
 * 透過ＰＮＧをIEでも表示できるように苦肉の策（iconフォルダ以下かつ、name属性が"_"だったら透過）
 */
function fnLoadPngs() {
    if (navigator.platform == "Win32" && navigator.appName == "Microsoft Internet Explorer" && window.attachEvent) {
        var rslt = navigator.appVersion.match(/MSIE (\d+\.\d+)/, '');
        var itsAllGood = (rslt != null && Number(rslt[1]) >= 5.5);

        for (var i = document.images.length - 1, img = null; (img = document.images[i]); i--) {
            if (itsAllGood && img.src.match(/\icons.*.png.*$/i) != null && img.name == "_") {
                transparentImage(img);
            }
        }
    }
}
function transparentImage(obj) {
  if(obj.runtimeStyle){
    var image = obj.src;
    obj.src = platform_url_root + "/images/skip/blank.gif";
    obj.width = 16;
    obj.height = 16;
    obj.runtimeStyle.filter = 'progid:DXImageTransform.Microsoft.AlphaImageLoader(src="' + image + '", sizingmethod="image");';
  }
}
/* -------------------------------------------------- */
function saveCookie(key,value,exp){
    if(key&&value){
        if(exp) {
            xDay = new Date;
            xDay.setDate(xDay.getDate() + eval(exp));
            _exp = ";expires=" + xDay.toGMTString();
        }
        else _exp ="";
        document.cookie = escape(key) + "=" + escape(value) + _exp + ";path=/"
    }
}
/* -------------------------------------------------- */
function loadCookie(key){
    value = document.cookie + ";";
    key = escape(key);
    startPoint1 = value.indexOf(key);
    if (startPoint1 == -1) { return ""; }
    startPoint2 = value.indexOf("=",startPoint1) +1;
    endPoint = value.indexOf(";",startPoint1);
    if(startPoint2 < endPoint && startPoint1 > -1 &&startPoint2-startPoint1 == key.length+1){
        value = value.substring(startPoint2,endPoint);
        value = unescape(value);
    }
    return value
}
/* -------------------------------------------------- */
function getSubwindowScript(url, height, width, title) {
    if(title == undefined) {
        title = 'subwindow'
    }
    if(height == undefined) {
        height = 780
    }
    if(width == undefined) {
        width = 700
    }
    window.open(url, title, 'width='+width+',height='+height+',resizable=yes,scrollbars=yes').focus();
}

function getSubwindowRule(height, width, title) {
    getSubwindowScript(platform_url_root + '/custom/rules.html', height, width, title);
}
