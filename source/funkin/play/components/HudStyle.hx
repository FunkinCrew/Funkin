package funkin.play.components;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.tweens.FlxTween;
import flixel.text.FlxText;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import funkin.Conductor;
import funkin.Preferences;
import funkin.ui.SimpleFunkinBar;
import funkin.graphics.FunkinSprite;
import funkin.ui.FullScreenScaleMode;
import funkin.play.notes.Strumline;
import funkin.play.notes.notestyle.NoteStyle;
import funkin.util.EaseUtil;
import funkin.modding.events.ScriptEvent;
import funkin.modding.IScriptedClass.IPlayStateScriptedClass;
#if mobile
import funkin.util.TouchUtil;
import funkin.mobile.ui.FunkinHitbox;
import funkin.mobile.input.ControlsHandler;
import funkin.mobile.ui.FunkinHitbox.FunkinHitboxControlSchemes;
#end

/**
 * A script that can be tied to a HudStyle.
 * Create a scripted class that extends HudStyle to use this.
 */
@:hscriptClass
class ScriptedHudStyle extends HudStyle implements polymod.hscript.HScriptedClass {}

class HudStyle extends flixel.group.FlxSpriteGroup implements IPlayStateScriptedClass
{
  // Representaion of PlayState.instance
  public var gameInstance:PlayState;

  public var playerStrumline:Strumline;
  public var opponentStrumline:Strumline;

  public var comboPopUps:FlxSpriteGroup;
  public var comboPopUpsOffset:FlxPoint = FlxPoint.get();

  public var scoreText:FlxText;

  // Healthbar object, represents player's health.
  public var healthBar:SimpleFunkinBar;

  // Icons for Player and Opponent.
  public var iconP1:Null<HealthIcon>;
  public var iconP2:Null<HealthIcon>;

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

  public function initHealthBar():Void
  {
    scoreText = new FlxText(0, 0, 0, '', 20);

    var healthBarYPos:Float = Preferences.downscroll ? FlxG.height * 0.1 : FlxG.height * 0.9;
    #if mobile
    if (Preferences.controlsScheme == FunkinHitboxControlSchemes.Arrows
      && !ControlsHandler.usingExternalInputDevice) healthBarYPos = FlxG.height * 0.1;
    #end

    healthBar = new SimpleFunkinBar(0, healthBarYPos, 'healthBar', () -> return gameInstance.health, Constants.HEALTH_MIN, Constants.HEALTH_MAX);
    healthBar.smoothFactor = 1;
    healthBar.scrollFactor.set();
    healthBar.screenCenter(X);
    healthBar.zIndex = 801;
    healthBar.setColors(Constants.COLOR_HEALTH_BAR_RED, Constants.COLOR_HEALTH_BAR_GREEN);
    add(healthBar);

    // The score text below the health bar.
    scoreText.x = healthBar.bg.x + healthBar.bg.width - 190;
    scoreText.y = healthBar.bg.y + 30;
    scoreText.setFormat(Paths.font('vcr.ttf'), 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    scoreText.scrollFactor.set();
    scoreText.zIndex = 802;
    add(scoreText);
  }

  public function initHealthIcons():Void
  {
    if (gameInstance?.currentStage == null) return;

    iconP1 = new HealthIcon('bf', 0);
    gameInstance?.currentStage.getBoyfriend().initHealthIcon(iconP1, false);
    iconP1.zIndex = 850;
    add(iconP1);

    iconP2 = new HealthIcon('dad', 1);
    gameInstance?.currentStage.getDad().initHealthIcon(iconP2, true);
    iconP2.zIndex = 850;
    add(iconP2);
  }

  public function createStrumlines():Void
  {
    playerStrumline = createStrumline(!gameInstance.isBotPlayMode);
    opponentStrumline = createStrumline(false);
  }

  public function createStrumline(player:Bool = false):Strumline
  {
    final strumline:Strumline = new Strumline(currentNotestyle, player, gameInstance?.currentChart?.scrollSpeed);
    final pos = getStrumlinePosition(strumline, player);
    strumline.setPosition(pos.x, pos.y);
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

  public function initPopUps():Void
  {
    comboPopUps = new FlxSpriteGroup();
    comboPopUps.zIndex = 900;
    add(comboPopUps);
  }

  public function displayRating(daRating:Null<String>):Void
  {
    if (comboPopUps == null) return;
    if (daRating == null) daRating = "good";

    final rating:Null<FunkinSprite> = currentNotestyle.buildJudgementSprite(daRating);
    if (rating == null) return;

    rating.zIndex = 1000;

    final styleOffsets = currentNotestyle.getJudgementSpriteOffsets(daRating);
    rating.x = (FlxG.width * 0.474) - (rating.width / 2) + comboPopUpsOffset.x + styleOffsets[0];
    rating.y = (FlxG.camera.height * 0.45 - 60) - (rating.height / 2) + comboPopUpsOffset.y + styleOffsets[1];
    rating.acceleration.y = 550;
    rating.velocity.y -= FlxG.random.int(140, 175);
    rating.velocity.x -= FlxG.random.int(0, 10);
    comboPopUps?.add(rating);

    final fadeEase = currentNotestyle.isJudgementSpritePixel(daRating) ? EaseUtil.stepped(2) : null;
    FlxTween.tween(rating, {alpha: 0}, 0.2,
      {
        onComplete: tween -> {
          remove(rating, true);
          rating.destroy();
        },
        startDelay: Conductor.instance.beatLengthMs * 0.001,
        ease: fadeEase
      });
  }

  public function displayCombo(combo:Int = 0):Void
  {
    if (comboPopUps == null) return;
    var seperatedScore:Array<Int> = [];
    var tempCombo:Int = combo;

    while (tempCombo != 0)
    {
      seperatedScore.push(tempCombo % 10);
      tempCombo = Std.int(tempCombo / 10);
    }
    while (seperatedScore.length < 3)
      seperatedScore.push(0);

    var daLoop:Int = 1;

    var _styleOffsets:Array<Float> = [0, 0];
    for (digit in seperatedScore)
    {
      var numScore:Null<FunkinSprite> = currentNotestyle.buildComboNumSprite(digit);
      if (numScore == null) continue;

      _styleOffsets = currentNotestyle.getComboNumSpriteOffsets(digit);
      numScore.x = (FlxG.width * 0.507) - (36 * daLoop) - 65 + comboPopUpsOffset.x + _styleOffsets[0];
      numScore.y = (FlxG.camera.height * 0.44) + comboPopUpsOffset.y + _styleOffsets[1];
      numScore.acceleration.y = FlxG.random.int(250, 300);
      numScore.velocity.y -= FlxG.random.int(130, 150);
      numScore.velocity.x = FlxG.random.float(-5, 5);

      comboPopUps?.add(numScore);

      var fadeEase = currentNotestyle.isComboNumSpritePixel(digit) ? EaseUtil.stepped(2) : null;
      FlxTween.tween(numScore, {alpha: 0}, 0.2,
        {
          onComplete: tween -> {
            remove(numScore, true);
            numScore.destroy();
          },
          startDelay: Conductor.instance.beatLengthMs * 0.002,
          ease: fadeEase
        });

      daLoop++;
    }
    _styleOffsets = null;
  }

  // You can use this function for you'r custom complex healthbar.
  public function setHealth(value:Float):Void {}

  public function setScore(score:Int):Void
  {
    scoreText.text = (gameInstance.isBotPlayMode ? 'Bot Play Enabled' : 'Score: ${flixel.util.FlxStringUtil.formatMoney(score, false, true)}');
  }

  public function initNoteHitbox():Void
  {
    #if mobile
    final amplification:Float = (FlxG.width / FlxG.height) / (FlxG.initialWidth / FlxG.initialHeight);
    final playerStrumlineScale:Float = ((FlxG.height / FlxG.width) * 1.95) * amplification;
    final playerNoteSpacing:Float = ((FlxG.height / FlxG.width) * 2.8) * amplification;

    playerStrumline.strumlineScale.set(playerStrumlineScale, playerStrumlineScale);
    playerStrumline.setNoteSpacing(playerNoteSpacing);
    for (strum in playerStrumline)
      strum.width *= 2;

    opponentStrumline.enterMiniMode(0.4 * amplification);

    playerStrumline.x = (FlxG.width - playerStrumline.width) / 2 + Constants.STRUMLINE_X_OFFSET;
    playerStrumline.y = (FlxG.height - playerStrumline.height) * 0.95 - Constants.STRUMLINE_Y_OFFSET;
    if (gameInstance?.currentChart?.noteStyle != "pixel")
    {
      #if android playerStrumline.y += 10; #end
    }
    else
    {
      playerStrumline.y -= 10;
    }
    opponentStrumline.y = Constants.STRUMLINE_Y_OFFSET * 0.3;
    opponentStrumline.x -= 30;
    #end
  }

  public function refresh():Void
  {
    sort(funkin.util.SortUtil.byZIndex, flixel.util.FlxSort.ASCENDING);
  }

  public function onScriptEvent(event:ScriptEvent):Void {};

  public function onCreate(event:ScriptEvent):Void {};

  public function onDestroy(event:ScriptEvent):Void {};

  public function onUpdate(event:UpdateScriptEvent):Void {};

  public function onNoteIncoming(event:NoteScriptEvent):Void {};

  public function onNoteHit(event:HitNoteScriptEvent):Void {};

  public function onNoteMiss(event:NoteScriptEvent):Void {};

  public function onNoteHoldDrop(event:HoldNoteScriptEvent):Void {};

  public function onStepHit(event:SongTimeScriptEvent):Void
  {
    iconP1?.onStepHit(event.step);
    iconP2?.onStepHit(event.step);
  }

  public function onBeatHit(event:SongTimeScriptEvent):Void {};

  public function onPause(event:PauseScriptEvent):Void
  {
    if (iconP1?.bopTween != null) iconP1.bopTween.active = false;
    if (iconP2?.bopTween != null) iconP2.bopTween.active = false;
  };

  public function onResume(event:ScriptEvent):Void
  {
    if (iconP1?.bopTween != null) iconP1.bopTween.active = true;
    if (iconP2?.bopTween != null) iconP2.bopTween.active = true;
  };

  public function onSongLoaded(event:SongLoadScriptEvent):Void {};

  public function onSongStart(event:ScriptEvent):Void {};

  public function onSongEnd(event:ScriptEvent):Void {};

  public function onGameOver(event:ScriptEvent):Void
  {
    iconP1?.updatePosition();
    iconP2?.updatePosition();

    healthBar?.snapPercent();
  }

  public function onSongRetry(event:SongRetryEvent):Void
  {
    iconP1?.snapToTargetSize();
    iconP2?.snapToTargetSize();
  };

  public function onNoteGhostMiss(event:GhostMissNoteScriptEvent):Void {};

  public function onSongEvent(event:SongEventScriptEvent):Void {};

  public function onCountdownStart(event:CountdownScriptEvent):Void {};

  public function onCountdownStep(event:CountdownScriptEvent):Void {};

  public function onCountdownEnd(event:CountdownScriptEvent):Void {};
}
