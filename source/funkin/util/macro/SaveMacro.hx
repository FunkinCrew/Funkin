package funkin.util.macro;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using haxe.macro.Tools;
#end

/**
 * Macros for simplifying SaveProperty creation and automatic initialization.
 */
@:nullSafety
class SaveMacro
{
  #if macro
  /**
   * Build macro that automatically generates SaveProperty initialization code.
   * Looks for fields with @:saveProperty metadata and generates initialization in constructor.
   */
  public static function buildSaveProperties():Array<Field>
  {
    var fields = Context.getBuildFields();
    var localClass = Context.getLocalClass().get();

    // Find all SaveProperty fields with metadata
    var savePropertyFields = [];
    for (field in fields)
    {
      if (isSavePropertyField(field) && hasSavePropertyMeta(field))
      {
        savePropertyFields.push(field);
      }
    }

    if (savePropertyFields.length == 0)
    {
      return fields; // No SaveProperty fields to process
    }

    // Generate initialization expressions
    var initExprs = [];
    for (field in savePropertyFields)
    {
      var initExpr = generateInitExpression(field);
      if (initExpr != null)
      {
        initExprs.push(initExpr);
      }
    }

    // Inject initialization into constructor
    if (initExprs.length > 0)
    {
      injectIntoConstructor(fields, initExprs);
    }

    return fields;
  }

  static function isSavePropertyField(field:Field):Bool
  {
    return switch (field.kind)
    {
      case FVar(t, _):
        switch (t)
        {
          case TPath(p): p.name == "SaveProperty";
          case _: false;
        }
      case _: false;
    };
  }

  static function hasSavePropertyMeta(field:Field):Bool
  {
    if (field.meta == null) return false;
    for (meta in field.meta)
    {
      if (meta.name == ":saveProperty") return true;
    }
    return false;
  }

  static function generateInitExpression(field:Field):Null<Expr>
  {
    if (field.meta == null) return null;

    var meta = null;
    for (m in field.meta)
    {
      if (m.name == ":saveProperty")
      {
        meta = m;
        break;
      }
    }

    if (meta == null || meta.params == null || meta.params.length == 0)
    {
      Context.error("@:saveProperty metadata requires at least one parameter (dataPath)", field.pos);
      return null;
    }

    // Parse the data path string and convert to expression
    var dataPath = parseDataPath(meta.params[0]);
    var defaultValue = meta.params.length > 1 ? meta.params[1] : null;

    var initExpr = if (defaultValue != null)
    {
      macro $i{field.name} = new funkin.save.SaveProperty($dataPath ?? $defaultValue, () -> $dataPath ?? $defaultValue, (value) -> $dataPath = value);
    }
    else
    {
      macro $i{field.name} = new funkin.save.SaveProperty($dataPath, () -> $dataPath, (value) -> $dataPath = value);
    };

    return initExpr;
  }

  static function parseDataPath(pathExpr:Expr):Expr
  {
    // Just return the expression as-is since we're no longer using string literals
    return pathExpr;
  }

  static function injectIntoConstructor(fields:Array<Field>, initExprs:Array<Expr>):Void
  {
    for (field in fields)
    {
      if (field.name == "new")
      {
        switch (field.kind)
        {
          case FFun(func):
            // Find where to inject - after data assignment but before other calls
            switch (func.expr.expr)
            {
              case EBlock(exprs):
                // Look for "this.data = ..." assignment
                var insertIndex = 1; // Default to after first statement
                for (i in 0...exprs.length)
                {
                  switch (exprs[i].expr)
                  {
                    case EBinop(OpAssign, {expr: EField({expr: EConst(CIdent("this"))}, "data")}, _):
                      insertIndex = i + 1;
                      break;
                    case _:
                  }
                }

                // Insert initialization expressions at the calculated position
                var newExprs = exprs.slice(0, insertIndex).concat(initExprs).concat(exprs.slice(insertIndex));

                func.expr = {expr: EBlock(newExprs), pos: func.expr.pos};

              case _:
                Context.error("Constructor must have a block expression", field.pos);
            }
          case _:
        }
        break;
      }
    }
  }
  #end
}
