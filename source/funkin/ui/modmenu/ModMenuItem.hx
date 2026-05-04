package funkin.ui.modmenu;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.graphics.FunkinSprite;
import funkin.group.FunkinGroup.FunkinSpriteGroup;
import funkin.group.FunkinGroup;
import funkin.modding.PolymodHandler;
import funkin.save.Save;
import funkin.ui.MusicBeatState;
import polymod.Polymod.ModMetadata;

/**
 * Represents an installed mod visually in the mod menu.
 */
class ModMenuItem extends FunkinSpriteGroup
{
  static final ITEM_WIDTH:Int = 420;
  static final ICON_HEIGHT:Int = 96;
  static final DESC_WIDTH:Int = 420 - 96 - 8;

  /**
   * The metadata for the mod this item represents.
   */
  final mod:ModMetadata;

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
    trace('Mod selected: ${mod.title}');
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

  public function new(mod:ModMetadata)
  {
    super();

    this.mod = mod;

    background = new FunkinSprite(0, 0).makeSolidColor(ITEM_WIDTH, ICON_HEIGHT, FlxColor.WHITE);
    background.localX = 0;
    background.localY = 0;
    background.color = 0xFF333333;
    add(background);

    loadModIcon(mod.icon);

    var modTitle:FlxText = new FlxText(0, 0, DESC_WIDTH);
    modTitle.setFormat(funkin.assets.Paths.font('ui/fonts/VCR OSD Mono'), 24, FlxColor.WHITE);
    add(modTitle);
    modTitle.localX = ICON_HEIGHT + 8;
    modTitle.text = '${mod.title}';

    var modDesc:FlxText = new FlxText(0, 0, DESC_WIDTH);
    modDesc.setFormat(funkin.assets.Paths.font('ui/fonts/VCR OSD Mono'), 16, FlxColor.WHITE);
    add(modDesc);
    modDesc.localX = ICON_HEIGHT + 8;
    modDesc.localY = modTitle.localY + modTitle.height + 4;
    modDesc.text = '${mod.description}';
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
      modIcon = new FunkinSprite(0, 0);
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

  override public function toString():String
  {
    return 'ModMenuItem(${mod.id})';
  }
}
