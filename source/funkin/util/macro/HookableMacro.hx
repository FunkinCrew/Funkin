package funkin.util.macro;

import haxe.macro.Context;
import haxe.macro.Expr;

using Lambda;

class HookableMacro
{
	/**
	 * The @:hookable annotation replaces a given function with a variable that contains a function.
	 * It's still callable, like normal, but now you can also replace the value! Neat!
	 * 
	 * NOTE: If you receive the following error when making a function use @:hookable:
	 *   `Cannot access this or other member field in variable initialization`
	 *   This is because you need to perform calls and assignments using a static variable referencing the target object.
	 */
	public static macro function build():Array<Field>
	{
		Context.info('Running HookableMacro...', Context.currentPos());

		var cls:haxe.macro.Type.ClassType = Context.getLocalClass().get();
		var fields:Array<Field> = Context.getBuildFields();
		// Find all fields with @:hookable metadata
		for (field in fields)
		{
			if (field.meta == null)
				continue;
			var scriptable_meta = field.meta.find(function(m) return m.name == ':hookable');
			if (scriptable_meta != null)
			{
				Context.info('  @:hookable annotation found on field ${field.name}', Context.currentPos());
				switch (field.kind)
				{
					case FFun(originalFunc):
						// This is the type of the function, like (Int, Int) -> Int
						var replFieldTypeRet:ComplexType = originalFunc.ret == null ? Context.toComplexType(Context.getType('Void')) : originalFunc.ret;
						var replFieldType:ComplexType = TFunction([for (arg in originalFunc.args) arg.type], replFieldTypeRet);
						// This is the expression of the function, i.e. the function body.

						var replFieldExpr:ExprDef = EFunction(FAnonymous, {
							ret: originalFunc.ret,
							params: originalFunc.params,
							args: originalFunc.args,
							expr: originalFunc.expr
						});

						var replField:Field = {
							name: field.name,
							doc: field.doc,
							access: field.access,
							pos: field.pos,
							meta: field.meta,
							kind: FVar(replFieldType, {
								expr: replFieldExpr,
								pos: field.pos
							}),
						};

						// Replace the original field with the new field
						fields[fields.indexOf(field)] = replField;
					default:
						Context.error('@:hookable can only be used on functions', field.pos);
				}
			}
		}

		return fields;
	}
}
