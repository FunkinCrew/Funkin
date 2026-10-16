package funkin.modding.psych;

import haxe.Json;

/**
 * Fase 2.1: detecta mods de Psych Engine (carpetas con pack.json) que no tienen
 * _polymod_meta.json, y lo genera a partir de pack.json para que Polymod los reconozca.
 */
class PsychModAdapter
{
  public static final META_FILE:String = '_polymod_meta.json';
  public static final PACK_FILE:String = 'pack.json';

  /**
   * Crea _polymod_meta.json en cada carpeta directa de root que tenga pack.json y no tenga metadatos.
   * @return Nombres de carpeta a los que se les creó metadatos.
   */
  public static function ensureMetadata(root:String):Array<String>
  {
    var created:Array<String> = [];
    #if sys
    if (!sys.FileSystem.exists(root) || !sys.FileSystem.isDirectory(root)) return created;

    for (dir in sys.FileSystem.readDirectory(root))
    {
      var modPath:String = root + '/' + dir;
      if (!sys.FileSystem.isDirectory(modPath)) continue;
      if (!sys.FileSystem.exists(modPath + '/' + PACK_FILE)) continue;
      if (sys.FileSystem.exists(modPath + '/' + META_FILE)) continue;

      if (writeMetadata(modPath, dir)) created.push(dir);
    }
    #end
    return created;
  }

  static function writeMetadata(modPath:String, dir:String):Bool
  {
    #if sys
    try
    {
      var pack:Dynamic = Json.parse(sys.io.File.getContent(modPath + '/' + PACK_FILE));

      var title:String = (pack.name != null) ? Std.string(pack.name) : dir;
      var description:String = (pack.description != null) ? Std.string(pack.description) : '';

      var meta:Dynamic = {
        title: title,
        description: description,
        homepage: '',
        id: makeId(dir),
        contributors: [],
        api_version: '0.8.7',
        mod_version: '1.0.0',
        license: 'Psych Engine (importado)'
      };

      sys.io.File.saveContent(modPath + '/' + META_FILE, Json.stringify(meta, null, '    ') + '\n');
      trace('[PSYCH] Metadatos creados para el mod de Psych: ' + dir);
      return true;
    }
    catch (e:Dynamic)
    {
      trace('[PSYCH] No se pudo crear metadatos para ' + dir + ': ' + e);
      return false;
    }
    #else
    return false;
    #end
  }

  static function makeId(dir:String):String
  {
    var id:String = ~/[^a-z0-9_-]+/g.replace(dir.toLowerCase(), '-');
    id = ~/^-+|-+$/g.replace(id, '');
    if (id == '') id = 'mod';
    return id;
  }
}
