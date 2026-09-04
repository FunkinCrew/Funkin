package funkin.ui.modmenu;

import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.graphics.FunkinAnimationDecoder;
import funkin.graphics.FunkinSprite;
import funkin.group.FunkinGroup.FunkinSpriteGroup;
import polymod.Polymod.ModMetadata;
import polymod.Polymod.ModDependencies;
import flixel.math.FlxRect;
import funkin.Paths;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import funkin.ui.ScrollingTextBox;
import lime.app.Application;

/**
 * Represents an installed mod visually in the mod menu.
 */
@:access(lime.graphics.Image)
class ModMenuItem extends FunkinSpriteGroup
{
  public static final ITEM_WIDTH:Int = 350;
  public static final ICON_HEIGHT:Int = 96;
  public static final DESC_WIDTH:Int = 216;
  public static final TITLE_HEIGHT:Int = 42;
  public static final TITLE_SPACING:Int = 36;
  public static final ITEM_WIDTH_PADDING:Int = 24;
  public static var BG_SLIDE_DISTANCE:Float = 14;
  public static var BG_SLIDE_LERP:Float = 20;
  public static var iconStrings:Array<String> = [];

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
   * The decoder for the mod's animated icon.
   */
  var modIconDecoder:Null<FunkinAnimationDecoder>;

  /**
   * The icon for the mod's thumbnail.
   */
  var modIcon:FunkinSprite;

  /**
   * The text displaying the title of the mod.
   */
  var titleText:ScrollingTextBox;

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

    if (titleText != null) titleText.scrolling = value;

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
      case -1:
        bgOffsetX = 0;
        bgOffsetY = -BG_SLIDE_DISTANCE; // came from up
      case 1:
        bgOffsetX = 0;
        bgOffsetY = BG_SLIDE_DISTANCE;
      case -2:
        bgOffsetX = -BG_SLIDE_DISTANCE;
        bgOffsetY = 0;
      case 2:
        bgOffsetX = BG_SLIDE_DISTANCE;
        bgOffsetY = 0;
      default:
        bgOffsetX = 0;
        bgOffsetY = 0;
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

  /**
   * True while this item is being manually lerped from one list to another (or within a list).
   */
  public var isInFlight(default, null):Bool = false;

  var flightStartX:Float = 0;
  var flightStartY:Float = 0;
  var flightTargetX:Float = 0;
  var flightTargetY:Float = 0;
  var flightElapsed:Float = 0;
  var flightDuration:Float = 0.2;
  var flightEase:Float->Float = FlxEase.quadOut;
  var flightOnComplete:Null<Void->Void> = null;

  /**
   * Starts a manual lerp of localX/localY from the item's CURRENT position to the given target.
   * @param targetX Target localX.
   * @param targetY Target localY.
   * @param duration Flight duration in seconds.
   * @param ease Optional ease function (defaults to FlxEase.quadOut).
   * @param onComplete Optional callback fired once, when the flight finishes (naturally or via finishFlight()).
   */
  public function startFlight(targetX:Float, targetY:Float, duration:Float, ?ease:Float->Float, ?onComplete:Void->Void):Void
  {
    flightStartX = localX;
    flightStartY = localY;
    flightTargetX = targetX;
    flightTargetY = targetY;
    flightElapsed = 0;
    flightDuration = duration > 0 ? duration : 0.0001;
    flightEase = ease != null ? ease : FlxEase.quadOut;
    flightOnComplete = onComplete;
    isInFlight = true;
  }

  /**
   * Immediately finishes the flight, snapping to the exact target and firing the
   * completion callback (if any). Safe to call even when not in flight (no-op then).
   */
  public function finishFlight():Void
  {
    if (!isInFlight) return;

    isInFlight = false;
    localX = flightTargetX;
    localY = flightTargetY;

    var cb = flightOnComplete;
    flightOnComplete = null;

    if (cb != null) cb();
  }

  /**
   * Cancels the flight in place, WITHOUT snapping to the target and WITHOUT firing
   * the completion callback. Use when something else is about to take over positioning
   * this frame anyway (e.g. a fresh startFlight() call, or a hard repositionItems()).
   */
  public function cancelFlight():Void
  {
    isInFlight = false;
    flightOnComplete = null;
  }

  function updateFlight(elapsed:Float):Void
  {
    if (!isInFlight) return;

    flightElapsed += elapsed;
    var t:Float = flightElapsed / flightDuration;

    if (t >= 1)
    {
      finishFlight();
      return;
    }

    var easedT:Float = flightEase(t);
    localX = FlxMath.lerp(flightStartX, flightTargetX, easedT);
    localY = FlxMath.lerp(flightStartY, flightTargetY, easedT);
  }

  var flashElapsed:Float = -1; // -1 means 'not flashing'

  static inline final FLASH_DURATION:Float = 0.5;
  static inline final FLASH_START_ALPHA:Float = 1.0;

  var flashTargetAlpha:Float = 0.25;

  public function new(mod:Null<ModMetadata>,
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
      modIcon.scrollFactor.set();
      modIcon.antialiasing = true;
      modIcon.setGraphicSize(ICON_HEIGHT, ICON_HEIGHT);
      modIcon.localScale.x = modIcon.scale.x;
      modIcon.localScale.y = modIcon.scale.y;
      modIcon.updateHitbox();
      add(modIcon);
    }
    else if (mod != null)
    {
      @:privateAccess
      if (mod.id != null && funkin.assets.FunkinBitmapFrontend.instance.exists(mod.id))
      {
        modIcon.loadGraphic(funkin.assets.FunkinBitmapFrontend.instance.get(mod.id));
        modIcon.scrollFactor.set();
        modIcon.antialiasing = true;
        modIcon.setGraphicSize(ICON_HEIGHT, ICON_HEIGHT);
        modIcon.localScale.x = modIcon.scale.x;
        modIcon.localScale.y = modIcon.scale.y;
        modIcon.updateHitbox();
        add(modIcon);
      }
      else if (mod.icon != null)
      {
        if (lime.graphics.Image.__isGIF(mod.icon))
        {
          modIconDecoder = new FunkinAnimationDecoder(mod.icon, GIF);

          modIcon.loadGraphic(modIconDecoder.bitmapData);
        }
        else if (lime.graphics.Image.__isWebP(mod.icon))
        {
          modIconDecoder = new FunkinAnimationDecoder(mod.icon, WEBP);

          modIcon.loadGraphic(modIconDecoder.bitmapData);
        }
        else
        {
          modIcon.loadGraphic(openfl.display.BitmapData.fromBytes(mod.icon, true));
        }

        modIcon.scrollFactor.set();
        modIcon.antialiasing = true;
        modIcon.setGraphicSize(ICON_HEIGHT, ICON_HEIGHT);
        modIcon.localScale.x = modIcon.scale.x;
        modIcon.localScale.y = modIcon.scale.y;
        modIcon.updateHitbox();
        add(modIcon);
      }
      else
      {
        trace('No icon found for mod ${mod.id}, using fallback');

        modIcon.loadGraphic(Paths.image('ui/mods/fallback-icon'));
        modIcon.scrollFactor.set();
        modIcon.antialiasing = true;
        modIcon.setGraphicSize(ICON_HEIGHT, ICON_HEIGHT);
        modIcon.localScale.x = modIcon.scale.x;
        modIcon.localScale.y = modIcon.scale.y;
        modIcon.updateHitbox();
        add(modIcon);
      }
    }

    titleText = new ScrollingTextBox(DESC_WIDTH, TITLE_HEIGHT, funkin.assets.Paths.font('ui/fonts/FunkinLingLong', 'otf'), 30, FlxColor.WHITE);
    titleText.localX = ICON_HEIGHT + 8;
    titleText.text = getModTitle();
    add(titleText);

    descriptionText = new FlxText(0, 0, DESC_WIDTH);
    descriptionText.setFormat(funkin.assets.Paths.font('ui/fonts/FunkinLingLong', 'otf'), 20, FlxColor.WHITE);
    descriptionText.localX = ICON_HEIGHT + 8;
    descriptionText.fieldHeight = 64;
    descriptionText.localY = titleText.localY + TITLE_SPACING;
    descriptionText.text = getModDescription();
    descriptionText.localAlpha = 0.7;
    add(descriptionText);

    setChildClipRect(descriptionText, FlxRect.get(0, 0, DESC_WIDTH, ICON_HEIGHT - TITLE_SPACING));
  }

  override public function update(elapsed:Float):Void
  {
    if (modIconDecoder != null)
    {
      modIconDecoder.update(elapsed);
    }

    super.update(elapsed);

    updateFlight(elapsed);
    updateBackgroundColor();
    updateFlash(elapsed);

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

  override public function destroy():Void
  {
    super.destroy();

    if (modIconDecoder != null)
    {
      modIconDecoder.destroy();
      modIconDecoder = null;
    }
  }

  function updateBackgroundColor():Void
  {
    // While flashing, updateFlash() owns background.localAlpha for this frame.
    if (flashElapsed >= 0) return;

    if (this.selected) background.localAlpha = 0.25;
    else
      background.localAlpha = 0;
  }

  /**
   * Briefly flashes the background to full alpha, then eases back down to its
   * resting alpha (0.25 if selected, 0 otherwise) over FLASH_DURATION seconds.
   */
  public function flashBackground():Void
  {
    flashTargetAlpha = this.selected ? 0.25 : 0;
    background.localAlpha = FLASH_START_ALPHA;
    flashElapsed = 0;
  }

  function updateFlash(elapsed:Float):Void
  {
    if (flashElapsed < 0) return;

    flashElapsed += elapsed;
    var t:Float = flashElapsed / FLASH_DURATION;

    if (t >= 1)
    {
      background.localAlpha = flashTargetAlpha;
      flashElapsed = -1;
      return;
    }

    var easedT:Float = FlxEase.quintOut(t);
    background.localAlpha = FlxMath.lerp(FLASH_START_ALPHA, flashTargetAlpha, easedT);
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

  /**
   * Mark this item as incompatible.
   * Greys out the title and shows a warning in the description.
   */
  public function setIncompatible():Void
  {
    titleText.textColor = FlxColor.GRAY;
    descriptionText.setFormat(funkin.assets.Paths.font('ui/fonts/FunkinLingLong', 'otf'), 16, 0xFFFF0000);
    descriptionText.localAlpha = 1.0;
    descriptionText.text = 'INCOMPATIBLE WITH v${Application.current.meta.get('version')}\nCURRENT MOD VERSION v${mod?.apiVersion.toString() ?? 'UNKNOWN'}';
    if (modIcon != null) modIcon.localAlpha = 0.5;
  }

  override public function toString():String
  {
    return 'ModMenuItem(${getModId()})';
  }
}
