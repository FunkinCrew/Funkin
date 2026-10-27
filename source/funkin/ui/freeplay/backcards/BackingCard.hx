package funkin.ui.freeplay.backcards;

import funkin.ui.freeplay.FreeplayState;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxSpriteUtil;
import funkin.graphics.FunkinSprite;
import funkin.ui.freeplay.charselect.PlayableCharacter;
import openfl.display.BlendMode;
import funkin.modding.events.ScriptEvent;
import flixel.group.FlxSpriteGroup;
import funkin.modding.IScriptedClass.IBPMSyncedScriptedClass;
import funkin.modding.IScriptedClass.IStateChangingScriptedClass;
import funkin.modding.IScriptedClass.IFreeplayScriptedClass;
import funkin.modding.events.ScriptEvent;
import funkin.ui.FullScreenScaleMode;
import funkin.util.BitmapUtil;
import funkin.assets.Paths;
import funkin.assets.Assets;

/**
 * A class for the backing cards so they dont have to be part of freeplayState......
 */
class BackingCard extends FlxSpriteGroup implements IBPMSyncedScriptedClass implements IStateChangingScriptedClass implements IFreeplayScriptedClass
{
  static var resolvedScriptedClasses:Map<String, Null<String>> = [];
  public var backingTextYeah:FunkinSprite;
  public var orangeBackShit:FunkinSprite;
  public var alsoOrangeLOL:FunkinSprite;
  public var pinkBack:FunkinSprite;
  public var confirmGlow:FlxSprite;
  public var confirmGlow2:FlxSprite;
  public var confirmTextGlow:FlxSprite;
  public var cardGlow:FlxSprite;

  var _exitMovers:Null<FreeplayState.ExitMoverData>;
  var _exitMoversCharSel:Null<FreeplayState.ExitMoverData>;

  public var instance:FreeplayState;
  public var currentCharacter:String;

  /**
   * Get the list of assets that are required to display the default backing card.
   *
   * @param type The type of asset to query for.
   * @return A list of asset paths.
   */
  public static function queryAssets(type:funkin.assets.Assets.AssetType):Array<funkin.assets.Paths.AssetPath>
  {
    var results:Array<funkin.assets.Paths.AssetPath> = [];

    switch (type)
    {
      case IMAGE:
        results.appendUnique([
          Paths.image('ui/freeplay/interface/card-glow'),
          Paths.image('ui/freeplay/interface/confirm-glow-1'),
          Paths.image('ui/freeplay/interface/glowing-text'),
          Paths.image('ui/freeplay/interface/confirm-glow-2'),
          Paths.image('ui/freeplay/interface/beat-glow'),

          // Since
          Paths.image('ui/freeplay/interface/back').withPixelData(),
        ]);

        results.appendUnique(Paths.animateAtlas('ui/freeplay/styles/bf/backing-card').image());
      case JSON:
        results.appendUnique(Paths.animateAtlas('ui/freeplay/styles/bf/backing-card').json());
      default:
        // Nothing
    }

    return results;
  }

  /**
   * Get the list of assets that are required to display a scripted backing card.
   * Checks the scripted backing card class for a static `queryAssets()` function to call.
   *
   * @param type The type of asset to query for.
   * @param characterId The playable character ID to get the assets for.
   * @return A list of asset paths.
   */
  public static function queryAssetsScripted(type:AssetType, characterId:String):Array<AssetPath>
  {
    var results:Array<AssetPath> = queryAssets(type);

    var clsName:Null<String> = getBackingCardScriptedClass(characterId);
    if (clsName == null) return results;

    if (!BackingCard.scriptStaticHas(clsName, 'queryAssets'))
    {
      return results;
    }

    var scriptedResults:Array<AssetPath> = BackingCard.scriptStaticCall(clsName, 'queryAssets', [type]);
    if (scriptedResults != null) results.appendUnique(scriptedResults);

    return results;
  }

  /**
   * Get the script class used to display a given character's backing card.
   *
   * @param characterId The playable character ID to get the script class for.
   * @return The corresponding backing card class, or `null` if there is none.
   */
  public static function getBackingCardScriptedClass(characterId:String):Null<String>
  {
    if (characterId == null || characterId == '') return null;

    if (resolvedScriptedClasses.exists(characterId))
    {
      return resolvedScriptedClasses.get(characterId);
    }

    var resultClass:Null<String> = null;
    try
    {
      var allScriptedCards:Array<String> = BackingCard.listScriptClasses();
      for (cardClass in allScriptedCards)
      {
        if (!BackingCard.scriptStaticHas(cardClass, 'getCharacterId')) continue;

        var result:Dynamic = BackingCard.scriptStaticCall(cardClass, 'getCharacterId', []);
        if (result == characterId)
        {
          resultClass = cardClass;
          break;
        }
      }
    }
    catch (e:Dynamic)
    {
      trace('[BackingCard] Failed to resolve scripted card for "$characterId": $e');
    }

    // Cache even null results so the same character cannot repeatedly trigger
    // script construction during a single transition/create cycle.
    resolvedScriptedClasses.set(characterId, resultClass);
    return resultClass;
  }

  /*public static function getCharacterId():String
    {
    return 'bf';
  }*/
  public function new(currentCharacter:String)
  {
    super();

    this.currentCharacter = currentCharacter;
    var bitmap = BitmapUtil.scalePartByWidth(Assets.getBitmapData(Paths.image('ui/freeplay/interface/card-glow').withPixelData()), FreeplayState.CUTOUT_WIDTH);
    cardGlow = new FlxSprite(-30, -30).loadGraphic(bitmap);

    confirmGlow = new FlxSprite(
      (FreeplayState.CUTOUT_WIDTH * FreeplayState.DJ_POS_MULTI) + -30,
      240
    ).loadGraphic(Paths.image('ui/freeplay/interface/confirm-glow-1').toFlxGraphicAsset());
    confirmTextGlow = new FlxSprite(
      (FreeplayState.CUTOUT_WIDTH * FreeplayState.DJ_POS_MULTI) + -8,
      115
    ).loadGraphic(Paths.image('ui/freeplay/interface/glowing-text').toFlxGraphicAsset());

    var bitmap = BitmapUtil.scalePartByWidth(Assets.getBitmapData(Paths.image('ui/freeplay/interface/back').withPixelData()), FreeplayState.CUTOUT_WIDTH);
    pinkBack = new FunkinSprite();
    pinkBack.loadGraphic(bitmap);

    orangeBackShit = new FunkinSprite(84, 440).makeSolidColor(Std.int(pinkBack.width), 75, 0xFFFEDA00);
    alsoOrangeLOL = new FunkinSprite(0, orangeBackShit.y).makeSolidColor(100, Std.int(orangeBackShit.height), 0xFFFFD400);
    confirmGlow2 = new FlxSprite(confirmGlow.x, confirmGlow.y).loadGraphic(Paths.image('ui/freeplay/interface/confirm-glow-2').toFlxGraphicAsset());

    backingTextYeah = new FunkinSprite(
      (FreeplayState.CUTOUT_WIDTH * FreeplayState.DJ_POS_MULTI) + -320,
      120
    ).loadTextureAtlas('ui/freeplay/styles/bf/backing-card');
    backingTextYeah.anim.addBySymbol('wholeTimeline', backingTextYeah.getDefaultSymbol(), backingTextYeah.library.frameRate, false);

    pinkBack.color = 0xFFFFD4E9; // sets it to pink!
    pinkBack.x -= pinkBack.width;
  }

  /**
   * Apply exit movers for the pieces of the backing card.
   * @param exitMovers The exit movers to apply.
   */
  public function applyExitMovers(?exitMovers:FreeplayState.ExitMoverData,
    ?exitMoversCharSel:FreeplayState.ExitMoverData):Void
  {
    if (exitMovers == null)
    {
      exitMovers = _exitMovers;
    }
    else
    {
      _exitMovers = exitMovers;
    }

    if (exitMovers == null) return;

    if (exitMoversCharSel == null)
    {
      exitMoversCharSel = _exitMoversCharSel;
    }
    else
    {
      _exitMoversCharSel = exitMoversCharSel;
    }

    if (exitMoversCharSel == null) return;

    exitMovers.set([pinkBack, orangeBackShit, alsoOrangeLOL], {
      x: -pinkBack.width,
      y: pinkBack.y,
      speed: 0.4,
      wait: 0
    });

    exitMoversCharSel.set([pinkBack], {
      y: -100,
      speed: 0.8,
      wait: 0.1
    });

    exitMoversCharSel.set([orangeBackShit, alsoOrangeLOL], {
      y: -40,
      speed: 0.8,
      wait: 0.1
    });
  }

  /**
   * Helper function to snap the back of the card to its final position.
   * Used when returning from character select, as we dont want to play the full animation of everything sliding in.
   */
  public function skipIntroTween():Void
  {
    FlxTween.cancelTweensOf(pinkBack);
    pinkBack.x = 0;
  }

  /**
   * Called after the dj finishes their start animation.
   */
  public function introDone():Void
  {
    pinkBack.color = 0xFFFFD863;
    orangeBackShit.visible = true;
    alsoOrangeLOL.visible = true;
    cardGlow.visible = true;
    FlxTween.tween(cardGlow, {
      alpha: 0,
      'scale.x': 1.2,
      'scale.y': 1.2
    }, 0.45, {
      ease: FlxEase.sineOut
    });
  }

  /**
   * Called when selecting a song.
   */
  public function confirm():Void
  {
    FlxTween.color(pinkBack, 0.33, 0xFFFFD0D5, 0xFF171831, {
      ease: FlxEase.quadOut
    });
    orangeBackShit.visible = false;
    alsoOrangeLOL.visible = false;

    confirmGlow.visible = true;
    confirmGlow2.visible = true;

    backingTextYeah.animation.play('wholeTimeline');
    confirmGlow2.alpha = 0;
    confirmGlow.alpha = 0;

    FlxTween.color(instance.backingImage, 0.5, 0xFFA8A8A8, 0xFF646464, {
      onUpdate: function(_)
      {
        instance.angleMaskShader.extraColor = instance.backingImage.color;
      }
    });
    FlxTween.tween(confirmGlow2, {
      alpha: 0.5
    }, 0.33, {
      ease: FlxEase.quadOut,
      onComplete: function(_)
      {
        confirmGlow2.alpha = 0.6;
        confirmGlow.alpha = 1;
        confirmTextGlow.visible = true;
        confirmTextGlow.alpha = 1;
        FlxTween.tween(confirmTextGlow, {
          alpha: 0.4
        }, 0.5);
        FlxTween.tween(confirmGlow, {
          alpha: 0
        }, 0.5);
        FlxTween.color(instance.backingImage, 2, 0xFFCDCDCD, 0xFF555555, {
          ease: FlxEase.expoOut,
          onUpdate: function(_)
          {
            instance.angleMaskShader.extraColor = instance.backingImage.color;
          }
        });
      }
    });
  }

  /**
   * Called when entering character select, does nothing by default.
   */
  public function enterCharSel():Void
  {
  }

  /**
   * Called on each beat in freeplay state.
   */
  public function beatHit():Void
  {
  }

  /**
   * Called when exiting the freeplay menu.
   */
  public function disappear():Void
  {
    FlxTween.color(pinkBack, 0.25, 0xFFFFD863, 0xFFFFD0D5, {
      ease: FlxEase.quadOut
    });

    cardGlow.visible = true;
    cardGlow.alpha = 1;
    cardGlow.scale.set(1, 1);
    FlxTween.tween(cardGlow, {
      alpha: 0,
      'scale.x': 1.2,
      'scale.y': 1.2
    }, 0.25, {
      ease: FlxEase.sineOut
    });

    orangeBackShit.visible = false;
    alsoOrangeLOL.visible = false;
  }

  public function onScriptEvent(event:ScriptEvent):Void
  {
  }

  /**
   * Called in create. Adds sprites and tweens.
   */
  public function onCreate(event:ScriptEvent):Void
  {
    FlxTween.tween(pinkBack, {
      x: 0
    }, 0.6, {
      ease: FlxEase.quartOut
    });
    add(pinkBack);

    add(orangeBackShit);

    add(alsoOrangeLOL);

    FlxSpriteUtil.alphaMaskFlxSprite(orangeBackShit, pinkBack, orangeBackShit);
    orangeBackShit.visible = false;
    alsoOrangeLOL.visible = false;

    confirmTextGlow.blend = BlendMode.ADD;
    confirmTextGlow.visible = false;

    confirmGlow.blend = BlendMode.ADD;

    confirmGlow.visible = false;
    confirmGlow2.visible = false;

    add(confirmGlow2);
    add(confirmGlow);

    add(confirmTextGlow);

    add(backingTextYeah);

    cardGlow.blend = BlendMode.ADD;
    cardGlow.visible = false;

    add(cardGlow);
  }

  public function onDestroy(event:ScriptEvent):Void
  {
  }

  public function onUpdate(event:UpdateScriptEvent):Void
  {
  }

  public function onStepHit(event:SongTimeScriptEvent):Void
  {
  }

  public function onBeatHit(event:SongTimeScriptEvent):Void
  {
  }

  public function onStateChangeBegin(event:StateChangeScriptEvent):Void
  {
  }

  public function onStateChangeEnd(event:StateChangeScriptEvent):Void
  {
  }

  public function onSubStateOpenBegin(event:SubStateScriptEvent):Void
  {
  }

  public function onSubStateOpenEnd(event:SubStateScriptEvent):Void
  {
  }

  public function onSubStateCloseBegin(event:SubStateScriptEvent):Void
  {
  }

  public function onSubStateCloseEnd(event:SubStateScriptEvent):Void
  {
  }

  public function onFocusLost(event:FocusScriptEvent):Void
  {
  }

  public function onFocusGained(event:FocusScriptEvent):Void
  {
  }

  /**
   * Called when a capsule is selected.
   */
  public function onCapsuleSelected(event:CapsuleScriptEvent):Void
  {
  }

  /**
   * Called when the current difficulty is changed.
   */
  public function onDifficultySwitch(event:CapsuleScriptEvent):Void
  {
  }

  /**
   * Called when a song is selected.
   */
  public function onSongSelected(event:CapsuleScriptEvent):Void
  {
  }

  /**
   * Called when the intro for Freeplay finishes.
   */
  public function onFreeplayIntroDone(event:FreeplayScriptEvent):Void
  {
  }

  /**
   * Called when the Freeplay outro begins.
   */
  public function onFreeplayOutro(event:FreeplayScriptEvent):Void
  {
  }

  /**
   * Called when Freeplay is closed.
   */
  public function onFreeplayClose(event:FreeplayScriptEvent):Void
  {
  }

  /**
   * Called when a capsule receives a new rank.
   */
  public function onCapsuleNewRank(event:CapsuleScriptEvent):Void
  {
  }

  /**
   * Called when the rank letter slams down on a freeplay capsule.
   */
  public function onRankSlam(event:CapsuleScriptEvent):Void
  {
  }

  /**
   * Called when the entire capsule slams down, after a new rank has been applied.
   */
  public function onCapsuleSlam(event:CapsuleScriptEvent):Void
  {
  }

  public function centerObjectOnCard(object:flixel.FlxObject)
  {
    if (pinkBack != null) object.x = (x + ((pinkBack.width - object.width) / 2)) * 0.74;
  }
}
