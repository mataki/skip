/*
 hotkey.js
  usage :
   var kb = new HotKey;
   kb.add("a",function(){alert("a")});
   kb.add("A",function(){alert("Shift+a")});
*/
function HotKey(element){
	this.target = element || document;
	this._keyfunc = {};
	this.init();

}
HotKey.kc2char = function(kc){
	var between = function(a,b){
		return a <= kc && kc <= b
	}
	var _32_40 = "space pageup pagedown end home left up right down".split(" ");
	var kt = {
		8  : "back",
		9  : "tab"  ,
		13 : "enter",
		16 : "shift",
		17 : "ctrl",
		46 : "delete"
	};
	return (
		between(65,90)  ? String.fromCharCode(kc+32) : // a-z
		between(48,57)  ? String.fromCharCode(kc) :    // 0-9
		between(96,105) ? String.fromCharCode(kc-48) : // num 0-9
		between(32,40)  ? _32_40[kc-32] :
		kt.hasOwnProperty(kc) ? kt[kc] : 
		null
	)
}

HotKey.prototype.ignore = /input|textarea/i;
HotKey.prototype.init = function(){
	var self = this;
	var listener = function(e){
		self.onkeydown.call(self,e)
	};
	if(this.target.addEventListener){
		this.target.addEventListener("keydown", listener, true);
	}else{
		this.target.attachEvent("onkeydown", listener)
	}
}
HotKey.prototype.onkeydown = function(e){
	var tag = (e.target || e.srcElement).tagName;
	if(this.ignore.test(tag)) return;
	var input = HotKey.kc2char(e.keyCode);

	if(e.shiftKey && input.length == 1){
		input = input.toUpperCase()
	}
	if(e.ctrlKey) input = "C" + input;

	if(this._keyfunc.hasOwnProperty(input)){
		this._keyfunc[input].call(this,e)
	}
}
HotKey.prototype.sendKey = function(key){
	this._keyfunc[key] && this._keyfunc[key]()
}
HotKey.prototype.add = function(key,func){
	if(key.constructor == Array){
		for(var i=0;i<key.length;i++)
			this._keyfunc[key[i]] = func;
	}else{
		this._keyfunc[key] = func;
	}
}
