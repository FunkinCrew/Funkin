package funkin.play.components.hud;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;
import funkin.Preferences;
import funkin.ui.FullScreenScaleMode;
import funkin.play.notes.Strumline;
import funkin.play.notes.notestyle.NoteStyle;
import funkin.play.components.*;

class HudStyle extends FlxSpriteGroup
{
  public var gameInstance:PlayState;

  public var playerStrumline:Strumline;
  public var opponentStrumline:Strumline;

  public var downscroll(get, never):Bool;

  inline private function get_downscroll():Bool
    return Preferences.downscroll;

  public var currentNotestyle(get, default):NoteStyle;

  inline private function get_currentNotestyle():NoteStyle
    return currentNotestyle ?? funkin.data.notestyle.NoteStyleRegistry.instance.fetchDefault();

  public function new()
  {
    super();
  }

  public function createStrumlines()
  {
    playerStrumline = createStrumline(!gameInstance.isBotPlayMode);
    opponentStrumline = createStrumline(false);
  }

  public function createStrumline(player:Bool = false):Strumline
  {
    final strumline:Strumline = new Strumline(currentNotestyle, player, gameInstance?.currentChart?.scrollSpeed);
    final pos = getStrumlinePosition(strumline, player);
    strumline.setPosition(pos.x, pos.y);
    // mobile specific stuff here
    // mobile specific stuff here
    add(strumline);
    return strumline;
  }

  public function getStrumlinePosition(strumline:Strumline, player:Bool, ?point:FlxPoint):FlxPoint
  {
    final cutoutSize = FullScreenScaleMode.gameCutoutSize.x / 2.5;
    point ??= FlxPoint.get();
    point.x = player ? ((FlxG.width / 2 + Constants.STRUMLINE_X_OFFSET) + (cutoutSize / 2.0)) : Constants.STRUMLINE_X_OFFSET + cutoutSize;
    point.y = strumline.isDownscroll ? FlxG.height - strumline.height - Constants.STRUMLINE_Y_OFFSET - currentNotestyle.getStrumlineOffsets()[1] : Constants.STRUMLINE_Y_OFFSET;
    return point;
  }

  override function update(dt:Float)
  {
    super.update(dt);
  }

  public function onStepHit(step:Int) {}

  public function onBeatHit(beat:Int) {}

  public function onMeasureHit(measure:Int) {}

  /*public function onSongEventExecution(event:SongEventData)
    {

  }*/
  public static function getHudStyle(name:Null<String>):HudStyle
  {
    return new FunkinHudStyle();
  }
}
