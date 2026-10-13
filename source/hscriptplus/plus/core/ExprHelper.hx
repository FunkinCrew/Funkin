package hscriptplus.plus.core;

class ExprHelper {
    public static inline function getExprDef(e:Expr) {
		#if hscriptPos
		return e.e;
		#else
		return e;
		#end
	}
}