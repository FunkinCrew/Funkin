package art;

using DateTools;

class Postbuild
{
  static function main()
  {
    /* trace('creating NG zip');
      var binFolder:String = 'export/release/html5/bin/';

      var date = Date.now();
      var outputName:String = 'NG-' + date.format("%Y%m%d--%H%M") + '.zip';

      var out = sys.io.File.write(outputName);
      var zip = new haxe.zip.Writer(out);
      zip.write(getEntries(binFolder));
      trace('Finished creating ZIP');
     */
  }

  static function getEntries(dir:String, entries:List<haxe.zip.Entry> = null, inDir:Null<String> = null)
  {
    if (entries == null) entries = new List<haxe.zip.Entry>();
    if (inDir == null) inDir = dir;

    for (file in sys.FileSystem.readDirectory(dir))
    {
      var path = haxe.io.Path.join([dir, file]);
      if (sys.FileSystem.isDirectory(path)) getEntries(path, entries, inDir);
      else
      {
        var bytes:haxe.io.Bytes = haxe.io.Bytes.ofData(sys.io.File.getBytes(path).getData());
        var entry:haxe.zip.Entry =
          {
            fileName: StringTools.replace(path, inDir, ""),
            fileSize: bytes.length,
            fileTime: Date.now(),
            compressed: false,
            dataSize: sys.FileSystem.stat(path).size,
            data: bytes,
            crc32: haxe.crypto.Crc32.make(bytes)
          };
        entries.push(entry);
      }
    }
    return entries;
  }
}
