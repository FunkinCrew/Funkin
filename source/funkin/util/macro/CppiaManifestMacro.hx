package funkin.util.macro;

#if macro
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;
#end

/**
 * Injects the manifest class that Polymod reads out of a compiled (cppia) script.
 */
class CppiaManifestMacro
{
  #if macro
  static final MANIFEST_NAME:String = 'PolymodCppiaManifest';

  /**
   * Call from a mod's build command as
   * `--macro funkin.util.macro.CppiaManifestMacro.build(['MyClass'])`.
   *
   * @param classNames The scripted classes this cppia provides, as fully qualified names.
   */
  public static function build(classNames:Array<String>):Void
  {
    if (classNames == null || classNames.length == 0)
    {
      Context.error('CppiaManifestMacro.build() needs at least one class name.', Context.currentPos());
      return;
    }

    var version:String = Context.definedValue('funkin');
    if (version == null)
    {
      Context.error('CppiaManifestMacro.build() could not read the "funkin" define. Build against the game hxml.', Context.currentPos());
      return;
    }

    var pos = Context.currentPos();

    var classRefs:Array<Expr> = [for (className in classNames) macro $p{className.split('.')}];

    Context.defineType(
      {
        pack: [],
        name: MANIFEST_NAME,
        pos: pos,
        kind: TDClass(),
        fields: [
          {
            name: 'gameVersion',
            access: [APublic, AStatic],
            kind: FVar(macro :String, macro $v{version}),
            pos: pos
          },
          {
            name: 'classes',
            access: [APublic, AStatic],
            kind: FVar(macro :Array<String>, macro $v{classNames}),
            pos: pos
          },
          {
            name: 'classRefs',
            access: [APublic, AStatic],
            kind: FVar(macro :Array<Class<Dynamic>>, {expr: EArrayDecl(classRefs), pos: pos}),
            pos: pos
          }
        ]
      });

    Compiler.keep(MANIFEST_NAME);
  }
  #end
}
