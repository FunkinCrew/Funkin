package funkin.modding.psych;

/**
 * Fase 2.4: stages de Psych Engine (stages/<id>.json) convertidos al formato de QT Slice.
 * Solo pasa posiciones, cámara y zoom. Los props y scripts vienen en la fase 2.5.
 */
class PsychStageAdapter
{
  /** Un stage de Psych tiene 'boyfriend' y no tiene 'characters'. */
  public static function isPsychStage(raw:Dynamic):Bool
  {
    return raw != null && Reflect.hasField(raw, 'boyfriend') && !Reflect.hasField(raw, 'characters');
  }

  public static function convert(raw:Dynamic, stageId:String):Dynamic
  {
    return {
      version: '1.0.2',
      name: stageId,
      cameraZoom: raw.defaultZoom ?? 1.0,
      directory: raw.directory ?? '',
      props: [],
      characters: {
        bf: characterSlot(raw.boyfriend, raw.camera_boyfriend),
        dad: characterSlot(raw.opponent, raw.camera_opponent),
        gf: characterSlot(raw.girlfriend, raw.camera_girlfriend)
      }
    };
  }

  static function characterSlot(position:Dynamic, cameraOffsets:Dynamic):Dynamic
  {
    return {
      zIndex: 0,
      position: position ?? [0.0, 0.0],
      scale: 1.0,
      cameraOffsets: cameraOffsets ?? [0.0, 0.0],
      scroll: [1.0, 1.0]
    };
  }
}
