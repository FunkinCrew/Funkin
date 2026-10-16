package funkin.modding.psych;

import funkin.data.song.SongData.SongEventData;

/**
 * Fase 2.4: eventos del chart de Psych Engine ([tiempo, [[nombre, valor1, valor2], ...]])
 * convertidos a eventos de QT Slice. Los eventos que no están aquí son de Lua (fase 2.5).
 */
class PsychEventAdapter
{
  public static function convert(psychEvents:Array<Dynamic>, songId:String):Array<SongEventData>
  {
    var result:Array<SongEventData> = [];

    for (entry in psychEvents)
    {
      var time:Float = entry[0];
      var list:Array<Dynamic> = entry[1];

      for (ev in list)
      {
        var name:String = Std.string(ev[0]);
        var v1:String = Std.string(ev[1]);
        var v2:String = ev.length > 2 ? Std.string(ev[2]) : '';
        var parts:Array<String> = v2.split(',');

        switch (name)
        {
          case 'FocusCamera':
            // v1 = personaje (0 bf, 1 dad, 2 gf); v2 = duración,x,y,ease
            result.push(new SongEventData(time, 'FocusCamera', {
              char: Std.parseInt(v1) ?? 0,
              duration: toFloat(parts[0], 4.0),
              x: toFloat(parts[1], 0.0),
              y: toFloat(parts[2], 0.0),
              ease: textAt(parts, 3, 'CLASSICIn')
            }));

          case 'ZoomCamera':
            // v1 = zoom; v2 = duración,ease,modo
            result.push(new SongEventData(time, 'ZoomCamera', {
              zoom: toFloat(v1, 1.0),
              duration: toFloat(parts[0], 4.0),
              ease: textAt(parts, 1, 'linear'),
              mode: textAt(parts, 2, 'direct')
            }));

          case 'SetCameraBop':
            // v1 = intensidad; v2 = ritmo
            result.push(new SongEventData(time, 'SetCameraBop', {
              intensity: toFloat(v1, 1.0),
              rate: toFloat(v2, 4.0)
            }));

          case 'PlayAnimation':
            // v1 = objetivo (boyfriend, dad, girlfriend); v2 = animación,force
            result.push(new SongEventData(time, 'PlayAnimation', {
              target: targetName(v1),
              anim: textAt(parts, 0, 'idle'),
              force: textAt(parts, 1, 'false').toLowerCase() == 'true'
            }));

          default:
            trace('[PSYCH] Evento "' + name + '" en ' + songId + ' se maneja en Lua (fase 2.5).');
        }
      }
    }

    return result;
  }

  static function targetName(psychName:String):String
  {
    return switch (psychName.toLowerCase())
    {
      case 'boyfriend', 'bf': 'bf';
      case 'dad', 'opponent': 'dad';
      case 'girlfriend', 'gf': 'gf';
      default: psychName;
    };
  }

  static function toFloat(text:Null<String>, fallback:Float):Float
  {
    if (text == null || StringTools.trim(text) == '') return fallback;
    var value:Float = Std.parseFloat(text);
    return Math.isNaN(value) ? fallback : value;
  }

  static function textAt(parts:Array<String>, index:Int, fallback:String):String
  {
    var text:Null<String> = parts[index];
    return (text == null || StringTools.trim(text) == '') ? fallback : StringTools.trim(text);
  }
}
