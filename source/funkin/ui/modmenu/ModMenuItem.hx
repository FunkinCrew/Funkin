package funkin.ui.modmenu;

import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.graphics.FunkinAnimationDecoder;
import funkin.graphics.FunkinSprite;
import funkin.group.FunkinGroup.FunkinSpriteGroup;
import polymod.Polymod.ModMetadata;
import polymod.Polymod.ModDependencies;
import flixel.math.FlxRect;
import flixel.util.FlxDirection;
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
  /**
   * Global default width of each mod menu item.
   */
  public static final ITEM_WIDTH:Int = 350;

  /**
   * Global default height of each icon.
   */
  public static final ICON_HEIGHT:Int = 96;

  /**
   * The width of the description in an item.
   */
  public static final DESC_WIDTH:Int = 216;

  /**
   * The height of the title in an item.
   */
  public static final TITLE_HEIGHT:Int = 42;

  /**
   * The spacing of the title in an item.
   */
  public static final TITLE_SPACING:Int = 36;

  /**
   * The padding width of an item.
   */
  public static final ITEM_WIDTH_PADDING:Int = 24;

  /**
   * The bg slide distance before settling.
   */
  public static var BG_SLIDE_DISTANCE:Float = 14;

  /**
   * The value to lerp for the sliding bg
   */
  public static var BG_SLIDE_LERP:Float = 20;

  /**
   * The goddamn friggin font!! Damn you ling long!
   */
  static inline final FONT:String = 'ui/fonts/FunkinLingLong';

  /**
   * How far right of the icon the title and description start.
   */
  static inline final TEXT_GAP:Int = 8;

  /**
   * The title font's default size.
   */
  static inline final TITLE_FONT_SIZE:Int = 30;

  /**
   * The description font's default size.
   */
  static inline final DESCRIPTION_FONT_SIZE:Int = 20;

  /**
   * The description field height's default size.
   */
  static inline final DESCRIPTION_FIELD_HEIGHT:Int = 64;

  /**
   * The default alpha for an item's description.
   */
  static inline final DESCRIPTION_ALPHA:Float = 0.7;

  /**
   * Alpha of the background while the item is selected.
   */
  static inline final SELECTED_BACKGROUND_ALPHA:Float = 0.25;

  /**
   * The incomptaible font's default size.
   */
  static inline final INCOMPATIBLE_FONT_SIZE:Int = 16;

  /**
   * The color to use for description in incompatible mods.
   */
  static inline final INCOMPATIBLE_COLOR:FlxColor = 0xFFFF0000;

  /**
   * The default alpha to use for an incompatible mod.
   */
  static inline final INCOMPATIBLE_ICON_ALPHA:Float = 0.5;

  /**
   * Flash duration.
   */
  static inline final FLASH_DURATION:Float = 0.5;

  /**
   * Flash starting alpha.
   */
  static inline final FLASH_START_ALPHA:Float = 1.0;

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
  var flashElapsed:Float = -1; // -1 means 'not flashing'
  var flashTargetAlpha:Float = SELECTED_BACKGROUND_ALPHA;

  /**
   * True while this item is being manually lerped from one list to another (or within a list).
   */
  public var isInFlight(default, null):Bool = false;

  // TODO: Maybe make the flight.. nicer... like maybe in TransitionRecord - Moon
  var flightStartX:Float = 0;
  var flightStartY:Float = 0;
  var flightTargetX:Float = 0;
  var flightTargetY:Float = 0;
  var flightElapsed:Float = 0;
  var flightDuration:Float = 0.2;
  var flightEase:Float->Float = FlxEase.quadOut;
  var flightOnComplete:Null<Void->Void> = null;

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

  /**
   * Whether this mod is enabled (it's on the right side)
   */
  public var enabled:Bool = false;

  /**
   * Creates a new mod menu item
   * @param mod The mod info for the item
   * @param iconAssetPath The path to the icon of this item.
   * @param fallbackModId The fallback mod id if there is no mod id.
   * @param fallbackDescription The fallback mod description.
   */
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

    // Background
    background = new FunkinSprite(0, 0);
    background.makeGraphic(ITEM_WIDTH - ITEM_WIDTH_PADDING, ICON_HEIGHT, FlxColor.WHITE);
    background.localX = 0;
    background.localY = 0;
    background.localAlpha = 0;
    add(background);

    buildIcon(iconAssetPath);
    buildTexts();
  }

  /**
   * Builds the icon, from the first of these that exists:
   * - The asset path the item was given.
   * - The icon the mod's loading already cached by its ID.
   * - The icon the mod ships, which can be a static image, a GIF or a WebP.
   * - The fallback icon.
   *
   * An item with neither an asset path nor mod metadata has no icon.
   *
   * @param iconAssetPath The asset path we want to use.
   */
  function buildIcon(iconAssetPath:Null<String>):Void
  {
    modIcon = new FunkinSprite(0, 0);

    var onIconLoaded = () ->
    {
      modIcon.setGraphicSize(ICON_HEIGHT, ICON_HEIGHT);
      modIcon.localScale.x = modIcon.scale.x;
      modIcon.localScale.y = modIcon.scale.y;
      modIcon.updateHitbox();
    };

    if (iconAssetPath != null)
    {
      modIcon.loadGraphic(Paths.image(iconAssetPath));
      onIconLoaded();
    }
    else if (mod != null)
    {
      loadModIcon(mod, onIconLoaded);
    }
    else
    {
      return;
    }

    modIcon.scrollFactor.set();
    modIcon.antialiasing = true;
    add(modIcon);
  }

  /**
   * Loads the item's mod icon.
   * @param mod The mod's meta data.
   */
  @:privateAccess
  function loadModIcon(mod:ModMetadata, onIconLoaded:Void->Void):Void
  {
    if (mod.id != null && funkin.assets.FunkinBitmapFrontend.instance.exists(mod.id))
    {
      modIcon.loadGraphic(funkin.assets.FunkinBitmapFrontend.instance.get(mod.id));
      onIconLoaded();
    }
    else if (mod.icon != null)
    {
      if (lime.graphics.Image.__isGIF(mod.icon))
      {
        modIconDecoder = new FunkinAnimationDecoder(mod.icon, GIF);

        modIcon.loadGraphic(modIconDecoder.bitmapData);
        onIconLoaded();
      }
      else if (lime.graphics.Image.__isWebP(mod.icon))
      {
        modIconDecoder = new FunkinAnimationDecoder(mod.icon, WEBP);

        modIcon.loadGraphic(modIconDecoder.bitmapData);
        onIconLoaded();
      }
      else
      {
        #if sys
        modIcon.loadGraphic(openfl.display.BitmapData.fromBytes(mod.icon, true));
        onIconLoaded();
        #else
        modIcon.makeGraphic(1, 1, FlxColor.TRANSPARENT);
        openfl.display.BitmapData.loadFromBytes(mod.icon).onComplete((bitmap) ->
        {
          if (bitmap != null) modIcon.loadGraphic(bitmap);
          onIconLoaded();
        }).onError((error) ->
          {
            trace('Failed to load icon for mod ${mod.id}: $error');
            modIcon.loadGraphic(Paths.image('ui/mods/fallback-icon'));
            onIconLoaded();
          });
        #end
      }
    }
    else
    {
      trace(' MOD MENU '.bold().bg_orange() + ' No icon found for mod ${mod.id}, using fallback');

      modIcon.loadGraphic(Paths.image('ui/mods/fallback-icon'));
      onIconLoaded();
    }
  }

  /**
   * Builds the texts the item will have
   */
  function buildTexts():Void
  {
    final textX:Float = ICON_HEIGHT + TEXT_GAP;

    titleText = new ScrollingTextBox(DESC_WIDTH, TITLE_HEIGHT, funkin.assets.Paths.font(FONT, 'otf'), TITLE_FONT_SIZE, FlxColor.WHITE);
    titleText.localX = textX;
    titleText.text = getModTitle();
    add(titleText);

    descriptionText = new FlxText(0, 0, DESC_WIDTH);
    descriptionText.setFormat(funkin.assets.Paths.font(FONT, 'otf'), DESCRIPTION_FONT_SIZE, FlxColor.WHITE);
    descriptionText.localX = textX;
    descriptionText.fieldHeight = DESCRIPTION_FIELD_HEIGHT;
    descriptionText.localY = titleText.localY + TITLE_SPACING;
    descriptionText.text = getModDescription();
    descriptionText.localAlpha = DESCRIPTION_ALPHA;
    descriptionText.clipRect = FlxRect.get(0, 0, DESC_WIDTH, ICON_HEIGHT - TITLE_SPACING);
    add(descriptionText);
  }

  override public function update(elapsed:Float):Void
  {
    if (modIconDecoder != null)
    {
      modIconDecoder.update(elapsed);
    }

    super.update(elapsed);

    updateFlight(elapsed);
    updateFlash(elapsed);
    updateBackgroundSlide(elapsed);
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

  /**
   * Turns the item's work off or back on. The list does this for items scrolled out of view,
   * so they stop updating (including their animated icon) and stop drawing.
   *
   * @param onScreen `false` to put the item to sleep.
   */
  public function setOnScreen(onScreen:Bool):Void
  {
    if (this.active == onScreen && this.visible == onScreen) return;

    this.active = onScreen;
    this.visible = onScreen;
  }

  // BACKGROUND //

  /**
   * Move the background in a direction so it visibly slides into place.
   * @param dir The direction we want to go to
   */
  public function slideBackgroundFrom(dir:Null<FlxDirection>):Void
  {
    switch (dir)
    {
      case FlxDirection.UP:
        bgOffsetX = 0;
        bgOffsetY = -BG_SLIDE_DISTANCE; // came from up
      case FlxDirection.DOWN:
        bgOffsetX = 0;
        bgOffsetY = BG_SLIDE_DISTANCE;
      case FlxDirection.LEFT:
        bgOffsetX = -BG_SLIDE_DISTANCE;
        bgOffsetY = 0;
      case FlxDirection.RIGHT:
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
   * Updates the sliding movement the item's background is doing.
   * @param elapsed Elapsed
   */
  function updateBackgroundSlide(elapsed:Float):Void
  {
    if (bgOffsetX == 0 && bgOffsetY == 0) return;

    var t = Math.min(1, BG_SLIDE_LERP * elapsed);
    bgOffsetX += (0 - bgOffsetX) * t;
    bgOffsetY += (0 - bgOffsetY) * t;

    if (Math.abs(bgOffsetX) < 0.1) bgOffsetX = 0;
    if (Math.abs(bgOffsetY) < 0.1) bgOffsetY = 0;

    background.localX = -bgOffsetX;
    background.localY = -bgOffsetY;
  }

  /**
   * The alpha the background rests at: lit up while selected, invisible otherwise.
   */
  function getRestingBackgroundAlpha():Float
  {
    return selected ? SELECTED_BACKGROUND_ALPHA : 0;
  }

  /**
   * Puts the background at its resting alpha. Called when the selection changes.
   */
  function refreshBackgroundAlpha():Void
  {
    // While flashing, updateFlash() owns background.localAlpha.
    if (background == null || flashElapsed >= 0) return;

    background.localAlpha = getRestingBackgroundAlpha();
  }

  // FLASH //

  /**
   * Briefly flashes the background to full alpha, then eases back down to its
   * resting alpha (0.25 if selected, 0 otherwise) over FLASH_DURATION seconds.
   */
  public function flashBackground():Void
  {
    flashTargetAlpha = getRestingBackgroundAlpha();
    background.localAlpha = FLASH_START_ALPHA;
    flashElapsed = 0;
  }

  /**
   * Updates the flashing.
   * @param elapsed Elapsed.
   */
  function updateFlash(elapsed:Float):Void
  {
    if (flashElapsed < 0) return;

    flashElapsed += elapsed;
    var t:Float = flashElapsed / FLASH_DURATION;

    if (t >= 1)
    {
      flashElapsed = -1;

      // The selection may have changed during the flash, so go to where it rests now.
      background.localAlpha = getRestingBackgroundAlpha();
      return;
    }

    var easedT:Float = FlxEase.quintOut(t);
    background.localAlpha = FlxMath.lerp(FLASH_START_ALPHA, flashTargetAlpha, easedT);
  }

  // FLIGHT //

  /**
   * Starts a manual lerp of X and Y pos from the item's CURRENT position to the given target.
   * @param targetX Target X pos.
   * @param targetY Target Y pos.
   * @param duration Flight duration in seconds.
   * @param ease Optional easing
   * @param onComplete Optional callback fired once when the flight finishes.
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
   * completion callback (if any). Safe to call even when not in flight.
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

  /**
   * Updates the flight.
   * @param elapsed Elapsed.
   */
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

  // MOD INFO //

  /**
   * Gets the mod id.
   * @return String the mod id.
   */
  public function getModId():String
  {
    return mod != null ? mod.id : fallbackModId;
  }

  /**
   * Gets the mod title.
   * @return String the mod title.
   */
  public function getModTitle():String
  {
    return mod != null ? mod.title : fallbackTitle;
  }

  /**
   * Gets the mod description.
   * @return String the mod description.
   */
  public function getModDescription():String
  {
    return mod != null ? mod.description : fallbackDescription;
  }

  /**
   * Gets the mod dependencies.
   * @return ModDependencies the mod dependencies.
   */
  public function getDependencies():ModDependencies
  {
    return mod != null ? mod.dependencies : cast [];
  }

  /**
   * Gets the mod's optional dependencies.
   * @return ModDependencies the mod's option dependencies.
   */
  public function getOptionalDependencies():ModDependencies
  {
    return mod != null ? mod.optionalDependencies : cast [];
  }

  /**
   * Gets the mod version.
   * @return Dynamic the mod version.
   */
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
    descriptionText.setFormat(funkin.assets.Paths.font(FONT, 'otf'), INCOMPATIBLE_FONT_SIZE, INCOMPATIBLE_COLOR);
    descriptionText.localAlpha = 1.0;
    descriptionText.text = 'INCOMPATIBLE WITH v${Application.current.meta.get('version')}\nCURRENT MOD VERSION v${mod?.apiVersion.toString() ?? 'UNKNOWN'}';
    if (modIcon != null) modIcon.localAlpha = INCOMPATIBLE_ICON_ALPHA;
  }

  // Setters / helpers

  function set_selected(value:Bool):Bool
  {
    this.selected = value;

    if (titleText != null) titleText.scrolling = value;

    refreshBackgroundAlpha();

    return selected;
  }

  override public function toString():String
  {
    return 'ModMenuItem(${getModId()})';
  }
}
