package funkin.mobile.macros;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.xml.Printer;
import sys.FileSystem;

using haxe.io.Path;

/**
 * This class provides a macro to include an XML build file in the metadata of a Haxe class.
 * The file must be located relative to the directory of the Haxe class that uses this macro.
 */
@:nullSafety
class LinkerMacro
{
  /**
   * Adds an XML `<include>` element to the class's metadata, pointing to a specified build file.
   * @param file_name The name of the XML file to include. Defaults to `Build.xml` if not provided.
   * @return An array of fields that are processed during the build.
   */
  public static macro function xml(?file_name:String = 'Build.xml'):Array<Field>
  {
    final pos:Position = Context.currentPos();
    final sourcePath:String = FileSystem.absolutePath(Context.getPosInfos(pos).file.directory()).removeTrailingSlashes();
    final fileToInclude:String = Path.join([sourcePath, file_name?.length > 0 ? file_name : 'Build.xml']);

    if (!FileSystem.exists(fileToInclude)) Context.error('The specified file "$fileToInclude" could not be found at "$sourcePath".', pos);

    final includeElement:Xml = Xml.createElement('include');
    includeElement.set('name', fileToInclude);
    Context.getLocalClass().get().meta.add(':buildXml', [
      {expr: EConst(CString(Printer.print(includeElement, true))), pos: pos}], pos);

    return Context.getBuildFields();
  }
}
