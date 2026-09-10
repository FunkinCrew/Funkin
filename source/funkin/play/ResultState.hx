package funkin.play;

import funkin.assets.FunkinAssetCache;
import flixel.math.FlxAngle;
import flixel.FlxState;
import funkin.ui.transition.stickers.StickerSubState;
import flixel.addons.display.FlxBackdrop;
import flixel.effects.FlxFlicker;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.graphics.frames.FlxBitmapFont;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxSignal;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.text.FlxBitmapText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.util.FlxTimer;
import funkin.audio.FunkinSound;
import funkin.data.freeplay.player.PlayerData.PlayerResultsAnimationData;
import funkin.data.freeplay.player.PlayerRegistry;
import funkin.data.song.SongRegistry;
import funkin.graphics.FunkinCamera;
import funkin.graphics.FunkinSprite;
import funkin.graphics.shaders.LeftMaskShader;
import funkin.play.components.ClearPercentCounter;
import funkin.play.components.TallyCounter;
import funkin.play.scoring.Scoring;
import funkin.play.song.Song;
import funkin.save.Save.SaveScoreData;
import funkin.ui.freeplay.charselect.PlayableCharacter;
import funkin.ui.freeplay.FreeplayState;
import funkin.ui.FullScreenScaleMode;
import funkin.ui.MusicBeatSubState;
import funkin.ui.story.StoryMenuState;
import funkin.util.HapticUtil;
import funkin.ui.debug.charting.ChartEditorState;
#if FEATURE_NEWGROUNDS
import funkin.api.newgrounds.Medals;
#end
#if FEATURE_TOUCH_CONTROLS
import funkin.util.TouchUtil;
#if FEATURE_MOBILE_ADVERTISEMENTS
import funkin.mobile.util.AdMobUtil;
#end
#if FEATURE_MOBILE_IAR
import funkin.mobile.util.InAppReviewUtil;
#end
#end
import funkin.util.DeviceUtil;

/**
 * The state for the results screen after a song or week is finished.
 */
class ResultState extends MusicBeatSubState
{
  final params:ResultsStateParams;
  var rank:ScoringRank;
  var songName:FlxBitmapText;
  var difficulty:FlxSprite;
  var clearPercentSmall:ClearPercentCounter;
  var maskShaderSongName:LeftMaskShader = new LeftMaskShader();
  var maskShaderDifficulty:LeftMaskShader = new LeftMaskShader();
  var resultsAnim:FunkinSprite;
  var ratingsPopin:FunkinSprite;
  var scorePopin:FunkinSprite;
  var bgFlash:FlxSprite;
  var highscoreNew:FlxSprite;
  var score:ResultScore;
  var characterAtlasAnimations:Array<
    {
      sprite:FunkinSprite,
      delay:Float,
      forceLoop:Bool,
      startFrameLabel:String,
      sound:String
    }> = [];
  var characterSparrowAnimations:Array<
    {
      sprite:FunkinSprite,
      delay:Float
    }> = [];
  var playerCharacterId:Null<String> = null;
  var playerCharacter:Null<PlayableCharacter> = null;
  var introMusicAudio:Null<FunkinSound> = null;

  /**
   * The music playing in the background of the state.
   */
  var resultsMusic:Null<FunkinSound> = null;

  var rankBg:FunkinSprite;
  var cameraBG:FunkinCamera;
  var cameraScroll:FunkinCamera;
  var cameraEverything:FunkinCamera;
  var blackTopBar:FlxSprite = new FlxSprite();
  var busy:Bool = false;
  var soundSystem:FlxSprite = new FlxSprite();
  var ratingGrp:FlxTypedGroup<TallyCounter> = new FlxTypedGroup<TallyCounter>();
  var textChange:FlxTypedSignal<Void->Void> = new FlxTypedSignal<Void->Void>();

  public var isChartingMode(get, never):Bool;

  function get_isChartingMode():Bool
  {
    if (PlayState.instance != null) return PlayState.instance.isChartingMode;
    else
      return false;
  }

  public function new(params:ResultsStateParams)
  {
    super();

    this.params = params;

    rank = Scoring.calculateRank(params.scoreData) ?? SHIT;

    rankVertAsset = rank.getVerTextAsset();
    rankBackAsset = rank.getHorTextAsset();

    cameraBG = new FunkinCamera('resultsBG', 0, 0, FlxG.width, FlxG.height);
    cameraScroll = new FunkinCamera('resultsScroll', 0, 0, FlxG.width, Math.round(FlxG.height * 1.2));
    cameraEverything = new FunkinCamera('resultsEverything', 0, 0, FlxG.width, FlxG.height);

    // We build a lot of this stuff in the constructor, then place it in create().
    // This prevents having to do `null` checks everywhere.

    var fontLetters:String = 'AaBbCcDdEeFfGgHhiIJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz:1234567890().-';
    songName = new FlxBitmapText(
      funkin.assets.Assets.getMonospaceBitmapFont(funkin.assets.Paths.image('ui/fonts/tardling'), fontLetters, FlxPoint.get(49, 61))
    );
    songName.text = params.title;
    songName.letterSpacing = -15;
    songName.angle = -4.4;
    songName.zIndex = 1000;
    songName.visible = false;

    difficulty = new FlxSprite(555 + FullScreenScaleMode.gameNotchSize.x);
    difficulty.zIndex = 1000;

    clearPercentSmall = new ClearPercentCounter(FlxG.width / 2 + 300, FlxG.height / 2 - 100, 100, true);
    clearPercentSmall.zIndex = 1000;
    clearPercentSmall.visible = false;

    bgFlash = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, [0xFFFFF1A6, 0xFFFFF1BE], 90);

    resultsAnim = FunkinSprite.createSparrow(FlxG.width - (1480 + (FullScreenScaleMode.gameCutoutSize.x / 2)), -10, "ui/results/interface/results");

    ratingsPopin = FunkinSprite.createSparrow(-135 + FullScreenScaleMode.gameNotchSize.x, 135, "ui/results/interface/ratings-popin");

    scorePopin = FunkinSprite.createSparrow(-180 + FullScreenScaleMode.gameNotchSize.x, 515, "ui/results/interface/score-popin");

    highscoreNew = new FlxSprite(44 + FullScreenScaleMode.gameNotchSize.x, 557);

    score = new ResultScore(35 + FullScreenScaleMode.gameNotchSize.x, 305, 10, params.scoreData.score);

    rankBg = new FunkinSprite(0, 0);
  }

  override function create():Void
  {
    if (FlxG.sound.music != null) FlxG.sound.music.stop();

    // We need multiple cameras so we can put one at an angle.
    cameraScroll.scrollAngle = -3.8;

    cameraBG.bgColor = FlxColor.MAGENTA;
    cameraScroll.bgColor = FlxColor.TRANSPARENT;
    cameraEverything.bgColor = FlxColor.TRANSPARENT;

    FlxG.cameras.add(cameraBG, false);
    FlxG.cameras.add(cameraScroll, false);
    FlxG.cameras.add(cameraEverything, false);

    FlxG.cameras.setDefaultDrawTarget(cameraEverything, true);
    this.camera = cameraEverything;

    // Reset the camera zoom on the results screen.
    FlxG.camera.zoom = 1.0;

    var bg:FlxSprite = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, [0xFFFECC5C, 0xFFFDC05C], 90);
    bg.scrollFactor.set();
    bg.zIndex = 10;
    bg.cameras = [cameraBG];
    add(bg);

    bgFlash.scrollFactor.set();
    bgFlash.visible = false;
    bgFlash.zIndex = 20;
    // bgFlash.cameras = [cameraBG];
    add(bgFlash);

    // The sound system which falls into place behind the score text. Plays every time!
    soundSystem = FunkinSprite.createSparrow(-15 + FullScreenScaleMode.gameNotchSize.x, -180, 'ui/results/interface/sound-system');
    soundSystem.animation.addByPrefix("idle", "sound system", 24, false);
    soundSystem.visible = false;
    new FlxTimer().start(8 / 24, _ ->
    {
      soundSystem.animation.play("idle");
      soundSystem.visible = true;
    });
    soundSystem.zIndex = 1100;
    add(soundSystem);

    // Fetch playable character data. Default to BF on the results screen if we can't find it.
    playerCharacterId = PlayerRegistry.instance.getCharacterOwnerId(params.characterId) ?? 'bf';
    playerCharacter = PlayerRegistry.instance.fetchEntry(playerCharacterId);

    trace('Got playable character: ${playerCharacter?.getName()}');

    // Query JSON data based on the rank, then use that to build the animation(s) the player sees.
    var playerAnimationDatas:Array<PlayerResultsAnimationData> = playerCharacter != null ? playerCharacter.getResultsAnimationDatas(rank) : [];

    for (animationData in playerAnimationDatas)
    {
      if (animationData == null) continue;

      if (animationData.filter != "both")
      {
        if (Preferences.naughtyness && animationData.filter != "naughty" || !Preferences.naughtyness && animationData.filter != "safe") continue;
      }

      var assetPath:String = "";
      var offsets:Array<Float> = animationData.offsets ?? [0, 0];

      var xPosition:Float = offsets[0] + (FullScreenScaleMode.gameCutoutSize.x / 2);
      var yPosition:Float = offsets[1];

      var animation:Null<FunkinSprite> = null;

      if (animationData.assetPath != null)
      {
        assetPath = animationData.assetPath;
      }

      switch (animationData.renderType)
      {
        case 'animateatlas':
          if (animationData.scriptClass != null) animation = FunkinSprite.scriptInit(animationData.scriptClass, xPosition, yPosition);
          else
            animation = FunkinSprite.createTextureAtlas(xPosition, yPosition, assetPath);

          if (animation == null) continue;

          if (animationData?.applyStageMatrix ?? false)
          {
            animation.applyStageMatrix = true;
          }

          animation.zIndex = animationData.zIndex ?? 500;
          animation.scale.set(animationData.scale ?? 1.0, animationData.scale ?? 1.0);

          animation.anim.addBySymbol('wholeTimeline', animation.getDefaultSymbol(), animation.library.frameRate, false);

          if (animationData.startFrameLabel != null && animationData.startFrameLabel != '')
          {
            animation.anim.addByFrameLabel('startLabel', animationData.startFrameLabel, animation.library.frameRate, false);
          }

          if (animationData.loopFrameLabel != null)
          {
            animation.anim.addByFrameLabel('loopLabel', animationData.loopFrameLabel, animation.library.frameRate);
          }

          if (!(animationData.looped ?? true))
          {
            // Animation is not looped.
            animation.animation.onFinish.add((_name:String) ->
            {
              if (animation != null)
              {
                animation.animation.pause();
              }
            });
          }
          else if (animationData.loopFrameLabel != null)
          {
            animation.animation.onFinish.add((_name:String) -> animation.animation.play('loopLabel', true));
          }
          else if (animationData.loopFrame != null)
          {
            animation.animation.onFinish.add((_name:String) -> animation.animation.play('wholeTimeline', true, false, animationData.loopFrame ?? 0));
          }

          // Hide until ready to play.
          animation.visible = false;

          // Queue to play.
          characterAtlasAnimations.push({
            sprite: animation,
            delay: animationData.delay ?? 0.0,
            forceLoop: (animationData.loopFrame ?? -1) == 0,
            startFrameLabel: (animationData.startFrameLabel ?? ""),
            sound: (animationData.sound ?? "")
          });

          // Add to the scene.
          add(animation);
        case 'sparrow':
          if (animationData.scriptClass != null)
          {
            animation = FunkinSprite.scriptInit(animationData.scriptClass, xPosition, yPosition);
          }
          else
          {
            animation = FunkinSprite.createSparrow(xPosition, yPosition, assetPath);
          }

          if (animation == null) continue;

          animation.animation.addByPrefix('idle', '', 24, false, false, false);

          if (animationData.loopFrame != null)
          {
            animation.animation.onFinish.add((_name:String) ->
            {
              if (animation != null)
              {
                animation.animation.play('idle', true, false, animationData.loopFrame ?? 0);
              }
            });
          }

          // Hide until ready to play.
          animation.visible = false;

          // Queue to play.
          characterSparrowAnimations.push({
            sprite: animation,
            delay: animationData.delay ?? 0.0
          });

          // Add to the scene.
          add(animation);
      }
    }

    difficulty.loadGraphic(Paths.image("ui/results/difficulty/" + (params?.difficultyId ?? Constants.DEFAULT_DIFFICULTY)));
    add(difficulty);

    add(songName);

    blackTopBar.loadGraphic(funkin.util.BitmapUtil.createResultsBar());
    blackTopBar.y = -blackTopBar.height;
    FlxTween.tween(blackTopBar, {
      y: 0
    }, 7 / 24, {
      ease: FlxEase.quartOut,
      startDelay: 3 / 24,
      onComplete: _ -> songName.visible = true
    });
    blackTopBar.zIndex = 1010;
    add(blackTopBar);

    difficulty.y += (blackTopBar.height - 148);
    clearPercentSmall.y += (blackTopBar.height - 148);
    songName.y += (blackTopBar.height - 148);

    var angleRad = songName.angle * Math.PI / 180;
    speedOfTween.x = -1.0 * Math.cos(angleRad);
    speedOfTween.y = -1.0 * Math.sin(angleRad);

    timerThenSongName(1.0, false);

    songName.shader = maskShaderSongName;
    difficulty.shader = maskShaderDifficulty;

    maskShaderDifficulty.swagMaskX = difficulty.x - 30;

    resultsAnim.animation.addByPrefix("result", "results instance 1", 24, false);
    resultsAnim.visible = false;
    resultsAnim.zIndex = 1200;
    add(resultsAnim);
    new FlxTimer().start(6 / 24, _ ->
    {
      resultsAnim.visible = true;
      resultsAnim.animation.play("result");
    });

    ratingsPopin.animation.addByPrefix("idle", "Categories", 24, false);
    ratingsPopin.visible = false;
    ratingsPopin.zIndex = 1200;
    add(ratingsPopin);
    new FlxTimer().start(21 / 24, _ ->
    {
      ratingsPopin.visible = true;
      ratingsPopin.animation.play("idle");
    });

    scorePopin.animation.addByPrefix("score", "tally score", 24, false);
    scorePopin.visible = false;
    scorePopin.zIndex = 1200;
    add(scorePopin);
    new FlxTimer().start(36 / 24, _ ->
    {
      scorePopin.visible = true;
      scorePopin.animation.play("score");
      scorePopin.animation.onFinish.add(anim -> {
      });
    });

    new FlxTimer().start(37 / 24, _ ->
    {
      score.visible = true;
      score.animateNumbers();
      startRankTallySequence();
    });

    new FlxTimer().start(rank.getBFDelay(), _ ->
    {
      afterRankTallySequence();
    });

    new FlxTimer().start(rank.getFlashDelay(), _ ->
    {
      displayRankText();
    });

    highscoreNew.frames = Paths.getSparrowAtlas("ui/results/interface/highscore-new");
    highscoreNew.animation.addByPrefix("new", "highscoreAnim0", 24, false);
    highscoreNew.visible = false;
    // highscoreNew.setGraphicSize(Std.int(highscoreNew.width * 0.8));
    highscoreNew.updateHitbox();
    highscoreNew.zIndex = 1200;
    add(highscoreNew);

    new FlxTimer().start(rank.getHighscoreDelay(), _ ->
    {
      if (params.isNewHighscore ?? false)
      {
        highscoreNew.visible = true;
        highscoreNew.animation.play("new");
        highscoreNew.animation.onFinish.add(_ -> highscoreNew.animation.play("new", true, false, 16));
      }
      else
      {
        highscoreNew.visible = false;
      }
    });

    var hStuf:Int = 50;

    ratingGrp.zIndex = 1200;
    add(ratingGrp);

    /**
     * NOTE: We display how many notes were HIT, not how many notes there were in total.
     *
     */
    var totalHit:TallyCounter = new TallyCounter(375 + FullScreenScaleMode.gameNotchSize.x, hStuf * 3, params.scoreData.tallies.totalNotesHit);
    ratingGrp.add(totalHit);

    var maxCombo:TallyCounter = new TallyCounter(375 + FullScreenScaleMode.gameNotchSize.x, hStuf * 4, params.scoreData.tallies.maxCombo);
    ratingGrp.add(maxCombo);

    if (params.scoreData.tallies.totalNotesHit >= 1000)
    {
      totalHit.x -= 30;
      maxCombo.x -= 30;
    }

    hStuf += 2;
    var extraYOffset:Float = 7;

    hStuf += 2;

    var tallySick:TallyCounter = new TallyCounter(
      230 + FullScreenScaleMode.gameNotchSize.x,
      (hStuf * 5) + extraYOffset,
      params.scoreData.tallies.sick,
      0xFF89E59E
    );
    ratingGrp.add(tallySick);

    var tallyGood:TallyCounter = new TallyCounter(
      210 + FullScreenScaleMode.gameNotchSize.x,
      (hStuf * 6) + extraYOffset,
      params.scoreData.tallies.good,
      0xFF89C9E5
    );
    ratingGrp.add(tallyGood);

    var tallyBad:TallyCounter = new TallyCounter(
      190 + FullScreenScaleMode.gameNotchSize.x,
      (hStuf * 7) + extraYOffset,
      params.scoreData.tallies.bad,
      0xFFE6CF8A
    );
    ratingGrp.add(tallyBad);

    var tallyShit:TallyCounter = new TallyCounter(
      220 + FullScreenScaleMode.gameNotchSize.x,
      (hStuf * 8) + extraYOffset,
      params.scoreData.tallies.shit,
      0xFFE68C8A
    );
    ratingGrp.add(tallyShit);

    var tallyMissed:TallyCounter = new TallyCounter(
      260 + FullScreenScaleMode.gameNotchSize.x,
      (hStuf * 9) + extraYOffset,
      params.scoreData.tallies.missed,
      0xFFC68AE6
    );
    ratingGrp.add(tallyMissed);

    score.visible = false;
    score.zIndex = 1200;
    add(score);

    for (ind => rating in ratingGrp.members)
    {
      rating.visible = false;
      new FlxTimer().start((0.3 * ind) + 1.20, _ ->
      {
        rating.visible = true;
        FlxTween.tween(rating, {
          curNumber: rating.neededNumber
        }, 0.5, {
          ease: FlxEase.quartOut
        });
      });
    }

    new FlxTimer().start(rank.getMusicDelay(), _ ->
    {
      var musicPath = getMusicPath(playerCharacter, rank);
      var introMusic:String = Paths.music('$musicPath-intro');

      if (Assets.exists(introMusic))
      {
        var mainMusic:String = Paths.music('$musicPath'); // wraps how FunkinSound load audios

        // preload the loop music
        @:nullSafety(Off)
        var musicLoop:FunkinSound = FunkinSound.load(mainMusic, 1.0, true, true, false, false, null, null, true);

        // Play the intro music.
        introMusicAudio = FunkinSound.load(introMusic, 1.0, false, true, true, () ->
        {
          introMusicAudio = null;
          musicLoop.play();
          if (!isChartingMode) // Don't override the music and cause problems on the chart editor
            FunkinSound.setMusic(musicLoop);
          else // Play the results music as a looped sound instead (that we cancel before closing and returning to the chart editor)
          {
            resultsMusic = musicLoop;
            false; // Why is this necessary for this to work?
          }
        });
      }
      else
      {
        if (!isChartingMode) FunkinSound.playMusic(musicPath, {
          startingVolume: 1.0,
          overrideExisting: true,
          restartTrack: true
        });
        else
        {
          resultsMusic = FunkinSound.load(Paths.music(getMusicPath(playerCharacter, rank)), 1.0, true, false, true);
        }
      }
    });

    rankBg.makeSolidColor(FlxG.width, FlxG.height, 0xFF000000);
    rankBg.zIndex = 99999;
    add(rankBg);

    rankBg.alpha = 0;

    refresh();

    super.create();
  }

  override public function destroy():Void
  {
    // Kill all music types to prevent audio overlap into new states.
    if (resultsMusic != null) resultsMusic.stop();
    if (introMusicAudio != null) introMusicAudio.stop();
    if (FlxG.sound.music != null) FlxG.sound.music.stop();

    super.destroy();
  }

  function getMusicPath(playerCharacter:Null<PlayableCharacter>,
    rank:ScoringRank,
    suffix:String = ''):String
  {
    return (playerCharacter?.getResultsMusicPath(rank) ?? 'gameplay/playable-characters/bf/results/music/results-normal/results-normal') + suffix;
  }

  var clearPercentTarget:Int = 100;
  var clearPercentLerp:Int = 0;

  function startRankTallySequence():Void
  {
    bgFlash.visible = true;
    FlxTween.tween(bgFlash, {
      alpha: 0
    }, 5 / 24);
    // NOTE: Only divide if totalNotes > 0 to prevent divide-by-zero errors.
    var clearPercentFloat = params.scoreData.tallies.totalNotes == 0 ? 0.0 : Scoring.tallyCompletion(params.scoreData.tallies) * 100;
    clearPercentTarget = Math.floor(clearPercentFloat);
    // Prevent off-by-one errors.

    clearPercentLerp = Std.int(Math.max(0, clearPercentTarget - 36));

    trace('Clear percent target: ' + clearPercentFloat + ', round: ' + clearPercentTarget);

    var clearPercentCounter:ClearPercentCounter = new ClearPercentCounter(
      (FlxG.width / 2 + 190) + (FullScreenScaleMode.gameCutoutSize.x / 2),
      FlxG.height / 2 - 70,
      clearPercentLerp
    );
    FlxTween.tween(clearPercentCounter, {
      curNumber: clearPercentTarget
    }, 58 / 24, {
      ease: FlxEase.quartOut,
      onUpdate: _ ->
      {
        clearPercentLerp = Math.round(clearPercentLerp);
        clearPercentCounter.curNumber = Math.round(clearPercentCounter.curNumber);
        // Only play the tick sound if the number increased.
        if (clearPercentLerp != clearPercentCounter.curNumber)
        {
          // trace('$clearPercentLerp and ${clearPercentCounter.curNumber}');
          clearPercentLerp = clearPercentCounter.curNumber;
          FunkinSound.playOnce(Paths.sound('ui/main-menu/scroll-menu'));

          // Weak vibration each number increase.
          HapticUtil.vibrate(0, 0.01);
        }
      },
      onComplete: _ ->
      {
        // Strong vibration when rank number tween ends.
        HapticUtil.vibrate(Constants.DEFAULT_VIBRATION_PERIOD, Constants.DEFAULT_VIBRATION_DURATION * 5, Constants.MAX_VIBRATION_AMPLITUDE);

        // Play confirm sound.
        FunkinSound.playOnce(Paths.sound('ui/main-menu/confirm-menu'));

        // Just to be sure that the lerp didn't mess things up.
        clearPercentCounter.curNumber = clearPercentTarget;

        #if FEATURE_NEWGROUNDS
        var isScoreValid = !(params?.isPracticeMode ?? false) && !(params?.isBotPlayMode ?? false);
        // This is the easiest spot to do the medal calculation lol.
        if (isScoreValid && clearPercentTarget == 69) Medals.award(Nice);
        #end

        clearPercentCounter.flash(true);
        new FlxTimer().start(0.4, _ ->
        {
          clearPercentCounter.flash(false);
        });

        // displayRankText();

        // previously 2.0 seconds
        new FlxTimer().start(0.25, _ ->
        {
          FlxTween.tween(clearPercentCounter, {
            alpha: 0
          }, 0.5, {
            startDelay: 0.5,
            ease: FlxEase.quartOut,
            onComplete: _ ->
            {
              remove(clearPercentCounter);
            }
          });

          // afterRankTallySequence();
        });
      }
    });
    clearPercentCounter.zIndex = 450;
    add(clearPercentCounter);

    if (ratingsPopin == null)
    {
      trace("Could not build ratingsPopin!");
    }

    refresh();
  }

  var rankTextVert:FlxBackdrop = new FlxBackdrop();
  var rankTextBack:FlxBackdrop = new FlxBackdrop();
  var rankVertAsset:String = "";
  var rankBackAsset:String = "";

  function displayRankText():Void
  {
    bgFlash.visible = true;
    bgFlash.alpha = 1;
    FlxTween.tween(bgFlash, {
      alpha: 0
    }, 14 / 24);

    rankTextVert = new FlxBackdrop(rankVertAsset, Y, 0, 30);
    rankTextVert.x = FlxG.width - 44;
    rankTextVert.y = 100;
    rankTextVert.zIndex = 990;
    add(rankTextVert);

    FlxFlicker.flicker(rankTextVert, 2 / 24 * 3, 2 / 24, true);

    // Scrolling.
    new FlxTimer().start(30 / 24, _ ->
    {
      rankTextVert.velocity.y = -80;
    });

    for (i in 0...12)
    {
      rankTextBack = new FlxBackdrop(rankBackAsset, X, 10, 0);
      rankTextBack.x = FlxG.width / 2 - 320;
      rankTextBack.y = 50 + (135 * i / 2) + 10;
      // rankTextBack.angle = -3.8;
      rankTextBack.zIndex = 100;
      rankTextBack.cameras = [cameraScroll];
      add(rankTextBack);

      // Scrolling.
      rankTextBack.velocity.x = (i % 2 == 0) ? -7.0 : 7.0;
    }

    refresh();
  }

  function afterRankTallySequence():Void
  {
    showSmallClearPercent();

    for (atlas in characterAtlasAnimations)
    {
      new FlxTimer().start(atlas.delay, _ ->
      {
        if (atlas.sprite == null) return;

        atlas.sprite.visible = true;

        if (atlas.sprite.hasAnimation('startLabel'))
        {
          atlas.sprite.animation.play('startLabel');
        }
        else
        {
          atlas.sprite.animation.play('wholeTimeline');
        }

        if (atlas.sound != "")
        {
          var sndPath:String = Paths.stripLibrary(atlas.sound);
          var sndLibrary:String = Paths.getLibrary(atlas.sound);

          FunkinSound.playOnce(Paths.sound(sndPath, sndLibrary), 1.0);
        }
      });
    }

    for (sprite in characterSparrowAnimations)
    {
      new FlxTimer().start(sprite.delay, _ ->
      {
        if (sprite.sprite == null) return;

        sprite.sprite.visible = true;
        sprite.sprite.animation.play('idle', true);
      });
    }
  }

  function timerThenSongName(timerLength:Float = 3.0, autoScroll:Bool = true):Void
  {
    movingSongStuff = false;

    difficulty.x = 555 + FullScreenScaleMode.gameNotchSize.x;

    var diffYTween:Float = 122;

    difficulty.y = -difficulty.height;
    FlxTween.tween(difficulty, {
      y: diffYTween + (blackTopBar.height - 148)
    }, 0.5, {
      ease: FlxEase.expoOut,
      startDelay: 0.8
    });

    if (clearPercentSmall != null)
    {
      clearPercentSmall.x = (difficulty.x + difficulty.width) + 60;
      clearPercentSmall.y = -clearPercentSmall.height;
      FlxTween.tween(clearPercentSmall, {
        y: (122 - 5) + (blackTopBar.height - 148)
      }, 0.5, {
        ease: FlxEase.expoOut,
        startDelay: 0.85
      });
    }

    songName.y = -songName.height;
    var fuckedupnumber:Float = -(songName.width * 0.5) * Math.sin(songName.angle * FlxAngle.TO_RAD) - 10;
    FlxTween.tween(songName, {
      y: (diffYTween - 25 - fuckedupnumber) + ((blackTopBar.height - 148) / 1)
    }, 0.5, {
      ease: FlxEase.expoOut,
      startDelay: 0.9
    });
    songName.x = clearPercentSmall.x + 94;

    new FlxTimer().start(timerLength, _ ->
    {
      var tempSpeed = FlxPoint.get(speedOfTween.x, speedOfTween.y);

      speedOfTween.set(0, 0);
      FlxTween.tween(speedOfTween, {
        x: tempSpeed.x,
        y: tempSpeed.y
      }, 0.7, {
        ease: FlxEase.quadIn
      });

      movingSongStuff = (autoScroll);
    });

    textChange.dispatch();
  }

  function showSmallClearPercent():Void
  {
    if (clearPercentSmall != null)
    {
      add(clearPercentSmall);
      clearPercentSmall.visible = true;
      clearPercentSmall.flash(true);
      new FlxTimer().start(0.4, _ ->
      {
        clearPercentSmall.flash(false);
      });

      clearPercentSmall.curNumber = clearPercentTarget;
      clearPercentSmall.zIndex = 1000;
      refresh();
    }

    new FlxTimer().start(2.5, _ ->
    {
      movingSongStuff = true;
    });
  }

  var movingSongStuff:Bool = false;
  var speedOfTween:FlxPoint = FlxPoint.get(-1, 1);
  var shouldClipSongName:Bool = true;

  override function draw():Void
  {
    super.draw();

    if (shouldClipSongName)
    {
      songName.clipRect = FlxRect.get(Math.max(0, 520 - songName.x), 0, FlxG.width, songName.height);
      clearPercentSmall.forEachAlive(spr -> spr.clipRect = FlxRect.get(Math.max(0, 520 - spr.x), 0, FlxG.width, spr.height));
    }
    else
    {
      songName.clipRect = null;
      clearPercentSmall.forEachAlive(spr -> spr.clipRect = null);
    }
    // PROBABLY SHOULD FIX MEMORY FREE OR WHATEVER THE PUT() FUNCTION DOES !!!! FEELS LIKE IT STUTTERS!!!

    // if (songName != null && songName.frame != null)
    // maskShaderSongName.frameUV = songName.frame.uv;
  }

  override function update(elapsed:Float):Void
  {
    maskShaderDifficulty.swagSprX = difficulty.x + difficulty.offset.x;

    if (movingSongStuff)
    {
      var speedX:Float = speedOfTween.x * 60 * elapsed;
      var speedY:Float = speedOfTween.y * 60 * elapsed;

      songName.x += speedX;
      difficulty.x += speedX;
      clearPercentSmall.x += speedX;
      songName.y += speedY;
      difficulty.y += speedY;
      clearPercentSmall.y += speedY;

      if (songName.x + songName.width < 100)
      {
        timerThenSongName();
      }
    }

    if (controls.RESET)
    {
      if (PlayState.instance == null) return; // Do nothing - there's no playstate to return to
      FlxTimer.globalManager.clear();
      FlxTween.globalManager.clear();
      if (introMusicAudio != null) introMusicAudio.stop();
      // if (resultsMusic != null) resultsMusic.stop();
      this.close();
      return;
    }

    if (controls.PAUSE_P || controls.ACCEPT_P #if FEATURE_TOUCH_CONTROLS || TouchUtil.pressAction() #end)
    {
      if (busy) return;
      if (_parentState is funkin.ui.debug.results.ResultsDebugSubState)
      {
        if (introMusicAudio != null)
        {
          introMusicAudio.stop();
          introMusicAudio.destroy();
          introMusicAudio = null;
        }
        close(); // IF we are a substate, we will close ourselves. This is used from ResultsDebugSubState
      }
      else if (introMusicAudio != null)
      {
        @:nullSafety(Off)
        introMusicAudio.onComplete = null;

        FlxTween.tween(introMusicAudio, {
          volume: 0
        }, 0.8, {
          onComplete: _ ->
          {
            if (introMusicAudio != null)
            {
              introMusicAudio.stop();
              introMusicAudio.destroy();
              introMusicAudio = null;
            }
          }
        });
        FlxTween.tween(introMusicAudio, {
          pitch: 3
        }, 0.1, {
          onComplete: _ ->
          {
            FlxTween.tween(introMusicAudio, {
              pitch: 0.5
            }, 0.4);
          }
        });
      }
      else if (FlxG.sound.music != null)
      {
        FlxTween.tween(FlxG.sound.music, {
          volume: 0
        }, 0.8, {
          onComplete: _ ->
          {
            FlxG.sound.music.stop();
            FlxG.sound.music.destroy();
          }
        });
        FlxTween.tween(FlxG.sound.music, {
          pitch: 3
        }, 0.1, {
          onComplete: _ ->
          {
            FlxTween.tween(FlxG.sound.music, {
              pitch: 0.5
            }, 0.4);
          }
        });
      }

      // Determining the target state(s) to go to.
      // Default to main menu because that's better than `null`.
      var targetState:FlxState = new funkin.ui.mainmenu.MainMenuState();
      var targetStateFactory:Null<Void->StickerSubState> = null;
      var shouldTween = false;
      var shouldUseSubstate = false;

      var stickerPackId:Null<String> = null;

      var song:Null<Song> = params.songId == null ? null : SongRegistry.instance.fetchEntry(params.songId, {
        variation: params?.variationId
      });

      if (song != null)
      {
        stickerPackId = song.getStickerPackId(params?.difficultyId ?? Constants.DEFAULT_DIFFICULTY, params?.variationId ?? Constants.DEFAULT_VARIATION);
      }
      if (stickerPackId == null && playerCharacter != null)
      {
        stickerPackId = playerCharacter.getStickerPackID();
      }

      if (params.storyMode)
      {
        if (PlayerRegistry.instance.hasNewCharacter())
        {
          // New character, display the notif.
          targetState = new StoryMenuState(null);

          var newCharacters = PlayerRegistry.instance.listNewCharacters();

          for (charId in newCharacters)
          {
            shouldTween = true;
            // This works recursively, ehe!
            targetState = new funkin.ui.charSelect.CharacterUnlockState(charId, targetState);
          }
        }
        else
        {
          // No new characters.
          shouldTween = false;
          shouldUseSubstate = true;
          // targetState = new funkin.ui.transition.stickers.StickerSubState(
          //   {
          //     targetState: (sticker) -> new StoryMenuState(sticker),
          //     stickerPack: stickerPackId
          //   });
          targetStateFactory = () -> new StickerSubState({
            targetState: (sticker) -> new StoryMenuState(sticker),
            stickerPack: stickerPackId
          });
        }
      }
      else
      {
        var isScoreValid = !(params?.isPracticeMode ?? false) && !(params?.isBotPlayMode ?? false);
        var isPersonalBest = rank > Scoring.calculateRank(params?.prevScoreData);

        if ((isScoreValid && isPersonalBest) || params.forceRankSlam)
        {
          trace('THE RANK IS Higher.....');

          shouldTween = true;
          if (isChartingMode)
          {
            PlayState.instance?.close();
            FlxTimer.globalManager.clear();
            FlxTween.globalManager.clear();
            if (introMusicAudio != null) introMusicAudio.stop();
            if (resultsMusic != null) resultsMusic.stop();
            this.close();
            return;
          }
          targetState = FreeplayState.build({
            {
              character: playerCharacterId ?? "bf",
              fromResults: {
                oldRank: Scoring.calculateRank(params?.prevScoreData),
                newRank: rank,
                songId: params.songId,
                difficultyId: params.difficultyId,
                playRankAnim: true
              }
            }
          });
        }
        else
        {
          if (isChartingMode)
          {
            PlayState.instance?.close();
            FlxTimer.globalManager.clear();
            FlxTween.globalManager.clear();
            if (introMusicAudio != null) introMusicAudio.stop();
            if (resultsMusic != null) resultsMusic.stop();
            this.close();
            return;
          }
          shouldTween = false;
          shouldUseSubstate = true;
          targetStateFactory = () -> new StickerSubState({
            targetState: (sticker) -> FreeplayState.build(null, sticker),
            stickerPack: stickerPackId
          });
        }
      }

      #if FEATURE_MOBILE_ADVERTISEMENTS
      // Shows a interstital ad on mobile devices each week victory.
      if (PlayStatePlaylist.isStoryMode || (AdMobUtil.PLAYING_COUNTER >= AdMobUtil.MAX_BEFORE_AD))
      {
        busy = true;

        AdMobUtil.loadInterstitial(function():Void
        {
          AdMobUtil.PLAYING_COUNTER = 0;

          busy = false;

          transitionToState(targetState, targetStateFactory, shouldTween, shouldUseSubstate);
        });
      }
      else
      {
        transitionToState(targetState, targetStateFactory, shouldTween, shouldUseSubstate);
      }
      #else
      transitionToState(targetState, targetStateFactory, shouldTween, shouldUseSubstate);
      #end
    }

    super.update(elapsed);
  }

  function transitionToState(targetState:FlxState,
    targetStateFactory:Null<Void->StickerSubState>,
    shouldTween:Bool,
    shouldUseSubstate:Bool):Void
  {
    if (shouldTween)
    {
      FlxTween.tween(rankBg, {
        alpha: 1
      }, 0.5, {
        ease: FlxEase.expoOut,
        onComplete: (_) ->
        {
          requestReview();

          if (targetStateFactory != null)
          {
            targetState = targetStateFactory();
          }

          if (shouldUseSubstate && targetState is FlxSubState)
          {
            openSubState(cast targetState);
          }
          else
          {
            FlxG.signals.preStateSwitch.addOnce(() ->
            {
              FunkinAssetCache.instance.preparePurgeCache();
            });
            FlxG.signals.postStateSwitch.addOnce(() ->
            {
              // TODO: In loading screens, you should be caching BETWEEN these.
              FunkinAssetCache.instance.purgeCache(#if ios DeviceUtil.iPhoneNumber > 12 #else true #end);
            });
            FlxG.switchState(() -> targetState);
          }
        }
      });
    }
    else
    {
      requestReview();

      if (targetStateFactory != null)
      {
        targetState = targetStateFactory();
      }

      if (shouldUseSubstate && targetState is FlxSubState)
      {
        openSubState(cast targetState);
      }
      else
      {
        FlxG.signals.preStateSwitch.addOnce(() -> {
          #if ios
          trace(DeviceUtil.iPhoneNumber);
          if (DeviceUtil.iPhoneNumber > 12)
          {
            FunkinAssetCache.instance.preparePurgeCache();
            // TODO: In loading screens, you should be caching BETWEEN these.
            FlxG.signals.preStateSwitch.addOnce(() ->
            {
              FunkinAssetCache.instance.purgeCache(true);
            });
          }
          else
          {
            FunkinAssetCache.instance.preparePurgeCache();
            // TODO: In loading screens, you should be caching BETWEEN these.
            FlxG.signals.preStateSwitch.addOnce(() ->
            {
              FunkinAssetCache.instance.purgeCache();
            });
          }
          #else
          FunkinAssetCache.instance.preparePurgeCache();
          // TODO: In loading screens, you should be caching BETWEEN these.
          FlxG.signals.preStateSwitch.addOnce(() ->
          {
            FunkinAssetCache.instance.purgeCache(true);
          });
          #end
        });
        FlxG.switchState(() -> targetState);
      }
    }
  }

  function requestReview():Void
  {
    #if FEATURE_MOBILE_IAR
    if (FlxG.random.bool(InAppReviewUtil.ODDS))
    {
      trace('Attempting to display in-app review!');

      InAppReviewUtil.requestReview();
    }
    #end
  }
}

typedef ResultsStateParams =
{
  /**
   * True if results are for a level, false if results are for a single song.
   */
  var storyMode:Bool;

  /**
   * A readable title for the song we just played.
   * Either "Song Name by Artist Name" or "Week Name"
   */
  var title:String;

  /**
   * The internal song ID for the song we just played.
   */
  var songId:String;

  /**
   * The character ID for the song we just played.
   * @default `bf`
   */
  var ?characterId:String;

  /**
   * Whether the displayed score is a new highscore
   */
  var ?isNewHighscore:Bool;

  /**
   * Whether the displayed score is from a song played with Practice Mode enabled.
   */
  var ?isPracticeMode:Bool;

  /**
   * Whether the displayed score is from a song played with Bot Play Mode enabled.
   */
  var ?isBotPlayMode:Bool;

  /**
   * The difficulty ID of the song/week we just played.
   * @default `Constants.DEFAULT_DIFFICULTY`
   */
  var ?difficultyId:String;

  /**
   * The variation ID of the song/week we just played.
   * @default `Constants.DEFAULT_VARIATION`
   */
  var ?variationId:String;

  /**
   * The score, accuracy, and judgements.
   */
  var scoreData:SaveScoreData;

  /**
   * The previous score data, used for rank comparison.
   */
  var ?prevScoreData:SaveScoreData;

  /**
   * Forces to do the rank slamming animation in freeplay for debug purposes
   */
  var ?forceRankSlam:Bool;
};
