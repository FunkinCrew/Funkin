/*
 * Copyright (C)2008-2017 Haxe Foundation
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */
package hscriptplus;
import hscriptplus.Expr;

enum Token {
	TEof;
	TConst( c : Const );
	TId( s : String );
	TOp( s : String );
	TPOpen;
	TPClose;
	TBrOpen;
	TBrClose;
	TDot;
	TComma;
	TSemicolon;
	TBkOpen;
	TBkClose;
	TQuestion;
	TDoubleDot;
	TMeta( s : String );
}

class Parser {

	// config / variables
	public var line : Int;
	public var opChars : String;
	public var identChars : String;
	#if haxe3
	public var opPriority : Map<String,Int>;
	public var opRightAssoc : Map<String,Bool>;
	public var unops : Map<String,Bool>; // true if allow postfix
	#else
	public var opPriority : Hash<Int>;
	public var opRightAssoc : Hash<Bool>;
	public var unops : Hash<Bool>; // true if allow postfix
	#end

	/**
		activate JSON compatiblity
	**/
	public var allowJSON : Bool;

	/**
		allow types declarations
	**/
	public var allowTypes : Bool;

	/**
		allow haxe metadata declarations
	**/
	public var allowMetadata : Bool;

	// implementation
	var input : haxe.io.Input;
	var char : Int;
	var ops : Array<Bool>;
	var idents : Array<Bool>;
	var uid : Int = 0;

	#if hscriptPos
	var origin : String;
	var readPos : Int;
	var tokenMin : Int;
	var tokenMax : Int;
	var oldTokenMin : Int;
	var oldTokenMax : Int;
	var tokens : List<{ min : Int, max : Int, t : Token }>;
	#else
	static inline var p1 = 0;
	static inline var readPos = 0;
	static inline var tokenMin = 0;
	static inline var tokenMax = 0;
	#if haxe3
	var tokens : haxe.ds.GenericStack<Token>;
	#else
	var tokens : haxe.FastList<Token>;
	#end

	#end


	public function new() {
		line = 1;
		opChars = "+*/-=!><&|^%~";
		identChars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_";
		var priorities = [
			["%"],
			["*", "/"],
			["+", "-"],
			["<<", ">>", ">>>"],
			["|", "&", "^"],
			["==", "!=", ">", "<", ">=", "<="],
			["..."],
			["&&"],
			["||"],
			["=","+=","-=","*=","/=","%=","<<=",">>=",">>>=","|=","&=","^=","=>"],
		];
		#if haxe3
		opPriority = new Map();
		opRightAssoc = new Map();
		unops = new Map();
		#else
		opPriority = new Hash();
		opRightAssoc = new Hash();
		unops = new Hash();
		#end
		for( i in 0...priorities.length )
			for( x in priorities[i] ) {
				opPriority.set(x, i);
				if( i == 9 ) opRightAssoc.set(x, true);
			}
		for( x in ["!", "++", "--", "-", "~"] )
			unops.set(x, x == "++" || x == "--");
	}

	public inline function error( err, pmin, pmax ) {
		#if hscriptPos
		throw new Error(err, pmin, pmax, origin, line);
		#else
		throw err;
		#end
	}

	public function invalidChar(c) {
		error(EInvalidChar(c), readPos, readPos);
	}

	public function parseString( s : String, ?origin : String = "hscriptplus" ) {
		uid = 0;
		return parse( new haxe.io.StringInput(s), origin );
	}

	public function parse( s : haxe.io.Input, ?origin : String = "hscriptplus" ) {
		line = 1;
		#if hscriptPos
		this.origin = origin;
		readPos = 0;
		tokenMin = oldTokenMin = 0;
		tokenMax = oldTokenMax = 0;
		tokens = new List();
		#elseif haxe3
		tokens = new haxe.ds.GenericStack<Token>();
		#else
		tokens = new haxe.FastList<Token>();
		#end
		char = -1;
		input = s;
		ops = new Array();
		idents = new Array();
		for( i in 0...opChars.length )
			ops[opChars.charCodeAt(i)] = true;
		for( i in 0...identChars.length )
			idents[identChars.charCodeAt(i)] = true;
		var a = new Array();
		while( true ) {
			var tk = token();
			if( tk == TEof ) break;
			push(tk);
			a.push(parseFullExpr());
		}
		return if( a.length == 1 ) a[0] else mk(EBlock(a),0);
	}

	function unexpected( tk ) : Dynamic {
		error(EUnexpected(tokenString(tk)),tokenMin,tokenMax);
		return null;
	}

	inline function push(tk) {
		#if hscriptPos
		tokens.push( { t : tk, min : tokenMin, max : tokenMax } );
		tokenMin = oldTokenMin;
		tokenMax = oldTokenMax;
		#else
		tokens.add(tk);
		#end
	}

	inline function ensure(tk) {
		var t = token();
		if( t != tk ) unexpected(t);
	}

	function getIdent() {
		var tk = token();
		switch( tk ) {
		case TId(id): return id;
		default:
			unexpected(tk);
			return null;
		}
	}

	inline function expr(e:Expr) {
		#if hscriptPos
		return e.e;
		#else
		return e;
		#end
	}

	inline function pmin(e:Expr) {
		#if hscriptPos
		return e.pmin;
		#else
		return 0;
		#end
	}

	inline function pmax(e:Expr) {
		#if hscriptPos
		return e.pmax;
		#else
		return 0;
		#end
	}

	inline function mk(e,?pmin,?pmax) : Expr {
		#if hscriptPos
		if( e == null ) return null;
		if( pmin == null ) pmin = tokenMin;
		if( pmax == null ) pmax = tokenMax;
		return { e : e, pmin : pmin, pmax : pmax, origin : origin, line : line };
		#else
		return e;
		#end
	}

	function isBlock(e) {
		return switch( expr(e) ) {
		case EBlock(_), EObject(_), ESwitch(_): true;
		case EFunction(_,e,_,_): isBlock(e);
		case EVar(_,_,e): e != null && isBlock(e);
		case EIf(_,e1,e2): if( e2 != null ) isBlock(e2) else isBlock(e1);
		case EBinop(_,_,e): isBlock(e);
		case EUnop(_,prefix,e): !prefix && isBlock(e);
		case EWhile(_,e): isBlock(e);
		case EDoWhile(_,e): isBlock(e);
		case EFor(_,_,e): isBlock(e);
		case EReturn(e): e != null && isBlock(e);
		case ETry(_, _, _, e): isBlock(e);
		case EMeta(_, _, e): isBlock(e);
		default: false;
		}
	}

	function parseFullExpr() {
		var e = parseExpr();
		var tk = token();
		if( tk != TSemicolon && tk != TEof ) {
			if( isBlock(e) )
				push(tk);
			else
				unexpected(tk);
		}
		return e;
	}

	function parseObject(p1) {
		// parse object
		var fl = new Array();
		while( true ) {
			var tk = token();
			var id = null;
			switch( tk ) {
			case TId(i): id = i;
			case TConst(c):
				if( !allowJSON )
					unexpected(tk);
				switch( c ) {
				case CString(s): id = s;
				default: unexpected(tk);
				}
			case TBrClose:
				break;
			default:
				unexpected(tk);
			}
			ensure(TDoubleDot);
			fl.push({ name : id, e : parseExpr() });
			tk = token();
			switch( tk ) {
			case TBrClose:
				break;
			case TComma:
			default:
				unexpected(tk);
			}
		}
		return parseExprNext(mk(EObject(fl),p1));
	}

	function parseExpr() {
		var tk = token();
		#if hscriptPos
		var p1 = tokenMin;
		#end
		switch( tk ) {
		case TId(id):
			var e = parseStructure(id);
			if( e == null )
				e = mk(EIdent(id));
			return parseExprNext(e);
		case TConst(c):
			return parseExprNext(mk(EConst(c)));
		case TPOpen:
			var e = parseExpr();
			ensure(TPClose);
			return parseExprNext(mk(EParent(e),p1,tokenMax));
		case TBrOpen:
			tk = token();
			switch( tk ) {
			case TBrClose:
				return parseExprNext(mk(EObject([]),p1));
			case TId(_):
				var tk2 = token();
				push(tk2);
				push(tk);
				switch( tk2 ) {
				case TDoubleDot:
					return parseExprNext(parseObject(p1));
				default:
				}
			case TConst(c):
				if( allowJSON ) {
					switch( c ) {
					case CString(_):
						var tk2 = token();
						push(tk2);
						push(tk);
						switch( tk2 ) {
						case TDoubleDot:
							return parseExprNext(parseObject(p1));
						default:
						}
					default:
						push(tk);
					}
				} else
					push(tk);
			default:
				push(tk);
			}
			var a = new Array();
			while( true ) {
				a.push(parseFullExpr());
				tk = token();
				if( tk == TBrClose )
					break;
				push(tk);
			}
			return mk(EBlock(a),p1);
		case TOp(op):
			if( unops.exists(op) )
				return makeUnop(op,parseExpr());
			return unexpected(tk);
		case TBkOpen:
			var a = new Array();
			tk = token();
			while( tk != TBkClose ) {
				push(tk);
				a.push(parseExpr());
				tk = token();
				if( tk == TComma )
					tk = token();
			}
			if( a.length == 1 )
				switch( expr(a[0]) ) {
				case EFor(_), EWhile(_), EDoWhile(_):
					var tmp = "__a_" + (uid++);
					var e = mk(EBlock([
						mk(EVar(tmp, null, mk(EArrayDecl([]), p1)), p1),
						mapCompr(tmp, a[0]),
						mk(EIdent(tmp),p1),
					]),p1);
					return parseExprNext(e);
				default:
				}
			return parseExprNext(mk(EArrayDecl(a), p1));
		case TMeta(id) if( allowMetadata ):
			var args = parseMetaArgs();
			return mk(EMeta(id, args, parseExpr()),p1);
		default:
			return unexpected(tk);
		}
	}

	function parseMetaArgs() {
		var tk = token();
		if( tk != TPOpen ) {
			push(tk);
			return null;
		}
		var args = [];
		tk = token();
		if( tk != TPClose ) {
			push(tk);
			while( true ) {
				args.push(parseExpr());
				switch( token() ) {
				case TComma:
				case TPClose:
					break;
				case tk:
					unexpected(tk);
				}
			}
		}
		return args;
	}

	function mapCompr( tmp : String, e : Expr ) {
		var edef = switch( expr(e) ) {
		case EFor(v, it, e2):
			EFor(v, it, mapCompr(tmp, e2));
		case EWhile(cond, e2):
			EWhile(cond, mapCompr(tmp, e2));
		case EDoWhile(cond, e2):
			EDoWhile(cond, mapCompr(tmp, e2));
		case EIf(cond, e1, e2) if( e2 == null ):
			EIf(cond, mapCompr(tmp, e1), null);
		case EBlock([e]):
			EBlock([mapCompr(tmp, e)]);
		case EParent(e2):
			EParent(mapCompr(tmp, e2));
		default:
			ECall( mk(EField(mk(EIdent(tmp), pmin(e), pmax(e)), "push"), pmin(e), pmax(e)), [e]);
		}
		return mk(edef, pmin(e), pmax(e));
	}

	function makeUnop( op, e ) {
		return switch( expr(e) ) {
		case EBinop(bop, e1, e2): mk(EBinop(bop, makeUnop(op, e1), e2), pmin(e1), pmax(e2));
		case ETernary(e1, e2, e3): mk(ETernary(makeUnop(op, e1), e2, e3), pmin(e1), pmax(e3));
		default: mk(EUnop(op,true,e),pmin(e),pmax(e));
		}
	}

	function makeBinop( op, e1, e ) {
		return switch( expr(e) ) {
		case EBinop(op2,e2,e3):
			if( opPriority.get(op) <= opPriority.get(op2) && !opRightAssoc.exists(op) )
				mk(EBinop(op2,makeBinop(op,e1,e2),e3),pmin(e1),pmax(e3));
			else
				mk(EBinop(op, e1, e), pmin(e1), pmax(e));
		case ETernary(e2,e3,e4):
			if( opRightAssoc.exists(op) )
				mk(EBinop(op,e1,e),pmin(e1),pmax(e));
			else
				mk(ETernary(makeBinop(op, e1, e2), e3, e4), pmin(e1), pmax(e));
		default:
			mk(EBinop(op,e1,e),pmin(e1),pmax(e));
		}
	}

	function parseStructure(id) {
		#if hscriptPos
		var p1 = tokenMin;
		#end
		return switch( id ) {
		case "if":
			ensure(TPOpen);
			var cond = parseExpr();
			ensure(TPClose);
			var e1 = parseExpr();
			var e2 = null;
			var semic = false;
			var tk = token();
			if( tk == TSemicolon ) {
				semic = true;
				tk = token();
			}
			if( Type.enumEq(tk,TId("else")) )
				e2 = parseExpr();
			else {
				push(tk);
				if( semic ) push(TSemicolon);
			}
			mk(EIf(cond,e1,e2),p1,(e2 == null) ? tokenMax : pmax(e2));
		case "var":
			var ident = getIdent();
			var tk = token();
			var t = null;
			if( tk == TDoubleDot && allowTypes ) {
				t = parseType();
				tk = token();
			}
			var e = null;
			if( Type.enumEq(tk,TOp("=")) )
				e = parseExpr();
			else
				push(tk);
			mk(EVar(ident,t,e),p1,(e == null) ? tokenMax : pmax(e));
		case "while":
			var econd = parseExpr();
			var e = parseExpr();
			mk(EWhile(econd,e),p1,pmax(e));
		case "do":
			var e = parseExpr();
			var tk = token();
			switch(tk)
			{
				case TId("while"): // Valid
				default: unexpected(tk);
			}
			var econd = parseExpr();
			mk(EDoWhile(econd,e),p1,pmax(econd));
		case "for":
			ensure(TPOpen);
			var vname = getIdent();
			var tk = token();
			if( !Type.enumEq(tk,TId("in")) ) unexpected(tk);
			var eiter = parseExpr();
			ensure(TPClose);
			var e = parseExpr();
			mk(EFor(vname,eiter,e),p1,pmax(e));
		case "break": mk(EBreak);
		case "continue": mk(EContinue);
		case "else": unexpected(TId(id));
		case "function":
			var tk = token();
			var name = null;
			switch( tk ) {
			case TId(id): name = id;
			default: push(tk);
			}
			ensure(TPOpen);
			var args = new Array();
			tk = token();
			if( tk != TPClose ) {
				var done = false;
				while( !done ) {
					var name = null, opt = false;
					switch( tk ) {
					case TQuestion:
						opt = true;
						tk = token();
					default:
					}
					switch( tk ) {
					case TId(id): name = id;
					default: unexpected(tk);
					}
					tk = token();
					var arg : Argument = { name : name };
					args.push(arg);
					if( opt ) arg.opt = true;
					if( tk == TDoubleDot && allowTypes ) {
						arg.t = parseType();
						tk = token();
					}
					switch( tk ) {
					case TComma:
						tk = token();
					case TPClose:
						done = true;
					default:
						unexpected(tk);
					}
				}
			}
			var ret = null;
			if( allowTypes ) {
				tk = token();
				if( tk != TDoubleDot )
					push(tk);
				else
					ret = parseType();
			}
			var body = parseExpr();
			mk(EFunction(args, body, name, ret),p1,pmax(body));
		case "return":
			var tk = token();
			push(tk);
			var e = if( tk == TSemicolon ) null else parseExpr();
			mk(EReturn(e),p1,if( e == null ) tokenMax else pmax(e));
		case "new":
			var a = new Array();
			a.push(getIdent());
			var next = true;
			while( next ) {
				var tk = token();
				switch( tk ) {
				case TDot:
					a.push(getIdent());
				case TPOpen:
					next = false;
				default:
					unexpected(tk);
				}
			}
			var args = parseExprList(TPClose);
			mk(ENew(a.join("."),args),p1);
		case "throw":
			var e = parseExpr();
			mk(EThrow(e),p1,pmax(e));
		case "try":
			var e = parseExpr();
			var tk = token();
			if( !Type.enumEq(tk, TId("catch")) ) unexpected(tk);
			ensure(TPOpen);
			var vname = getIdent();
			ensure(TDoubleDot);
			var t = null;
			if( allowTypes )
				t = parseType();
			else {
				tk = token();
				if( !Type.enumEq(tk, TId("Dynamic")) ) unexpected(tk);
			}
			ensure(TPClose);
			var ec = parseExpr();
			mk(ETry(e, vname, t, ec), p1, pmax(ec));
		case "switch":
			var e = parseExpr();
			var def = null, cases = [];
			ensure(TBrOpen);
			while( true ) {
				var tk = token();
				switch( tk ) {
				case TId("case"):
					var c = { values : [], expr : null };
					cases.push(c);
					while( true ) {
						var e = parseExpr();
						c.values.push(e);
						tk = token();
						switch( tk ) {
						case TComma:
							// next expr
						case TDoubleDot:
							break;
						default:
							unexpected(tk);
						}
					}
					var exprs = [];
					while( true ) {
						tk = token();
						push(tk);
						switch( tk ) {
						case TId("case"), TId("default"), TBrClose:
							break;
						default:
							exprs.push(parseFullExpr());
						}
					}
					c.expr = if( exprs.length == 1)
						exprs[0];
					else if( exprs.length == 0 )
						mk(EBlock([]), tokenMin, tokenMin);
					else
						mk(EBlock(exprs), pmin(exprs[0]), pmax(exprs[exprs.length - 1]));
				case TId("default"):
					if( def != null ) unexpected(tk);
					ensure(TDoubleDot);
					var exprs = [];
					while( true ) {
						tk = token();
						push(tk);
						switch( tk ) {
						case TId("case"), TId("default"), TBrClose:
							break;
						default:
							exprs.push(parseFullExpr());
						}
					}
					def = if( exprs.length == 1)
						exprs[0];
					else if( exprs.length == 0 )
						mk(EBlock([]), tokenMin, tokenMin);
					else
						mk(EBlock(exprs), pmin(exprs[0]), pmax(exprs[exprs.length - 1]));
				case TBrClose:
					break;
				default:
					unexpected(tk);
				}
			}
			mk(ESwitch(e, cases, def), p1, tokenMax);
		default:
			null;
		}
	}

	function parseExprNext( e1 : Expr ) {
		var tk = token();
		switch( tk ) {
		case TOp(op):
			if( unops.get(op) ) {
				if( isBlock(e1) || switch(expr(e1)) { case EParent(_): true; default: false; } ) {
					push(tk);
					return e1;
				}
				return parseExprNext(mk(EUnop(op,false,e1),pmin(e1)));
			}
			return makeBinop(op,e1,parseExpr());
		case TDot:
			var field = getIdent();
			return parseExprNext(mk(EField(e1,field),pmin(e1)));
		case TPOpen:
			return parseExprNext(mk(ECall(e1,parseExprList(TPClose)),pmin(e1)));
		case TBkOpen:
			var e2 = parseExpr();
			ensure(TBkClose);
			return parseExprNext(mk(EArray(e1,e2),pmin(e1)));
		case TQuestion:
			var e2 = parseExpr();
			ensure(TDoubleDot);
			var e3 = parseExpr();
			return mk(ETernary(e1,e2,e3),pmin(e1),pmax(e3));
		default:
			push(tk);
			return e1;
		}
	}

	function parseType() : CType {
		var t = token();
		switch( t ) {
		case TId(v):
			var path = [v];
			while( true ) {
				t = token();
				if( t != TDot )
					break;
				path.push(getIdent());
			}
			var params = null;
			switch( t ) {
			case TOp(op):
				if( op == "<" ) {
					params = [];
					while( true ) {
						params.push(parseType());
						t = token();
						switch( t ) {
						case TComma: continue;
						case TOp(op):
							if( op == ">" ) break;
							if( op.charCodeAt(0) == ">".code ) {
								#if hscriptPos
								tokens.add({ t : TOp(op.substr(1)), min : tokenMax - op.length - 1, max : tokenMax });
								#else
								tokens.add(TOp(op.substr(1)));
								#end
								break;
							}
						default:
						}
						unexpected(t);
					}
				} else
					push(t);
			default:
				push(t);
			}
			return parseTypeNext(CTPath(path, params));
		case TPOpen:
			var t = parseType();
			ensure(TPClose);
			return parseTypeNext(CTParent(t));
		case TBrOpen:
			var fields = [];
			var meta = null;
			while( true ) {
				t = token();
				switch( t ) {
				case TBrClose: break;
				case TId("var"):
					var name = getIdent();
					ensure(TDoubleDot);
					fields.push( { name : name, t : parseType(), meta : meta } );
					meta = null;
					ensure(TSemicolon);
				case TId(name):
					ensure(TDoubleDot);
					fields.push( { name : name, t : parseType(), meta : meta } );
					t = token();
					switch( t ) {
					case TComma:
					case TBrClose: break;
					default: unexpected(t);
					}
				case TMeta(name):
					if( meta == null ) meta = [];
					meta.push({ name : name, params : parseMetaArgs() });
				default:
					unexpected(t);
				}
			}
			return parseTypeNext(CTAnon(fields));
		default:
			return unexpected(t);
		}
	}

	function parseTypeNext( t : CType ) {
		var tk = token();
		switch( tk ) {
		case TOp(op):
			if( op != "->" ) {
				push(tk);
				return t;
			}
		default:
			push(tk);
			return t;
		}
		var t2 = parseType();
		switch( t2 ) {
		case CTFun(args, _):
			args.unshift(t);
			return t2;
		default:
			return CTFun([t], t2);
		}
	}

	function parseExprList( etk ) {
		var args = new Array();
		var tk = token();
		if( tk == etk )
			return args;
		push(tk);
		while( true ) {
			args.push(parseExpr());
			tk = token();
			switch( tk ) {
			case TComma:
			default:
				if( tk == etk ) break;
				unexpected(tk);
			}
		}
		return args;
	}

	inline function incPos() {
		#if hscriptPos
		readPos++;
		#end
	}

	function readChar() {
		incPos();
		return try input.readByte() catch( e : Dynamic ) 0;
	}

	function readString( until ) {
		var c = 0;
		var b = new haxe.io.BytesOutput();
		var esc = false;
		var old = line;
		var s = input;
		#if hscriptPos
		var p1 = readPos - 1;
		#end
		while( true ) {
			try {
				incPos();
				c = s.readByte();
			} catch( e : Dynamic ) {
				line = old;
				error(EUnterminatedString, p1, p1);
			}
			if( esc ) {
				esc = false;
				switch( c ) {
				case 'n'.code: b.writeByte(10);
				case 'r'.code: b.writeByte(13);
				case 't'.code: b.writeByte(9);
				case "'".code, '"'.code, '\\'.code: b.writeByte(c);
				case '/'.code: if( allowJSON ) b.writeByte(c) else invalidChar(c);
				case "u".code:
					if( !allowJSON ) invalidChar(c);
					var code = null;
					try {
						incPos();
						incPos();
						incPos();
						incPos();
						code = s.readString(4);
					} catch( e : Dynamic ) {
						line = old;
						error(EUnterminatedString, p1, p1);
					}
					var k = 0;
					for( i in 0...4 ) {
						k <<= 4;
						var char = code.charCodeAt(i);
						switch( char ) {
						case 48,49,50,51,52,53,54,55,56,57: // 0-9
							k += char - 48;
						case 65,66,67,68,69,70: // A-F
							k += char - 55;
						case 97,98,99,100,101,102: // a-f
							k += char - 87;
						default:
							invalidChar(char);
						}
					}
					// encode k in UTF8
					if( k <= 0x7F )
						b.writeByte(k);
					else if( k <= 0x7FF ) {
						b.writeByte( 0xC0 | (k >> 6));
						b.writeByte( 0x80 | (k & 63));
					} else {
						b.writeByte( 0xE0 | (k >> 12) );
						b.writeByte( 0x80 | ((k >> 6) & 63) );
						b.writeByte( 0x80 | (k & 63) );
					}
				default: invalidChar(c);
				}
			} else if( c == 92 )
				esc = true;
			else if( c == until )
				break;
			else {
				if( c == 10 ) line++;
				b.writeByte(c);
			}
		}
		return b.getBytes().toString();
	}

	function token() {
		#if hscriptPos
		var t = tokens.pop();
		if( t != null ) {
			tokenMin = t.min;
			tokenMax = t.max;
			return t.t;
		}
		oldTokenMin = tokenMin;
		oldTokenMax = tokenMax;
		tokenMin = (this.char < 0) ? readPos : readPos - 1;
		var t = _token();
		tokenMax = (this.char < 0) ? readPos - 1 : readPos - 2;
		return t;
	}

	function _token() {
		#else
		if( !tokens.isEmpty() )
			return tokens.pop();
		#end
		var char;
		if( this.char < 0 )
			char = readChar();
		else {
			char = this.char;
			this.char = -1;
		}
		while( true ) {
			switch( char ) {
			case 0: return TEof;
			case 32,9,13: // space, tab, CR
				#if hscriptPos
				tokenMin++;
				#end
			case 10: line++; // LF
				#if hscriptPos
				tokenMin++;
				#end
			case 48,49,50,51,52,53,54,55,56,57: // 0...9
				var n = (char - 48) * 1.0;
				var exp = 0.;
				while( true ) {
					char = readChar();
					exp *= 10;
					switch( char ) {
					case 48,49,50,51,52,53,54,55,56,57:
						n = n * 10 + (char - 48);
					case 46:
						if( exp > 0 ) {
							// in case of '...'
							if( exp == 10 && readChar() == 46 ) {
								push(TOp("..."));
								var i = Std.int(n);
								return TConst( (i == n) ? CInt(i) : CFloat(n) );
							}
							invalidChar(char);
						}
						exp = 1.;
					case 120: // x
						if( n > 0 || exp > 0 )
							invalidChar(char);
						// read hexa
						#if haxe3
						var n = 0;
						while( true ) {
							char = readChar();
							switch( char ) {
							case 48,49,50,51,52,53,54,55,56,57: // 0-9
								n = (n << 4) + char - 48;
							case 65,66,67,68,69,70: // A-F
								n = (n << 4) + (char - 55);
							case 97,98,99,100,101,102: // a-f
								n = (n << 4) + (char - 87);
							default:
								this.char = char;
								return TConst(CInt(n));
							}
						}
						#else
						var n = haxe.Int32.ofInt(0);
						while( true ) {
							char = readChar();
							switch( char ) {
							case 48,49,50,51,52,53,54,55,56,57: // 0-9
								n = haxe.Int32.add(haxe.Int32.shl(n,4), cast (char - 48));
							case 65,66,67,68,69,70: // A-F
								n = haxe.Int32.add(haxe.Int32.shl(n,4), cast (char - 55));
							case 97,98,99,100,101,102: // a-f
								n = haxe.Int32.add(haxe.Int32.shl(n,4), cast (char - 87));
							default:
								this.char = char;
								// we allow to parse hexadecimal Int32 in Neko, but when the value will be
								// evaluated by Interpreter, a failure will occur if no Int32 operation is
								// performed
								var v = try CInt(haxe.Int32.toInt(n)) catch( e : Dynamic ) CInt32(n);
								return TConst(v);
							}
						}
						#end
					default:
						this.char = char;
						var i = Std.int(n);
						return TConst( (exp > 0) ? CFloat(n * 10 / exp) : ((i == n) ? CInt(i) : CFloat(n)) );
					}
				}
			case 59: return TSemicolon;
			case 40: return TPOpen;
			case 41: return TPClose;
			case 44: return TComma;
			case 46:
				char = readChar();
				switch( char ) {
				case 48,49,50,51,52,53,54,55,56,57:
					var n = char - 48;
					var exp = 1;
					while( true ) {
						char = readChar();
						exp *= 10;
						switch( char ) {
						case 48,49,50,51,52,53,54,55,56,57:
							n = n * 10 + (char - 48);
						default:
							this.char = char;
							return TConst( CFloat(n/exp) );
						}
					}
				case 46:
					char = readChar();
					if( char != 46 )
						invalidChar(char);
					return TOp("...");
				default:
					this.char = char;
					return TDot;
				}
			case 123: return TBrOpen;
			case 125: return TBrClose;
			case 91: return TBkOpen;
			case 93: return TBkClose;
			case 39: return TConst( CString(readString(39)) );
			case 34: return TConst( CString(readString(34)) );
			case 63: return TQuestion;
			case 58: return TDoubleDot;
			case '='.code:
				char = readChar();
				if( char == '='.code )
					return TOp("==");
				else if ( char == '>'.code )
					return TOp("=>");
				this.char = char;
				return TOp("=");
			case '@'.code:
				char = readChar();
				if( idents[char] || char == ':'.code ) {
					var id = String.fromCharCode(char);
					while( true ) {
						char = readChar();
						if( !idents[char] ) {
							this.char = char;
							return TMeta(id);
						}
						id += String.fromCharCode(char);
					}
				}
				invalidChar(char);
			default:
				if( ops[char] ) {
					var op = String.fromCharCode(char);
					var prev = -1;
					while( true ) {
						char = readChar();
						if( !ops[char] || prev == '='.code ) {
							if( op.charCodeAt(0) == '/'.code )
								return tokenComment(op,char);
							this.char = char;
							return TOp(op);
						}
						prev = char;
						op += String.fromCharCode(char);
					}
				}
				if( idents[char] ) {
					var id = String.fromCharCode(char);
					while( true ) {
						char = readChar();
						if( !idents[char] ) {
							this.char = char;
							return TId(id);
						}
						id += String.fromCharCode(char);
					}
				}
				invalidChar(char);
			}
			char = readChar();
		}
		return null;
	}

	function tokenComment( op : String, char : Int ) {
		var c = op.charCodeAt(1);
		var s = input;
		if( c == '/'.code ) { // comment
			try {
				while( char != '\r'.code && char != '\n'.code ) {
					incPos();
					char = s.readByte();
				}
				this.char = char;
			} catch( e : Dynamic ) {
			}
			return token();
		}
		if( c == '*'.code ) { /* comment */
			var old = line;
			if( op == "/**/" ) {
				this.char = char;
				return token();
			}
			try {
				while( true ) {
					while( char != '*'.code ) {
						if( char == '\n'.code ) line++;
						incPos();
						char = s.readByte();
					}
					incPos();
					char = s.readByte();
					if( char == '/'.code )
						break;
				}
			} catch( e : Dynamic ) {
				line = old;
				error(EUnterminatedComment, tokenMin, tokenMin);
			}
			return token();
		}
		this.char = char;
		return TOp(op);
	}

	function constString( c ) {
		return switch(c) {
		case CInt(v): Std.string(v);
		case CFloat(f): Std.string(f);
		case CString(s): s; // TODO : escape + quote
		#if !haxe3
		case CInt32(v): Std.string(v);
		#end
		}
	}

	function tokenString( t ) {
		return switch( t ) {
		case TEof: "<eof>";
		case TConst(c): constString(c);
		case TId(s): s;
		case TOp(s): s;
		case TPOpen: "(";
		case TPClose: ")";
		case TBrOpen: "{";
		case TBrClose: "}";
		case TDot: ".";
		case TComma: ",";
		case TSemicolon: ";";
		case TBkOpen: "[";
		case TBkClose: "]";
		case TQuestion: "?";
		case TDoubleDot: ":";
		case TMeta(id): "@" + id;
		}
	}

}
