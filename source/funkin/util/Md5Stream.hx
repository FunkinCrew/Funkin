package funkin.util;

import haxe.io.Bytes;

/**
 * A stream that can be fed data and will compute the MD5 hash of it.
 */
@:nullSafety
class Md5Stream
{
  static final K:Array<Int> = [
    0xd76aa478, 0xe8c7b756, 0x242070db, 0xc1bdceee, 0xf57c0faf, 0x4787c62a, 0xa8304613, 0xfd469501,
    0x698098d8, 0x8b44f7af, 0xffff5bb1, 0x895cd7be, 0x6b901122, 0xfd987193, 0xa679438e, 0x49b40821,
    0xf61e2562, 0xc040b340, 0x265e5a51, 0xe9b6c7aa, 0xd62f105d, 0x02441453, 0xd8a1e681, 0xe7d3fbc8,
    0x21e1cde6, 0xc33707d6, 0xf4d50d87, 0x455a14ed, 0xa9e3e905, 0xfcefa3f8, 0x676f02d9, 0x8d2a4c8a,
    0xfffa3942, 0x8771f681, 0x6d9d6122, 0xfde5380c, 0xa4beea44, 0x4bdecfa9, 0xf6bb4b60, 0xbebfbc70,
    0x289b7ec6, 0xeaa127fa, 0xd4ef3085, 0x04881d05, 0xd9d4d039, 0xe6db99e5, 0x1fa27cf8, 0xc4ac5665,
    0xf4292244, 0x432aff97, 0xab9423a7, 0xfc93a039, 0x655b59c3, 0x8f0ccc92, 0xffeff47d, 0x85845dd1,
    0x6fa87e4f, 0xfe2ce6e0, 0xa3014314, 0x4e0811a1, 0xf7537e82, 0xbd3af235, 0x2ad7d2bb, 0xeb86d391
  ];
  static final S:Array<Int> = [
    7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22,
    5,  9, 14, 20, 5,  9, 14, 20, 5,  9, 14, 20, 5,  9, 14, 20,
    4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23,
    6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21
  ];

  var a:Int = 0x67452301;
  var b:Int = 0xefcdab89;
  var c:Int = 0x98badcfe;
  var d:Int = 0x10325476;
  final block:Bytes = Bytes.alloc(64);
  var blockLength:Int = 0;
  var totalLength:Int = 0;

  public function new()
  {
  }

  public function update(data:Bytes, pos:Int, len:Int):Void
  {
    totalLength += len;

    var offset:Int = pos;
    final end:Int = pos + len;

    if (blockLength > 0)
    {
      final count:Int = Std.int(Math.min(64 - blockLength, len));

      block.blit(blockLength, data, offset, count);
      blockLength += count;
      offset += count;

      if (blockLength < 64) return;

      processBlock(block, 0);
      blockLength = 0;
    }

    while (end - offset >= 64)
    {
      processBlock(data, offset);
      offset += 64;
    }

    if (offset < end)
    {
      block.blit(0, data, offset, end - offset);
      blockLength = end - offset;
    }
  }

  /**
   * Finishes the hash.
   * @return The hash as lowercase hex.
   */
  public function digest():String
  {
    final bitsLow:Int = totalLength << 3;
    final bitsHigh:Int = totalLength >>> 29;

    final padLength:Int = blockLength < 56 ? 56 - blockLength : 120 - blockLength;
    final tail:Bytes = Bytes.alloc(padLength + 8);

    tail.fill(0, tail.length, 0);
    tail.set(0, 0x80);
    tail.setInt32(padLength, bitsLow);
    tail.setInt32(padLength + 4, bitsHigh);

    update(tail, 0, tail.length);

    final out:Bytes = Bytes.alloc(16);
    out.setInt32(0, a);
    out.setInt32(4, b);
    out.setInt32(8, c);
    out.setInt32(12, d);

    return out.toHex();
  }

  function processBlock(data:Bytes, offset:Int):Void
  {
    var aa:Int = a;
    var bb:Int = b;
    var cc:Int = c;
    var dd:Int = d;

    for (i in 0...64)
    {
      var f:Int;
      var g:Int;

      if (i < 16)
      {
        f = (bb & cc) | (~bb & dd);
        g = i;
      }
      else if (i < 32)
      {
        f = (dd & bb) | (~dd & cc);
        g = (5 * i + 1) & 15;
      }
      else if (i < 48)
      {
        f = bb ^ cc ^ dd;
        g = (3 * i + 5) & 15;
      }
      else
      {
        f = cc ^ (bb | ~dd);
        g = (7 * i) & 15;
      }

      f = add(add(f, aa), add(K[i], data.getInt32(offset + g * 4)));

      aa = dd;
      dd = cc;
      cc = bb;
      bb = add(bb, (f << S[i]) | (f >>> (32 - S[i])));
    }

    a = add(a, aa);
    b = add(b, bb);
    c = add(c, cc);
    d = add(d, dd);
  }

  /**
   * Adds two words with 32 bit wraparound, without leaning on signed overflow.
   */
  static inline function add(x:Int, y:Int):Int
  {
    final low:Int = (x & 0xFFFF) + (y & 0xFFFF);
    final high:Int = (x >> 16) + (y >> 16) + (low >> 16);

    return (high << 16) | (low & 0xFFFF);
  }
}
