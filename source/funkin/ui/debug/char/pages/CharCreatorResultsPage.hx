package funkin.ui.debug.char.pages;

import flixel.tweens.FlxEase;
import openfl.media.Sound;
import haxe.ui.components.Label;
import haxe.ui.components.CheckBox;
import haxe.ui.containers.Box;
import haxe.ui.containers.menus.Menu;
import haxe.ui.containers.menus.MenuItem;
import haxe.ui.containers.menus.MenuCheckBox;
import funkin.graphics.adobeanimate.FlxAtlasSprite;
import funkin.ui.debug.char.animate.CharSelectAtlasSprite;
import funkin.graphics.FunkinSprite;
import funkin.ui.debug.char.components.dialogs.results.*;
import funkin.ui.debug.char.components.dialogs.DefaultPageDialog;
import funkin.data.freeplay.player.PlayerData;
import funkin.data.freeplay.player.PlayerRegistry;
import funkin.play.components.TallyCounter;
import funkin.play.components.ClearPercentCounter;
import funkin.play.scoring.Scoring.ScoringRank;
import funkin.play.ResultScore;
import funkin.util.SortUtil;
import flixel.graphics.frames.FlxBitmapFont;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.math.FlxPoint;
import flixel.text.FlxBitmapText;
import flixel.tweens.FlxTween;
import funkin.audio.FunkinSound;
import flixel.util.FlxGradient;
import flixel.util.FlxTimer;
import flixel.util.FlxSort;
import flixel.FlxSprite;
import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import flixel.addons.display.shapes.FlxShapeCircle;

using StringTools;

class CharCreatorResultsPage extends CharCreatorDefaultPage
{
  static final ALL_RANKS:Array<ScoringRank> = [PERFECT_GOLD, PERFECT, EXCELLENT, GREAT, GOOD, SHIT];

  var data:WizardGenerateParams;

  public var dialogMap:Map<ResultsDialogType, DefaultPageDialog>;

  var rankMusicMap:Map<ScoringRank, ResultsMusic> = [];

  public var currentAnims:Array<CharCreatorResultAnim> = [];
  public var currentMarkers:Array<FlxShapeCircle> = [];
  public var frameTxts:Array<FlxText> = [];

  override public function new(state:CharCreatorState, data:WizardGenerateParams)
  {
    super(state);
    this.data = data;

    dialogMap = new Map<ResultsDialogType, DefaultPageDialog>();
    dialogMap.set(RankAnims, new ResultsAnimDialog(this));
    dialogMap.set(Music, new ResultsMusicDialog(this));

    var player = PlayerRegistry.instance.fetchEntry(data.importedPlayerData ?? "");

    for (rank in ALL_RANKS)
      rankMusicMap.set(rank, new ResultsMusic(player, rank));

    if (player != null) generateSpritesByData(player.getResultsAnimationDatas(PERFECT_GOLD));

    generateUI();
    initFunkinUI();
    makeMarkers();
    refresh();
  }

  var labelRank:Label = new Label();
  var checkPlayMusic:CheckBox = new CheckBox();

  override public function fillUpPageSettings(menu:Menu):Void
  {
    var animDialog = new MenuCheckBox();
    animDialog.text = "Rank Animations";
    animDialog.onClick = function(_) {
      dialogMap[RankAnims].hidden = !animDialog.selected;
    }
    menu.addComponent(animDialog);

    var musicDialog = new MenuCheckBox();
    musicDialog.text = "Rank Music";
    musicDialog.onClick = function(_) {
      dialogMap[Music].hidden = !musicDialog.selected;
    }
    menu.addComponent(musicDialog);
  }

  override public function fillUpBottomBar(left:Box, middle:Box, right:Box):Void
  {
    var splitRule = new haxe.ui.components.VerticalRule();
    splitRule.percentHeight = 80;

    middle.addComponent(labelRank);
    middle.addComponent(splitRule);
    middle.addComponent(checkPlayMusic);
  }

  function generateUI():Void
  {
    var animDialog:ResultsAnimDialog = cast dialogMap[RankAnims];

    labelRank.text = animDialog.rankDropdown.safeSelectedItem.text;
    labelRank.styleNames = "infoText";
    labelRank.verticalAlign = "center";

    checkPlayMusic.text = "Play Music";

    labelRank.onClick = function(_) {
      var supposedInd = animDialog.rankDropdown.selectedIndex + 1;
      if (supposedInd >= animDialog.rankDropdown.dataSource.size) supposedInd = 0;
      animDialog.rankDropdown.selectedIndex = supposedInd;

      clearSprites();
      animDialog.changeRankPreview();
      playAnimation();
    }

    labelRank.onRightClick = function(_) {
      var supposedInd = animDialog.rankDropdown.selectedIndex - 1;
      if (supposedInd < 0) supposedInd = animDialog.rankDropdown.dataSource.size - 1;
      animDialog.rankDropdown.selectedIndex = supposedInd;

      clearSprites();
      animDialog.changeRankPreview();
      playAnimation();
    }
  }

  override public function performCleanup():Void
  {
    var animDialog:ResultsAnimDialog = cast dialogMap[RankAnims];
    rankMusicMap[animDialog.currentRank].stop();
    FlxG.sound.music.volume = 1;
    setStatusOfEverything(false);
  }

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);

    for (marker in currentMarkers)
    {
      if (currentAnims[marker.ID].sprite == null) continue;

      switch (marker.fillColor)
      {
        case 0xffff00ff:
          var atlas:CharSelectAtlasSprite = cast currentAnims[marker.ID].sprite;
          var pivotPos = atlas.getPivotPosition();
          marker.visible = (daState.menubarCheckToolsPivot.selected);

          if (pivotPos != null) marker.setPosition(pivotPos.x - marker.width / 2, pivotPos.y - marker.height / 2);

        case 0xff00ffff:
          var atlas:CharSelectAtlasSprite = cast currentAnims[marker.ID].sprite;
          var basePos = atlas.getBasePosition();
          marker.visible = (daState.menubarCheckToolsBase.selected);

          if (basePos != null) marker.setPosition(basePos.x - marker.width / 2, basePos.y - marker.height / 2);

        case 0xffffff00:
          var sparrow:FunkinSprite = cast currentAnims[marker.ID].sprite;
          marker.visible = (daState.menubarCheckToolsMidpoint.selected);
          marker.setPosition(sparrow.getMidpoint().x - marker.width / 2, sparrow.getMidpoint().y - marker.height / 2);
      }
    }

    for (txt in frameTxts) // gonna put the anim speed shiz here too lol!
    {
      txt.visible = daState.menubarCheckToolsFrames.selected;
      if (currentAnims[txt.ID].sprite == null) continue;

      var atlas = (Std.isOfType(currentAnims[txt.ID].sprite, CharSelectAtlasSprite) ? cast(currentAnims[txt.ID].sprite, CharSelectAtlasSprite) : null);
      var sparrow = (Std.isOfType(currentAnims[txt.ID].sprite, FunkinSprite) ? cast(currentAnims[txt.ID].sprite, FunkinSprite) : null);

      if (atlas != null && sparrow == null)
      {
        var pivotPos = atlas.getPivotPosition();

        txt.text = "Frame: " + atlas.curFrame + "/" + (atlas.totalFrames - 1);
        if (pivotPos != null) txt.setPosition(pivotPos.x - txt.width / 2, pivotPos.y - txt.height / 2);
      }
      else if (atlas == null && sparrow != null)
      {
        txt.text = "Frame: " + (sparrow.animation.curAnim?.curFrame ?? 0) + "/" + ((sparrow.animation.curAnim?.numFrames ?? 0) - 1);
        txt.setPosition(sparrow.getMidpoint().x - txt.width / 2, sparrow.getMidpoint().y - txt.height / 2);
      }
    }

    if (!CharCreatorUtil.isHaxeUIDialogOpen && FlxG.keys.justPressed.SPACE)
    {
      if (!FlxG.keys.pressed.SHIFT && daState.menubarCheckToolsPause.selected)
      {
        setStatusOfEverything(!activityStatus);
      }
      else
      {
        setStatusOfEverything();
        playAnimation();
      }
    }
  }

  public function clearSprites():Void
  {
    setStatusOfEverything();

    while (currentAnims.length > 0)
    {
      var data = currentAnims.shift();
      var atlas = (Std.isOfType(data.sprite, CharSelectAtlasSprite) ? cast(data.sprite, CharSelectAtlasSprite) : null);
      var sparrow = (Std.isOfType(data.sprite, FunkinSprite) ? cast(data.sprite, FunkinSprite) : null);

      if (atlas != null)
      {
        atlas.kill();
        remove(atlas, true);
        atlas.destroy();
      }
      else if (sparrow != null)
      {
        sparrow.kill();
        remove(sparrow, true);
        sparrow.destroy();
      }
    }
  }

  public function makeMarkers()
  {
    while (currentMarkers.length > 0)
    {
      var circ = currentMarkers.shift();

      circ.kill();
      remove(circ, true);
      circ.destroy();
    }

    while (frameTxts.length > 0)
    {
      var txt = frameTxts.shift();

      txt.kill();
      remove(txt, true);
      txt.destroy();
    }

    for (i in 0...currentAnims.length)
    {
      var isAtlas:Bool = Std.isOfType(currentAnims[i].sprite, CharSelectAtlasSprite);

      if (isAtlas)
      {
        var pivotPointer = new FlxShapeCircle(0, 0, 16, cast {thickness: 2, color: 0xffff00ff}, 0xffff00ff);
        var basePointer = new FlxShapeCircle(0, 0, 16, cast {thickness: 2, color: 0xff00ffff}, 0xff00ffff);

        pivotPointer.ID = basePointer.ID = i;
        pivotPointer.visible = basePointer.visible = false;
        pivotPointer.alpha = basePointer.alpha = 0.5;
        pivotPointer.zIndex = basePointer.zIndex = flixel.math.FlxMath.MAX_VALUE_INT - 2;

        add(pivotPointer);
        add(basePointer);
        currentMarkers.push(pivotPointer);
        currentMarkers.push(basePointer);
      }
      else
      {
        var midPointPointer = new FlxShapeCircle(0, 0, 16, cast {thickness: 2, color: 0xffffff00}, 0xffffff00);
        midPointPointer.ID = i;
        midPointPointer.visible = false;
        midPointPointer.zIndex = flixel.math.FlxMath.MAX_VALUE_INT - 2;
        midPointPointer.alpha = 0.5;
        add(midPointPointer);
        currentMarkers.push(midPointPointer);
      }

      var frameTxt = new FlxText(0, 0, 0, "", 48);
      frameTxt.setFormat(Paths.font("vcr.ttf"), 48, FlxColor.WHITE, LEFT);
      frameTxt.setBorderStyle(OUTLINE, FlxColor.BLACK, 3);
      frameTxt.zIndex = flixel.math.FlxMath.MAX_VALUE_INT;
      frameTxt.ID = i;
      add(frameTxt);

      frameTxts.push(frameTxt);
    }
  }

  public function generateSpritesByData(data:Array<PlayerResultsAnimationData>)
  {
    clearSprites();
    for (animData in data)
    {
      if (animData == null) continue;

      var animPath:String = Paths.stripLibrary(animData.assetPath);
      var animLibrary:String = Paths.getLibrary(animData.assetPath);
      var offsets = animData.offsets ?? [0, 0];

      switch (animData.renderType)
      {
        case 'animateatlas':
          var animation:CharSelectAtlasSprite = new CharSelectAtlasSprite(offsets[0], offsets[1], Paths.animateAtlas(animPath, animLibrary));
          animation.zIndex = animData.zIndex ?? 500;

          animation.scale.set(animData.scale ?? 1.0, animData.scale ?? 1.0);

          if (!(animData.looped ?? true))
          {
            // Animation is not looped.
            animation.onAnimationComplete.add((_name:String) -> {
              if (animation != null) animation.anim.pause();
            });
          }
          else if (animData.loopFrameLabel != null)
          {
            animation.onAnimationComplete.add((_name:String) -> {
              if (animation != null) animation.playAnimation(animData.loopFrameLabel ?? '', true, false, true); // unpauses this anim, since it's on PlayOnce!
            });
          }
          else if (animData.loopFrame != null)
          {
            animation.onAnimationComplete.add((_name:String) -> {
              if (animation != null)
              {
                animation.anim.curFrame = animData.loopFrame ?? 0;
                animation.anim.play(); // unpauses this anim, since it's on PlayOnce!
              }
            });
          }

          currentAnims.push(
            {
              sprite: animation,
              delay: animData.delay ?? 0.0
            });

          add(animation);
        case 'sparrow':
          var animation:FunkinSprite = FunkinSprite.createSparrow(offsets[0], offsets[1], animPath);
          animation.animation.addByPrefix('idle', '', 24, false, false, false);

          if (animData.loopFrame != null)
          {
            animation.animation.finishCallback = (_name:String) -> {
              if (animation != null)
              {
                animation.animation.play('idle', true, false, animData.loopFrame ?? 0);
              }
            }
          }

          currentAnims.push(
            {
              sprite: animation,
              delay: animData.delay ?? 0.0
            });
          add(animation);
      }
    }

    refresh();
    makeMarkers();
  }

  var animTimers:Array<FlxTimer> = [];
  var animTweens:Array<FlxTween> = [];
  var previousMusic:Null<ResultsMusic> = null;

  public function playAnimation():Void
  {
    stopTweensAndTimers();

    if (previousMusic != null) previousMusic.stop();

    refresh(); // just to be sure

    var animDialog:ResultsAnimDialog = cast dialogMap[RankAnims];

    var rank = animDialog.currentRank;

    labelRank.text = animDialog.rankDropdown.safeSelectedItem.text;

    var newMusic = rankMusicMap[rank];
    previousMusic = newMusic;

    if (checkPlayMusic.selected)
    {
      FlxG.sound.music.volume = 0;
      animTimers.push(new FlxTimer().start(rank.getMusicDelay(), _ -> {
        newMusic.play();
      }));
    }
    else
    {
      newMusic.stop();
      FlxG.sound.music.volume = 1;
    }

    for (ind => rating in ratingGrp.members)
    {
      rating.curNumber = 0;
      rating.visible = false;
      animTimers.push(new FlxTimer().start((0.3 * ind) + 1.20, _ -> {
        rating.visible = true;
        animTweens.push(FlxTween.tween(rating, {curNumber: rating.neededNumber}, 0.5, {ease: FlxEase.quartOut}));
      }));
    }

    resultsAnim.visible = false;
    animTimers.push(new FlxTimer().start(6 / 24, _ -> {
      resultsAnim.visible = true;
      resultsAnim.animation.play("result", true);
    }));

    ratingsPopin.visible = false;
    animTimers.push(new FlxTimer().start(21 / 24, _ -> {
      ratingsPopin.visible = true;
      ratingsPopin.animation.play("idle", true);
    }));

    scorePopin.visible = false;
    animTimers.push(new FlxTimer().start(36 / 24, _ -> {
      scorePopin.visible = true;
      scorePopin.animation.play("score", true);
    }));

    score.visible = false;
    clearPercentCounter.visible = false;

    animTimers.push(new FlxTimer().start(37 / 24, _ -> {
      score.visible = true;
      score.animateNumbers();

      var clearPercentLerp:Float = 0;
      clearPercentCounter.alpha = 1.0;
      clearPercentCounter.curNumber = 0;
      clearPercentCounter.visible = true;
      animTweens.push(FlxTween.tween(clearPercentCounter, {curNumber: 100}, 58 / 24,
        {
          ease: FlxEase.quartOut,
          onUpdate: _ -> {
            clearPercentLerp = Math.round(clearPercentLerp);
            clearPercentCounter.curNumber = Math.round(clearPercentCounter.curNumber);
            if (clearPercentLerp != clearPercentCounter.curNumber)
            {
              clearPercentLerp = clearPercentCounter.curNumber;

              if (checkPlayMusic.selected) FunkinSound.playOnce(Paths.sound('scrollMenu'));
            }
          },
          onComplete: _ -> {
            if (checkPlayMusic.selected) FunkinSound.playOnce(Paths.sound('confirmMenu'));

            clearPercentCounter.curNumber = 100;

            clearPercentCounter.flash(true);
            animTimers.push(new FlxTimer().start(0.4, _ -> {
              clearPercentCounter.flash(false);
            }));

            animTimers.push(new FlxTimer().start(0.25, _ -> {
              animTweens.push(FlxTween.tween(clearPercentCounter, {alpha: 0}, 0.5,
                {
                  startDelay: 0.5,
                  ease: FlxEase.quartOut,
                  onComplete: _ -> {
                    clearPercentCounter.visible = false;
                  }
                }));
            }));
          }
        }));
    }));

    clearPercentSmall.curNumber = 100;
    clearPercentSmall.visible = false;
    animTimers.push(new FlxTimer().start(rank.getBFDelay(), _ -> {
      clearPercentSmall.visible = true;
      clearPercentSmall.flash(true);
      animTimers.push(new FlxTimer().start(0.4, _ -> {
        clearPercentSmall.flash(false);
      }));
    }));

    for (bs in currentAnims)
    {
      var atlas = (Std.isOfType(bs.sprite, CharSelectAtlasSprite) ? cast(bs.sprite, CharSelectAtlasSprite) : null);
      var sparrow = (Std.isOfType(bs.sprite, FunkinSprite) ? cast(bs.sprite, FunkinSprite) : null);
      if (atlas == null && sparrow == null) continue;

      if (sparrow != null) sparrow.visible = false;
      if (atlas != null) atlas.visible = false;

      animTimers.push(new FlxTimer().start(bs.delay + rank.getBFDelay(), _ -> {
        if (atlas == null && sparrow == null) return;

        if (sparrow != null) sparrow.visible = true;
        if (atlas != null) atlas.visible = true;

        if (atlas != null) atlas.anim.play("", true);
        else if (sparrow != null) sparrow.animation.play("idle", true);
      }));
    }
  }

  var activityStatus:Bool = true;

  public function setStatusOfEverything(value:Bool = true)
  {
    activityStatus = value;
    for (timer in animTimers)
      timer.active = value;

    for (tween in animTweens)
      tween.active = value;

    var animDialog:ResultsAnimDialog = cast dialogMap[RankAnims];
    var rank = animDialog.currentRank;

    for (onething in members)
    {
      onething.active = value;
    }

    // genuine witchcraft
    (value ? rankMusicMap[rank].resume : rankMusicMap[rank].pause)();
  }

  function stopTweensAndTimers():Void
  {
    while (animTimers.length > 0)
    {
      var timer = animTimers.shift();
      timer.cancel();
      timer.destroy();
    }

    while (animTweens.length > 0)
    {
      var tween = animTweens.shift();
      tween.cancel();
      tween.destroy();
    }
  }

  public function getRankFromString(str:String)
  {
    return switch (str.toLowerCase())
    {
      case "perfect":
        PERFECT;
      case "excellent":
        EXCELLENT;
      case "great":
        GREAT;
      case "good":
        GOOD;
      case "shit":
        SHIT;
      default: PERFECT_GOLD;
    }
  }

  var difficulty:FlxSprite;
  var songName:FlxBitmapText;
  var clearPercentCounter:ClearPercentCounter;
  var clearPercentSmall:ClearPercentCounter;
  var resultsAnim:FunkinSprite;
  var ratingsPopin:FunkinSprite;
  var scorePopin:FunkinSprite;
  var score:ResultScore;
  var ratingGrp:FlxTypedSpriteGroup<TallyCounter>;

  function initFunkinUI():Void
  {
    var bg:FlxSprite = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, [0xFFFECC5C, 0xFFFDC05C], 90);
    bg.scrollFactor.set();
    bg.zIndex = 10;
    add(bg);

    clearPercentCounter = new ClearPercentCounter(FlxG.width / 2 + 190, FlxG.height / 2 - 70, 0);
    clearPercentCounter.zIndex = 450;
    add(clearPercentCounter);

    difficulty = new FlxSprite(555, 122);
    difficulty.zIndex = 1000;
    difficulty.loadGraphic(Paths.image("resultScreen/diff_hard"));
    add(difficulty);

    var fontLetters:String = "AaBbCcDdEeFfGgHhiIJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz:1234567890";
    songName = new FlxBitmapText(FlxBitmapFont.fromMonospace(Paths.image("resultScreen/tardlingSpritesheet"), fontLetters, FlxPoint.get(49, 62)));
    songName.text = "Playable Character Creator";
    songName.letterSpacing = -15;
    songName.angle = -4.4;
    songName.zIndex = 1000;
    songName.x = difficulty.x + difficulty.width + 60 + 94;
    songName.y = 122 - 25 - (10 * (songName.text.length / 15));
    add(songName);

    clearPercentSmall = new ClearPercentCounter(difficulty.x + difficulty.width + 60, 122 - 5, 100, true);
    clearPercentSmall.zIndex = 1000;
    add(clearPercentSmall);

    var blackTopBar:FlxSprite = new FlxSprite().loadGraphic(Paths.image("resultScreen/topBarBlack"));
    blackTopBar.zIndex = 1010;
    add(blackTopBar);

    var soundSystem:FunkinSprite = FunkinSprite.createSparrow(-15, -180, 'resultScreen/soundSystem');
    soundSystem.animation.addByPrefix("idle", "sound system", 24, false);
    soundSystem.animation.play("idle");
    soundSystem.zIndex = 1100;
    add(soundSystem);

    resultsAnim = FunkinSprite.createSparrow(-200, -10, "resultScreen/results");
    resultsAnim.animation.addByPrefix("result", "results instance 1", 24, false);
    resultsAnim.animation.play("result");
    resultsAnim.zIndex = 1200;
    add(resultsAnim);

    ratingsPopin = FunkinSprite.createSparrow(-135, 135, "resultScreen/ratingsPopin");
    ratingsPopin.animation.addByPrefix("idle", "Categories", 24, false);
    ratingsPopin.animation.play("idle");
    ratingsPopin.zIndex = 1200;
    add(ratingsPopin);

    scorePopin = FunkinSprite.createSparrow(-180, 515, "resultScreen/scorePopin");
    scorePopin.animation.addByPrefix("score", "tally score", 24, false);
    scorePopin.animation.play("score");
    scorePopin.zIndex = 1200;
    add(scorePopin);

    var hStuf:Int = 50;

    ratingGrp = new FlxTypedSpriteGroup<TallyCounter>();
    ratingGrp.zIndex = 1200;
    add(ratingGrp);

    /**
     * NOTE: We display how many notes were HIT, not how many notes there were in total.
     *
     */
    var totalHit:TallyCounter = new TallyCounter(375, hStuf * 3, 999);
    ratingGrp.add(totalHit);

    var maxCombo:TallyCounter = new TallyCounter(375, hStuf * 4, 999);
    ratingGrp.add(maxCombo);

    hStuf += 2;
    var extraYOffset:Float = 7;

    hStuf += 2;

    var tallySick:TallyCounter = new TallyCounter(230, (hStuf * 5) + extraYOffset, 999, 0xFF89E59E);
    ratingGrp.add(tallySick);

    var tallyGood:TallyCounter = new TallyCounter(210, (hStuf * 6) + extraYOffset, 999, 0xFF89C9E5);
    ratingGrp.add(tallyGood);

    var tallyBad:TallyCounter = new TallyCounter(190, (hStuf * 7) + extraYOffset, 999, 0xFFE6CF8A);
    ratingGrp.add(tallyBad);

    var tallyShit:TallyCounter = new TallyCounter(220, (hStuf * 8) + extraYOffset, 999, 0xFFE68C8A);
    ratingGrp.add(tallyShit);

    var tallyMissed:TallyCounter = new TallyCounter(260, (hStuf * 9) + extraYOffset, 999, 0xFFC68AE6);
    ratingGrp.add(tallyMissed);

    score = new ResultScore(35, 305, 10, 999);
    score.zIndex = 1200;
    add(score);
  }

  public function refresh():Void
  {
    sort(SortUtil.byZIndex, FlxSort.ASCENDING);
  }
}

private class ResultsMusic
{
  var introMusic:Null<FunkinSound>;
  var music:Null<FunkinSound>;

  public function new(player, rank)
  {
    var path = player?.getResultsMusicPath(rank) ?? "";

    var musicPath = Paths.music('$path/$path');
    music = FunkinSound.load(musicPath, 1.0, true);

    var introMusicPath = Paths.music('$path/$path-intro');
    if (openfl.utils.Assets.exists(introMusicPath))
    {
      introMusic = FunkinSound.load(introMusicPath, 1.0, () -> {
        music?.play();
      });
    }
  }

  public function reloadSoundsFromBytes(?musicBytes:haxe.io.Bytes, ?introBytes:haxe.io.Bytes)
  {
    music = funkin.util.assets.SoundUtil.buildSoundFromBytes(musicBytes);
    introMusic = funkin.util.assets.SoundUtil.buildSoundFromBytes(introBytes);

    if (introMusic != null) introMusic.onComplete = function() music?.play();
    if (music != null) music.looped = true;
  }

  public function play():Void
  {
    if (introMusic != null) introMusic?.play();
    else
      music?.play();
  }

  public function stop():Void
  {
    introMusic?.stop();
    music?.stop();
  }

  public function pause():Void
  {
    introMusic?.pause();
    music?.pause();
  }

  public function resume():Void
  {
    introMusic?.resume();
    music?.resume();
  }

  public function destroy():Void
  {
    stop();
    introMusic?.destroy();
    music?.destroy();
  }
}

typedef CharCreatorResultAnim =
{
  var ?sprite:flixel.util.typeLimit.OneOfTwo<CharSelectAtlasSprite, FunkinSprite>;
  var delay:Float;
}

enum ResultsDialogType
{
  RankAnims;
  Music;
}
