/*
 * jQuery jTagging plugin
 * Version 1.0.0  (10/01/2007)
 *
 * Copyright (c) 2007 Alcohol.Wang
 * Dual licensed under the MIT and GPL licenses.
 *
 * http://www.alcoholwang.cn/jquery/jTagging.htm
*/

(
	function($)
	{
		$.jTagging =
		{
			version : "1.0.0",
			defaults : 
			{
				normalStyle : { padding : "2px 1px 0 1px", textDecoration : "none", color : "#6665cb", backgroundColor : "" },
				selectedStyle : { padding : "2px 1px 0 1px", textDecoration : "none", color : "#fff", backgroundColor : "#6665cb"},
				normalHoverStyle : { padding : "2px 1px 0 1px", textDecoration : "none", color : "#fff", backgroundColor : "#6665cb"}
			}, 
			arrayRemove : function(array, value)
			{
				array = array || [];
                // TODO prototype.jsがArrayを拡張しており、以下の書き方ではArray#sizeの範囲外のプロパティも全て回してしまう。
                // そのため正常に動作しない問題がある。jQuery化終了後にprototypeを除去した後で元に戻す。
//				for(var o in array)
//				{
//					array[o] = $.trim(array[o]);
//					if (array[o] == value || array[o] == "")
//					{
//						array.splice(o, 1);
//					}
//				}
                for(i=0; i < array.length; i++)
				{
					array[i] = $.trim(array[i]);
					if (array[i] == value || array[i] == "")
					{
						array.splice(i, 1);
					}
				}
			},
			setClass : function(el, nc, hc)
			{
				$(el).css(nc);
				$(el).hover
				(
					function()
					{
						$(el).css(hc);
					}
					,
					function()
					{
						$(el).css(nc);
					}
				);
			}
		};
	
		$.fn.jTagging = function(tags, seperator, normalStyle, selectedStyle, normalHoverStyle, timeout)
		{
			seperator = seperator || ",";
			normalStyle =normalStyle || $.jTagging.defaults.normalStyle;
			selectedStyle =selectedStyle || $.jTagging.defaults.selectedStyle;
			normalHoverStyle = normalHoverStyle || $.jTagging.defaults.normalHoverStyle;
            timeout = timeout || 500
			tags = [tags];
		    return this.each
			(
				function()
				{
					var name = this.nodeName.toLowerCase();
					var type = this.type.toLowerCase();
					if  (name != "input" || type != "text"  && name != "textarea")
					{
						throw "Element must be \"input:text\" or \"textarea\"";
					}
					
					var input = this;
                    // タグの数が増えると重くなるので指定秒入力が無いときのみkeyupイベントが発生するようにした。
                    var tid = null;
                    var handler = function() {
                            $.each ( tags, function(i, n) {
                                $.each ( n, function (j, o) {
                                    $("a", o).each ( function(k) {
                                        var value = $(input).val().split(seperator);
                                        $.jTagging.arrayRemove(value);
                                        if ($(value).index($(this).text()) >= 0) {
                                            $.jTagging.setClass(this, selectedStyle, normalHoverStyle);
                                        } else {
                                            $.jTagging.setClass(this, normalStyle, normalHoverStyle);
                                        }
                                    });
                                });
                            });
                    };
                    $(input)
                    .bind('keydown', function() {
                        clearTimeout(tid);
                        tid = null;
                    })
                    .bind('keyup', function() {
                        ( tid == null ) && ( tid = setTimeout(handler, timeout) );
                    });
					
					$.each
					(
						tags, function(i, n)
						{
							$.each
							(
								n, function (j, o)
								{
									 $("a", o).each
									 (
										function(k)
										{
											$(this).removeClass();
											$(this).attr("href", "#");
											$(this).click
											(
												function()
												{
													var value = $(input).val().split(seperator);
													$.jTagging.arrayRemove(value);
													if ($(value).index($(this).text()) >= 0)
													{
														$.jTagging.arrayRemove(value, $(this).text());
														$(input).val(value.join(seperator));
														$.jTagging.setClass(this, normalStyle, normalHoverStyle);
													}
													else
													{
														value.push($(this).text());
														$(input).val(value.join(seperator));
														$.jTagging.setClass(this, selectedStyle, normalHoverStyle);
													}
													this.blur();
													return false;
												}
											);

											var value = $(input).val().split(seperator);
											$.jTagging.arrayRemove(value);
											if ($(value).index($(this).text()) >= 0)
											{
												$.jTagging.setClass(this, selectedStyle, normalHoverStyle);
											}
											else
											{
												$.jTagging.setClass(this,normalStyle, normalHoverStyle);
											}
										}
									);
								}
							);
						}
					);
				}
			);
		}
	}
)
(jQuery);
