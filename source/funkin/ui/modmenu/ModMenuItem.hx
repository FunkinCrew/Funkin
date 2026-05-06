package funkin.ui.modmenu;

import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.graphics.FunkinSprite;
import funkin.group.FunkinGroup.FunkinSpriteGroup;
import polymod.Polymod.ModMetadata;
import polymod.Polymod.ModDependencies;
import funkin.Paths;

/**
 * Represents an installed mod visually in the mod menu.
 */
class ModMenuItem extends FunkinSpriteGroup
{
  public static final ITEM_WIDTH:Int = 420;
  public static final ICON_HEIGHT:Int = 96;
  public static final DESC_WIDTH:Int = 280;

  /**
   * Whether this mod item is immutable in list operations.
   */
  public var locked:Bool = false;

  /**
   * The metadata for the mod this item represents.
   */
  public final mod:Null<ModMetadata>;

  var fallbackModId:String;
  var fallbackTitle:String;
  var fallbackDescription:String;

  /**
   * The icon for the mod's thumbnail.
   */
  var modIcon:FunkinSprite;

  /**
   * The text displaying the title of the mod.
   */
  var titleText:FlxText;

  /**
   * The text displaying the description of the mod.
   */
  var descriptionText:FlxText;

  /**
   * The sprite for the background color.
   */
  var background:FunkinSprite;

  /**
   * Whether this mod is selected (pressing arrows moves it around)
   */
  public var selected(default, set):Bool = false;

  function set_selected(value:Bool):Bool
  {
    this.selected = value;
    updateBackgroundColor();
    return selected;
  }

  /**
   * Whether this mod is enabled (it's on the right side)
   */
  public var enabled(default, set):Bool = false;

  function set_enabled(value:Bool):Bool
  {
    this.enabled = value;
    updateBackgroundColor();
    return enabled;
  }

  public function new(
      mod:Null<ModMetadata>,
      iconAssetPath:Null<String> = null,
      fallbackModId:String = '__unknown_mod__',
      fallbackTitle:String = 'Unknown Mod',
      fallbackDescription:String = '')
  {
    super();

    this.mod = mod;
    this.fallbackModId = fallbackModId;
    this.fallbackTitle = fallbackTitle;
    this.fallbackDescription = fallbackDescription;

    background = new FunkinSprite(0, 0);
    background.makeGraphic(ITEM_WIDTH, ICON_HEIGHT, FlxColor.WHITE);
    background.localX = 0;
    background.localY = 0;
    background.color = 0xFF333333;
    add(background);

    modIcon = new FunkinSprite(0, 0);
    if (iconAssetPath != null)
    {
      modIcon.loadGraphic(Paths.image(iconAssetPath));
      add(modIcon);

      modIcon.scrollFactor.set();
      modIcon.antialiasing = true;
      modIcon.setGraphicSize(ICON_HEIGHT, ICON_HEIGHT);
      modIcon.localScale.x = modIcon.scale.x;
      modIcon.localScale.y = modIcon.scale.y;
      modIcon.updateHitbox();
    }
    else if (mod != null)
    {
      loadModIcon(mod.icon);
    }

    titleText = new FlxText(0, 0, DESC_WIDTH);
    titleText.setFormat(funkin.assets.Paths.font('ui/fonts/VCR OSD Mono'), 24, FlxColor.WHITE);
    titleText.localX = ICON_HEIGHT + 8;
    titleText.text = getModTitle();
    add(titleText);

    titleText.clipRect = FlxRect.get(0, 0, DESC_WIDTH, 32);

    descriptionText = new FlxText(0, 0, DESC_WIDTH);
    descriptionText.setFormat(funkin.assets.Paths.font('ui/fonts/VCR OSD Mono'), 14, FlxColor.WHITE);
    descriptionText.localX = ICON_HEIGHT + 8;
    descriptionText.localY = titleText.localY + Math.min(titleText.height, 32) + 4;
    descriptionText.text = getModDescription();
    add(descriptionText);

    descriptionText.clipRect = FlxRect.get(0, 0, DESC_WIDTH, ICON_HEIGHT - titleText.height - 4);
  }

  function updateBackgroundColor():Void
  {
    if (this.enabled)
    {
      background.color = this.selected ? 0xFF999999 : 0xFF666666;
    }
    else
    {
      background.color = this.selected ? 0xFF666666 : 0xFF333333;
    }
  }

  function loadModIcon(bytes:haxe.io.Bytes):Void
  {
    // Stolen from Enigma Engine LMFAO -Eric

    // Convert a haxe byte array to the proper data structure.
    var future = openfl.utils.ByteArray.loadFromBytes(bytes);

    future.onComplete((openFlBytes:openfl.utils.ByteArray) ->
    {
      trace('Loaded icon bytes!');
      // Convert the bytes into bitmap data.
      var bitmapData = openfl.display.BitmapData.fromBytes(openFlBytes);
      // Tie the bitmap data to a sprite.
      modIcon.loadGraphic(bitmapData);
      add(modIcon);

      modIcon.scrollFactor.set();
      modIcon.antialiasing = true;

      // FunkinGroup is funny
      modIcon.setGraphicSize(ICON_HEIGHT, ICON_HEIGHT);
      modIcon.localScale.x = modIcon.scale.x;
      modIcon.localScale.y = modIcon.scale.y;

      modIcon.updateHitbox();
    });
    future.onError((error) ->
    {
      trace(error);
    });
  }

  public function getModId():String
  {
    return mod != null ? mod.id : fallbackModId;
  }

  public function getModTitle():String
  {
    return mod != null ? mod.title : fallbackTitle;
  }

  public function getModDescription():String
  {
    return mod != null ? mod.description : fallbackDescription;
  }

  public function getDependencies():ModDependencies
  {
    return mod != null ? mod.dependencies : cast [];
  }

  public function getOptionalDependencies():ModDependencies
  {
    return mod != null ? mod.optionalDependencies : cast [];
  }

  public function getModVersion():Dynamic
  {
    return mod != null ? mod.modVersion : null;
  }

  override public function toString():String
  {
    return 'ModMenuItem(${getModId()})';
  }
}
