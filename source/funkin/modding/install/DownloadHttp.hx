package funkin.modding.install;

#if sys
import haxe.io.Bytes;
import haxe.io.Eof;

/**
 * `haxe.Http` with a response reader built for large downloads.
 */
class DownloadHttp extends haxe.Http
{
  static inline final READ_SIZE:Int = 64 * 1024;

  final buf:Bytes = Bytes.alloc(READ_SIZE);
  var pos:Int = 0;
  var len:Int = 0;

  override function readHttpResponse(api:haxe.io.Output, sock:sys.net.Socket):Void
  {
    pos = 0;
    len = 0;

    responseHeaders = new haxe.ds.StringMap();
    responseHeadersSameKey = new Map<String, Array<String>>();

    sock.setTimeout(cnxTimeout);

    final lines:Array<String> = readHeaderBlock(sock).split('\r\n');

    final status:Null<Int> = Std.parseInt(lines.shift().split(' ')[1]);
    if (status == 0 || status == null) throw 'Response status error';

    var size:Null<Int> = null;
    var chunked:Bool = false;

    for (line in lines)
    {
      final parts:Array<String> = line.split(': ');
      final name:String = parts.shift();
      final value:String = StringTools.trim(parts.join(': '));

      // Repeated headers are kept the same way the standard reader keeps them.
      final previous:Null<String> = responseHeaders.get(name);
      if (previous != null)
      {
        var values:Null<Array<String>> = responseHeadersSameKey.get(name);
        if (values == null)
        {
          values = [previous];
          responseHeadersSameKey.set(name, values);
        }

        values.push(value);
      }

      responseHeaders.set(name, value);

      switch (name.toLowerCase())
      {
        case 'content-length':
          size = Std.parseInt(value);
        case 'transfer-encoding':
          chunked = value.toLowerCase() == 'chunked';
      }
    }

    onStatus(status);

    if (chunked)
    {
      readChunked(api, sock);
    }
    else if (size == null)
    {
      if (!noShutdown) sock.shutdown(false, true);

      readToEnd(api, sock);
    }
    else
    {
      api.prepare(size);

      readFixed(api, sock, size);
    }

    if (status < 200 || status >= 400) throw 'Http Error #${status}';

    api.close();
  }

  function readHeaderBlock(sock:sys.net.Socket):String
  {
    var scanFrom:Int = pos;

    while (true)
    {
      for (i in scanFrom...len - 3)
      {
        if (buf.get(i) == 13 && buf.get(i + 1) == 10 && buf.get(i + 2) == 13 && buf.get(i + 3) == 10)
        {
          final text:String = buf.getString(pos, i - pos);
          pos = i + 4;
          return text;
        }
      }

      // The last three bytes might be the start of the blank line, so they get looked at again.
      scanFrom = Std.int(Math.max(pos, len - 3)) - pos;

      if (pos == 0 && len == buf.length) throw 'Response headers are too large';
      if (!fill(sock)) throw 'Transfer aborted';

      scanFrom += pos;
    }
  }

  function readLine(sock:sys.net.Socket):String
  {
    var scanFrom:Int = pos;

    while (true)
    {
      for (i in scanFrom...len - 1)
      {
        if (buf.get(i) == 13 && buf.get(i + 1) == 10)
        {
          final line:String = buf.getString(pos, i - pos);
          pos = i + 2;
          return line;
        }
      }

      scanFrom = Std.int(Math.max(pos, len - 1)) - pos;

      if (pos == 0 && len == buf.length) throw 'Invalid chunk';
      if (!fill(sock)) throw 'Transfer aborted';

      scanFrom += pos;
    }
  }

  function readChunked(api:haxe.io.Output, sock:sys.net.Socket):Void
  {
    while (true)
    {
      // A chunk size can be followed by extensions after a semicolon.
      final sizeText:String = StringTools.trim(readLine(sock).split(';')[0]);
      final chunkSize:Null<Int> = sizeText == '' ? null : Std.parseInt('0x${sizeText}');

      if (chunkSize == null || chunkSize < 0) throw 'Invalid chunk';

      if (chunkSize == 0)
      {
        // Skip any trailing headers, up to the blank line that ends the body.
        while (readLine(sock) != '')
        {
        }

        return;
      }

      readFixed(api, sock, chunkSize);

      if (readLine(sock) != '') throw 'Invalid chunk';
    }
  }

  function readFixed(api:haxe.io.Output, sock:sys.net.Socket, size:Int):Void
  {
    var remaining:Int = size;

    while (remaining > 0)
    {
      if (pos == len && !fill(sock)) throw 'Transfer aborted';

      final count:Int = Std.int(Math.min(len - pos, remaining));

      api.writeFullBytes(buf, pos, count);

      pos += count;
      remaining -= count;
    }
  }

  function readToEnd(api:haxe.io.Output, sock:sys.net.Socket):Void
  {
    while (pos < len || fill(sock))
    {
      api.writeFullBytes(buf, pos, len - pos);

      pos = len;
    }
  }

  function fill(sock:sys.net.Socket):Bool
  {
    if (pos == len)
    {
      pos = 0;
      len = 0;
    }
    else if (len == buf.length)
    {
      buf.blit(0, buf, pos, len - pos);
      len -= pos;
      pos = 0;
    }

    try
    {
      final count:Int = sock.input.readBytes(buf, len, buf.length - len);
      if (count <= 0) return false;

      len += count;
      return true;
    }
    catch (e:Eof)
    {
      return false;
    }
  }
}
#end
