package funkin.util.macro;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type.ClassType;

using haxe.macro.ExprTools;
using haxe.macro.TypeTools;
using thx.Arrays;

/**
 * This macro creates necessary pooling fields for script events.
 */
class ScriptEventPoolMacro
{
  /**
   * A meta to indicate that pooling functions have been added.
   */
  public static final PROCESSED_META:String = ':hasBuiltPool';

  public static macro function buildPool():Array<Field>
  {
    var cls:ClassType = Context.getLocalClass().get();
    if (cls.meta.has(PROCESSED_META)) return null;

    var pos:Position = Context.currentPos();
    var buildFields:Array<Field> = Context.getBuildFields().copy();

    cls.meta.add(PROCESSED_META, [], pos);

    var retType:ComplexType = Context.getType('${cls.module}.${cls.name}').toComplexType();
    buildFields.push({
      name: 'pool',
      doc: 'The pool of the events to recycle events from.',
      access: [APublic, AStatic],
      pos: pos,
      kind: FVar(macro :Array<$retType>, {
        expr: EArrayDecl([]),
        pos: pos
      })
    });

    var constructor:Null<Field> = buildFields.find((fld) -> fld.name == 'new');
    if (constructor == null)
    {
      Context.error('ScriptEventPoolMacro: Missing constructor for ${cls.name}.', pos);
      return null;
    }

    switch (constructor?.kind)
    {
      case FFun(f):
        var argNames:Array<Expr> = [for (arg in f.args) macro $i{arg.name}];
        var name:String = cls.pack.copy().concat([cls.name]).join('.');

        // To create the resetting function, the expression of the constructor is copied and the 'super(args)' part is replaced with an appropriate reset function.
        // The exception to this is `ScriptEvent`, whose constructor can be copied over without any adjustments, as it doesn't extend anything.
        var resetFunction:String = 'reset_${cls.name}';
        var resetExpr:Expr = {
          expr: f.expr.expr,
          pos: pos
        };

        if (cls.superClass != null)
        {
          switch (resetExpr.expr)
          {
            case EBlock(exprs):
              var exprArray:Array<Expr> = exprs.copy();

              for (i in 0...exprArray.length)
              {
                switch (exprArray[i].expr)
                {
                  case ECall(e, params) if (Type.enumEq(e.expr, EConst(CIdent('super')))):
                    exprArray[i] = {
                      pos: exprArray[i].pos,
                      expr: ECall({
                        pos: e.pos,
                        expr: EConst(CIdent('reset_${cls.superClass.t.get().name}'))
                      }, params)
                    }
                    break;
                  default:
                }
              }

              resetExpr.expr = EBlock(exprArray);
            case ECall(e, params) if (Type.enumEq(e.expr, EConst(CIdent('super')))):
              resetExpr.expr = ECall({
                pos: e.pos,
                expr: EConst(CIdent('reset_${cls.superClass.t.get().name}'))
              }, params);

            default:
              Context.error('ScriptEventPoolMacro: The constructor for $name must be either a block or a super() call.', pos);
              return null;
          }
        }

        buildFields.push({
          name: resetFunction,
          doc: 'An alternative way of resetting an event without calling the constructor.',
          access: [APrivate],
          pos: pos,
          kind: FFun({
            args: f.args,
            ret: f.ret,
            params: f.params,
            expr: resetExpr
          })
        });

        buildFields.push({
          name: 'get',
          doc: 'Returns a recycled instance of an event, if possible.\nIf not, creates a new event and adds it to the pool.',
          access: [APublic, AStatic],
          pos: pos,
          kind: FFun({
            args: f.args,
            ret: retType,
            params: f.params,
            expr: macro
            {
              var event = null;
              for (item in pool)
              {
                if (!item.hasBeenUsed)
                {
                  event = item;
                  event.hasBeenUsed = true;
                  event.$resetFunction($a{argNames});
                  return event;
                }
              }

              event = Type.createInstance(Type.resolveClass($v{name}), [$a{argNames}]);
              if (event == null) throw 'Couldn\'t instantiate the event class ' + $v{name};

              event.hasBeenUsed = true;
              pool.push(event);
              return event;
            }
          })
        });

      default:
        Context.error('ScriptEventPoolMacro: Incorrect type of constructor for ${cls.name}, expected a function.', pos);
        return null;
    }

    return buildFields;
  }
}
#end
