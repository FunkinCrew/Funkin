package funkin.util.macro;

#if macro
import haxe.io.Bytes;
import haxe.macro.Compiler;
import haxe.macro.Context;
#end

/**
 * Empties the resource table of a compiled script.
 */
class CppiaStripMacro
{
  #if macro
  static final RESOURCES:Int = 77;
  static final RESO:Int = 78;

  /**
   * Call from a mod's build command as
   * `--macro funkin.util.macro.CppiaStripMacro.stripResources()`.
   */
  public static function stripResources():Void
  {
    Context.onAfterGenerate(function() {
      var path:String = Compiler.getOutput();

      if (path == null || !sys.FileSystem.exists(path))
      {
        Context.warning('CppiaStripMacro found no generated file, its resources were left in.', Context.currentPos());
        return;
      }

      var data:Bytes = sys.io.File.getBytes(path);
      var start:Int = findResourceTable(data);

      if (start < 0)
      {
        Context.warning('CppiaStripMacro found no resource table in "$path", its resources were left in.', Context.currentPos());
        return;
      }

      // The tag has to stay, the reader throws without it. Only the count goes to zero.
      var out:Bytes = Bytes.alloc(start + 2);
      out.blit(0, data, 0, start);
      out.set(start, RESOURCES);
      out.set(start + 1, 0);

      sys.io.File.saveBytes(path, out);
    });
  }

  /**
   * Where the resource table starts, or -1 if it could not be located.
   */
  static function findResourceTable(data:Bytes):Int
  {
    var cursor:CppiaCursor = new CppiaCursor(data);

    if (!cursor.skipHeader()) return -1;

    for (start in cursor.pos...data.length)
    {
      if (data.get(start) != RESOURCES) continue;
      if (tableEndsAtEof(data, start)) return start;
    }

    return -1;
  }

  /**
   * Whether a table read from here accounts for the rest of the file exactly.
   * The blobs run to the end, so this tells a real table from a byte that happens to be 77.
   */
  static function tableEndsAtEof(data:Bytes, start:Int):Bool
  {
    var cursor:CppiaCursor = new CppiaCursor(data);
    cursor.pos = start + 1;

    try
    {
      var count:Int = cursor.binInt();
      if (count < 0 || count > 100000) return false;

      var total:Int = 0;
      for (_ in 0...count)
      {
        if (cursor.take() != RESO) return false;
        cursor.binInt();
        total += cursor.binInt();
      }

      return cursor.pos + total == data.length;
    }
    catch (e:Dynamic)
    {
      return false;
    }
  }
  #end
}

#if macro
/**
 * Reads the parts of the cppia format we need, matching hxcpp's CppiaStream.
 */
private class CppiaCursor
{
  public var pos:Int = 0;

  final data:Bytes;

  public function new(data:Bytes)
  {
    this.data = data;
  }

  public function take():Int
  {
    if (pos >= data.length) throw 'end of file';
    return data.get(pos++);
  }

  /**
   * Skip the magic, the string table and the type table.
   */
  public function skipHeader():Bool
  {
    try
    {
      asciiToken();
      var strings:Int = asciiInt();
      for (_ in 0...strings)
        skipString();

      var types:Int = asciiInt();
      for (_ in 0...types)
        skipString();

      return true;
    }
    catch (e:Dynamic)
    {
      return false;
    }
  }

  public function binInt():Int
  {
    var code:Int = take();
    if (code < 254) return code;
    if (code == 254) return take() | (take() << 8);
    return take() | (take() << 8) | (take() << 16) | (take() << 24);
  }

  function asciiToken():String
  {
    skipWhitespace();
    var start:Int = pos;
    while (pos < data.length && data.get(pos) > 32)
      pos++;
    return data.getString(start, pos - start);
  }

  function asciiInt():Int
  {
    var token:String = asciiToken();
    var value:Null<Int> = Std.parseInt(token);
    if (value == null) throw 'expected a number, got "$token"';
    return value;
  }

  function skipString():Void
  {
    var len:Int = asciiInt();
    if (len < 0) throw 'bad string length $len';

    // One separator byte sits between the length and the bytes.
    pos += 1 + len;
    if (pos > data.length) throw 'end of file';
  }

  function skipWhitespace():Void
  {
    while (true)
    {
      while (pos < data.length && data.get(pos) <= 32)
        pos++;

      if (pos < data.length && data.get(pos) == '#'.code)
      {
        while (pos < data.length && data.get(pos) != '\n'.code)
          pos++;
      }
      else
      {
        break;
      }
    }
  }
}
#end
