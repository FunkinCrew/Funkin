package funkin.ui.charSelect.icons;

import flixel.animation.FlxAnimation;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import funkin.data.freeplay.player.PlayerData.PlayerCharSelectData;
import funkin.data.freeplay.player.PlayerRegistry;
import funkin.graphics.FunkinSprite;
import funkin.graphics.shaders.VerticalCutShader;
import funkin.group.FunkinGroup;
import funkin.input.Controls;
import funkin.ui.charSelect.CharacterSelectState;
import funkin.ui.freeplay.charselect.PlayableCharacter;
import funkin.util.FramesJSFLParser;
import funkin.util.MathUtil;
import openfl.filters.BitmapFilter;
import openfl.filters.DropShadowFilter;
#if FEATURE_TOUCH_CONTROLS
import flixel.FlxObject;
import flixel.group.FlxGroup.FlxTypedGroup;
#end

/**
 * A `FunkinGroup` that holds all of the icons for the Character Select screen.
 */
@:nullSafety
class IconGroup extends FunkinGroup<FunkinSprite>
{
  /**
   * The filters applied to the currently selected icon.
   */
  public static final SELECTED_FILTERS:Array<BitmapFilter> = [
    new DropShadowFilter(0, 0, 0xFFFFFF, 1, 2, 2, 19, 1, false, false, false),
    new DropShadowFilter(5, 45, 0x000000, 1, 2, 2, 1, 1, false, false, false)
  ];

  /**
   * The path to the icon animation info file.
   */
  public static final ICON_ANIMATION_INFO_PATH:String = 'ui/character-select/interface/icon-bop/info.txt';

  /**
   * The speed to lerp the icons at when scrolling pages.
   */
  public static final SLOT_LERP_VALUE:Float = 0.1;

  /**
   * The distance between icons for both axes.
   * @default 100, 100
   */
  public var iconSpread:FlxPoint = FlxPoint.get(107, 105);

  /**
   * The controls for the Character Select screen.
   */
  var controls(get, never):Controls;

  function get_controls():Controls
  {
    @:privateAccess
    return CharacterSelectState.instance.controls;
  }

  /**
   * An intro tween for the icons that plays when entering Character Select.
   */
  var introTween:Null<FlxTween> = null;

  /**
   * An exit tween for the icons that plays when exiting Character Select.
   */
  var exitTween:Null<FlxTween> = null;

  /**
   * The shader to apply to the last 3 icons from the previous page.
   * Only used for locks.
   */
  var topCutShader:VerticalCutShader = new VerticalCutShader(TOP);

  /**
   * The shader to apply to the first 3 icons from the next page.
   * Only used for locks.
   */
  var bottomCutShader:VerticalCutShader = new VerticalCutShader(BOTTOM);

  #if FEATURE_TOUCH_CONTROLS
  /**
   * A group of hitboxes for the icons.
   * Only used on mobile.
   *
   * It's a `FlxTypedGroup` because `FunkinGroup` doesn't support `FlxObject`s...
   */
  var hitboxes:FlxTypedGroup<FlxObject> = new FlxTypedGroup<FlxObject>();
  #end

  final ANIMATION_DELAY:Float = 1 / 24;
  var _shouldAnimate:Bool = false;
  var _currentAnimationFrame:Int = 0;
  var _iconAnimationInfo:Null<Null<FramesJSFLInfo>>;
  var _iconToAnimate:Null<FunkinSprite>;
  var _animationTimer:Float = 0;

  public function new(x:Float = 0, y:Float = 0)
  {
    super(x, y);

    _iconAnimationInfo = FramesJSFLParser.parse(Paths.file(ICON_ANIMATION_INFO_PATH));
    if (_iconAnimationInfo == null)
    {
      throw 'Failed to icon animation data at path ${ICON_ANIMATION_INFO_PATH}, is the path provided correct?';
    }

    this.scrollFactor.set();
  }

  /**
   * Retrieves an icon by its ID.
   * @param id The ID of the icon to retrieve.
   * @return The icon, or null if it doesn't exist.
   */
  public function getIcon(id:String):Null<FunkinSprite>
  {
    return this.getFirst((icon) -> icon.ID == 0 && cast(icon, PixelatedIcon).char == id);
  }

  /**
   * Retrieves an icon by its index.
   * @param index The index of the icon to retrieve.
   * @return The icon, or null if it doesn't exist.
   */
  public function getIconByIndex(index:Int):Null<FunkinSprite>
  {
    for (iconIndex => member in this.children)
    {
      if (iconIndex == index)
      {
        return member;
      }
    }

    return null;
  }

  /**
   * Replaces a lock with a new icon.
   * @param characterId The character ID of the new icon.
   * @param lockIndex The index of the lock to replace.
   */
  public function replaceLock(characterId:String, lockIndex:Int):Void
  {
    var newIcon:PixelatedIcon = createPixelIcon(characterId);
    var oldLock:Null<FunkinSprite> = getIconByIndex(lockIndex);

    if (oldLock == null) return;

    this.remove(oldLock);
    this.insert(newIcon, lockIndex);
  }

  /**
   * Loads the icons for the Character Select screen.
   * @param slotCount The total number of slots in the Character Select screen.
   * @param characterList The list of available characters.
   * @param locksToUnlock The list of locks to unlock.
   */
  public function loadCharacters(slotCount:Int,
    characterList:Map<Int, String>,
    locksToUnlock:Array<Int>):Void
  {
    for (i in 0...slotCount)
    {
      var newIcon:Null<FunkinSprite> = null;
      var playableCharacterId:Null<String> = characterList.get(i) ?? Constants.DEFAULT_CHARACTER;
      var player:Null<PlayableCharacter> = PlayerRegistry.instance.fetchEntry(playableCharacterId);

      if (characterList.exists(i) && PlayerRegistry.instance.isCharacterSeen(playableCharacterId))
      {
        newIcon = createPixelIcon(playableCharacterId);
        newIcon.scale.set(2, 2);

        this.add(newIcon);
      }
      else
      {
        var isPlayerUnlocked:Bool = player?.isUnlocked() ?? false;
        if (characterList.exists(i) && isPlayerUnlocked)
        {
          locksToUnlock.push(i);
        }

        newIcon = new Lock(0, 0, i);
        newIcon.ID = 1;

        this.add(newIcon);
      }

      if (newIcon == null) continue;

      #if FEATURE_TOUCH_CONTROLS
      var iconHitbox:FlxObject = new FlxObject(0, 0, 86, 86);
      iconHitbox.active = false;
      iconHitbox.scrollFactor.set();
      hitboxes.add(iconHitbox);
      #end
    }

    updateIconPositions();
  }

  /**
   * Creates a pixel icon for the character select screen.
   * @param characterId The character ID of the icon to create.
   * @return The newly created icon.
   */
  public function createPixelIcon(characterId:String):PixelatedIcon
  {
    var newIcon:PixelatedIcon = new PixelatedIcon(0, 0);
    newIcon.setCharacter(characterId);
    newIcon.setGraphicSize(128, 128);
    newIcon.updateHitbox();
    newIcon.ID = 0;

    var playerData:Null<PlayerCharSelectData> = PlayerRegistry.instance.fetchEntry(characterId)?.getCharSelectData();
    var iconOffsets:Array<Float> = playerData?.pixelIconOffsets ?? [0, 0];
    newIcon.offset.x -= iconOffsets[0];
    newIcon.offset.y -= iconOffsets[1];

    // Add a reversed confirm animation for the pixel icon
    // I would just play the animation in reverse directly but I'd rather not mess with Flixel's janky animation controller lol
    // - Abnormal
    if (newIcon.hasAnimation('confirm') && newIcon.animation != null)
    {
      var confirmAnimation:Null<FlxAnimation> = newIcon.animation.getByName('confirm');
      if (confirmAnimation == null) return newIcon;

      var frameCount:Int = confirmAnimation.numFrames;
      var confirmFrames:Array<Int> = [for (i in 0...frameCount) i];
      confirmFrames.reverse();

      newIcon.animation.addByIndices('confirm-reversed', 'confirm0', confirmFrames, '', 10, false);
    }

    return newIcon;
  }

  /**
   * Starts the intro tween for the Character Select screen.
   */
  public function doIntroTween():Void
  {
    if (CharacterSelectState.instance == null) return;

    if (introTween != null) introTween.cancel();

    var currentPage:Int = Math.floor(CharacterSelectState.instance.currentSelection / CharacterSelectState.SLOTS_PER_PAGE);
    var targetY:Float = (120 - currentPage * iconSpread.y * 3) - 120;

    this.y = targetY + 300;

    introTween = FlxTween.tween(this, {
      y: targetY
    }, 1, {
      ease: FlxEase.expoOut
    });
    introTween.start();
  }

  /**
   * Starts the exit tween for the Character Select screen.
   */
  public function doExitTween():Void
  {
    if (exitTween != null) exitTween.cancel();

    exitTween = FlxTween.tween(this, {
      y: this.y + 300
    }, 0.8, {
      ease: FlxEase.backIn
    });
    exitTween.start();
  }

  /**
   * Updates the positions of the icons in the Character Select screen.
   */
  public function updateIconPositions():Void
  {
    for (index => member in this.children)
    {
      var iconX:Float = (index % CharacterSelectState.SLOTS_PER_ROW);
      var iconY:Float = Math.floor(index / CharacterSelectState.SLOTS_PER_ROW);

      member.localX = (iconX * iconSpread.x) + (CharacterSelectState.CUTOUT_SIZE + 450);
      member.localY = (iconY * iconSpread.y) + 135;
    }

    #if FEATURE_TOUCH_CONTROLS
    for (index => member in hitboxes.members)
    {
      var iconX:Float = (index % CharacterSelectState.SLOTS_PER_ROW);
      var iconY:Float = Math.floor(index / CharacterSelectState.SLOTS_PER_ROW);

      member.x = ((iconX * iconSpread.x) + (CharacterSelectState.CUTOUT_SIZE + 450)) + 20;
      member.y = (iconY * iconSpread.y) + 155;
    }
    #end
  }

  /**
   * Plays an animation on an icon.
   * Not to be confused with `playIconBop`!! That's just a function for the unlock animation.
   *
   * @param index The index of the icon to play the animation on.
   * @param animation The animation to play.
   * @param force Whether to force the animation to play.
   * @param reversed Whether to play the animation in reverse.
   */
  public function playIconAnimation(index:Int, animation:String, force:Bool = false, reversed:Bool = false):Void
  {
    var icon:Null<FunkinSprite> = getIconByIndex(index);
    if (icon == null)
    {
      throw 'Could not find icon in index $index';
      return;
    }

    icon.animation.play(animation, force, reversed);
  }

  /**
   * Selects an icon.
   * @param index The index of the icon to select.
   */
  public function selectIcon(index:Int):Void
  {
    var icon:Null<FunkinSprite> = getIconByIndex(index);

    if (icon == null) return;
    if (icon == _iconToAnimate) return;

    if (isPixelIcon(icon))
    {
      icon.filters = SELECTED_FILTERS;
      icon.scale.set(2.6, 2.6);
    }
    else
    {
      // If the icon is a lock, we need to play its selected animation!
      icon.animation.play('selected');
    }
  }

  /**
   * Deselects an icon.
   * @param index The index of the icon to deselect.
   */
  public function deselectIcon(index:Int):Void
  {
    var icon:Null<FunkinSprite> = getIconByIndex(index);
    if (icon == null) return;

    if (icon == _iconToAnimate)
    {
      _iconToAnimate = null;
      _shouldAnimate = false;
      _currentAnimationFrame = 0;
    }

    if (isPixelIcon(icon))
    {
      icon.filters = null;
      icon.scale.set(2, 2);
    }
    else
    {
      icon.animation.play('idle');
    }
  }

  /**
   * Plays the icon bop animation.
   * @param characterId The character ID of the icon to animate.
   */
  public function playIconBop(characterId:String):Void
  {
    if (_iconAnimationInfo == null) return;

    _iconToAnimate = getIcon(characterId);
    _shouldAnimate = true;
  }

  /**
   * Whether or not the specified icon is a pixel icon.
   * @param icon The icon to check.
   * @return `True`... or `False`...
   */
  public function isPixelIcon(icon:FunkinSprite):Bool
  {
    return icon.ID == 0;
  }

  function runAnimation(elapsed:Float):Void
  {
    if (_iconAnimationInfo == null) return;
    if (_iconToAnimate == null) return;

    if (_currentAnimationFrame >= _iconAnimationInfo.frames.length)
    {
      _shouldAnimate = false;
      _currentAnimationFrame = 0;
      return;
    }

    _animationTimer += elapsed;

    if (_animationTimer >= ANIMATION_DELAY)
    {
      _animationTimer -= _animationTimer;

      var finalFrame:FramesJSFLFrame = _iconAnimationInfo.frames.getFinal();
      var currentFrame:FramesJSFLFrame = _iconAnimationInfo.frames[_currentAnimationFrame];

      if (_currentAnimationFrame >= 13) _iconToAnimate.filters = SELECTED_FILTERS;

      var scaleXDiff:Float = currentFrame.scaleX - finalFrame.scaleX;
      var scaleYDiff:Float = currentFrame.scaleY - finalFrame.scaleY;

      _iconToAnimate.scale.set(2.6, 2.6);
      _iconToAnimate.scale.add(scaleXDiff, scaleYDiff);

      _currentAnimationFrame++;
    }
  }

  override public function updateChildren():Void
  {
    for (child in children)
    {
      // In this case, we want to do a lot stuff like scaling ourselves,
      // but we want FunkinGroup to handle positioning!
      if (child != null && child.exists && child.active)
      {
        var displace:FlxPoint = FlxPoint.get(child.localX, child.localY);

        child.x = x + displace.x;
        child.y = y + displace.y;

        // force child cameras to the group's cameras.
        if (child.cameras != cameras) child.cameras = cameras;
      }
    }
  }

  var previousPage:Int = -1;

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (_shouldAnimate)
    {
      runAnimation(elapsed);
    }

    if (CharacterSelectState.instance == null) return;

    var currentPage:Int = Math.floor(CharacterSelectState.instance.currentSelection / CharacterSelectState.SLOTS_PER_PAGE);

    if (introTween != null && introTween.active)
    {
      if (previousPage != currentPage && previousPage != -1)
      {
        @:privateAccess
        introTween.finish();
      }
    }
    else
    {
      this.y = MathUtil.smoothLerpPrecision(this.y, (120 - currentPage * iconSpread.y * 3) - 120, elapsed, SLOT_LERP_VALUE);
    }

    // The last 3 icons from the previous page are clipped from the top half
    // The first 3 icons from the next page are clipped from the bottom half
    // Any other icons not in the current page are hidden
    for (index => member in this.children)
    {
      var memberPage:Int = Math.floor(index / CharacterSelectState.SLOTS_PER_PAGE);
      var isNext3:Bool = (index % CharacterSelectState.SLOTS_PER_PAGE) < 3 && memberPage == currentPage + 1;
      var isLast3:Bool = (index % CharacterSelectState.SLOTS_PER_PAGE) >= (CharacterSelectState.SLOTS_PER_PAGE - 3) && memberPage == currentPage - 1;

      var shouldClip:Bool = isNext3 || isLast3;

      var targetAlpha:Float = (memberPage == currentPage) ? 1 : (shouldClip ? 0.5 : 0);
      member.alpha = targetAlpha;

      if (isPixelIcon(member))
      {
        @:nullSafety(Off)
        member.clipRect = null;
      }
      else
      {
        @:nullSafety(Off)
        member.shader = null;
      }

      if (shouldClip)
      {
        // FIXME: clipRect is buggy on locks specifically when trying to clip out the bottom half
        // A shader is used instead for now
        // - Abnormal
        if (isLast3)
        {
          if (isPixelIcon(member))
          {
            member.clipRect = FlxRect.get(0, member.frameHeight / 2, member.frameWidth, member.frameHeight);
          }
          else
          {
            member.shader = topCutShader;
          }
        }
        else if (isNext3)
        {
          if (isPixelIcon(member))
          {
            member.clipRect = FlxRect.get(0, 0, member.frameWidth, member.frameHeight / 2);
          }
          else
          {
            member.shader = bottomCutShader;
          }
        }
      }
    }

    previousPage = currentPage;
  }
}
