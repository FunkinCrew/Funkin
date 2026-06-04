package funkin.ui.modmenu;

import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.graphics.FunkinSprite;
import funkin.group.FunkinGroup.FunkinSpriteGroup;
import polymod.Polymod.ModMetadata;
import polymod.Polymod.ModDependencies;
import flixel.math.FlxRect;
import funkin.Paths;

/**
 * Represents an installed mod visually in the mod menu.
 */
class ModMenuItem extends FunkinSpriteGroup
{
  public static final ITEM_WIDTH:Int = 350;
  public static final ICON_HEIGHT:Int = 96;
  public static final DESC_WIDTH:Int = 216;
  public static final ITEM_WIDTH_PADDING:Int = 24;

  public static var BG_SLIDE_DISTANCE:Float = 14;
  public static var BG_SLIDE_LERP:Float = 20;

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

  var bgOffsetX:Float = 0;
  var bgOffsetY:Float = 0;

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
   * Move the background in a direction so it visibly slides into place.
   * dir: -1 up, 1 down, -2 left, 2 right.
   */
  public function slideBackgroundFrom(dir:Int):Void
  {
    switch (dir)
    {
      case -1: bgOffsetX = 0; bgOffsetY = -BG_SLIDE_DISTANCE; // came from up
      case 1:  bgOffsetX = 0; bgOffsetY = BG_SLIDE_DISTANCE;
      case -2: bgOffsetX = -BG_SLIDE_DISTANCE; bgOffsetY = 0;
      case 2:  bgOffsetX = BG_SLIDE_DISTANCE; bgOffsetY = 0;
      default: bgOffsetX = 0; bgOffsetY = 0;
    }
    background.localX = -bgOffsetX;
    background.localY = -bgOffsetY;
  }

  /**
   * Whether this mod is enabled (it's on the right side)
   */
  public var enabled(default, set):Bool = false;

  function set_enabled(value:Bool):Bool
  {
    this.enabled = value;
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
    background.makeGraphic(ITEM_WIDTH - ITEM_WIDTH_PADDING, ICON_HEIGHT, FlxColor.WHITE);
    background.localX = 0;
    background.localY = 0;
    background.localAlpha = 0;
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
      trace(mod.icon);
      if (mod.icon != null) loadModIcon(mod.icon);
      else
      {
        trace('No icon found for mod ${mod.id}, using fallback');
        // Fallback icon
        modIcon.loadGraphic(Paths.image("ui/mods/mod-menu-fallback-icon"));
        add(modIcon);

        modIcon.scrollFactor.set();
        modIcon.antialiasing = true;
        modIcon.setGraphicSize(ICON_HEIGHT, ICON_HEIGHT);
        modIcon.localScale.x = modIcon.scale.x;
        modIcon.localScale.y = modIcon.scale.y;
        modIcon.updateHitbox();
      }
    }

    titleText = new FlxText(0, 0, DESC_WIDTH);
    titleText.setFormat(funkin.assets.Paths.font('ui/fonts/FunkinLingLong', 'otf'), 30, FlxColor.WHITE);
    titleText.localX = ICON_HEIGHT + 8;
    titleText.fieldHeight = 42;
    titleText.text = getModTitle();
    titleText.scale.set(1,0.8);
    add(titleText);

    titleText.clipRect = FlxRect.get(0, 0, DESC_WIDTH, 32);

    descriptionText = new FlxText(0, 0, DESC_WIDTH);
    descriptionText.setFormat(funkin.assets.Paths.font('ui/fonts/FunkinLingLong', 'otf'), 20, FlxColor.WHITE);
    descriptionText.localX = ICON_HEIGHT + 8;
    descriptionText.fieldHeight = 64;
    descriptionText.localY = titleText.localY + Math.min(titleText.height, 32) + 4;
    descriptionText.text = getModDescription();
    descriptionText.scale.set(1,0.8);
    descriptionText.localAlpha = 0.7;
    add(descriptionText);

    descriptionText.clipRect = FlxRect.get(0, 0, DESC_WIDTH, ICON_HEIGHT - titleText.height - 4);
  }

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (bgOffsetX != 0 || bgOffsetY != 0)
    {
      var t = Math.min(1, BG_SLIDE_LERP * elapsed);
      bgOffsetX += (0 - bgOffsetX) * t;
      bgOffsetY += (0 - bgOffsetY) * t;

      if (Math.abs(bgOffsetX) < 0.1) bgOffsetX = 0;
      if (Math.abs(bgOffsetY) < 0.1) bgOffsetY = 0;

      background.localX = -bgOffsetX;
      background.localY = -bgOffsetY;
    }
  }

  function updateBackgroundColor():Void
  {
    if (this.selected) background.localAlpha = 0.25;
    else background.localAlpha = 0;
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
