package funkin.ui.freeplay;

import funkin.ui.FullScreenScaleMode;
import funkin.ui.freeplay.FreeplayState.FreeplaySongData;
import funkin.graphics.shaders.HSVShader;
import funkin.graphics.shaders.GaussianBlurShader;
import flixel.group.FlxGroup;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;
import flixel.util.FlxTimer;
import funkin.util.MathUtil;
import funkin.graphics.shaders.Grayscale;
import openfl.display.BlendMode;
import flixel.FlxObject;
import funkin.graphics.FunkinSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.addons.effects.FlxTrail;
import funkin.play.scoring.Scoring.ScoringRank;
import flixel.util.FlxColor;
import funkin.ui.PixelatedIcon;
import funkin.util.TouchUtil;
import funkin.util.SwipeUtil;

using StringTools;

class SongMenuItem extends FlxSpriteGroup
{
  public var capsule:FlxSprite;

  var pixelIcon:PixelatedIcon;

  /**
   * Modify this by calling `init()`
   * If `null`, assume this SongMenuItem is for the "Random Song" option.
   */
  public var freeplayData(default, null):Null<FreeplaySongData> = null;

  public var selected(default, set):Bool;
  public var forceHighlight(default, set):Bool;

  var songText:CapsuleText;

  public var favIconBlurred:FlxSprite;
  public var favIcon:FlxSprite;

  public var ranking:FreeplayRank;

  public var fakeRanking:FreeplayRank;

  var ranks:Array<String> = ["fail", "average", "great", "excellent", "perfect", "perfectsick"];

  public var targetPos:FlxPoint = new FlxPoint();
  public var doLerp:Bool = false;
  public var doJumpIn:Bool = false;

  public var doJumpOut:Bool = false;

  public var onConfirm:Void->Void;
  public var grayscaleShader:Grayscale;

  public var hsvShader(default, set):HSVShader;

  // var diffRatingSprite:FlxSprite;
  public var bpmText:FlxSprite;
  public var difficultyText:FlxSprite;
  public var weekType:FlxSprite;

  public var newText:FlxSprite;

  // public var weekType:FlxSprite;
  public var bigNumbers:Array<CapsuleNumber> = [];

  public var smallNumbers:Array<CapsuleNumber> = [];

  public var weekNumbers:Array<CapsuleNumber> = [];

  var impactThing:FunkinSprite;

  public var sparkle:FlxSprite;

  var sparkleTimer:FlxTimer;

  public var theActualHitbox:FlxObject;

  var index:Int;

  public var curSelected:Int;

  public function new(x:Float, y:Float)
  {
    super(x, y);

    capsule = new FlxSprite();
    capsule.frames = Paths.getSparrowAtlas('freeplay/freeplayCapsule/capsule/freeplayCapsule');
    capsule.animation.addByPrefix('selected', 'mp3 capsule w backing0', 24);
    capsule.animation.addByPrefix('unselected', 'mp3 capsule w backing NOT SELECTED', 24);
    // capsule.animation
    add(capsule);

    bpmText = new FlxSprite(144, 87).loadGraphic(Paths.image('freeplay/freeplayCapsule/bpmtext'));
    bpmText.setGraphicSize(Std.int(bpmText.width * 0.9));
    add(bpmText);

    difficultyText = new FlxSprite(414, 87).loadGraphic(Paths.image('freeplay/freeplayCapsule/difficultytext'));
    difficultyText.setGraphicSize(Std.int(difficultyText.width * 0.9));
    add(difficultyText);

    weekType = new FlxSprite(291, 87);
    weekType.frames = Paths.getSparrowAtlas('freeplay/freeplayCapsule/weektypes');

    weekType.animation.addByPrefix('WEEK', 'WEEK text instance 1', 24, false);
    weekType.animation.addByPrefix('WEEKEND', 'WEEKEND text instance 1', 24, false);

    weekType.setGraphicSize(Std.int(weekType.width * 0.9));
    add(weekType);

    newText = new FlxSprite(454, 9);
    newText.frames = Paths.getSparrowAtlas('freeplay/freeplayCapsule/new');
    newText.animation.addByPrefix('newAnim', 'NEW notif', 24, true);
    newText.animation.play('newAnim', true);
    newText.setGraphicSize(Std.int(newText.width * 0.9));

    // newText.visible = false;

    add(newText);

    // var debugNumber2:CapsuleNumber = new CapsuleNumber(0, 0, true, 2);
    // add(debugNumber2);

    for (i in 0...2)
    {
      var bigNumber:CapsuleNumber = new CapsuleNumber(466 + (i * 30), 32, true, 0);
      add(bigNumber);

      bigNumbers.push(bigNumber);
    }

    for (i in 0...3)
    {
      var smallNumber:CapsuleNumber = new CapsuleNumber(185 + (i * 11), 88.5, false, 0);
      add(smallNumber);

      smallNumbers.push(smallNumber);
    }

    // doesn't get added, simply is here to help with visibility of things for the pop in!
    grpHide = new FlxGroup();

    fakeRanking = new FreeplayRank(400, 15);
    add(fakeRanking);

    fakeRanking.visible = false;

    ranking = new FreeplayRank(400, 15);
    add(ranking);

    sparkle = new FlxSprite(ranking.x, ranking.y);
    sparkle.frames = Paths.getSparrowAtlas('freeplay/sparkle');
    sparkle.animation.addByPrefix('sparkle', 'sparkle Export0', 24, false);
    sparkle.animation.play('sparkle', true);
    sparkle.scale.set(0.8, 0.8);
    sparkle.blend = BlendMode.ADD;

    sparkle.visible = false;
    sparkle.alpha = 0.7;

    add(sparkle);

    // ranking.loadGraphic(Paths.image('freeplay/ranks/' + rank));
    // ranking.scale.x = ranking.scale.y = realScaled;
    // ranking.alpha = 0.75;
    // ranking.visible = false;
    // ranking.origin.set(capsule.origin.x - ranking.x, capsule.origin.y - ranking.y);
    // add(ranking);
    // grpHide.add(ranking);

    // switch (rank)
    // {
    //   case 'perfect':
    //     ranking.x -= 10;
    // }

    grayscaleShader = new Grayscale(1);

    // diffRatingSprite = new FlxSprite(145, 90).loadGraphic(Paths.image('freeplay/diffRatings/diff00'));
    // diffRatingSprite.shader = grayscaleShader;
    // diffRatingSprite.origin.set(capsule.origin.x - diffRatingSprite.x, capsule.origin.y - diffRatingSprite.y);
    // TODO: Readd once ratings are fully implemented
    // add(diffRatingSprite);
    // grpHide.add(diffRatingSprite);

    songText = new CapsuleText(capsule.width * 0.26, 45, 'Random', Std.int(40 * realScaled));
    add(songText);
    grpHide.add(songText);

    // TODO: Use value from metadata instead of random.
    updateDifficultyRating(FlxG.random.int(0, 20));

    pixelIcon = new PixelatedIcon(160, 35);
    add(pixelIcon);
    grpHide.add(pixelIcon);

    favIconBlurred = new FlxSprite(380, 40);
    favIconBlurred.frames = Paths.getSparrowAtlas('freeplay/favHeart');
    favIconBlurred.animation.addByPrefix('fav', 'favorite heart', 24, false);
    favIconBlurred.animation.play('fav');

    favIconBlurred.setGraphicSize(50, 50);
    favIconBlurred.blend = BlendMode.ADD;
    favIconBlurred.shader = new GaussianBlurShader(1.2);
    favIconBlurred.visible = false;
    add(favIconBlurred);

    favIcon = new FlxSprite(favIconBlurred.x, favIconBlurred.y);
    favIcon.frames = Paths.getSparrowAtlas('freeplay/favHeart');
    favIcon.animation.addByPrefix('fav', 'favorite heart', 24, false);
    favIcon.animation.play('fav');
    favIcon.setGraphicSize(50, 50);
    favIcon.visible = false;
    favIcon.blend = BlendMode.ADD;
    add(favIcon);

    var weekNumber:CapsuleNumber = new CapsuleNumber(355, 88.5, false, 0);
    add(weekNumber);

    weekNumbers.push(weekNumber);

    setVisibleGrp(false);

    theActualHitbox = new FlxObject(capsule.x + 160, capsule.y - 20, Math.round(capsule.width / 1.4), Math.round(capsule.height / 1.4));
    theActualHitbox.cameras = cameras;
    theActualHitbox.active = false;
  }

  function sparkleEffect(timer:FlxTimer):Void
  {
    sparkle.setPosition(FlxG.random.float(ranking.x - 20, ranking.x + 3), FlxG.random.float(ranking.y - 29, ranking.y + 4));
    sparkle.animation.play('sparkle', true);
    sparkleTimer = new FlxTimer().start(FlxG.random.float(1.2, 4.5), sparkleEffect);
  }

  // no way to grab weeks rn, so this needs to be done :/
  // negative values mean weekends
  function checkWeek(name:String):Void
  {
    // trace(name);
    var weekNum:Int = 0;
    switch (name)
    {
      case 'bopeebo' | 'fresh' | 'dadbattle':
        weekNum = 1;
      case 'spookeez' | 'south' | 'monster':
        weekNum = 2;
      case 'pico' | 'philly-nice' | 'blammed':
        weekNum = 3;
      case "satin-panties" | 'high' | 'milf':
        weekNum = 4;
      case "cocoa" | 'eggnog' | 'winter-horrorland':
        weekNum = 5;
      case 'senpai' | 'roses' | 'thorns':
        weekNum = 6;
      case 'ugh' | 'guns' | 'stress':
        weekNum = 7;
      case 'darnell' | 'lit-up' | '2hot' | 'blazin':
        weekNum = -1;
      default:
        weekNum = 0;
    }

    weekNumbers[0].digit = Std.int(Math.abs(weekNum));

    if (weekNum == 0)
    {
      weekType.visible = false;
      weekNumbers[0].visible = false;
    }
    else
    {
      weekType.visible = true;
      weekNumbers[0].visible = true;
    }
    if (weekNum > 0)
    {
      weekType.animation.play('WEEK', true);
    }
    else
    {
      weekType.animation.play('WEEKEND', true);
      weekNumbers[0].offset.x -= 35;
    }
  }

  /**
   * Checks whether the song is favorited, and/or has a rank, and adjusts the clipping
   * for the scenario when the text could be too long
   */
  public function checkClip():Void
  {
    var clipSize:Int = 290;
    var clipType:Int = 0;

    if (ranking.visible || fakeRanking.visible)
    {
      favIconBlurred.x = this.x + 370;
      favIcon.x = favIconBlurred.x;
      clipType += 1;
    }
    else
    {
      favIconBlurred.x = favIcon.x = this.x + 405;
    }

    if (favIcon.visible) clipType += 1;

    switch (clipType)
    {
      case 2:
        clipSize = 210;
      case 1:
        clipSize = 245;
    }
    songText.clipWidth = clipSize;
  }

  function updateBPM(newBPM:Int):Void
  {
    var shiftX:Float = 191;
    var tempShift:Float = 0;

    if (Math.floor(newBPM / 100) == 1)
    {
      shiftX = 186;
    }

    for (i in 0...smallNumbers.length)
    {
      smallNumbers[i].x = this.x + (shiftX + (i * 11));
      switch (i)
      {
        case 0:
          if (newBPM < 100)
          {
            smallNumbers[i].digit = 0;
          }
          else
          {
            smallNumbers[i].digit = Math.floor(newBPM / 100) % 10;
          }

        case 1:
          if (newBPM < 10)
          {
            smallNumbers[i].digit = 0;
          }
          else
          {
            smallNumbers[i].digit = Math.floor(newBPM / 10) % 10;

            if (Math.floor(newBPM / 10) % 10 == 1) tempShift = -4;
          }
        case 2:
          smallNumbers[i].digit = newBPM % 10;
        default:
          trace('why the fuck is this being called');
      }
      smallNumbers[i].x += tempShift;
    }
    // diffRatingSprite.loadGraphic(Paths.image('freeplay/diffRatings/diff${ratingPadded}'));
    // diffRatingSprite.visible = false;
  }

  var evilTrail:FlxTrail;

  public function fadeAnim():Void
  {
    impactThing = new FunkinSprite(0, 0);
    impactThing.frames = capsule.frames;
    impactThing.frame = capsule.frame;
    impactThing.updateHitbox();
    // impactThing.x = capsule.x;
    // impactThing.y = capsule.y;
    // picoFade.stamp(this, 0, 0);
    impactThing.alpha = 0;
    impactThing.zIndex = capsule.zIndex - 3;
    add(impactThing);
    FlxTween.tween(impactThing.scale, {x: 2.5, y: 2.5}, 0.5);
    // FlxTween.tween(impactThing, {alpha: 0}, 0.5);

    evilTrail = new FlxTrail(impactThing, null, 15, 2, 0.01, 0.069);
    evilTrail.blend = BlendMode.ADD;
    evilTrail.zIndex = capsule.zIndex - 5;
    FlxTween.tween(evilTrail, {alpha: 0}, 0.6,
      {
        ease: FlxEase.quadOut,
        onComplete: function(_) {
          remove(evilTrail);
        }
      });
    add(evilTrail);

    evilTrail.color = ranking.rank.getRankingFreeplayColor();
  }

  public function getTrailColor():FlxColor
  {
    return evilTrail.color;
  }

  public function refreshDisplay(updateRank:Bool = true):Void
  {
    if (freeplayData == null)
    {
      songText.text = 'Random';
      pixelIcon.visible = false;
      ranking.visible = false;
      favIcon.visible = false;
      favIconBlurred.visible = false;
      newText.visible = false;
    }
    else
    {
      songText.text = freeplayData.fullSongName;
      if (freeplayData.songCharacter != null) pixelIcon.setCharacter(freeplayData.songCharacter);
      pixelIcon.visible = true;
      updateBPM(Std.int(freeplayData.songStartingBpm) ?? 0);
      updateDifficultyRating(freeplayData.difficultyRating ?? 0);
      if (updateRank) updateScoringRank(freeplayData.scoringRank);
      newText.visible = freeplayData.isNew;
      favIcon.visible = freeplayData.isFav;
      favIconBlurred.visible = freeplayData.isFav;
      checkClip();
    }
    updateSelected();
  }

  function updateDifficultyRating(newRating:Int):Void
  {
    var ratingPadded:String = newRating < 10 ? '0$newRating' : '$newRating';

    for (i in 0...bigNumbers.length)
    {
      switch (i)
      {
        case 0:
          if (newRating < 10)
          {
            bigNumbers[i].digit = 0;
          }
          else
          {
            bigNumbers[i].digit = Math.floor(newRating / 10);
          }
        case 1:
          bigNumbers[i].digit = newRating % 10;
        default:
          trace('why the fuck is this being called');
      }
    }
    // diffRatingSprite.loadGraphic(Paths.image('freeplay/diffRatings/diff${ratingPadded}'));
    // diffRatingSprite.visible = false;
  }

  function updateScoringRank(newRank:Null<ScoringRank>):Void
  {
    if (sparkleTimer != null) sparkleTimer.cancel();
    sparkle.visible = false;

    this.ranking.rank = newRank;

    if (newRank == PERFECT_GOLD)
    {
      sparkleTimer = new FlxTimer().start(1, sparkleEffect);
      sparkle.visible = true;
    }
  }

  function set_hsvShader(value:HSVShader):HSVShader
  {
    this.hsvShader = value;
    capsule.shader = hsvShader;
    songText.shader = hsvShader;

    return value;
  }

  function textAppear():Void
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

  function setVisibleGrp(value:Bool):Void
  {
    for (spr in grpHide.members)
    {
      spr.visible = value;
    }

    updateSelected();
  }

  public function initPosition(x:Float, y:Float):Void
  {
    this.x = x;
    this.y = y;
  }

  public function initData(freeplayData:Null<FreeplaySongData>, ?styleData:FreeplayStyle = null, index:Int = null):Void
  {
    this.freeplayData = freeplayData;

    if (index != null) this.index = index;

    // im so mad i have to do this but im pretty sure with the capsules recycling i cant call the new function properly :/
    // if thats possible someone Please change the new function to be something like
    // capsule.frames = Paths.getSparrowAtlas(styleData == null ? 'freeplay/freeplayCapsule/capsule/freeplayCapsule' : styleData.getCapsuleAssetKey()); thank u luv u
    if (styleData != null)
    {
      capsule.frames = Paths.getSparrowAtlas(styleData.getCapsuleAssetKey());
      capsule.animation.addByPrefix('selected', 'mp3 capsule w backing0', 24);
      capsule.animation.addByPrefix('unselected', 'mp3 capsule w backing NOT SELECTED', 24);
      songText.applyStyle(styleData);
    }

    updateScoringRank(freeplayData?.scoringRank);
    favIcon.animation.curAnim.curFrame = favIcon.animation.curAnim.numFrames - 1;
    favIconBlurred.animation.curAnim.curFrame = favIconBlurred.animation.curAnim.numFrames - 1;

    refreshDisplay();

    checkWeek(freeplayData?.data.id);
  }

  public function initRandom(?styleData:FreeplayStyle = null):Void
  {
    initPosition(FlxG.width, 0);
    initData(null, styleData, 1);
    y = intendedY(0) + 10;
    targetPos.x = x;
    alpha = 0.5;
    songText.visible = false;
    favIcon.visible = false;
    favIconBlurred.visible = false;
    ranking.visible = false;
  }

  var frameInTicker:Float = 0;
  var frameInTypeBeat:Int = 0;

  var frameOutTicker:Float = 0;
  var frameOutTypeBeat:Int = 0;

  var xFrames:Array<Float> = [1.7, 1.8, 0.85, 0.85, 0.97, 0.97, 1];
  var xPosLerpLol:Array<Float> = [0, 0, 0.16, 0.16, 0.22, 0.22, 0.245]; // NUMBERS ARE JANK CUZ THE SCALING OR WHATEVER
  var xPosOutLerpLol:Array<Float> = [0.245, 0.75, 0.98, 0.98, 1.2]; // NUMBERS ARE JANK CUZ THE SCALING OR WHATEVER

  public var realScaled:Float = 0.8;

  public function initJumpIn(maxTimer:Float, ?force:Bool):Void
  {
    frameInTypeBeat = 0;

    new FlxTimer().start((1 / 24) * maxTimer, function(doShit) {
      doJumpIn = true;
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

  public function forcePosition():Void
  {
    visible = true;
    capsule.alpha = 1;
    updateSelected();
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

  override function update(elapsed:Float):Void
  {
    if (impactThing != null) impactThing.angle = capsule.angle;

    if (doJumpIn)
    {
      frameInTicker += elapsed;

      if (frameInTicker >= 1 / 24 && frameInTypeBeat < xFrames.length)
      {
        frameInTicker = 0;

        capsule.scale.x = xFrames[frameInTypeBeat];
        capsule.scale.y = 1 / xFrames[frameInTypeBeat];
        targetPos.x = FlxG.width * xPosLerpLol[Std.int(Math.min(frameInTypeBeat, xPosLerpLol.length - 1))];
        capsule.scale.x *= realScaled;
        capsule.scale.y *= realScaled;

        frameInTypeBeat += 1;
        final shiftx:Float = FullScreenScaleMode.wideScale.x * 320;
        final widescreenMult:Float = (FullScreenScaleMode.gameCutoutSize.x / 1.5) * 0.75;
        // Move the targetPos set to the if statement below if you want them to shift to their target positions after jumping in instead
        // I have no idea why this if instead of frameInTypeBeat == xFrames.length works even though they're the same thing
        if (targetPos.x <= shiftx) targetPos.x = intendedX(index - curSelected) + widescreenMult;
      }
      else if (frameInTypeBeat == xFrames.length)
      {
        doJumpIn = false;
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
        this.x = FlxG.width * xPosOutLerpLol[Std.int(Math.min(frameOutTypeBeat, xPosOutLerpLol.length - 1))];

        capsule.scale.x *= realScaled;
        capsule.scale.y *= realScaled;

        frameOutTypeBeat += 1;
      }
      else if (frameOutTypeBeat == xFrames.length)
      {
        doJumpOut = false;
      }
    }

    if (doLerp)
    {
      x = MathUtil.smoothLerpPrecision(x, targetPos.x, elapsed, 0.256);
      y = MathUtil.smoothLerpPrecision(y, targetPos.y, elapsed, 0.192);
    }

    theActualHitbox.x = x + 100;
    theActualHitbox.y = y + 20;

    super.update(elapsed);
  }

  /**
   * Play any animations associated with selecting this song.
   */
  public function confirm():Void
  {
    if (songText != null)
    {
      textAppear();
      songText.flickerText();
    }
    if (pixelIcon != null && pixelIcon.visible)
    {
      pixelIcon.animation.play('confirm');
    }
  }

  public function intendedX(index:Float):Float
  {
    return 270 + (60 * (Math.sin(index)));
  }

  public function intendedY(index:Float):Float
  {
    return (index * ((height * realScaled) + 10)) + 120;
  }

  function set_selected(value:Bool):Bool
  {
    // cute one liners, lol!
    selected = value;
    updateSelected();
    return selected;
  }

  function set_forceHighlight(value:Bool):Bool
  {
    // cute one liners, lol!
    forceHighlight = value;
    updateSelected();
    return forceHighlight;
  }

  function updateSelected():Void
  {
    grayscaleShader.setAmount((this.selected || this.forceHighlight) ? 0 : 0.8);
    songText.alpha = (this.selected || this.forceHighlight) ? 1 : 0.6;
    songText.blurredText.visible = (this.selected || this.forceHighlight) ? true : false;
    capsule.offset.x = (this.selected || this.forceHighlight) ? 0 : -5;
    capsule.animation.play((this.selected || this.forceHighlight) ? "selected" : "unselected");
    ranking.alpha = (this.selected || this.forceHighlight) ? 1 : 0.7;
    favIcon.alpha = (this.selected || this.forceHighlight) ? 1 : 0.6;
    favIconBlurred.alpha = (this.selected || this.forceHighlight) ? 1 : 0;
    ranking.color = (this.selected || this.forceHighlight) ? 0xFFFFFFFF : 0xFFAAAAAA;

    if (songText.tooLong) songText.resetText();

    if (selected && songText.tooLong) songText.initMove();
  }

  public override function kill():Void
  {
    super.kill();

    visible = true;
    capsule.alpha = 1;
    doLerp = false;
    doJumpIn = false;
    doJumpOut = false;
  }
}

/**
 * Holds blurred and unblurred versions of the rank icon
 */
class FreeplayRank extends FlxSpriteGroup
{
  public var rank(default, set):Null<ScoringRank> = null;

  var spr:FlxSprite;
  var blur:FlxSprite;

  function set_rank(val:Null<ScoringRank>):Null<ScoringRank>
  {
    rank = val;

    if (rank == null || val == null)
    {
      this.visible = false;
    }
    else
    {
      this.visible = true;

      spr.animation.play(val.getFreeplayRankIconAsset(), true, false);
      blur.animation.play(val.getFreeplayRankIconAsset(), true, false);

      centerOffsets(false);

      switch (val)
      {
        case SHIT:
          // offset.x -= 1;
        case GOOD:
          // offset.x -= 1;
          offset.y -= 8;
        case GREAT:
          // offset.x -= 1;
          offset.y -= 8;
        case EXCELLENT:
          // offset.y += 5;
        case PERFECT:
          // offset.y += 5;
        case PERFECT_GOLD:
          // offset.y += 5;
        default:
          centerOffsets(false);
          this.visible = false;
      }
      updateHitbox();
    }

    return rank = val;
  }

  public var baseX:Float = 0;
  public var baseY:Float = 0;

  public function new(x:Float, y:Float)
  {
    super(x, y);

    blur = new FlxSprite();
    blur.frames = Paths.getSparrowAtlas('freeplay/rankbadges');
    blur.shader = new GaussianBlurShader(1);
    add(blur);

    spr = new FlxSprite();
    spr.frames = Paths.getSparrowAtlas('freeplay/rankbadges');
    add(spr);

    for (i in members)
    {
      i.animation.addByPrefix('PERFECT', 'PERFECT rank0', 24, false);
      i.animation.addByPrefix('EXCELLENT', 'EXCELLENT rank0', 24, false);
      i.animation.addByPrefix('GOOD', 'GOOD rank0', 24, false);
      i.animation.addByPrefix('PERFECTSICK', 'PERFECT rank GOLD', 24, false);
      i.animation.addByPrefix('GREAT', 'GREAT rank0', 24, false);
      i.animation.addByPrefix('LOSS', 'LOSS rank0', 24, false);
    }

    blend = BlendMode.ADD;

    this.rank = null;

    // setGraphicSize(Std.int(width * 0.9));
    scale.set(0.9, 0.9);
    updateHitbox();
  }

  /**
   * Plays an animation for each member of the group
   * Just passes the arguments to `animation.play`, since that's not available in FlxGroups
   * @param animName The name of the animation to play
   * @param force false
   * @param reversed false
   * @param frame 0
   */
  public function playAnimationEach(animName:String, force = false, reversed = false, frame = 0):Void
  {
    for (i in members)
    {
      i.animation.play(animName, force, reversed, frame);
    }
  }
}

class CapsuleNumber extends FlxSprite
{
  public var digit(default, set):Int = 0;

  function set_digit(val):Int
  {
    animation.play(numToString[val], true, false, 0);

    centerOffsets(false);

    switch (val)
    {
      case 1:
        offset.x -= 4;
      case 3:
        offset.x -= 1;

      case 6:

      case 4:
        // offset.y += 5;
      case 9:
        // offset.y += 5;
      default:
        centerOffsets(false);
    }
    return val;
  }

  public var baseY:Float = 0;
  public var baseX:Float = 0;

  var numToString:Array<String> = ["ZERO", "ONE", "TWO", "THREE", "FOUR", "FIVE", "SIX", "SEVEN", "EIGHT", "NINE"];

  public function new(x:Float, y:Float, big:Bool = false, ?initDigit:Int = 0)
  {
    super(x, y);

    if (big)
    {
      frames = Paths.getSparrowAtlas('freeplay/freeplayCapsule/bignumbers');
    }
    else
    {
      frames = Paths.getSparrowAtlas('freeplay/freeplayCapsule/smallnumbers');
    }

    for (i in 0...10)
    {
      var stringNum:String = numToString[i];
      animation.addByPrefix(stringNum, '$stringNum', 24, false);
    }

    this.digit = initDigit;

    animation.play(numToString[initDigit], true);

    setGraphicSize(Std.int(width * 0.9));
    updateHitbox();
  }
}
