package funkin.modding.psych;

/**
 * Fase 2.3: personajes de Psych Engine (characters/<id>.json) convertidos al formato de QT Slice.
 */
class PsychCharacterAdapter
{
  public static final CHARACTER_DATA_VERSION:String = '1.0.2';

  /** Un personaje de Psych tiene 'image' y 'animations'; QT no usa esos campos. */
  public static function isPsychCharacter(raw:Dynamic):Bool
  {
    return raw != null && Reflect.hasField(raw, 'image') && Reflect.hasField(raw, 'animations');
  }

  public static function convert(raw:Dynamic, charId:String):Dynamic
  {
    var animations:Array<Dynamic> = [];
    var psychAnims:Array<Dynamic> = raw.animations ?? [];

    for (anim in psychAnims)
    {
      var indices:Array<Dynamic> = anim.indices ?? [];
      if (indices.length > 0)
      {
        trace('[PSYCH] "' + anim.anim + '" de ' + charId + ' usa índices de frames; QT aún no los soporta.');
      }

      animations.push({
        name: anim.anim,
        prefix: StringTools.trim(Std.string(anim.name)),
        offsets: anim.offsets ?? [0.0, 0.0],
        looped: anim.loop ?? false,
        frameRate: anim.fps ?? 24
      });
    }

    if (raw.healthbar_colors != null)
    {
      trace('[PSYCH] healthbar_colors de ' + charId + ' aún no se aplica (QT no lo tiene en el personaje).');
    }

    return {
      version: CHARACTER_DATA_VERSION,
      name: charId,
      renderType: 'sparrow',
      assetPath: raw.image,
      scale: raw.scale ?? 1.0,
      healthIcon: {
        id: raw.healthicon ?? charId,
        shouldBop: true,
        scale: 1.0,
        flipX: false,
        isPixel: false,
        offsets: [0.0, 0.0]
      },
      offsets: raw.position ?? [0.0, 0.0],
      cameraOffsets: raw.camera_position ?? [0.0, 0.0],
      isPixel: raw.no_antialiasing ?? false,
      singTime: raw.sing_duration ?? 8.0,
      animations: animations,
      startingAnimation: 'idle',
      flipX: raw.flip_x ?? false,
      applyStageMatrix: false
    };
  }
}
