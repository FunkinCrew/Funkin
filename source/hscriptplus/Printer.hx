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

class Printer {

	var buf : StringBuf;
	var tabs : String;

	public function new() {
	}

	public function exprToString( e : Expr ) {
		buf = new StringBuf();
		tabs = "";
		expr(e);
		return buf.toString();
	}

	inline function add<T>(s:T) buf.add(s);

	function type( t : CType ) {
		switch( t ) {
		case CTPath(path, params):
			add(path.join("."));
			if( params != null ) {
				add("<");
				var first = true;
				for( p in params ) {
					if( first ) first = false else add(", ");
					type(p);
				}
				add(">");
			}
		case CTFun(args, ret):
			if( args.length == 0 )
				add("Void -> ");
			else {
				for( a in args ) {
					type(a);
					add(" -> ");
				}
			}
			type(ret);
		case CTAnon(fields):
			add("{");
			var first = true;
			for( f in fields ) {
				if( first ) { first = false; add(" "); } else add(", ");
				add(f.name + " : ");
				type(f.t);
			}
			add(first ? "}" : " }");
		case CTParent(t):
			add("(");
			type(t);
			add(")");
		}
	}

	function addType( t : CType ) {
		if( t != null ) {
			add(":");
			type(t);
		}
	}

	function expr( e : Expr ) {
		if( e == null ) {
			add("??NULL??");
			return;
		}
		switch( #if hscriptPos e.e #else e #end ) {
		case EConst(c):
			switch( c ) {
			case CInt(i): add(i);
			case CFloat(f): add(f);
			case CString(s): add('"'); add(s.split('"').join('\\"').split("\n").join("\\n").split("\r").join("\\r").split("\t").join("\\t")); add('"');
			}
		case EIdent(v):
			add(v);
		case EVar(n, t, e):
			add("var " + n);
			addType(t);
			if( e != null ) {
				add(" = ");
				expr(e);
			}
		case EParent(e):
			add("("); expr(e); add(")");
		case EBlock(el):
			if( el.length == 0 ) {
				add("{}");
			} else {
				tabs += "\t";
				add("{\n");
				for( e in el ) {
					add(tabs);
					expr(e);
					add(";\n");
				}
				add("}");
				tabs = tabs.substr(1);
			}
		case EField(e, f):
			expr(e);
			add("." + f);
		case EBinop(op, e1, e2):
			expr(e1);
			add(" " + op + " ");
			expr(e2);
		case EUnop(op, pre, e):
			if( pre ) {
				add(op);
				expr(e);
			} else {
				expr(e);
				add(op);
			}
		case ECall(e, args):
			if( e == null )
				expr(e);
			else switch( #if hscriptPos e.e #else e #end ) {
			case EField(_), EIdent(_), EConst(_):
				expr(e);
			default:
				add("(");
				expr(e);
				add(")");
			}
			add("(");
			var first = true;
			for( a in args ) {
				if( first ) first = false else add(", ");
				expr(a);
			}
			add(")");
		case EIf(cond,e1,e2):
			add("if( ");
			expr(cond);
			add(" ) ");
			expr(e1);
			if( e2 != null ) {
				add(" else ");
				expr(e2);
			}
		case EWhile(cond,e):
			add("while( ");
			expr(cond);
			add(" ) ");
			expr(e);
		case EDoWhile(cond,e):
			add("do ");
			expr(e);
			add(" while ( ");
			expr(cond);
			add(" )");
		case EFor(v, it, e):
			add("for( "+v+" in ");
			expr(it);
			add(" ) ");
			expr(e);
		case EBreak:
			add("break");
		case EContinue:
			add("continue");
		case EFunction(params, e, name, ret):
			add("function");
			if( name != null )
				add(" " + name);
			add("(");
			var first = true;
			for( a in params ) {
				if( first ) first = false else add(", ");
				if( a.opt ) add("?");
				add(a.name);
				addType(a.t);
			}
			add(")");
			addType(ret);
			add(" ");
			expr(e);
		case EReturn(e):
			add("return");
			if( e != null ) {
				add(" ");
				expr(e);
			}
		case EArray(e,index):
			expr(e);
			add("[");
			expr(index);
			add("]");
		case EArrayDecl(el):
			add("[");
			var first = true;
			for( e in el ) {
				if( first ) first = false else add(", ");
				expr(e);
			}
			add("]");
		case ENew(cl, args):
			add("new " + cl + "(");
			var first = true;
			for( e in args ) {
				if( first ) first = false else add(", ");
				expr(e);
			}
			add(")");
		case EThrow(e):
			add("throw ");
			expr(e);
		case ETry(e, v, t, ecatch):
			add("try ");
			expr(e);
			add(" catch( " + v);
			addType(t);
			add(") ");
			expr(ecatch);
		case EObject(fl):
			if( fl.length == 0 ) {
				add("{}");
			} else {
				tabs += "\t";
				add("{\n");
				for( f in fl ) {
					add(tabs);
					add(f.name+":");
					expr(f.e);
					add(",\n");
				}
				tabs = tabs.substr(1);
				add("}");
			}
		case ETernary(c,e1,e2):
			expr(c);
			add(" ? ");
			expr(e1);
			add(" : ");
			expr(e2);
		case ESwitch(e, cases, def):
			add("switch( ");
			expr(e);
			add(") {");
			for( c in cases ) {
				add("case ");
				var first = true;
				for( v in c.values ) {
					if( first ) first = false else add(", ");
					expr(v);
				}
				add(": ");
				expr(c.expr);
				add(";\n");
			}
			if( def != null ) {
				add("default: ");
				expr(def);
				add(";\n");
			}
			add("}");
		case EMeta(name, args, e):
			add("@");
			add(name);
			if( args != null && args.length > 0 ) {
				add("(");
				var first = true;
				for( a in args ) {
					if( first ) first = false else add(", ");
					expr(e);
				}
				add(")");
			}
			add(" ");
			expr(e);

		case EPackage(path):
			add("package $path;");
		case EImport(path):
			add("import $path;");
		case EClass(name, e, baseClass):
			add('class $name');
			if (baseClass != null)
				add(' extends $baseClass');
			add(' {\n');
			tabs += "\t";
			expr(e);
			tabs = tabs.substr(1);
			add("}");
		}
	}

	public static function toString( e : Expr ) {
		return new Printer().exprToString(e);
	}

	public static function errorToString( e : Expr.Error ) {
		var message = switch( #if hscriptPos e.e #else e #end ) {
			case EInvalidChar(c): "Invalid character: '"+String.fromCharCode(c)+"' ("+c+")";
			case EUnexpected(s): "Unexpected token: \""+s+"\"";
			case EUnterminatedString: "Unterminated string";
			case EUnterminatedComment: "Unterminated comment";
			case EUnknownVariable(v): "Unknown variable: "+v;
			case EInvalidIterator(v): "Invalid iterator: "+v;
			case EInvalidOp(op): "Invalid operator: "+op;
			case EInvalidAccess(f): "Invalid access to field "+f;
		};
		#if hscriptPos
		return e.origin + ":" + e.line + ": " + message;
		#else
		return message;
		#end
	}


}
