package funkin.util.texture;

import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.io.Eof;

/**
 * Cabecera de un archivo KTX 1.1 (Khronos).
 */
typedef KTXHeader =
{
  glType:Int,
  glTypeSize:Int,
  glFormat:Int,
  glInternalFormat:Int,
  glBaseInternalFormat:Int,
  pixelWidth:Int,
  pixelHeight:Int,
  pixelDepth:Int,
  numberOfArrayElements:Int,
  numberOfFaces:Int,
  numberOfMipmapLevels:Int,
  bytesOfKeyValueData:Int
}

/**
 * Un nivel de mipmap ya leído del archivo. `data` contiene solo los bytes comprimidos de ese nivel.
 */
typedef KTXMip =
{
  level:Int,
  width:Int,
  height:Int,
  data:Bytes
}

typedef KTXFile =
{
  header:KTXHeader,
  /** `true` si la textura está comprimida (glType == 0 en KTX). */
  isCompressed:Bool,
  mips:Array<KTXMip>
}

/**
 * Lector de contenedores KTX 1.1 para texturas 2D.
 *
 * Solo parsea la cabecera y los niveles de mipmap. No descomprime ni sube nada a la GPU;
 * eso lo hace quien llame a `parse`.
 *
 * Soporta solo little-endian (lo que escriben `toktx` y KTX-Software en x86/ARM), 2D, una cara y una capa.
 */
class KTXParser
{
  public static final HEADER_SIZE:Int = 64;

  /** Identificador de 12 bytes: «KTX 11»\r\n\x1A\n */
  static final IDENTIFIER:Array<Int> = [0xAB, 0x4B, 0x54, 0x58, 0x20, 0x31, 0x31, 0xBB, 0x0D, 0x0A, 0x1A, 0x0A];

  /** Valor de endianness tal como se lee en little-endian en un archivo LE. */
  static final ENDIANNESS_LE:Int = 0x04030201;

  // Formatos internos comprimidos (GL), usados para validar tamaños.
  public static final GL_COMPRESSED_RGB_S3TC_DXT1_EXT:Int = 0x83F0;
  public static final GL_COMPRESSED_RGBA_S3TC_DXT1_EXT:Int = 0x83F1;
  public static final GL_COMPRESSED_RGBA_S3TC_DXT3_EXT:Int = 0x83F2;
  public static final GL_COMPRESSED_RGBA_S3TC_DXT5_EXT:Int = 0x83F3;
  public static final GL_ETC1_RGB8_OES:Int = 0x8D64;
  public static final GL_COMPRESSED_RGB8_ETC2:Int = 0x9274;
  public static final GL_COMPRESSED_RGBA8_ETC2_EAC:Int = 0x9278;

  /**
   * Parsea un KTX desde sus bytes.
   * @throws String con el motivo si el archivo no es válido o está truncado.
   */
  public static function parse(bytes:Bytes):KTXFile
  {
    if (bytes.length < HEADER_SIZE) throw 'KTX: archivo demasiado corto (${bytes.length} bytes)';

    for (i in 0...IDENTIFIER.length)
    {
      if (bytes.get(i) != IDENTIFIER[i]) throw 'KTX: identificador inválido, no es un archivo KTX 1.1';
    }

    var input = new BytesInput(bytes, IDENTIFIER.length, bytes.length - IDENTIFIER.length);
    input.bigEndian = false;

    var endianness = readInt(input, 'endianness');
    if (endianness != ENDIANNESS_LE) throw 'KTX: solo se soporta little-endian (endianness=0x${StringTools.hex(endianness, 8)})';

    var header:KTXHeader = {
      glType: readInt(input, 'glType'),
      glTypeSize: readInt(input, 'glTypeSize'),
      glFormat: readInt(input, 'glFormat'),
      glInternalFormat: readInt(input, 'glInternalFormat'),
      glBaseInternalFormat: readInt(input, 'glBaseInternalFormat'),
      pixelWidth: readInt(input, 'pixelWidth'),
      pixelHeight: readInt(input, 'pixelHeight'),
      pixelDepth: readInt(input, 'pixelDepth'),
      numberOfArrayElements: readInt(input, 'numberOfArrayElements'),
      numberOfFaces: readInt(input, 'numberOfFaces'),
      numberOfMipmapLevels: readInt(input, 'numberOfMipmapLevels'),
      bytesOfKeyValueData: readInt(input, 'bytesOfKeyValueData'),
    };

    if (header.pixelWidth <= 0 || header.pixelHeight <= 0) throw 'KTX: dimensiones inválidas (${header.pixelWidth}x${header.pixelHeight})';
    if (header.pixelDepth > 1) throw 'KTX: solo se soportan texturas 2D (pixelDepth=${header.pixelDepth})';
    if (header.numberOfArrayElements > 1) throw 'KTX: arrays de texturas no soportados';
    if (header.numberOfFaces != 1) throw 'KTX: cubemaps no soportados (numberOfFaces=${header.numberOfFaces})';
    if (header.bytesOfKeyValueData < 0) throw 'KTX: bytesOfKeyValueData negativo';

    // Los datos clave-valor se saltan; no los usamos.
    if (header.bytesOfKeyValueData > 0) readBytes(input, header.bytesOfKeyValueData, 'key-value data');

    var isCompressed = header.glType == 0;
    var mipCount = header.numberOfMipmapLevels < 1 ? 1 : header.numberOfMipmapLevels;

    var mips:Array<KTXMip> = [];
    var width = header.pixelWidth;
    var height = header.pixelHeight;

    for (level in 0...mipCount)
    {
      var imageSize = readInt(input, 'imageSize del nivel $level');
      if (imageSize < 0) throw 'KTX: imageSize negativo en el nivel $level';

      var data = readBytes(input, imageSize, 'datos del nivel $level');

      if (isCompressed)
      {
        var expected = expectedBlockSize(header.glInternalFormat, width, height);
        if (expected >= 0 && expected != imageSize)
        {
          throw 'KTX: nivel $level tiene $imageSize bytes, se esperaban $expected (${width}x${height})';
        }
      }

      mips.push({level: level, width: width, height: height, data: data});

      // Cada nivel está alineado a 4 bytes.
      var padding = (4 - (imageSize % 4)) % 4;
      if (padding > 0) readBytes(input, padding, 'padding del nivel $level');

      width = width > 1 ? width >> 1 : 1;
      height = height > 1 ? height >> 1 : 1;
    }

    return {header: header, isCompressed: isCompressed, mips: mips};
  }

  /**
   * Bytes esperados para un nivel comprimido. Devuelve -1 si el formato no está en la lista conocida.
   */
  public static function expectedBlockSize(glInternalFormat:Int, width:Int, height:Int):Int
  {
    var blockBytes:Int = -1;
    if (glInternalFormat == GL_COMPRESSED_RGB_S3TC_DXT1_EXT || glInternalFormat == GL_COMPRESSED_RGBA_S3TC_DXT1_EXT)
      blockBytes = 8;
    else if (glInternalFormat == GL_COMPRESSED_RGBA_S3TC_DXT3_EXT || glInternalFormat == GL_COMPRESSED_RGBA_S3TC_DXT5_EXT)
      blockBytes = 16;
    else if (glInternalFormat == GL_ETC1_RGB8_OES || glInternalFormat == GL_COMPRESSED_RGB8_ETC2)
      blockBytes = 8;
    else if (glInternalFormat == GL_COMPRESSED_RGBA8_ETC2_EAC)
      blockBytes = 16;

    if (blockBytes < 0) return -1;

    var blocksX = Std.int((width + 3) / 4);
    var blocksY = Std.int((height + 3) / 4);
    return blocksX * blocksY * blockBytes;
  }

  static function readInt(input:BytesInput, what:String):Int
  {
    try
    {
      return input.readInt32();
    }
    catch (e:Eof)
    {
      throw 'KTX: archivo truncado leyendo $what';
    }
  }

  static function readBytes(input:BytesInput, n:Int, what:String):Bytes
  {
    try
    {
      return input.read(n);
    }
    catch (e:Eof)
    {
      throw 'KTX: archivo truncado leyendo $what';
    }
  }
}
