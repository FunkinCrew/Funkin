package funkin.util.macro;

/**
 * This class provides a macro to include an XML build file in the metadata of a Haxe class.
 *
 * The file must be located relative to the directory of the Haxe class that uses this macro.
 */
@:nullSafety
class LinkerMacro
{
  /**
   * Adds an XML `<include>` element to the class's metadata, pointing to a specified build file.
   * @param fileName The name of the XML file to include. Defaults to `Build.xml` if not provided.
   * @return An array of fields that are processed during the build.
   */
  public static macro function xml(?fileName:String = 'Build.xml'):Array<haxe.macro.Expr.Field>
  {
    final fields:Array<haxe.macro.Expr.Field> = haxe.macro.Context.getBuildFields();
    final cls:haxe.macro.Type.ClassType = haxe.macro.Context.getLocalClass().get();
    final pos:haxe.macro.Expr.Position = haxe.macro.Context.currentPos();

    final sourcePath:String = haxe.io.Path.directory(haxe.macro.Context.getPosInfos(pos).file);
    final absSourcePath:String = haxe.io.Path.removeTrailingSlashes(sys.FileSystem.absolutePath(sourcePath));
    final fileToInclude:String = haxe.io.Path.join([absSourcePath, fileName?.length > 0 ? fileName : 'Build.xml']);

    if (!sys.FileSystem.exists(fileToInclude))
    {
      haxe.macro.Context.error('The specified file "$fileToInclude" could not be found at "$absSourcePath".', pos);
    }

    final includeElement:Xml = Xml.createElement('include');

    includeElement.set('name', fileToInclude);

    cls.meta.add(':buildXml', [
      {
        expr: EConst(CString(haxe.xml.Printer.print(includeElement, true))),
        pos: pos
      }
    ], pos);

    return fields;
  }
}
