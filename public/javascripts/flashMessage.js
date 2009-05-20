jQuery.fn.flashMessage = function(flashes, relativeUrlRoot){
  var flash = jQuery(this);
  if(jQuery.browser.ie){
    var position = flash.position();

    var iframe = jQuery("<iframe id='ie-select-fix'></iframe>").
      attr("src", relativeUrlRoot + "/blank").
      css("z-index",  flash.css("z-index")).
      css("width",  flash.width()).
      css("height",  flash.height()).
      css("top", position.top).
      css("left", position.left);

    flash.css("z-index", Number(iframe.css("z-index")) + 1).after(iframe);
  };

  flash.find(" > div").click(function(){
    jQuery("#ie-select-fix").hide();
    jQuery(this).fadeOut();
  });

  function showFlash(type, message, hideAfterSec){
    jQuery("#ie-select-fix").show();
    flash.find("div." + type).show().find("h3").text(message);
    if(hideAfterSec){
      setTimeout(function(){ flash.find("div." + type).trigger("click"); }, hideAfterSec * 1000);
    };
  };

  flash.bind("error",  function(_,message){ showFlash("error", message) }).
        bind("warn",   function(_,message){ showFlash("warn", message, 5) }).
        bind("notice", function(_,message){ showFlash("notice", message, 2) });

  jQuery.each(flashes, function(key,val){ flash.triggerHandler(key, val) });

  return flash;
};


