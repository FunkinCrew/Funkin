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
      var binary:Null<Bool> = isBinary(data);

      if (binary == null)
      {
        Context.warning('CppiaStripMacro did not recognise "$path" as a compiled script, its resources were left in.', Context.currentPos());
        return;
      }

      var start:Int = findResourceTable(data, binary);

      if (start < 0)
      {
        Context.warning('CppiaStripMacro found no resource table in "$path", its resources were left in.', Context.currentPos());
        return;
      }

      // The tag has to stay, the reader throws without it. Only the count goes to zero.
      var tail:Bytes = binary ? emptyBinaryTable() : Bytes.ofString('RESOURCES 0\n');

      var out:Bytes = Bytes.alloc(start + tail.length);
      out.blit(0, data, 0, start);
      out.blit(start, tail, 0, tail.length);

      sys.io.File.saveBytes(path, out);
    });
  }

  static function emptyBinaryTable():Bytes
  {
    var tail:Bytes = Bytes.alloc(2);
    tail.set(0, RESOURCES);
    tail.set(1, 0);
    return tail;
  }

  /**
   * Whether the file is a binary or text cppia, or null if it is neither.
   */
  static function isBinary(data:Bytes):Null<Bool>
  {
    if (data.length < 5) return null;

    var magic:String = data.getString(0, 5);
    if (magic == 'CPPIB') return true;
    if (magic == 'CPPIA') return false;
    return null;
  }

  /**
   * Where the resource table starts, or -1 if it could not be located.
   */
  static function findResourceTable(data:Bytes, binary:Bool):Int
  {
    var cursor:CppiaCursor = new CppiaCursor(data, binary);

    if (!cursor.skipHeader()) return -1;

    for (start in cursor.pos...data.length)
    {
      if (!looksLikeTag(data, start, binary)) continue;
      if (tableEndsAtEof(data, binary, start)) return start;
    }

    return -1;
  }

  static function looksLikeTag(data:Bytes, start:Int, binary:Bool):Bool
  {
    if (binary) return data.get(start) == RESOURCES;

    if (start + 9 > data.length) return false;
    if (start > 0 && data.get(start - 1) > 32) return false;
    return data.getString(start, 9) == 'RESOURCES';
  }

  static function tableEndsAtEof(data:Bytes, binary:Bool, start:Int):Bool
  {
    var cursor:CppiaCursor = new CppiaCursor(data, binary);
    cursor.pos = start;

    try
    {
      if (cursor.token() != 'RESOURCES') return false;

      var count:Int = cursor.int();
      if (count < 0 || count > 100000) return false;

      var total:Int = 0;
      for (_ in 0...count)
      {
        if (cursor.token() != 'RESO') return false;
        cursor.int();
        total += cursor.int();
      }

      if (!binary) cursor.pos++;

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
  final binary:Bool;

  public function new(data:Bytes, binary:Bool)
  {
    this.data = data;
    this.binary = binary;
  }

  public function take():Int
  {
    if (pos >= data.length) throw 'end of file';
    return data.get(pos++);
  }

  /**
   * Skip the magic, the string table and the type table.
   * Both forms write these the same way.
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

  public function token():String
  {
    if (!binary) return asciiToken();

    return switch (int())
    {
      case 77: 'RESOURCES';
      case 78: 'RESO';
      default: '';
    }
  }

  public function int():Int
  {
    if (!binary) return asciiInt();

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
