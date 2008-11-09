/*
 * このjavascriptの前提条件としてvar platform_url_root
 * が定義されている必要があるので、skip_javascript_include_tagを通して利用すること
 */
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
