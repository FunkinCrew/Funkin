import haxe.io.Bytes;
import haxe.io.BytesOutput;
import funkin.util.texture.KTXParser;

/**
 * Pruebas del parser KTX. Compilar y correr con, por ejemplo:
 *   haxe -cp source -cp tests -main KTXParserTest --interp
 */
class KTXParserTest
{
  static var failures:Int = 0;

  static function check(cond:Bool, name:String):Void
  {
    if (cond) trace('PASS $name');
    else
    {
      failures++;
      trace('FAIL $name');
    }
  }

  static function buildKTX(w:Int, h:Int, internal:Int, mipSizes:Array<Int>, identifierOverride:Bool = false):Bytes
  {
    var out = new BytesOutput();
    out.bigEndian = false;

    var id = [0xAB, 0x4B, 0x54, 0x58, 0x20, 0x31, 0x31, 0xBB, 0x0D, 0x0A, 0x1A, 0x0A];
    if (identifierOverride) id[0] = 0x00;
    for (b in id) out.writeByte(b);

    out.writeInt32(0x04030201); // endianness
    out.writeInt32(0);          // glType (0 = comprimido)
    out.writeInt32(1);          // glTypeSize
    out.writeInt32(0);          // glFormat
    out.writeInt32(internal);   // glInternalFormat
    out.writeInt32(0x1908);     // glBaseInternalFormat (GL_RGBA)
    out.writeInt32(w);
    out.writeInt32(h);
    out.writeInt32(0);          // pixelDepth
    out.writeInt32(0);          // numberOfArrayElements
    out.writeInt32(1);          // numberOfFaces
    out.writeInt32(mipSizes.length);
    out.writeInt32(0);          // bytesOfKeyValueData

    for (i in 0...mipSizes.length)
    {
      out.writeInt32(mipSizes[i]);
      for (_ in 0...mipSizes[i]) out.writeByte(i + 1);
      var pad = (4 - (mipSizes[i] % 4)) % 4;
      for (_ in 0...pad) out.writeByte(0);
    }

    return out.getBytes();
  }

  static function expectError(bytes:Bytes, name:String):Void
  {
    var threw = false;
    try
    {
      KTXParser.parse(bytes);
    }
    catch (e:Dynamic)
    {
      threw = true;
    }
    check(threw, name);
  }

  public static function main():Void
  {
    // DXT5 8x8 con 4 niveles: 8x8 = 2x2 bloques = 64 bytes, 4x4 = 16, 2x2 = 16, 1x1 = 16.
    var dxt5 = buildKTX(8, 8, KTXParser.GL_COMPRESSED_RGBA_S3TC_DXT5_EXT, [64, 16, 16, 16]);
    var file = KTXParser.parse(dxt5);

    check(file.isCompressed, 'DXT5 se marca como comprimido');
    check(file.header.pixelWidth == 8 && file.header.pixelHeight == 8, 'dimensiones 8x8');
    check(file.mips.length == 4, 'cuatro niveles de mipmap');
    check(file.mips[0].width == 8 && file.mips[1].width == 4 && file.mips[2].width == 2 && file.mips[3].width == 1, 'anchos de mip 8,4,2,1');
    check(file.mips[0].data.length == 64 && file.mips[3].data.length == 16, 'tamaños de datos por nivel');
    check(file.mips[0].data.get(0) == 1 && file.mips[1].data.get(0) == 2, 'contenido de cada nivel correcto (no se corrió el offset)');

    // Los formatos de bloque (DXT, ETC) siempre tienen tamaños múltiplos de 4, así que el padding no se activa aquí.
    var padded = buildKTX(4, 4, KTXParser.GL_COMPRESSED_RGBA_S3TC_DXT1_EXT, [8, 8, 8]);
    var paddedFile = KTXParser.parse(padded);
    check(paddedFile.mips.length == 3, 'DXT1 4x4 con tres niveles');

    // Tamaño incorrecto para DXT5 8x8 nivel 0 (debería ser 64).
    expectError(buildKTX(8, 8, KTXParser.GL_COMPRESSED_RGBA_S3TC_DXT5_EXT, [60, 16, 16, 16]), 'tamaño de bloque incorrecto se rechaza');

    // Identificador malo.
    expectError(buildKTX(8, 8, KTXParser.GL_COMPRESSED_RGBA_S3TC_DXT5_EXT, [64], true), 'identificador inválido se rechaza');

    // Archivo truncado.
    var truncated = dxt5.sub(0, dxt5.length - 10);
    expectError(truncated, 'archivo truncado se rechaza');

    // Muy corto.
    expectError(Bytes.alloc(10), 'archivo menor a la cabecera se rechaza');

    trace(failures == 0 ? 'OK: todas las pruebas pasaron' : 'FALLARON $failures pruebas');
    Sys.exit(failures == 0 ? 0 : 1);
  }
}
