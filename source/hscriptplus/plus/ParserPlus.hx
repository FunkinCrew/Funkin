package hscriptplus.plus;

import hscriptplus.Expr;
import hscriptplus.Parser;

class ParserPlus extends Parser {
	var access:Array<Access> = [];

	public function new() {
		super();
		allowTypes = true;
	}

	override function isBlock(e:Expr) {
		var ret = super.isBlock(e);
		if (ret) return ret;

		return switch (expr(e)) {
			case EPackage(_), EImport(_): true;
			case EClass(_, e, _): isBlock(e);
			default: false;
		}
	}

	override function parseStructure(id:String) {
		// workaround for bug failing to get access modfiers
		// for function with var declarations inside
		var access = null;
		switch (id) {
			case "function", "var":
				access = this.access;
				this.access = [];
		}

		var ret = super.parseStructure(id);

		if (ret != null) {
			switch (expr(ret)) {
				case EVar(name, t, e, access):
					// if `e` is `null` then default it to "null"
					if (e == null) e = mk(EConst(CString("null")));
					ret = mk(EVar(name, t, e, access));
				case EFunction(args, e, name, r, a):
					ret = mk(EFunction(args, e, name, r, access));
				default:
			}

			return ret;
		}

		return switch(id) {
			case "package":
				var path = parsePath();
				mk(EPackage(path));
			case "import":
				var path = parsePath();
				mk(EImport(path));
			case "class":
			// example: class ClassName
				var tk = token();
				var name = null;
				
				switch (tk) {
					case TId(id): name = id;
					default: push(tk);
				}

				var baseClass = null;
				tk = token();
				// optional - example: extends BaseClass 
				switch (tk) {
					case TId(id) if (id == "extends"):
						tk = token();
						switch (tk) {
							case TId(id): baseClass = id;
							default: unexpected(tk);
						}
					default:
					push(tk);
				}

				var body = parseExpr();
				mk(EClass(name, body, baseClass));

			case "public": pushAndParseNext(APublic);
			case "private": pushAndParseNext(APrivate);
			case "static": pushAndParseNext(AStatic);
			case "override": pushAndParseNext(AOverride);
			case "dynamic": pushAndParseNext(ADynamic);
			case "inline": pushAndParseNext(AInline);

			default: null;
		}
	}

	/**
	 *  @return "something.like.this"
	 */
	function parsePath():String {
		var tk = token();
		switch (tk) {
			case TId(id):
				var path = id;
				while (true) {
					tk = token();
					if (tk != TDot)
						break;
					path += ".";
					tk = token();
					switch (tk) {
						case TId(id):
							path += id;
						default:
							unexpected(tk);
					}
				}
				return path;
			case TSemicolon:
				push(tk);
				return "";
			default:
				unexpected(tk);
				return "";
		}
	}

	function pushAndParseNext(a:Access) {
		access.push(a);
		var tk = token();
		return switch (tk) {
			case TId(id): parseStructure(id);
			default: unexpected(tk);
		}
	}
}