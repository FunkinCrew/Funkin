package funkin.play.components.hud;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.tweens.FlxTween;
import flixel.text.FlxText;
import flixel.math.FlxPoint;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import funkin.Conductor;
import funkin.Preferences;
import funkin.ui.SimpleFunkinBar;
import funkin.graphics.FunkinSprite;
import funkin.ui.FullScreenScaleMode;
import funkin.play.notes.Strumline;
import funkin.play.notes.notestyle.NoteStyle;
import funkin.play.components.*;
import funkin.util.EaseUtil;
import polymod.hscript.HScriptedClass;

@:hscriptClass
class ScriptedHudStyle extends HudStyle implements HScriptedClass {}

class HudStyle extends FlxSpriteGroup
{
  public var gameInstance:PlayState;

  public var playerStrumline:Strumline;
  public var opponentStrumline:Strumline;

  public var downscroll(get, never):Bool;

  public var comboPopUps:FlxSpriteGroup;
  public var comboPopUpsOffset:FlxPoint = FlxPoint.get();

  var scoreText:FlxText;

  public var healthBar:SimpleFunkinBar;

  public var iconP1:Null<HealthIcon>;
  public var iconP2:Null<HealthIcon>;

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
    healthBar.smoothFactor = .85;
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

  public function initHealthIcons()
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

  public function displayRating(daRating:Null<String>)
  {
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
    comboPopUps.add(rating);

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

      comboPopUps.add(numScore);

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

  override function update(dt:Float)
  {
    super.update(dt);
  }

  public function onStepHit(step:Int)
  {
    iconP1?.onStepHit(step);
    iconP2?.onStepHit(step);
  }

  public function onBeatHit(beat:Int) {}

  public function onMeasureHit(measure:Int) {}

  /*public function onSongEventExecution(event:SongEventData)
    {

  }*/
  public function setHealth(value:Float)
  {
    healthBar.value = value;
  }

  public function setScore(score:Int)
  {
    scoreText.text = (gameInstance.isBotPlayMode ? 'Bot Play Enabled' : 'Score: ${flixel.util.FlxStringUtil.formatMoney(score, false, true)}');
  }

  public function onGameOver()
  {
    iconP1?.updatePosition();
    iconP2?.updatePosition();

    healthBar?.snapPercent();
  }

  function initNoteHitbox()
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
    if (currentChart?.noteStyle != "pixel")
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

  public static function getHudStyle(name:Null<String>):HudStyle
  {
    name = name.trim();
    // final scriptedHudStyles:Array<String> = ScriptedHudStyle.listScriptClasses();
    final scriptedHudStyles:Array<String> = [];
    trace(scriptedHudStyles.length, scriptedHudStyles);

    if (!scriptedHudStyles.contains(name) && name != "")
    {
      trace('Cant find "$name" HudStlye! Falling back on default.');
      return new HudStyle();
    }
    else
      try
      {
        // return ScriptedHudStyle.init(name);
        return new HudStyle();
      }
      catch (e) {}

    // fallback on default HudStyle
    return new HudStyle();
  }
}
