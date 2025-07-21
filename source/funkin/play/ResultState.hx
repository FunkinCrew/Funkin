package funkin.play;

import flixel.FlxState;
import funkin.ui.transition.stickers.StickerSubState;
import flixel.addons.display.FlxBackdrop;
import flixel.effects.FlxFlicker;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.graphics.frames.FlxBitmapFont;
import flixel.group.FlxGroup.FlxTypedGroup;
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
import funkin.graphics.adobeanimate.FlxAtlasSprite;
import funkin.graphics.FunkinCamera;
import funkin.graphics.FunkinSprite;
import funkin.graphics.shaders.LeftMaskShader;
import funkin.modding.base.ScriptedFlxAtlasSprite;
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
import funkin.graphics.ScriptedFunkinSprite;
#if FEATURE_NEWGROUNDS
import funkin.api.newgrounds.Medals;
#end
#if mobile
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
@:nullSafety
class ResultState extends MusicBeatSubState
{
  final params:ResultsStateParams;

  final rank:ScoringRank;
  final songName:FlxBitmapText;
  final difficulty:FlxSprite;
  final clearPercentSmall:ClearPercentCounter;

  final maskShaderSongName:LeftMaskShader = new LeftMaskShader();
  final maskShaderDifficulty:LeftMaskShader = new LeftMaskShader();

  final resultsAnim:FunkinSprite;
  final ratingsPopin:FunkinSprite;
  final scorePopin:FunkinSprite;

  final bgFlash:FlxSprite;

  final highscoreNew:FlxSprite;
  final score:ResultScore;

  var characterAtlasAnimations:Array<
    {
      sprite:FlxAtlasSprite,
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

  var rankBg:FunkinSprite;
  final cameraBG:FunkinCamera;
  final cameraScroll:FunkinCamera;
  final cameraEverything:FunkinCamera;

  var blackTopBar:FlxSprite = new FlxSprite();

  var busy:Bool = false;

  public function new(params:ResultsStateParams)
  {
    super();

    this.params = params;

    rank = Scoring.calculateRank(params.scoreData) ?? SHIT;

    cameraBG = new FunkinCamera('resultsBG', 0, 0, FlxG.width, FlxG.height);
    cameraScroll = new FunkinCamera('resultsScroll', 0, 0, FlxG.width, Math.round(FlxG.height * 1.2));
    cameraEverything = new FunkinCamera('resultsEverything', 0, 0, FlxG.width, FlxG.height);

    // We build a lot of this stuff in the constructor, then place it in create().
    // This prevents having to do `null` checks everywhere.

    var fontLetters:String = "AaBbCcDdEeFfGgHhiIJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz:1234567890";
    songName = new FlxBitmapText(FlxBitmapFont.fromMonospace(Paths.image("resultScreen/tardlingSpritesheet"), fontLetters, FlxPoint.get(49, 62)));
    songName.text = params.title;
    songName.letterSpacing = -15;
    songName.angle = -4.4;
    songName.zIndex = 1000;

    difficulty = new FlxSprite(555 + FullScreenScaleMode.gameNotchSize.x);
    difficulty.zIndex = 1000;

    clearPercentSmall = new ClearPercentCounter(FlxG.width / 2 + 300, FlxG.height / 2 - 100, 100, true);
    clearPercentSmall.zIndex = 1000;
    clearPercentSmall.visible = false;

    bgFlash = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, [0xFFFFF1A6, 0xFFFFF1BE], 90);

    resultsAnim = FunkinSprite.createSparrow(FlxG.width - (1480 + (FullScreenScaleMode.gameCutoutSize.x / 2)), -10, "resultScreen/results");

    ratingsPopin = FunkinSprite.createSparrow(-135 + FullScreenScaleMode.gameNotchSize.x, 135, "resultScreen/ratingsPopin");

    scorePopin = FunkinSprite.createSparrow(-180 + FullScreenScaleMode.gameNotchSize.x, 515, "resultScreen/scorePopin");

    highscoreNew = new FlxSprite(44 + FullScreenScaleMode.gameNotchSize.x, 557);

    score = new ResultScore(35 + FullScreenScaleMode.gameNotchSize.x, 305, 10, params.scoreData.score);

    rankBg = new FunkinSprite(0, 0);
  }

  override function create():Void
  {
    if (FlxG.sound.music != null) FlxG.sound.music.stop();

    // We need multiple cameras so we can put one at an angle.
    cameraScroll.canvas.rotation = -3.8;

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
    var soundSystem:FlxSprite = FunkinSprite.createSparrow(-15 + FullScreenScaleMode.gameNotchSize.x, -180, 'resultScreen/soundSystem');
    soundSystem.animation.addByPrefix("idle", "sound system", 24, false);
    soundSystem.visible = false;
    new FlxTimer().start(8 / 24, _ -> {
      soundSystem.animation.play("idle");
      soundSystem.visible = true;
    });
    soundSystem.zIndex = 1100;
    add(soundSystem);

    // Fetch playable character data. Default to BF on the results screen if we can't find it.
    playerCharacterId = PlayerRegistry.instance.getCharacterOwnerId(params.characterId);
    playerCharacter = PlayerRegistry.instance.fetchEntry(playerCharacterId ?? 'bf');

    trace('Got playable character: ${playerCharacter?.getName()}');
    // Query JSON data based on the rank, then use that to build the animation(s) the player sees.
    var playerAnimationDatas:Array<PlayerResultsAnimationData> = playerCharacter != null ? playerCharacter.getResultsAnimationDatas(rank) : [];

    for (animData in playerAnimationDatas)
    {
      if (animData == null) continue;

      if (animData.filter != "both")
      {
        if (Preferences.naughtyness && animData.filter != "naughty" || !Preferences.naughtyness && animData.filter != "safe") continue;
      }

      var animPath:String = "";
      var animLibrary:String = "";

      if (animData.assetPath != null)
      {
        animPath = Paths.stripLibrary(animData.assetPath);
        animLibrary = Paths.getLibrary(animData.assetPath);
      }
      var offsets = animData.offsets ?? [0, 0];
      switch (animData.renderType)
      {
        case 'animateatlas':
          @:nullSafety(Off)
          var animation:FlxAtlasSprite = null;

          var xPos = offsets[0] + (FullScreenScaleMode.gameCutoutSize.x / 2);
          var yPos = offsets[1];

          if (animData.scriptClass != null) animation = ScriptedFlxAtlasSprite.init(animData.scriptClass, xPos, yPos);
          else
            animation = new FlxAtlasSprite(xPos, yPos, Paths.animateAtlas(animPath, animLibrary));

          if (animation == null) continue;

          animation.zIndex = animData.zIndex ?? 500;

          animation.scale.set(animData.scale ?? 1.0, animData.scale ?? 1.0);

          if (!(animData.looped ?? true))
          {
            // Animation is not looped.
            animation.onAnimationComplete.add((_name:String) -> {
              if (animation != null)
              {
                animation.anim.pause();
              }
            });
          }
          else if (animData.loopFrameLabel != null)
          {
            animation.onAnimationComplete.add((_name:String) -> {
              if (animation != null)
              {
                animation.playAnimation(animData.loopFrameLabel ?? '', true, false, true); // unpauses this anim, since it's on PlayOnce!
              }
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
          // Hide until ready to play.
          animation.visible = false;
          // Queue to play.
          characterAtlasAnimations.push(
            {
              sprite: animation,
              delay: animData.delay ?? 0.0,
              forceLoop: (animData.loopFrame ?? -1) == 0,
              startFrameLabel: (animData.startFrameLabel ?? ""),
              sound: (animData.sound ?? "")
            });
          // Add to the scene.
          add(animation);
        case 'sparrow':
          @:nullSafety(Off)
          var animation:FunkinSprite = null;

          if (animData.scriptClass != null) animation = ScriptedFunkinSprite.init(animData.scriptClass,
            offsets[0] + (FullScreenScaleMode.gameCutoutSize.x / 2), offsets[1]);
          else
            animation = FunkinSprite.createSparrow(offsets[0] + (FullScreenScaleMode.gameCutoutSize.x / 2), offsets[1], animPath);

          if (animation == null) continue;

          animation.animation.addByPrefix('idle', '', 24, false, false, false);

          if (animData.loopFrame != null)
          {
            animation.animation.onFinish.add((_name:String) -> {
              if (animation != null)
              {
                animation.animation.play('idle', true, false, animData.loopFrame ?? 0);
              }
            });
          }

          // Hide until ready to play.
          animation.visible = false;
          // Queue to play.
          characterSparrowAnimations.push(
            {
              sprite: animation,
              delay: animData.delay ?? 0.0
            });
          // Add to the scene.
          add(animation);
      }
    }

    var diffSpr:String = 'diff_${params?.difficultyId ?? Constants.DEFAULT_DIFFICULTY}';
    difficulty.loadGraphic(Paths.image("resultScreen/" + diffSpr));
    add(difficulty);

    add(songName);

    blackTopBar.loadGraphic(funkin.util.BitmapUtil.createResultsBar());
    blackTopBar.y = -blackTopBar.height;
    FlxTween.tween(blackTopBar, {y: 0}, 7 / 24, {ease: FlxEase.quartOut, startDelay: 3 / 24});
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
    new FlxTimer().start(6 / 24, _ -> {
      resultsAnim.visible = true;
      resultsAnim.animation.play("result");
    });

    ratingsPopin.animation.addByPrefix("idle", "Categories", 24, false);
    ratingsPopin.visible = false;
    ratingsPopin.zIndex = 1200;
    add(ratingsPopin);
    new FlxTimer().start(21 / 24, _ -> {
      ratingsPopin.visible = true;
      ratingsPopin.animation.play("idle");
    });

    scorePopin.animation.addByPrefix("score", "tally score", 24, false);
    scorePopin.visible = false;
    scorePopin.zIndex = 1200;
    add(scorePopin);
    new FlxTimer().start(36 / 24, _ -> {
      scorePopin.visible = true;
      scorePopin.animation.play("score");
      scorePopin.animation.onFinish.add(anim -> {});
    });

    new FlxTimer().start(37 / 24, _ -> {
      score.visible = true;
      score.animateNumbers();
      startRankTallySequence();
    });

    new FlxTimer().start(rank.getBFDelay(), _ -> {
      afterRankTallySequence();
    });

    new FlxTimer().start(rank.getFlashDelay(), _ -> {
      displayRankText();
    });

    highscoreNew.frames = Paths.getSparrowAtlas("resultScreen/highscoreNew");
    highscoreNew.animation.addByPrefix("new", "highscoreAnim0", 24, false);
    highscoreNew.visible = false;
    // highscoreNew.setGraphicSize(Std.int(highscoreNew.width * 0.8));
    highscoreNew.updateHitbox();
    highscoreNew.zIndex = 1200;
    add(highscoreNew);

    new FlxTimer().start(rank.getHighscoreDelay(), _ -> {
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

    var ratingGrp:FlxTypedGroup<TallyCounter> = new FlxTypedGroup<TallyCounter>();
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

    var tallySick:TallyCounter = new TallyCounter(230 + FullScreenScaleMode.gameNotchSize.x, (hStuf * 5) + extraYOffset, params.scoreData.tallies.sick,
      0xFF89E59E);
    ratingGrp.add(tallySick);

    var tallyGood:TallyCounter = new TallyCounter(210 + FullScreenScaleMode.gameNotchSize.x, (hStuf * 6) + extraYOffset, params.scoreData.tallies.good,
      0xFF89C9E5);
    ratingGrp.add(tallyGood);

    var tallyBad:TallyCounter = new TallyCounter(190 + FullScreenScaleMode.gameNotchSize.x, (hStuf * 7) + extraYOffset, params.scoreData.tallies.bad,
      0xFFE6CF8A);
    ratingGrp.add(tallyBad);

    var tallyShit:TallyCounter = new TallyCounter(220 + FullScreenScaleMode.gameNotchSize.x, (hStuf * 8) + extraYOffset, params.scoreData.tallies.shit,
      0xFFE68C8A);
    ratingGrp.add(tallyShit);

    var tallyMissed:TallyCounter = new TallyCounter(260 + FullScreenScaleMode.gameNotchSize.x, (hStuf * 9) + extraYOffset, params.scoreData.tallies.missed,
      0xFFC68AE6);
    ratingGrp.add(tallyMissed);

    score.visible = false;
    score.zIndex = 1200;
    add(score);

    for (ind => rating in ratingGrp.members)
    {
      rating.visible = false;
      new FlxTimer().start((0.3 * ind) + 1.20, _ -> {
        rating.visible = true;
        FlxTween.tween(rating, {curNumber: rating.neededNumber}, 0.5, {ease: FlxEase.quartOut});
      });
    }

    // if (params.isNewHighscore ?? false)
    // {
    //   highscoreNew.visible = true;
    //   highscoreNew.animation.play("new");
    //   //FlxTween.tween(highscoreNew, {y: highscoreNew.y + 10}, 0.8, {ease: FlxEase.quartOut});
    // }
    // else
    // {
    //   highscoreNew.visible = false;
    // }

    new FlxTimer().start(rank.getMusicDelay(), _ -> {
      var introMusic:String = Paths.music(getMusicPath(playerCharacter, rank) + '/' + getMusicPath(playerCharacter, rank) + '-intro');
      if (Assets.exists(introMusic))
      {
        // Play the intro music.
        introMusicAudio = FunkinSound.load(introMusic, 1.0, false, true, true, () -> {
          introMusicAudio = null;
          FunkinSound.playMusic(getMusicPath(playerCharacter, rank),
            {
              startingVolume: 1.0,
              overrideExisting: true,
              restartTrack: true
            });
        });
      }
      else
      {
        FunkinSound.playMusic(getMusicPath(playerCharacter, rank),
          {
            startingVolume: 1.0,
            overrideExisting: true,
            restartTrack: true
          });
      }
    });

    rankBg.makeSolidColor(FlxG.width, FlxG.height, 0xFF000000);
    rankBg.zIndex = 99999;
    add(rankBg);

    rankBg.alpha = 0;

    refresh();

    super.create();
  }

  function getMusicPath(playerCharacter:Null<PlayableCharacter>, rank:ScoringRank):String
  {
    return playerCharacter?.getResultsMusicPath(rank) ?? 'resultsNORMAL';
  }

  var rankTallyTimer:Null<FlxTimer> = null;
  var clearPercentTarget:Int = 100;
  var clearPercentLerp:Int = 0;

  function startRankTallySequence():Void
  {
    bgFlash.visible = true;
    FlxTween.tween(bgFlash, {alpha: 0}, 5 / 24);
    // NOTE: Only divide if totalNotes > 0 to prevent divide-by-zero errors.
    var clearPercentFloat = params.scoreData.tallies.totalNotes == 0 ? 0.0 : (params.scoreData.tallies.sick + params.scoreData.tallies.good
      - params.scoreData.tallies.missed) / params.scoreData.tallies.totalNotes * 100;
    clearPercentTarget = Math.floor(clearPercentFloat);
    // Prevent off-by-one errors.

    clearPercentLerp = Std.int(Math.max(0, clearPercentTarget - 36));

    trace('Clear percent target: ' + clearPercentFloat + ', round: ' + clearPercentTarget);

    var clearPercentCounter:ClearPercentCounter = new ClearPercentCounter((FlxG.width / 2 + 190) + (FullScreenScaleMode.gameCutoutSize.x / 2),
      FlxG.height / 2 - 70, clearPercentLerp);
    FlxTween.tween(clearPercentCounter, {curNumber: clearPercentTarget}, 58 / 24,
      {
        ease: FlxEase.quartOut,
        onUpdate: _ -> {
          clearPercentLerp = Math.round(clearPercentLerp);
          clearPercentCounter.curNumber = Math.round(clearPercentCounter.curNumber);
          // Only play the tick sound if the number increased.
          if (clearPercentLerp != clearPercentCounter.curNumber)
          {
            // trace('$clearPercentLerp and ${clearPercentCounter.curNumber}');
            clearPercentLerp = clearPercentCounter.curNumber;
            FunkinSound.playOnce(Paths.sound('scrollMenu'));

            // Weak vibration each number increase.
            HapticUtil.vibrate(0, 0.01);
          }
        },
        onComplete: _ -> {
          // Strong vibration when rank number tween ends.
          HapticUtil.vibrate(Constants.DEFAULT_VIBRATION_PERIOD, Constants.DEFAULT_VIBRATION_DURATION * 5, Constants.MAX_VIBRATION_AMPLITUDE);

          // Play confirm sound.
          FunkinSound.playOnce(Paths.sound('confirmMenu'));

          // Just to be sure that the lerp didn't mess things up.
          clearPercentCounter.curNumber = clearPercentTarget;

          #if FEATURE_NEWGROUNDS
          var isScoreValid = !(params?.isPracticeMode ?? false) && !(params?.isBotPlayMode ?? false);
          // This is the easiest spot to do the medal calculation lol.
          if (isScoreValid && clearPercentTarget == 69) Medals.award(Nice);
          #end

          clearPercentCounter.flash(true);
          new FlxTimer().start(0.4, _ -> {
            clearPercentCounter.flash(false);
          });

          // displayRankText();

          // previously 2.0 seconds
          new FlxTimer().start(0.25, _ -> {
            FlxTween.tween(clearPercentCounter, {alpha: 0}, 0.5,
              {
                startDelay: 0.5,
                ease: FlxEase.quartOut,
                onComplete: _ -> {
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
    else
    {
      // ratingsPopin.animation.play("idle");
      // ratingsPopin.visible = true;

      ratingsPopin.animation.onFinish.add(anim ->
        {
          // scorePopin.animation.play("score");

          // scorePopin.visible = true;
        });
    }

    refresh();
  }

  function displayRankText():Void
  {
    bgFlash.visible = true;
    bgFlash.alpha = 1;
    FlxTween.tween(bgFlash, {alpha: 0}, 14 / 24);

    var rankTextVert:FlxBackdrop = new FlxBackdrop(Paths.image(rank.getVerTextAsset()), Y, 0, 30);
    rankTextVert.x = FlxG.width - 44;
    rankTextVert.y = 100;
    rankTextVert.zIndex = 990;
    add(rankTextVert);

    FlxFlicker.flicker(rankTextVert, 2 / 24 * 3, 2 / 24, true);

    // Scrolling.
    new FlxTimer().start(30 / 24, _ -> {
      rankTextVert.velocity.y = -80;
    });

    for (i in 0...12)
    {
      var rankTextBack:FlxBackdrop = new FlxBackdrop(Paths.image(rank.getHorTextAsset()), X, 10, 0);
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
      new FlxTimer().start(atlas.delay, _ -> {
        if (atlas.sprite == null) return;
        atlas.sprite.visible = true;
        atlas.sprite.playAnimation(atlas.startFrameLabel);
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
      new FlxTimer().start(sprite.delay, _ -> {
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
    FlxTween.tween(difficulty, {y: diffYTween + (blackTopBar.height - 148)}, 0.5, {ease: FlxEase.expoOut, startDelay: 0.8});

    if (clearPercentSmall != null)
    {
      clearPercentSmall.x = (difficulty.x + difficulty.width) + 60;
      clearPercentSmall.y = -clearPercentSmall.height;
      FlxTween.tween(clearPercentSmall, {y: (122 - 5) + (blackTopBar.height - 148)}, 0.5, {ease: FlxEase.expoOut, startDelay: 0.85});
    }

    songName.y = -songName.height;
    var fuckedupnumber = (10) * (songName.text.length / 15);
    FlxTween.tween(songName, {y: (diffYTween - 25 - fuckedupnumber) + ((blackTopBar.height - 148) / 1)}, 0.5, {ease: FlxEase.expoOut, startDelay: 0.9});
    songName.x = clearPercentSmall.x + 94;

    new FlxTimer().start(timerLength, _ -> {
      var tempSpeed = FlxPoint.get(speedOfTween.x, speedOfTween.y);

      speedOfTween.set(0, 0);
      FlxTween.tween(speedOfTween, {x: tempSpeed.x, y: tempSpeed.y}, 0.7, {ease: FlxEase.quadIn});

      movingSongStuff = (autoScroll);
    });
  }

  function showSmallClearPercent():Void
  {
    if (clearPercentSmall != null)
    {
      add(clearPercentSmall);
      clearPercentSmall.visible = true;
      clearPercentSmall.flash(true);
      new FlxTimer().start(0.4, _ -> {
        clearPercentSmall.flash(false);
      });

      clearPercentSmall.curNumber = clearPercentTarget;
      clearPercentSmall.zIndex = 1000;
      refresh();
    }

    new FlxTimer().start(2.5, _ -> {
      movingSongStuff = true;
    });
  }

  var movingSongStuff:Bool = false;
  var speedOfTween:FlxPoint = FlxPoint.get(-1, 1);

  override function draw():Void
  {
    super.draw();

    songName.clipRect = FlxRect.get(Math.max(0, 520 - songName.x), 0, FlxG.width, songName.height);

    // PROBABLY SHOULD FIX MEMORY FREE OR WHATEVER THE PUT() FUNCTION DOES !!!! FEELS LIKE IT STUTTERS!!!

    // if (songName != null && songName.frame != null)
    // maskShaderSongName.frameUV = songName.frame.uv;
  }

  private function handleAnimationVibrations()
  {
    for (atlas in characterAtlasAnimations)
    {
      if (atlas == null || atlas.sprite == null) continue;

      switch (rank)
      {
        case ScoringRank.PERFECT | ScoringRank.PERFECT_GOLD:
          switch (playerCharacterId)
          {
            // Feel the bed fun :freaky:
            case "bf":
              if (atlas.sprite.anim.curFrame > 87 && atlas.sprite.anim.curFrame % 5 == 0)
              {
                HapticUtil.vibrate(0, 0.01, Constants.MAX_VIBRATION_AMPLITUDE);
                break;
              }

              // GF slams into the wall.
              if (atlas.sprite.anim.curFrame == 51)
              {
                HapticUtil.vibrate(0, 0.01, (Constants.MAX_VIBRATION_AMPLITUDE / 3) * 2.5);
                break;
              }

            // Pico drop-kicking Nene.
            case "pico":
              if (atlas.sprite.anim.curFrame == 52)
              {
                HapticUtil.vibrate(Constants.DEFAULT_VIBRATION_PERIOD, Constants.DEFAULT_VIBRATION_DURATION * 5, Constants.MAX_VIBRATION_AMPLITUDE);
                break;
              }

            default:
              break;
          }

        case ScoringRank.GREAT | ScoringRank.EXCELLENT:
          switch (playerCharacterId)
          {
            // Pico explodes the targets with a rocket launcher.
            case "pico":
              // Pico shoots.
              if (atlas.sprite.anim.curFrame == 45)
              {
                HapticUtil.vibrate(0, 0.01, (Constants.MAX_VIBRATION_AMPLITUDE / 3) * 2.5);
                break;
              }

              // The targets explode.
              if (atlas.sprite.anim.curFrame == 50)
              {
                HapticUtil.vibrate(Constants.DEFAULT_VIBRATION_PERIOD, Constants.DEFAULT_VIBRATION_DURATION, Constants.MAX_VIBRATION_AMPLITUDE);
                break;
              }

            default:
              break;
          }

        case ScoringRank.GOOD:
          switch (playerCharacterId)
          {
            // Pico shooting the targets.
            case "pico":
              if (atlas.sprite.anim.curFrame % 2 != 0) continue;

              final frames:Array<Array<Int>> = [[40, 50], [80, 90], [140, 157]];
              for (i in 0...frames.length)
              {
                if (atlas.sprite.anim.curFrame < frames[i][0] || atlas.sprite.anim.curFrame > frames[i][1]) continue;

                HapticUtil.vibrate(0, 0.01, Constants.MAX_VIBRATION_AMPLITUDE);
                break;
              }

            default:
              break;
          }

        case ScoringRank.SHIT:
          switch (playerCharacterId)
          {
            // BF falling and GF slams on BF with her ass.
            case "bf":
              if (atlas.sprite.anim.curFrame == 5 || atlas.sprite.anim.curFrame == 90)
              {
                HapticUtil.vibrate(Constants.DEFAULT_VIBRATION_PERIOD * 2, Constants.DEFAULT_VIBRATION_DURATION * 2, Constants.MAX_VIBRATION_AMPLITUDE);
                break;
              }

            default:
              break;
          }
      }
    }
  }

  override function update(elapsed:Float):Void
  {
    maskShaderDifficulty.swagSprX = difficulty.x;

    if (movingSongStuff)
    {
      songName.x += speedOfTween.x;
      difficulty.x += speedOfTween.x;
      clearPercentSmall.x += speedOfTween.x;
      songName.y += speedOfTween.y;
      difficulty.y += speedOfTween.y;
      clearPercentSmall.y += speedOfTween.y;

      if (songName.x + songName.width < 100)
      {
        timerThenSongName();
      }
    }

    if (controls.PAUSE || controls.ACCEPT #if mobile || TouchUtil.pressAction() #end)
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

        FlxTween.tween(introMusicAudio, {volume: 0}, 0.8,
          {
            onComplete: _ -> {
              if (introMusicAudio != null)
              {
                introMusicAudio.stop();
                introMusicAudio.destroy();
                introMusicAudio = null;
              }
            }
          });
        FlxTween.tween(introMusicAudio, {pitch: 3}, 0.1,
          {
            onComplete: _ -> {
              FlxTween.tween(introMusicAudio, {pitch: 0.5}, 0.4);
            }
          });
      }
      else if (FlxG.sound.music != null)
      {
        FlxTween.tween(FlxG.sound.music, {volume: 0}, 0.8,
          {
            onComplete: _ -> {
              FlxG.sound.music.stop();
              FlxG.sound.music.destroy();
            }
          });
        FlxTween.tween(FlxG.sound.music, {pitch: 3}, 0.1,
          {
            onComplete: _ -> {
              FlxTween.tween(FlxG.sound.music, {pitch: 0.5}, 0.4);
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

      var song:Null<Song> = params.songId == null ? null : SongRegistry.instance.fetchEntry(params.songId);

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
          targetStateFactory = () -> new StickerSubState(
            {
              targetState: (sticker) -> new StoryMenuState(sticker),
              stickerPack: stickerPackId
            });
        }
      }
      else
      {
        var isScoreValid = !(params?.isPracticeMode ?? false) && !(params?.isBotPlayMode ?? false);
        var isPersonalBest = rank > Scoring.calculateRank(params?.prevScoreData);

        if (isScoreValid && isPersonalBest)
        {
          trace('THE RANK IS Higher.....');

          shouldTween = true;
          targetState = FreeplayState.build(
            {
              {
                character: playerCharacterId ?? "bf",
                fromResults:
                  {
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
          shouldTween = false;
          shouldUseSubstate = true;
          targetStateFactory = () -> new StickerSubState(
            {
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

        AdMobUtil.loadInterstitial(function():Void {
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

    if (HapticUtil.hapticsAvailable) handleAnimationVibrations();

    super.update(elapsed);
  }

  function transitionToState(targetState:FlxState, targetStateFactory:Null<Void->StickerSubState>, shouldTween:Bool, shouldUseSubstate:Bool):Void
  {
    if (shouldTween)
    {
      FlxTween.tween(rankBg, {alpha: 1}, 0.5,
        {
          ease: FlxEase.expoOut,
          onComplete: function(_) {
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
              FlxG.signals.preStateSwitch.addOnce(function() {
                #if ios
                trace(DeviceUtil.iPhoneNumber);
                if (DeviceUtil.iPhoneNumber > 12) funkin.FunkinMemory.purgeCache(true);
                else
                  funkin.FunkinMemory.purgeCache();
                #else
                funkin.FunkinMemory.purgeCache(true);
                #end
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
        FlxG.signals.preStateSwitch.addOnce(function() {
          #if ios
          trace(DeviceUtil.iPhoneNumber);
          if (DeviceUtil.iPhoneNumber > 12) funkin.FunkinMemory.purgeCache(true);
          else
            funkin.FunkinMemory.purgeCache();
          #else
          funkin.FunkinMemory.purgeCache(true);
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
   * The previous score data, used for rank comparision.
   */
  var ?prevScoreData:SaveScoreData;
};
