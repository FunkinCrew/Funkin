package funkin.util.macro;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr.Position;
import haxe.macro.Type;
import haxe.macro.TypedExprTools;
#end

/**
 * Auto prune classes that are brought into the type table through imports (that are not used by any script class) when compiling with cppia.
 **/
class CppiaPruneMacro
{
  #if macro
  static var host:Map<String, Bool>;
  static var reached:Map<String, Bool>;
  static var via:Map<String, {from:String, pos:Position}>;
  static var queue:Array<Void->Void>;

  /**
   * @param roots The module paths whose types are always kept.
   */
  public static function register(roots:Array<String>):Void
  {
    Context.onGenerate(function(types:Array<Type>) prune(types, roots));
  }

  static function prune(types:Array<Type>, roots:Array<String>):Void
  {
    host = readHost();
    if (host == null)
    {
      Context.warning('Found no dll_import class list, nothing was pruned.', Context.currentPos());
      return;
    }

    reached = new Map<String, Bool>();
    via = new Map<String, {from:String, pos:Position}>();
    queue = [];

    var rootModules:Map<String, Bool> = [for (r in roots) r => true];
    rootModules.set('PolymodCppiaManifest', true);
    rootModules.set('cpp.cppia.HostClasses', true);

    for (type in types)
    {
      switch (type)
      {
        case TInst(ref, _):
          var c:ClassType = ref.get();
          if (rootModules.exists(c.module) || isRuntimeSupport(c.pack)) markClass(c, '<root>', c.pos);
        case TEnum(ref, _):
          var e:EnumType = ref.get();
          if (rootModules.exists(e.module) || isRuntimeSupport(e.pack)) markEnum(e, '<root>', e.pos);
        default:
      }
    }

    while (queue.length > 0)
      queue.pop()();

    var pruned:Int = 0;

    for (type in types)
    {
      switch (type)
      {
        case TInst(ref, _):
          var name:String = nameOf(ref.get().pack, ref.get().name);
          if (host.exists(name) || reached.exists(name)) continue;
          ref.get().exclude();
          pruned++;
        case TEnum(ref, _):
          var name:String = nameOf(ref.get().pack, ref.get().name);
          if (host.exists(name) || reached.exists(name)) continue;
          ref.get().exclude();
          pruned++;
        default:
      }
    }

    Sys.println('[cppia] pruned $pruned type(s) no script class reaches.');

    var why:String = Context.definedValue('cppia_why');
    if (why != null) for (name in why.split(',')) explain(StringTools.trim(name));
  }

  static function explain(name:String):Void
  {
    if (!via.exists(name))
    {
      Sys.println('[cppia] $name is not referenced by any script class.');
      return;
    }

    var current:String = name;
    var seen:Map<String, Bool> = new Map<String, Bool>();

    while (via.exists(current) && !seen.exists(current))
    {
      seen.set(current, true);
      var link = via.get(current);
      Context.warning('$current is used by ${link.from}', link.pos);
      current = link.from;
    }
  }

  static function isRuntimeSupport(pack:Array<String>):Bool
  {
    return pack.length >= 2 && pack[0] == 'haxe' && pack[1] == 'lang';
  }

  static function readHost():Null<Map<String, Bool>>
  {
    var path:String = Context.definedValue('dll_import');
    if (path == null || path == '1' || !sys.FileSystem.exists(path)) return null;

    var result:Map<String, Bool> = new Map<String, Bool>();
    for (name in @:privateAccess cpp.cppia.HostClasses.classes)
      result.set(name, true);

    for (line in sys.io.File.getContent(path).split('\n'))
    {
      var parts:Array<String> = StringTools.trim(line).split(' ');
      if (parts.length < 2) continue;
      if (parts[0] == 'class' || parts[0] == 'interface' || parts[0] == 'enum') result.set(parts[1], true);
    }

    return result;
  }

  static function note(name:String, from:String, pos:Position):Bool
  {
    if (reached.exists(name)) return false;
    reached.set(name, true);
    via.set(name, {from: from, pos: pos});
    return true;
  }

  static function markClass(c:ClassType, from:String, pos:Position):Void
  {
    var name:String = nameOf(c.pack, c.name);
    if (!note(name, from, pos)) return;
    if (c.isExtern || host.exists(name)) return;

    queue.push(function() walkClass(c, name));
  }

  static function markEnum(e:EnumType, from:String, pos:Position):Void
  {
    var name:String = nameOf(e.pack, e.name);
    if (!note(name, from, pos)) return;
    if (e.isExtern || host.exists(name)) return;

    queue.push(function() {
      for (ef in e.constructs)
        visitType(ef.type, name, ef.pos);
    });
  }

  static function walkClass(c:ClassType, name:String):Void
  {
    if (c.superClass != null) markClass(c.superClass.t.get(), name, c.pos);
    for (i in c.interfaces)
      markClass(i.t.get(), name, c.pos);

    var fields:Array<ClassField> = c.fields.get().concat(c.statics.get());
    if (c.constructor != null) fields.push(c.constructor.get());

    for (cf in fields)
    {
      walkField(cf, name);
      for (o in cf.overloads.get())
        walkField(o, name);
    }

    if (c.init != null) walkExpr(c.init, name);

    switch (c.kind)
    {
      case KAbstractImpl(a):
        visitType(a.get().type, name, c.pos);
      default:
    }
  }

  static function walkField(cf:ClassField, owner:String):Void
  {
    visitType(cf.type, owner, cf.pos);
    walkExpr(cf.expr(), owner);
  }

  static function walkExpr(e:Null<TypedExpr>, owner:String):Void
  {
    if (e == null) return;

    visitType(e.t, owner, e.pos);

    switch (e.expr)
    {
      case TTypeExpr(m):
        visitModuleType(m, owner, e.pos);
      case TNew(c, _, _):
        markClass(c.get(), owner, e.pos);
      case TField(_, fa):
        switch (fa)
        {
          case FInstance(c, _, _), FStatic(c, _):
            markClass(c.get(), owner, e.pos);
          case FClosure(c, _):
            if (c != null) markClass(c.c.get(), owner, e.pos);
          case FEnum(en, _):
            markEnum(en.get(), owner, e.pos);
          default:
        }
      case TVar(v, _):
        visitType(v.t, owner, e.pos);
      case TFunction(f):
        for (a in f.args)
          visitType(a.v.t, owner, e.pos);
        visitType(f.t, owner, e.pos);
      case TTry(_, catches):
        for (c in catches)
          visitType(c.v.t, owner, e.pos);
      case TCast(_, m):
        if (m != null) visitModuleType(m, owner, e.pos);
      default:
    }

    TypedExprTools.iter(e, function(sub) walkExpr(sub, owner));
  }

  static function visitModuleType(m:ModuleType, owner:String, pos:Position):Void
  {
    switch (m)
    {
      case TClassDecl(c):
        markClass(c.get(), owner, pos);
      case TEnumDecl(en):
        markEnum(en.get(), owner, pos);
      case TTypeDecl(t):
        visitType(t.get().type, owner, pos);
      case TAbstract(a):
        var impl = a.get().impl;
        if (impl != null) markClass(impl.get(), owner, pos);
    }
  }

  static function visitType(t:Null<Type>, owner:String, pos:Position):Void
  {
    if (t == null) return;

    switch (t)
    {
      case TInst(c, params):
        markClass(c.get(), owner, pos);
        for (p in params)
          visitType(p, owner, pos);
      case TEnum(en, params):
        markEnum(en.get(), owner, pos);
        for (p in params)
          visitType(p, owner, pos);
      case TType(td, params):
        var d:DefType = td.get();
        var key:String = 'typedef ' + nameOf(d.pack, d.name);
        if (note(key, owner, pos)) visitType(d.type, owner, pos);
        for (p in params)
          visitType(p, owner, pos);
      case TAbstract(a, params):
        var impl = a.get().impl;
        if (impl != null) markClass(impl.get(), owner, pos);
        var key:String = 'abstract ' + nameOf(a.get().pack, a.get().name);
        if (note(key, owner, pos)) visitType(a.get().type, owner, pos);
        for (p in params)
          visitType(p, owner, pos);
      case TFun(args, ret):
        for (a in args)
          visitType(a.t, owner, pos);
        visitType(ret, owner, pos);
      case TAnonymous(an):
        switch (an.get().status)
        {
          case AClassStatics(c):
            markClass(c.get(), owner, pos);
            return;
          case AEnumStatics(en):
            markEnum(en.get(), owner, pos);
            return;
          case AAbstractStatics(a):
            var impl = a.get().impl;
            if (impl != null) markClass(impl.get(), owner, pos);
            return;
          default:
        }
        for (f in an.get().fields)
          visitType(f.type, owner, pos);
      case TMono(m):
        visitType(m.get(), owner, pos);
      case TLazy(f):
        visitType(f(), owner, pos);
      case TDynamic(inner):
        if (inner != null) visitType(inner, owner, pos);
    }
  }

  static function nameOf(pack:Array<String>, name:String):String
  {
    return pack.length == 0 ? name : pack.join('.') + '.' + name;
  }
  #end
}
