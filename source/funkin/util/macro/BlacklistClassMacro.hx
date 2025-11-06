package funkin.util.macro;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Expr.Field;
import haxe.macro.Type;

using haxe.macro.ExprTools;
using haxe.macro.TypeTools;
using haxe.macro.ComplexTypeTools;
#end
using Lambda;
using StringTools;

enum abstract WrapMode(String) from String to String
{
  var Blacklist;
  var Whitelist;
}

typedef WrapperParams =
{
  /**
   * Classes to generate functions for.
   */
  var classes:Array<String>;

  /**
   * Aliases to functions, for instance `[ "getAnonymousField" => ["field"] ]` generates a `field` function that calls `getAnonymousField`.
   * It works in both ways, so you can generate aliases in the class that point to the ones in `classes` and vice-versa.
   */
  @:optional
  var aliases:Map<String, Array<String>>;

  /**
   * Defines how fields, whether part or apart of `wrapList`, are wrapped.
   * If it's `Whitelist` fields not in the list are blacklisted by default.
   *
   * @default `Whitelist`
   */
  @:optional
  var wrapMode:WrapMode;

  /**
   * Fields that you want to be wrapped differently depending on the value of `wrapMode`.
   * If a field is part of an alias or the ignore list, this will have no effect on it.
   */
  @:optional
  var wrapList:Array<String>;

  /**
   * Functions in `classes` that the macro should not generate.
   * If a function is part of an alias, this will have no effect on it.
   */
  @:optional
  var ignoreList:Array<String>;
}

#if macro
/**
 * Generates fields that wrap functions from the provided classes in a way that
 * they'll throw an error if accessed, or call the original function if whitelisted.
 * It is best to be used with classes with only static fields. Private fields and variables are always ignored.
 *
 * You can add your own sandboxed implementations of the fields and make aliases to them (see `BlacklistParams.aliases`).
 * Note that if the field already exists in `BlacklistParams.classes` you should add `@:blacklistOverride` to it.
 */
class BlacklistClassMacro
{
  /**
   * Documentation used by blacklisted functions.
   */
  static final BLACKLISTED_FUNCTION_DOC:String = 'This function is not allowed to be used by scripts.\n@throws error When called by a script.';

  static var buildFields:Array<Field>;
  static var processedFieldNames:Array<String> = [];

  static inline function containsField(fieldName:String):Bool
  {
    return buildFields.exists(f -> f.name == fieldName);
  }

  static inline function getField(fieldName:String):Null<Field>
  {
    return buildFields.find(f -> f.name == fieldName);
  }

  /**
   * Generates a sandboxed version of the fields of the classes provided.
   * @param params A set of parameters to customize the build macro.
   * @return The generated fields.
   */
  public static macro function build(params:ExprOf<WrapperParams>):Array<Field>
  {
    var params:WrapperParams = {
      classes: MacroUtil.extractObjectField(params, 'classes').getValue(),
      aliases: MacroUtil.extractMap(MacroUtil.extractObjectField(params, 'aliases')),
      wrapMode: extractStringEnum(MacroUtil.extractObjectField(params, 'wrapMode'), 'WrapMode') ?? Whitelist,
      wrapList: MacroUtil.extractObjectField(params, 'wrapList')?.getValue() ?? cast [],
    }

    final classes:Array<ClassType> = [for (c in params.classes) MacroUtil.getClassType(c)];

    if (classes.length == 0) Context.fatalError('Invalid class amount, no classes were provided.', Context.currentPos());
    buildFields = Context.getBuildFields();
    var generatedFields:Array<Field> = [];

    var fieldsToSkip:Array<String> = params.ignoreList?.copy() ?? [];
    var pendingFieldsToWrap:Array<String> = [];

    if (params.aliases != null)
    {
      generatedFields = generateAliases(params.aliases, pendingFieldsToWrap);
    }
    for (c in classes)
    {
      for (field in c.statics.get())
      {
        if (!field.isPublic || fieldsToSkip.contains(field.name) || ~/^(get|set)_/.match(field.name)) continue;
        if (containsField(field.name))
        {
          if (!getField(field.name).meta.exists(m -> m.name == ':blacklistOverride'))
          {
            // 'reportError' doesn't abort compilation, so it allows us to see all the duplicate fields!
            Context.reportError('Tried to generate "${field.name}" but it already exists in the class.\n'
              + 'Add @:blacklistOverride or add it to "ignoreList" to ignore.',
              getField(field.name).pos);
          }
          continue;
        }
        final blacklisted:Bool = (params.wrapMode == Whitelist) != params.wrapList.contains(field.name);
        final wrapper:Null<Field> = generateWrapperField(field.name, field, c.name, blacklisted);
        if (wrapper == null) continue; // Not a function
        generatedFields.push(wrapper);
        // TODO: When this happens should it make the field whitelisted (or vice-versa)?
        if (pendingFieldsToWrap.contains(field.name))
        {
          for (alias in params.aliases.get(field.name))
          {
            generatedFields.push(generateWrapperField(alias, wrapper));
            pendingFieldsToWrap.remove(field.name);
          }
        }
      }
    }
    for (f in pendingFieldsToWrap)
    {
      Context.reportError('Tried to generate alias fields for "$f" but it does not exist.', Context.currentPos());
    }
    return buildFields.concat(generatedFields);
  }

  static function generateAliases(aliases:Map<String, Array<String>>, ?unresolvedAliases:Array<String>):Array<Field>
  {
    var result:Array<Field> = [];

    for (field => aliasFields in aliases)
    {
      if (aliasFields.length == 0) Context.warning('No alias fields specified to be generated for "$field"', Context.currentPos());

      final wrappedField:Null<Field> = getField(field);
      if (wrappedField == null && unresolvedAliases != null)
      {
        // Field might be on the provided classes, put it on queue.
        unresolvedAliases.push(field);
        continue;
      }

      for (aliasName in aliasFields)
      {
        if (containsField(aliasName))
        {
          Context.error('Tried to generate "${aliasName}" alias but it already exists in the class.', getField(aliasName).pos);
        }

        final wrapper:Null<Field> = generateWrapperField(aliasName, wrappedField);
        if (wrapper != null)
        {
          result.push(wrapper);
          processedFieldNames.push(aliasName);
        }
        else
        {
          Context.error('Could not generate alias for field "$field"; it may not be a function.', wrappedField.pos);
        }
      }
    }

    return result;
  }

  static function generateWrapperField(fieldName:String, wrappedField:Dynamic, ?className:String, blacklist:Bool = false):Null<Field>
  {
    final pack:Array<String> = [wrappedField.name];
    if (className != null) pack.unshift(className);

    final access = [APublic, AStatic];

    var result:Field = {
      name: fieldName,
      pos: wrappedField.pos,
      doc: blacklist ? BLACKLISTED_FUNCTION_DOC : wrappedField.doc,
      access: access,
      kind: null // This will be filled later
    };

    function getWrapperExpr(args:Array<
      {name:String}>, ?retType:ComplexType):Expr
    {
      return if (blacklist)
      {
        macro throw $v{'Function ${pack.join('.')} is blacklisted.'};
      }
      else
      {
        final params:Array<Expr> = [for (a in args) macro $i{a.name}];
        retType.toString() == 'StdTypes.Void' ? macro $p{pack}($a{params}) : macro return $p{pack}($a{params});
      }
    }

    if (wrappedField.kind is FieldType)
    {
      switch (wrappedField.kind)
      {
        case FFun(f):
          final wrapFunc:Function = Reflect.copy(f);
          wrapFunc.expr = getWrapperExpr(wrapFunc.args, wrapFunc.ret);
          result.kind = FFun(wrapFunc);
        default:
          return Context.error('Blacklist Macro: Making wrappers for anything other than functions is not supported.', wrappedField.pos);
      }
    }
    else if (wrappedField.expr() != null)
    {
      switch (wrappedField.expr().expr)
      {
        case TFunction(tfunc):
          final tArgs:Array<FunctionArg> = [for (a in tfunc.args)
            {
              name: a.v.name,
              value: a.value != null ? Context.getTypedExpr(a.value) : null,
              type: a.v.t.toComplexType()
            }];
          result.kind = FFun({
            args: tArgs,
            params: getParamDecls(wrappedField.params),
            ret: tfunc.t.toComplexType(),
            expr: getWrapperExpr(tArgs, tfunc.t.toComplexType()),
          });
        default:
          return null;
      }
    }
    else
    {
      // Some targets have core types with externs as functions and those don't have a TypedExpr.
      // We perform Context.follow once to get rid of any TLazy type
      switch (Context.follow(wrappedField.type, true))
      {
        case TFun(args, ret):
          result.kind = FFun({
            args: [for (a in args) {name: a.name, opt: a.opt, type: a.t.toComplexType()}],
            params: getParamDecls(wrappedField.params),
            ret: ret.toComplexType(),
            expr: getWrapperExpr(args, ret.toComplexType())
          });
        default:
          return null;
      }
    }

    if (result.kind.match(FFun(_)))
    {
      access.push(AInline);
    }

    return result;
  }

  static function getParamDecls(params:Array<TypeParameter>):Array<TypeParamDecl>
  {
    final result:Array<TypeParamDecl> = [];
    for (p in params)
    {
      switch (p.t.getClass()?.kind)
      {
        case KTypeParameter(constraints):
          result.push({name: p.name, constraints: [for (c in constraints) c.toComplexType()]});
        default:
          Context.error("Provided type parameters are not of the KTypeParameter kind, this shouldn't happen!", Context.currentPos());
      }
    }
    return result;
  }

  static function extractStringEnum(input:Null<ExprOf<Enum<String>>>, enumTypeName:String):Null<String>
  {
    if (input == null) return null;

    switch (Context.typeof(input))
    {
      case TAbstract(_.get().name => name, _) if (name == enumTypeName):
      case exprType:
        Context.error('Unexpected type ${exprType.toString()}, wanted ${enumTypeName}', input.pos);
    }

    switch (input.expr)
    {
      case EConst(CIdent(mode)):
        return mode;
      default:
        Context.error('Invalid value for enum: ${input.toString()}', input.pos);
    }

    return null;
  }
}
#end
