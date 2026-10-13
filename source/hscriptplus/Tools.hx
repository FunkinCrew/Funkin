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

class Tools {

	public static function iter( e : Expr, f : Expr -> Void ) {
		switch( e ) {
		case EClass(_, e, _): f(e);
		case EPackage(_), EImport(_), EConst(_), EIdent(_):
		case EVar(_, _, e): if( e != null ) f(e);
		case EParent(e): f(e);
		case EBlock(el): for( e in el ) f(e);
		case EField(e, _): f(e);
		case EBinop(_, e1, e2): f(e1); f(e2);
		case EUnop(_, _, e): f(e);
		case ECall(e, args): f(e); for( a in args ) f(a);
		case EIf(c, e1, e2): f(c); f(e1); if( e2 != null ) f(e2);
		case EWhile(c, e): f(c); f(e);
		case EDoWhile(c, e): f(c); f(e);
		case EFor(_, it, e): f(it); f(e);
		case EBreak,EContinue:
		case EFunction(_, e, _, _): f(e);
		case EReturn(e): if( e != null ) f(e);
		case EArray(e, i): f(e); f(i);
		case EArrayDecl(el): for( e in el ) f(e);
		case ENew(_,el): for( e in el ) f(e);
		case EThrow(e): f(e);
		case ETry(e, _, _, c): f(e); f(c);
		case EObject(fl): for( fi in fl ) f(fi.e);
		case ETernary(c, e1, e2): f(c); f(e1); f(e2);
		case ESwitch(e, cases, def):
			f(e);
			for( c in cases ) {
				for( v in c.values ) f(v);
				f(c.expr);
			}
			if( def != null ) f(def);
		case EMeta(name, args, e): if( args != null ) for( a in args ) f(a); f(e);
		}
	}

	public static function map( e : Expr, f : Expr -> Expr ) {
		return switch( e ) {
		case EClass(name, e, baseClass): EClass(name, f(e), baseClass);
		case EPackage(_), EImport(_), EConst(_), EIdent(_): e;
		case EVar(n, t, e): EVar(n, t, if( e != null ) f(e) else null);
		case EParent(e): EParent(f(e));
		case EBlock(el): EBlock([for( e in el ) f(e)]);
		case EField(e, fi): EField(f(e),fi);
		case EBinop(op, e1, e2): EBinop(op, f(e1), f(e2));
		case EUnop(op, pre, e): EUnop(op, pre, f(e));
		case ECall(e, args): ECall(f(e),[for( a in args ) f(a)]);
		case EIf(c, e1, e2): EIf(f(c),f(e1),if( e2 != null ) f(e2) else null);
		case EWhile(c, e): EWhile(f(c),f(e));
		case EDoWhile(c, e): EDoWhile(f(c),f(e)); 
		case EFor(v, it, e): EFor(v, f(it), f(e));
		case EBreak, EContinue: e;
		case EFunction(args, e, name, t): EFunction(args, f(e), name, t);
		case EReturn(e): EReturn(if( e != null ) f(e) else null);
		case EArray(e, i): EArray(f(e),f(i));
		case EArrayDecl(el): EArrayDecl([for( e in el ) f(e)]);
		case ENew(cl,el): ENew(cl,[for( e in el ) f(e)]);
		case EThrow(e): EThrow(f(e));
		case ETry(e, v, t, c): ETry(f(e), v, t, f(c));
		case EObject(fl): EObject([for( fi in fl ) { name : fi.name, e : f(fi.e) }]);
		case ETernary(c, e1, e2): ETernary(f(c), f(e1), f(e2));
		case ESwitch(e, cases, def): ESwitch(f(e), [for( c in cases ) { values : [for( v in c.values ) f(v)], expr : f(c.expr) } ], def == null ? null : f(def));
		case EMeta(name, args, e): EMeta(name, args == null ? null : [for( a in args ) f(a)], f(e));
		}
	}

}