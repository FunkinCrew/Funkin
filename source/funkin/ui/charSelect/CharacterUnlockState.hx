package funkin.ui.charSelect;

import flixel.util.typeLimit.NextState;
import funkin.ui.transition.NextSubState;
import funkin.assets.FunkinAssetCache;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import funkin.graphics.FunkinSprite;
import flixel.util.FlxColor;
import funkin.data.character.CharacterRegistry;
import funkin.play.components.HealthIcon;
import funkin.ui.freeplay.charselect.PlayableCharacter;
import funkin.data.freeplay.player.PlayerRegistry;
import funkin.ui.mainmenu.MainMenuState;
import funkin.ui.transition.Transition;
#if FEATURE_TOUCH_CONTROLS
import funkin.util.TouchUtil;
import funkin.util.DeviceUtil;
#end
//
// ~PATHS~
//
import funkin.assets.Assets;
import funkin.assets.Assets.AssetType;
import funkin.assets.Paths.AnimateAtlasAssetPathBuilder;
import funkin.assets.Paths.AssetPath;
import funkin.assets.Paths.MusicAssetPathBuilder;
import funkin.assets.ValidatedPaths as Paths;

using flixel.util.FlxSpriteUtil;

/**
 * When you want the player to unlock a character, call `CharacterUnlockState.unlock(characterName)`.
 * It handles both the act of unlocking the character and displaying the dialog.
 */
@:nullSafety
class CharacterUnlockState extends MusicBeatState
{
  public var targetCharacterId:String = "";
  public var targetCharacterData:Null<PlayableCharacter>;

  var nextState:NextState;
  var nextQueryAssetsFunc:(AssetType) -> Array<AssetPath>;

  static final DIALOG_BG_COLOR:FlxColor = 0xFF000000; // Iconic
  static final DIALOG_COLOR:FlxColor = 0xFF4344F6; // Iconic
  static final DIALOG_FONT_COLOR:FlxColor = 0xFFFFFFFF; // Iconic

  var busy:Bool = false;

  /**
   * Determine the AssetPaths that this state depends on to load.
   *
   * @param type The type of AssetPath to return a list of paths for.
   * @param characterID The character ID for unlocking.
   * @return The list of AssetPaths.
   */
  public static function queryAssets(type:AssetType, characterID:String):Array<AssetPath>
  {
    var results:Array<AssetPath> = [];

    var baseCharacterData = CharacterRegistry.instance.fetchCharacterData(characterID ?? Constants.DEFAULT_CHARACTER);
    var charId = baseCharacterData?.healthIcon?.id ?? Constants.DEFAULT_HEALTH_ICON;

    switch (type)
    {
      case IMAGE:
        results.appendUnique([funkin.assets.Paths.image('gameplay/characters/$charId/icon-$charId')]);

      case XML:
        @:privateAccess
        if (HealthIcon.isNewSpritesheet(charId))
        {
          results.appendUnique([funkin.assets.Paths.xml('gameplay/characters/$charId/icon-$charId')]);
        }

      default:
    }
    return results;
  }

  public function new(targetPlayableCharacter:String,
    ?nextState:NextState,
    ?nextQueryAssetsFunc:(AssetType) -> Array<AssetPath>)
  {
    super();

    this.targetCharacterId = targetPlayableCharacter;
    this.targetCharacterData = PlayerRegistry.instance.fetchEntry(targetCharacterId);
    this.nextState = nextState == null ? () -> new MainMenuState() : nextState;
    this.nextQueryAssetsFunc = nextQueryAssetsFunc == null ? MainMenuState.queryAssets : nextQueryAssetsFunc;
  }

  override function create():Void
  {
    super.create();

    handleMusic();

    bgColor = DIALOG_BG_COLOR;

    var dialogContainer:FlxSpriteGroup = new FlxSpriteGroup();
    add(dialogContainer);

    // Build the graphic for the text...
    var charName:String = targetCharacterData != null ? targetCharacterData.getName() : targetCharacterId.toTitleCase();
    // var dialogText:FlxText = new FlxText(0, 0, 0, 'You can now play as     $charName.\n\nCheck it out in Freeplay!');
    var dialogText:FlxText = new FlxText(0, 0, 0, 'You can now play as     $charName.');
    dialogText.setFormat(funkin.assets.Paths.font('ui/fonts/VCR OSD Mono'), 32, DIALOG_FONT_COLOR, LEFT);

    // THEN we can size the dialog to match...
    var dialogBG:FlxSprite = new FlxSprite(0, 0);
    dialogBG.makeGraphic(Std.int(dialogText.width + 32), Std.int(dialogText.height + 32), FlxColor.TRANSPARENT);
    dialogBG.drawRoundRect(0, 0, dialogBG.width, dialogBG.height, 16, 16, DIALOG_COLOR);
    dialogContainer.add(dialogBG);

    dialogBG.screenCenter(XY);

    // THEN we can position the text inside that.
    dialogText.x = dialogBG.x + 16;
    dialogText.y = dialogBG.y + 16;
    dialogContainer.add(dialogText);

    // HealthIcon handles getting the right frames for us,
    // but it has a bunch of overhead in it that makes it gross to work with outside the health bar.
    var healthIconCharacterId = targetCharacterData?.getOwnedCharacterIds()[0];
    var baseCharacterData = CharacterRegistry.instance.fetchCharacterData(healthIconCharacterId ?? Constants.DEFAULT_CHARACTER);
    var healthIcon:HealthIcon = new HealthIcon(healthIconCharacterId);
    @:privateAccess
    healthIcon.configure(baseCharacterData?.healthIcon);
    healthIcon.autoUpdate = false;
    healthIcon.bopEvery = 0; // You can increase this number later once the animation is done.
    healthIcon.size.set(0.5, 0.5);
    healthIcon.x = dialogBG.x + 390;
    healthIcon.y = dialogBG.y + 6;
    healthIcon.flipX = true;
    healthIcon.snapToTargetSize();
    dialogContainer.add(healthIcon);

    dialogContainer.scale.set(0, 0);
    FlxTween.num(0.0, 1.0, 0.75, {
      ease: FlxEase.elasticOut,
    }, function(curScale)
    {
      dialogContainer.scale.set(curScale, curScale);
      healthIcon.size.set(0.5 * curScale, 0.5 * curScale);
    });

    // performUnlock();
  }

  function handleMusic():Void
  {
    FlxG.sound.music?.stop();
    FlxG.sound.play(Paths.sound('ui/main-menu/confirm-menu').toFlxSoundAsset());
  }

  override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (controls.ACCEPT_P || controls.BACK_P #if FEATURE_TOUCH_CONTROLS || TouchUtil.pressAction() #end && !busy)
    {
      busy = true;
      startClose();
    }
  }

  function startClose():Void
  {
    // Fade to black, then switch state.
    FlxG.camera.fade(FlxColor.BLACK, 0.75, false, () ->
    {
      Transition.switchState(nextState, {
        assetQuery: nextQueryAssetsFunc,
        transition: BlackScreen(None, Fade(South)),
      });
    });
  }
}
