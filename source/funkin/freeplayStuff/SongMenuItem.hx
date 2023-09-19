package funkin.freeplayStuff;

import funkin.shaderslmfao.HSVShader;
import funkin.shaderslmfao.GaussianBlurShader;
import flixel.group.FlxGroup;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.util.FlxTimer;
import funkin.shaderslmfao.Grayscale;

class SongMenuItem extends FlxSpriteGroup
{
  public var capsule:FlxSprite;

  var pixelIcon:FlxSprite;

  public var selected(default, set):Bool;

  public var songTitle:String = "Test";

  public var songText:CapsuleText;
  public var favIcon:FlxSprite;
  public var ranking:FlxSprite;

  var ranks:Array<String> = ["fail", "average", "great", "excellent", "perfect"];

  // lol...
  var diffRanks:Array<String> = [
    "00", "01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12", "14", "15"
  ];

  public var targetPos:FlxPoint = new FlxPoint();
  public var doLerp:Bool = false;
  public var doJumpIn:Bool = false;

  public var doJumpOut:Bool = false;

  public var onConfirm:Void->Void;
  public var diffGrayscale:Grayscale;

  public var hsvShader(default, set):HSVShader;

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

    // doesn't get added, simply is here to help with visibility of things for the pop in!
    grpHide = new FlxGroup();

    var rank:String = FlxG.random.getObject(ranks);

    ranking = new FlxSprite(capsule.width * 0.84, 30);
    ranking.loadGraphic(Paths.image("freeplay/ranks/" + rank));
    ranking.scale.x = ranking.scale.y = realScaled;
    ranking.alpha = 0.75;
    ranking.origin.set(capsule.origin.x - ranking.x, capsule.origin.y - ranking.y);
    add(ranking);
    grpHide.add(ranking);

    diffGrayscale = new Grayscale(1);

    var diffRank = new FlxSprite(145, 90).loadGraphic(Paths.image("freeplay/diffRankings/diff" + FlxG.random.getObject(diffRanks)));
    diffRank.shader = diffGrayscale;
    diffRank.visible = false;
    add(diffRank);
    diffRank.origin.set(capsule.origin.x - diffRank.x, capsule.origin.y - diffRank.y);
    grpHide.add(diffRank);

    switch (rank)
    {
      case "perfect":
        ranking.x -= 10;
    }

    songText = new CapsuleText(capsule.width * 0.26, 45, songTitle, Std.int(40 * realScaled));
    add(songText);
    grpHide.add(songText);

    pixelIcon = new FlxSprite(155, 15);
    pixelIcon.makeGraphic(32, 32, 0x00000000);
    pixelIcon.antialiasing = false;
    pixelIcon.active = false;
    add(pixelIcon);
    grpHide.add(pixelIcon);

    if (character != null) setCharacter(character);

    favIcon = new FlxSprite(400, 40);
    favIcon.frames = Paths.getSparrowAtlas('freeplay/favHeart');
    favIcon.animation.addByPrefix('fav', "favorite heart", 24, false);
    favIcon.animation.play('fav');
    favIcon.setGraphicSize(50, 50);
    favIcon.visible = false;
    add(favIcon);
    // grpHide.add(favIcon);

    setVisibleGrp(false);
  }

  function set_hsvShader(value:HSVShader):HSVShader
  {
    this.hsvShader = value;
    capsule.shader = hsvShader;
    songText.shader = hsvShader;

    return value;
  }

  function textAppear()
  {
    songText.scale.x = 1.7;
    songText.scale.y = 0.2;

    new FlxTimer().start(1 / 24, function(_) {
      songText.scale.x = 0.4;
      songText.scale.y = 1.4;
    });

    new FlxTimer().start(2 / 24, function(_) {
      songText.scale.x = songText.scale.y = 1;
    });
  }

  function setVisibleGrp(value:Bool)
  {
    for (spr in grpHide.members)
    {
      spr.visible = value;
    }

    if (value) textAppear();

    selectedAlpha();
  }

  public function init(x:Float, y:Float, song:String, ?character:String)
  {
    this.x = x;
    this.y = y;
    this.songTitle = song;
    songText.text = this.songTitle;
    if (character != null) setCharacter(character);

    selected = selected;
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
    pixelIcon.scale.x = pixelIcon.scale.y = 2;
    pixelIcon.origin.x = 100;
    // pixelIcon.origin.x = capsule.origin.x;
    // pixelIcon.offset.x -= pixelIcon.origin.x;
  }

  var frameInTicker:Float = 0;
  var frameInTypeBeat:Int = 0;

  var frameOutTicker:Float = 0;
  var frameOutTypeBeat:Int = 0;

  var xFrames:Array<Float> = [1.7, 1.8, 0.85, 0.85, 0.97, 0.97, 1];
  var xPosLerpLol:Array<Float> = [0.9, 0.4, 0.16, 0.16, 0.22, 0.22, 0.245]; // NUMBERS ARE JANK CUZ THE SCALING OR WHATEVER
  var xPosOutLerpLol:Array<Float> = [0.245, 0.75, 0.98, 0.98, 1.2]; // NUMBERS ARE JANK CUZ THE SCALING OR WHATEVER

  public var realScaled:Float = 0.8;

  public function initJumpIn(maxTimer:Float, ?force:Bool):Void
  {
    frameInTypeBeat = 0;

    new FlxTimer().start((1 / 24) * maxTimer, function(doShit) {
      doJumpIn = true;
    });

    new FlxTimer().start((0.09 * maxTimer) + 0.85, function(lerpTmr) {
      doLerp = true;
    });

    if (force)
    {
      visible = true;
      capsule.alpha = 1;
      setVisibleGrp(true);
    }
    else
    {
      new FlxTimer().start((xFrames.length / 24) * 2.5, function(_) {
        visible = true;
        capsule.alpha = 1;
        setVisibleGrp(true);
      });
    }
  }

  var grpHide:FlxGroup;

  public function forcePosition()
  {
    visible = true;
    capsule.alpha = 1;
    selectedAlpha();
    doLerp = true;
    doJumpIn = false;
    doJumpOut = false;

    frameInTypeBeat = xFrames.length;
    frameOutTypeBeat = 0;

    capsule.scale.x = xFrames[frameInTypeBeat - 1];
    capsule.scale.y = 1 / xFrames[frameInTypeBeat - 1];
    // x = FlxG.width * xPosLerpLol[Std.int(Math.min(frameInTypeBeat - 1, xPosLerpLol.length - 1))];

    x = targetPos.x;
    y = targetPos.y;

    capsule.scale.x *= realScaled;
    capsule.scale.y *= realScaled;

    setVisibleGrp(true);
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
    trace("set_selected: " + value);
    // cute one liners, lol!
    diffGrayscale.setAmount(value ? 0 : 0.8);
    songText.alpha = value ? 1 : 0.6;
    songText.blurredText.visible = value ? true : false;
    capsule.offset.x = value ? 0 : -5;
    capsule.animation.play(value ? "selected" : "unselected");
    ranking.alpha = value ? 1 : 0.7;
    ranking.color = value ? 0xFFFFFFFF : 0xFFAAAAAA;
    return value;
  }
}
