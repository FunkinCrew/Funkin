package funkin.freeplayStuff;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.util.FlxTimer;

class SongMenuItem extends FlxSpriteGroup
{
  var capsule:FlxSprite;
  var pixelIcon:FlxSprite;

  public var selected(default, set):Bool = false;

  public var songTitle:String = "Test";

  public var songText:FlxText;
  public var favIcon:FlxSprite;

  public var targetPos:FlxPoint = new FlxPoint();
  public var doLerp:Bool = false;
  public var doJumpIn:Bool = false;

  public var doJumpOut:Bool = false;

  public var onConfirm:Void->Void;

  public function new(x:Float, y:Float, song:String, ?character:String)
  {
    super(x, y);

    this.songTitle = song;

    capsule = new FlxSprite();
    capsule.frames = Paths.getSparrowAtlas('freeplay/freeplayCapsule');
    capsule.animation.addByPrefix('selected', 'mp3 capsule w backing0', 24);
    capsule.animation.addByPrefix('unselected', 'mp3 capsule w backing NOT SELECTED', 24);
    // capsule.animation
    add(capsule);

    songText = new FlxText(capsule.width * 0.23, 40, 0, songTitle, Std.int(40 * realScaled));
    songText.font = "5by7";
    songText.color = 0xFF43C1EA;
    add(songText);

    pixelIcon = new FlxSprite(80, 35);
    pixelIcon.makeGraphic(32, 32, 0x00000000);
    pixelIcon.antialiasing = false;
    add(pixelIcon);

    if (character != null) setCharacter(character);

    favIcon = new FlxSprite(400, 40);
    favIcon.frames = Paths.getSparrowAtlas('freeplay/favHeart');
    favIcon.animation.addByPrefix('fav', "favorite heart", 24, false);
    favIcon.animation.play('fav');
    favIcon.setGraphicSize(60, 60);
    add(favIcon);

    selected = selected; // just to kickstart the set_selected
  }

  /**
   * [Description]
   * @param char Should be songCharacter, and will get translated to the correct path via switch
   */
  public function setCharacter(char:String)
  {
    var charPath:String = "freeplay/icons/";

    switch (char)
    {
      case "monster-christmas":
        charPath += "monsterpixel";
      case "mom":
        charPath += "mommypixel";
      case "dad":
        charPath += "daddypixel";
      default:
        charPath += char + "pixel";
    }

    pixelIcon.loadGraphic(Paths.image(charPath));
    pixelIcon.setGraphicSize(Std.int(pixelIcon.width * 2));
    // pixelIcon.updateHitbox();
  }

  var frameInTicker:Float = 0;
  var frameInTypeBeat:Int = 0;

  var frameOutTicker:Float = 0;
  var frameOutTypeBeat:Int = 0;

  var xFrames:Array<Float> = [1.7, 1.8, 0.85, 0.85, 0.97, 0.97, 1];
  var xPosLerpLol:Array<Float> = [0.9, 0.4, 0.16, 0.16, 0.22, 0.22, 0.245]; // NUMBERS ARE JANK CUZ THE SCALING OR WHATEVER
  var xPosOutLerpLol:Array<Float> = [0.245, 0.75, 0.98, 0.98, 1.2]; // NUMBERS ARE JANK CUZ THE SCALING OR WHATEVER

  public final realScaled:Float = 0.8;

  public function initJumpIn(maxTimer:Float, ?force:Bool):Void
  {
    new FlxTimer().start((1 / 24) * maxTimer, function(doShit) {
      doJumpIn = true;
    });

    new FlxTimer().start((0.09 * maxTimer) + 0.85, function(lerpTmr) {
      doLerp = true;
    });

    if (!force)
    {
      new FlxTimer().start(((0.20 * maxTimer) / (1 + maxTimer)) + 0.75, function(swagShi) {
        songText.visible = true;
        alpha = 1;
      });
    }
    else
    {
      songText.visible = true;
      alpha = 1;
    }
  }

  override function update(elapsed:Float)
  {
    if (doJumpIn)
    {
      frameInTicker += elapsed;

      if (frameInTicker >= 1 / 24 && frameInTypeBeat < xFrames.length)
      {
        frameInTicker = 0;

        capsule.scale.x = xFrames[frameInTypeBeat];
        capsule.scale.y = 1 / xFrames[frameInTypeBeat];
        x = FlxG.width * xPosLerpLol[Std.int(Math.min(frameInTypeBeat, xPosLerpLol.length - 1))];

        capsule.scale.x *= realScaled;
        capsule.scale.y *= realScaled;

        frameInTypeBeat += 1;
      }
    }

    if (doJumpOut)
    {
      frameOutTicker += elapsed;

      if (frameOutTicker >= 1 / 24 && frameOutTypeBeat < xFrames.length)
      {
        frameOutTicker = 0;

        capsule.scale.x = xFrames[frameOutTypeBeat];
        capsule.scale.y = 1 / xFrames[frameOutTypeBeat];
        x = FlxG.width * xPosOutLerpLol[Std.int(Math.min(frameOutTypeBeat, xPosOutLerpLol.length - 1))];

        capsule.scale.x *= realScaled;
        capsule.scale.y *= realScaled;

        frameOutTypeBeat += 1;
      }
    }

    if (doLerp)
    {
      x = CoolUtil.coolLerp(x, targetPos.x, 0.3);
      y = CoolUtil.coolLerp(y, targetPos.y, 0.4);
    }

    super.update(elapsed);
  }

  public function intendedY(index:Int):Float
  {
    return (index * ((height * realScaled) + 10)) + 120;
  }

  function set_selected(value:Bool):Bool
  {
    // trace(value);

    // cute one liners, lol!
    songText.alpha = value ? 1 : 0.6;
    capsule.offset.x = value ? 0 : -5;
    capsule.animation.play(value ? "selected" : "unselected");
    return value;
  }
}
