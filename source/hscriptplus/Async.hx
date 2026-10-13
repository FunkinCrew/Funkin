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

class Async {

	var varNames : Array<String>;
	var currentFun : String;
	var currentLoop : hscriptplus.Expr;
	var currentBreak : hscriptplus.Expr;
	var uid = 0;

	/**
		Convert a script into asynchronous one.
		- calls such as foo(a,b,c) are translated to a_foo(function(r) ...rest, a,b,c) where r is the result value
		- object access such obj.bar(a,b,c) are translated to obj.a_bar(function(r) ...rest, a, b, c)
		- @async expr will execute the expression but continue without waiting for it to finish
		- @split [ e1, e2, e3 ] is transformed to split(function(_) ...rest, [e1, e2, e3]) which
		  should execute asynchronously all expressions - until they return - before continuing the execution
		- for(i in v) block; loops are translated to the following:
			var _i = makeIterator(v);
			function _loop() {
				if( !_i.hasNext() ) return;
				var v = _i.next();
				block(function(_) _loop());
			}
			_loop()
		- while loops are translated similar to for loops
		- break and continue are correctly handled
		- you can use @sync <expr> to disable async transformation in some code parts (for performance reason)
		- a few expressions are still not supported (complex calls, try/catch, and a few others)

		In these examples ...rest represents the continuation of execution of the script after the expression
	**/
	public static function toAsync( e : Expr, topLevelSync = false ) {
		var a = new Async();
		return a.build(e, topLevelSync);
	}

	public function build( e : Expr, topLevelSync = false ) {
		if( topLevelSync ) {
			return buildSync(e);
		} else {
			var nothing = ignore();
			return new Async().toCps(e, nothing, nothing);
		}
	}

	function buildSync( e : Expr ) {
		switch( e ) {
		case EFunction(_):
			return toCps(e, null, null);
		case EBlock(el):
			var v = saveVars();
			for( e in el )
				switch( e ) {
				case EFunction(_, _, name, _) if( name != null ): varNames.push(name);
				default:
				}
			var e = EBlock([for(e in el) buildSync(e)]);
			restoreVars(v);
			return e;
		case EMeta("async", _, e):
			return toCps(e, ignore(), ignore());
		default:
			return hscriptplus.Tools.map(e, buildSync);
		}
	}

	public function new() {
		varNames = [];
	}

	function ignore(?e) {
		return EFunction([{ name : "_", t : null }], EBlock(e == null ? [] : [e]));
	}

	function retNull(e) {
		return ECall(e, [EIdent("null")]);
	}

	function makeCall( ecall, args : Array<hscriptplus.Expr>, rest : hscriptplus.Expr, exit, sync = false ) {
		var names = [for( i in 0...args.length ) "_a"+uid++];
		var rargs = [for( i in 0...args.length ) EIdent(names[i])];
		if( !sync )
			rargs.unshift(rest);
		var rest = sync ? ECall(rest,[ECall(ecall, rargs)]) : ECall(ecall, rargs);
		var i = args.length - 1;
		while( i >= 0 ) {
			rest = toCps(args[i], EFunction([ { name : names[i], t : null } ], rest), exit);
			i--;
		}
		return rest;
	}

	var syncFlag : Bool;

	function isSync( e : Expr ) {
		syncFlag = true;
		checkSync(e);
		return syncFlag;
	}

	function checkSync( e : Expr ) {
		if( !syncFlag )
			return;
		switch( e ) {
		case ECall(_), EFunction(_):
			syncFlag = false;
		case EReturn(_):
			// require specific handling to pass it to exit expr
			syncFlag = false;
		case EMeta("sync" | "async", _, _):
			// isolated from the sync part
		default:
			Tools.iter(e, checkSync);
		}
	}

	function saveVars() {
		return varNames.length;
	}

	function restoreVars(k) {
		while( varNames.length > k ) varNames.pop();
	}

	public function toCps( e : hscriptplus.Expr, rest : hscriptplus.Expr, exit : hscriptplus.Expr ) {
		if( isSync(e) )
			return ECall(rest, [buildSync(e)]);
		switch( e ) {
		case EBlock(el):
			var el = el.copy();
			var vold = saveVars();
			// local recursion
			for( e in el )
				switch( e ) {
				case EFunction(_, _, name, null): varNames.push(name);
				default:
				}
			while( el.length > 0 ) {
				var e = toCps(el.pop(), rest, exit);
				rest = ignore(e);
			}
			restoreVars(vold);
			return retNull(rest);
		case EFunction(args, body, name, t):
			var vold = saveVars();
			if( name != null )
				varNames.push(name);
			for( a in args )
				varNames.push(a.name);
			args.unshift( { name : "_onEnd", t : null } );
			var frest = EIdent("_onEnd");
			var oldFun = currentFun;
			currentFun = name;
			var body = toCps(body, frest, frest);
			var f = EFunction(args, body, name, t);
			restoreVars(vold);
			return rest == null ? f : ECall(rest, [f]);
		case EParent(e):
			return EParent(toCps(e, rest, exit));
		case EMeta("sync", _, e):
			return ECall(rest,[buildSync(e)]);
		case EMeta("async", _, e):
			var nothing = ignore();
			return EBlock([toCps(e,nothing,nothing),retNull(rest)]);
		case EMeta("split", _, e):
			var args = switch( e ) { case EArrayDecl(el): el; default: throw "@split expression should be an array"; };
			var args = [for( a in args ) EFunction([ { name : "_rest", t : null } ], toCps(EBlock([a]), EIdent("_rest"), exit))];
			return ECall(EIdent("split"), [rest, EArrayDecl(args)]);
		case ECall(EIdent(i), args):
			return makeCall( EIdent( varNames.indexOf(i) < 0 ? "a_" + i : i) , args, rest, exit);
		case ECall(EField(e, f), args):
			return makeCall(EField(e,"a_"+f), args, rest, exit);
		case EFor(v, eit, e):
			var id = ++uid;
			var it = EIdent("_i" + id);
			var oldLoop = currentLoop, oldBreak = currentBreak;
			var loop = EIdent("_loop" + id);
			currentLoop = loop;
			currentBreak = EBlock([ECall(rest, [EIdent("null")]), EReturn()]);
			var e = EBlock([
				EVar("_i" + id, ECall(EIdent("makeIterator"),[eit])),
				EFunction([{ name : "_", t : null }], EBlock([
					EIf(EUnop("!", true, ECall(EField(it, "hasNext"), [])), currentBreak),
					EVar(v, ECall(EField(it, "next"), [])),
					toCps(e, loop, exit),
				]),"_loop" + id),
				ECall(loop, [EIdent("null")]),
			]);
			currentLoop = oldLoop;
			currentBreak = oldBreak;
			return e;
		case EUnop(op = "!", prefix, e):
			return toCps(e, EFunction([ { name:"_r", t:null } ], ECall(rest, [EUnop(op, prefix, EIdent("_r"))])), exit);
		case EBinop(op, e1, e2):
			switch( op ) {
			case "=", "+=", "-=", "/=", "*=", "%=", "&=", "|=", "^=":
				switch( e1 ) {
				case EIdent(_):
					var id = "_r" + uid++;
					return toCps(e2, EFunction([ { name:id, t:null } ], ECall(rest, [EBinop(op, e1, EIdent(id))])), exit);
				case EField(e1, f):
					var id1 = "_r" + uid++;
					var id2 = "_r" + uid++;
					return toCps(e1, EFunction([ { name:id1, t:null } ], toCps(e2, EFunction([ { name : id2, t : null } ], ECall(rest, [EBinop(op, EField(EIdent(id1),f), EIdent(id2))])), exit)), exit);
				case EArray(earr, eindex):
					var idArr = "_r" + uid++;
					var idIndex = "_r" + uid++;
					var idVal = "_r" + uid++;
					return toCps(earr,
						EFunction([ { name:idArr, t:null } ], toCps(eindex,
							EFunction([ { name : idIndex, t : null } ], toCps(e2,
								EFunction([ { name : idVal, t : null } ],
									ECall(rest, [EBinop(op, EArray(EIdent(idArr), EIdent(idIndex)), EIdent(idVal))])
								), exit)
							), exit)
						),exit);
				default:
					throw "assert " + e1;
				}
			case "||":
				var id1 = "_r" + uid++;
				var id2 = "_r" + uid++;
				return toCps(e1, EFunction([ { name:id1, t:null } ], EIf(EBinop("==", EIdent(id1), EIdent("true")),ECall(rest,[EIdent("true")]),toCps(e2, rest, exit))), exit);
			case "&&":
				var id1 = "_r" + uid++;
				var id2 = "_r" + uid++;
				return toCps(e1, EFunction([ { name:id1, t:null } ], EIf(EBinop("!=", EIdent(id1), EIdent("true")),ECall(rest,[EIdent("false")]),toCps(e2, rest, exit))), exit);
			default:
				var id1 = "_r" + uid++;
				var id2 = "_r" + uid++;
				return toCps(e1, EFunction([ { name:id1, t:null } ], toCps(e2, EFunction([ { name : id2, t : null } ], ECall(rest, [EBinop(op, EIdent(id1), EIdent(id2))])), exit)), exit);
			}
		case EIf(cond, e1, e2), ETernary(cond, e1, e2):
			return toCps(cond, EFunction([ { name : "_c", t : null } ], EIf(EIdent("_c"), toCps(e1, rest, exit), e2 == null ? retNull(rest) : toCps(e2, rest, exit))), exit);
		case EWhile(cond, e):
			var id = ++uid;
			var loop = EIdent("_loop" + id);
			var oldLoop = currentLoop, oldBreak = currentBreak;
			currentLoop = loop;
			currentBreak = EBlock([ECall(rest, [EIdent("null")]), EReturn()]);
			var ewhile = EBlock([
				EFunction([{ name : "_r", t : null }],
					toCps(cond, EFunction([ { name : "_c", t : null } ], EIf(EIdent("_c"), toCps(e, loop, exit), ECall(rest,[EIdent("null")]))), exit)
				, "_loop"+id),
				ECall(loop, [EIdent("null")]),
			]);
			currentLoop = oldLoop;
			currentBreak = oldBreak;
			return ewhile;
		case EReturn(e):
			return e == null ? ECall(exit, [EIdent("null")]) : toCps(e, exit, exit);
		case EObject(fields):
			var id = "_o" + uid++;
			var rest = ECall(rest, [EIdent(id)]);
			fields.reverse();
			for( f in fields )
				rest = toCps(f.e, EFunction([ { name : "_r", t : null } ], EBlock([
					EBinop("=", EField(EIdent(id), f.name), EIdent("_r")),
					rest,
				])),exit);
			return EBlock([
				EVar(id, EObject([])),
				rest,
			]);
		case EArrayDecl(el):
			var id = "_a" + uid++;
			var rest = ECall(rest, [EIdent(id)]);
			var i = el.length - 1;
			while( i >= 0 ) {
				rest = toCps(el[i], EFunction([ { name : "_r", t : null } ], EBlock([
					EBinop("=", EArray(EIdent(id), EConst(CInt(i))), EIdent("_r")),
					rest,
				])), exit);
				i--;
			}
			return EBlock([
				EVar(id, EArrayDecl([])),
				rest,
			]);
		case EArray(e, eindex):
			var id1 = "_r" + uid++;
			var id2 = "_r" + uid++;
			return toCps(e, EFunction([ { name:id1, t:null } ], toCps(eindex, EFunction([ { name : id2, t : null } ], ECall(rest, [EArray(EIdent(id1), EIdent(id2))])), exit)), exit);
		case EVar(v, t, ev):
			if( ev == null )
				return EBlock([e, ECall(rest, [EIdent("null")])]);
			return EBlock([
				EVar(v, t),
				toCps(ev, EFunction([ { name : "_r", t : null } ], EBlock([
					EBinop("=", EIdent(v), EIdent("_r")),
					ECall(rest,[EIdent("null")]),
				])), exit),
			]);
		case EConst(_), EIdent(_), EUnop(_), EField(_):
			return ECall(rest, [e]);
		case ENew(cl, args):
			var names = [for( i in 0...args.length ) "_a"+uid++];
			var rargs = [for( i in 0...args.length ) EIdent(names[i])];
			var rest = ECall(rest,[ENew(cl, rargs)]);
			var i = args.length - 1;
			while( i >= 0 ) {
				rest = toCps(args[i], EFunction([ { name : names[i], t : null } ], rest), exit);
				i--;
			}
			return rest;
		case EBreak:
			if( currentBreak == null ) throw "Break outside loop";
			return currentBreak;
		case EContinue:
			if( currentLoop == null ) throw "Continue outside loop";
			return EBlock([ECall(currentLoop, [EIdent("null")]), EReturn()]);
		case ESwitch(v, cases, def):
			var cases = [for( c in cases ) { values : c.values, expr : toCps(c.expr, rest, exit) } ];
			return toCps(v, EFunction([ { name : "_c", t : null } ], ESwitch(EIdent("_c"), cases, def == null ? retNull(rest) : toCps(def, rest, exit))), exit );
		case EThrow(v):
			return toCps(v, EFunction([ { name : "_v", t : null } ], EThrow(v)), exit);
		//case EDoWhile(_), ETry(_), ECall(_):
		default:
			throw "Unsupported async expression " + Printer.toString(e);
		}
	}

}


class AsyncInterp extends hscriptplus.Interp {

	public function setContext( api : Dynamic ) {

		var funs = new Array();
		for( v in variables.keys() )
			if( Reflect.isFunction(variables.get(v)) )
				funs.push({ v : v, obj : null });

		variables.set("split", split);
		variables.set("makeIterator", makeIterator);

		var c = Type.getClass(api);
		for( f in (c == null ? Reflect.fields(api) : Type.getInstanceFields(c)) ) {
			var fv = Reflect.field(api, f);
			if( !Reflect.isFunction(fv) ) continue;
			if( f.charCodeAt(0) == "_".code ) f = f.substr(1);
			variables.set(f, fv);
			// create the async wrapper if doesn't exists
			if( f.substr(0, 2) != "a_" )
				funs.push({ v : f, obj : api });
		}

		for( v in funs ) {
			if( variables.exists("a_" + v.v) ) continue;
			var fv : Dynamic = variables.get(v.v);
			var obj = v.obj;
			variables.set("a_" + v.v, Reflect.makeVarArgs(function(args:Array<Dynamic>) {
				var onEnd = args.shift();
				onEnd(Reflect.callMethod(obj, fv, args));
			}));
		}
	}

	public function hasMethod( name : String ) {
		var v = variables.get(name);
		return v != null && Reflect.isFunction(v);
	}

	public function callValue( value : Dynamic, args : Array<Dynamic>, ?onResult : Dynamic -> Void, ?vthis : {} ) {
		var oldThis = variables.get("this");
		if( vthis != null )
			variables.set("this", vthis);
		if( onResult == null )
			onResult = function(_) {};
		args.unshift(onResult);
		Reflect.callMethod(null, value, args);
		variables.set("this", oldThis);
	}

	public function callAsync( id : String, args, ?onResult, ?vthis : {} ) {
		var v = variables.get(id);
		if( v == null )
			throw "Missing function " + id + "()";
		callValue(v, args, onResult, vthis);
	}

	function split( rest : Dynamic -> Void, args : Array<Dynamic> ) {
		if( args.length == 0 )
			rest(null);
		else {
			var count = args.length;
			function next(_) {
				if( --count == 0 ) rest(null);
			}
			for( a in args )
				a(next);
		}
	}

	override function fcall( o : Dynamic, f : String, args : Array<Dynamic> ) : Dynamic {
		var m = Reflect.field(o, f);
		if( m == null ) {
			if( f.substr(0, 2) == "a_" ) {
				m = Reflect.field(o, f.substr(2));
				// fallback on sync version
				if( m != null ) {
					var onEnd = args.shift();
					onEnd(call(o, m, args));
					return null;
				}
				// fallback on generic script
				m = Reflect.field(o, "scriptCall");
				if( m != null ) {
					call(o, m, [args.shift(), f.substr(2), args]);
					return null;
				}
			} else {
				// fallback on generic script
				m = Reflect.field(o, "scriptCall");
				if( m != null ) {
					var result : Dynamic = null;
					call(o, m, [function(r) result = r, f, args]);
					return result;
				}
			}
			throw o + " has no method " + f;
		}
		return call(o, m, args);
	}

}
