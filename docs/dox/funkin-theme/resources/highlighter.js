// highlighter adapted/modified from code.haxe.org
(function (console) { "use strict";
var EReg = function(r,opt) {
	opt = opt.split("u").join("");
	this.r = new RegExp(r,opt);
};
EReg.prototype = {
	replace: function(s,by) {
		return s.replace(this.r,by);
	}
};
var Highlighter = function() { };
Highlighter.main = function() {
	var _g = 0;
	var _g1 = window.document.body.querySelectorAll("pre code");
	while(_g < _g1.length) {
		var el = _g1[_g];
		++_g;
		if(!Highlighter.hasClass(el,"highlighted")) {
			el.innerHTML = Highlighter.syntaxHighlight(el.innerHTML);
			el.className += " highlighted";
		}
	}
};
Highlighter.hasClass = function(el,className) {
	return el.className.indexOf(className) != -1;
};
Highlighter.syntaxHighlight = function(html) {
	var kwds = ["abstract","break","case","cast","catch","class","continue","default","do","dynamic","else","enum","extends","extern","false","final","for","function","if","implements","import","in","inline","interface","macro","new","operator","overload","override","package","private","public","return","static","switch","this","throw","true","try","typedef","untyped","using","var","while"];
	var kwds1 = new EReg("\\b(" + kwds.join("|") + ")\\b","g");
	var vals = ["null","true","false","this"];
	var vals1 = new EReg("\\b(" + vals.join("|") + ")\\b","g");
	var types = new EReg("\\b([A-Z][a-zA-Z0-9]*)\\b","g");
	html = kwds1.replace(html,"<span class='kwd'>$1</span>");
	html = vals1.replace(html,"<span class='val'>$1</span>");
	html = types.replace(html,"<span class='type'>$1</span>");
	html = new EReg("(\"[^\"]*\")","g").replace(html,"<span class='str'>$1</span>");
	html = new EReg("(//.+?)(\n|$)","g").replace(html,"<span class='cmt'>$1</span>$2");
	html = new EReg("(/\\*\\*?(.|\n)+?\\*?\\*/)","g").replace(html,"<span class='cmt'>$1</span>");
	return html;
};
Highlighter.main();
})(typeof console != "undefined" ? console : {log:function(){}});
