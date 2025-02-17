package funkin.play.character;

import flixel.animation.FlxAnimationController;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.math.FlxMath;
import flixel.math.FlxPoint.FlxCallbackPoint;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import funkin.graphics.FunkinSprite;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import funkin.graphics.adobeanimate.FlxAtlasSprite;
import funkin.modding.events.ScriptEvent;
import funkin.play.character.CharacterData.CharacterRenderType;
import flixel.util.FlxDirectionFlags;
import openfl.display.BitmapData;
import openfl.display.BlendMode;

/**
 * Individual animation data for an AnimateAtlasCharacter.
 */
typedef AnimateAtlasAnimation =
{
  name:String,
  prefix:String,
  offsets:Null<Array<Float>>,
  looped:Bool,
}

/**
 * An AnimateAtlasCharacter is a Character which is rendered by
 * displaying an animation derived from an Adobe Animate texture atlas spritesheet file.
 *
 * BaseCharacter has game logic, AnimateAtlasCharacter has only rendering logic.
 * KEEP THEM SEPARATE!
 */
class AnimateAtlasCharacter extends BaseCharacter
{
  // BaseCharacter extends FlxSprite but we can't make it also extend FlxAtlasSprite UGH
  // I basically copied the code from FlxSpriteGroup to make the FlxAtlasSprite a "child" of this class
  var mainSprite:FlxAtlasSprite;

  var _skipTransformChildren:Bool = false;

  var animations:Map<String, AnimateAtlasAnimation> = new Map<String, AnimateAtlasAnimation>();
  var currentAnimName:Null<String> = null;
  var animFinished:Bool = false;

  public function new(id:String)
  {
    super(id, CharacterRenderType.AnimateAtlas);
  }

  override function initVars():Void
  {
    // this.flixelType = SPRITEGROUP;

    // TODO: Make `animation` a stub that redirects calls to `mainSprite`?
    animation = new FlxAnimationController(this);

    offset = new FlxCallbackPoint(offsetCallback);
    origin = new FlxCallbackPoint(originCallback);
    scale = new FlxCallbackPoint(scaleCallback);
    scrollFactor = new FlxCallbackPoint(scrollFactorCallback);

    scale.set(1, 1);
    scrollFactor.set(1, 1);

    initMotionVars();
  }

  override function onCreate(event:ScriptEvent):Void
  {
    // Display a custom scope for debugging purposes.
    #if FEATURE_DEBUG_TRACY
    cpp.vm.tracy.TracyProfiler.zoneScoped('AnimateAtlasCharacter.create(${this.characterId})');
    #end

    try
    {
      trace('Loading assets for Animate Atlas character "${characterId}"', flixel.util.FlxColor.fromString("#89CFF0"));
      var atlasSprite:FlxAtlasSprite = loadAtlasSprite();
      setSprite(atlasSprite);

      loadAnimations();
    }
    catch (e)
    {
      throw "Exception thrown while building FlxAtlasSprite: " + e;
    }

    super.onCreate(event);
  }

  public override function playAnimation(name:String, restart:Bool = false, ignoreOther:Bool = false, reverse:Bool = false):Void
  {
    var correctName = correctAnimationName(name);
    if (correctName == null)
    {
      trace('$characterName Could not find Atlas animation: ' + name);
      return;
    }

    var animData = getAnimationData(correctName);
    currentAnimName = correctName;
    var prefix:String = animData.prefix;
    if (prefix == null) prefix = correctName;
    var loop:Bool = animData.looped;

    this.mainSprite.playAnimation(prefix, restart, ignoreOther, loop);
  }

  public override function hasAnimation(name:String):Bool
  {
    return getAnimationData(name) != null;
  }

  /**
   * Returns true if the animation has finished playing.
   * Never true if animation is configured to loop.
   */
  public override function isAnimationFinished():Bool
  {
    return mainSprite?.isAnimationFinished() ?? false;
  }

  function loadAtlasSprite():FlxAtlasSprite
  {
    trace('[ATLASCHAR] Loading sprite atlas for ${characterId}.');

    var animLibrary:String = Paths.getLibrary(_data.assetPath);
    var animPath:String = Paths.stripLibrary(_data.assetPath);
    var assetPath:String = Paths.animateAtlas(animPath, animLibrary);

    var sprite:FlxAtlasSprite = new FlxAtlasSprite(0, 0, assetPath);

    // sprite.onAnimationComplete.removeAll();
    sprite.onAnimationComplete.add(this.onAnimationFinished);

    return sprite;
  }

  override function onAnimationFinished(prefix:String):Void
  {
    super.onAnimationFinished(prefix);

    if (!getCurrentAnimation().endsWith(Constants.ANIMATION_HOLD_SUFFIX)
      && hasAnimation(getCurrentAnimation() + Constants.ANIMATION_HOLD_SUFFIX))
    {
      playAnimation(getCurrentAnimation() + Constants.ANIMATION_HOLD_SUFFIX);
    }

    if (getAnimationData() != null && getAnimationData().looped)
    {
      if (StringTools.endsWith(prefix, "-hold")) trace(prefix);
      playAnimation(prefix, true, false);
    }
    else
    {
      // Make the game hold on the last frame.
      this.mainSprite.cleanupAnimation(prefix);
      // currentAnimName = null;

      // Fallback to idle!
      // playAnimation('idle', true, false);
    }
  }

  function setSprite(sprite:FlxAtlasSprite):Void
  {
    trace('[ATLASCHAR] Applying sprite properties to ${characterId}');

    this.mainSprite = sprite;

    mainSprite.ignoreExclusionPref = ["sing"];

    // This forces the atlas to recalcuate its width and height
    this.mainSprite.alpha = 0.0001;
    this.mainSprite.draw();
    this.mainSprite.alpha = 1.0;

    var feetPos:FlxPoint = feetPosition;
    this.updateHitbox();

    sprite.x = this.x;
    sprite.y = this.y;
    sprite.alpha *= alpha;
    sprite.flipX = flipX;
    sprite.flipY = flipY;
    sprite.scrollFactor.copyFrom(scrollFactor);
    sprite.cameras = _cameras; // _cameras instead of cameras because get_cameras() will not return null

    if (clipRect != null) clipRectTransform(sprite, clipRect);
  }

  function loadAnimations():Void
  {
    trace('[ATLASCHAR] Attempting to load ${_data.animations.length} animations for ${characterId}');

    var animData:Array<AnimateAtlasAnimation> = cast _data.animations;

    for (anim in animData)
    {
      // Validate the animation before adding.
      var prefix = anim.prefix;
      if (!this.mainSprite.hasAnimation(prefix))
      {
        FlxG.log.warn('[ATLASCHAR] Animation ${prefix} not found in Animate Atlas ${_data.assetPath}');
        trace('[ATLASCHAR] Animation ${prefix} not found in Animate Atlas ${_data.assetPath}');
        continue;
      }
      animations.set(anim.name, anim);
      trace('[ATLASCHAR] - Successfully loaded animation ${anim.name} to ${characterId}');
    }

    trace('[ATLASCHAR] Loaded ${animations.size()} animations for ${characterId}');
  }

  public override function getCurrentAnimation():String
  {
    // return this.mainSprite.getCurrentAnimation();
    return currentAnimName;
  }

  function getAnimationData(name:String = null):AnimateAtlasAnimation
  {
    if (name == null) name = getCurrentAnimation();
    return animations.get(name);
  }

  //
  //
  // Code copied from FlxSpriteGroup
  //
  //

  /**
   * Handy function that allows you to quickly transform one property of sprites in this group at a time.
   *
   * @param   callback   Function to transform the sprites. Example:
   *                     `function(sprite, v:Dynamic) { s.acceleration.x = v; s.makeGraphic(10,10,0xFF000000); }`
   * @param   value      Value which will passed to lambda function.
   */
  @:generic
  public function transformChildren<V>(callback:FlxAtlasSprite->V->Void, value:V):Void
  {
    if (_skipTransformChildren || this.mainSprite == null) return;

    callback(this.mainSprite, value);
  }

  /**
   * Calls `kill()` on the group's members and then on the group itself.
   * You can revive this group later via `revive()` after this.
   */
  public override function kill():Void
  {
    _skipTransformChildren = true;
    super.kill();
    _skipTransformChildren = false;
    if (this.mainSprite != null)
    {
      this.mainSprite.kill();
      this.mainSprite = null;
    }
  }

  /**
   * Revives the group.
   */
  public override function revive():Void
  {
    _skipTransformChildren = true;
    super.revive(); // calls set_exists and set_alive
    _skipTransformChildren = false;
    this.mainSprite.revive();
  }

  /**
   * **WARNING:** A destroyed `FlxBasic` can't be used anymore.
   * It may even cause crashes if it is still part of a group or state.
   * You may want to use `kill()` instead if you want to disable the object temporarily only and `revive()` it later.
   *
   * This function is usually not called manually (Flixel calls it automatically during state switches for all `add()`ed objects).
   *
   * Override this function to `null` out variables manually or call `destroy()` on class members if necessary.
   * Don't forget to call `super.destroy()`!
   */
  public override function destroy():Void
  {
    // normally don't have to destroy FlxPoints, but these are FlxCallbackPoints!
    offset = FlxDestroyUtil.destroy(offset);
    origin = FlxDestroyUtil.destroy(origin);
    scale = FlxDestroyUtil.destroy(scale);
    scrollFactor = FlxDestroyUtil.destroy(scrollFactor);

    this.mainSprite = FlxDestroyUtil.destroy(this.mainSprite);

    super.destroy();
  }

  /**
   * Check and see if any sprite in this group is currently on screen.
   *
   * @param   Camera   Specify which game camera you want. If `null`, it will just grab the first global camera.
   * @return  Whether the object is on screen or not.
   */
  public override function isOnScreen(?camera:FlxCamera):Bool
  {
    if (this.mainSprite != null && this.mainSprite.exists && this.mainSprite.visible && this.mainSprite.isOnScreen(camera)) return true;

    return false;
  }

  /**
   * Checks to see if a point in 2D world space overlaps any `FlxSprite` object from this group.
   *
   * @param   Point           The point in world space you want to check.
   * @param   InScreenSpace   Whether to take scroll factors into account when checking for overlap.
   * @param   Camera          Specify which game camera you want. If `null`, it will just grab the first global camera.
   * @return  Whether or not the point overlaps this group.
   */
  public override function overlapsPoint(point:FlxPoint, inScreenSpace:Bool = false, camera:FlxCamera = null):Bool
  {
    var result:Bool = false;
    result = this.mainSprite.overlapsPoint(point, inScreenSpace, camera);
    return result;
  }

  /**
   * Checks to see if a point in 2D world space overlaps any of FlxSprite object's current displayed pixels.
   * This check is ALWAYS made in screen space, and always takes scroll factors into account.
   *
   * @param   Point    The point in world space you want to check.
   * @param   Mask     Used in the pixel hit test to determine what counts as solid.
   * @param   Camera   Specify which game camera you want.  If `null`, it will just grab the first global camera.
   * @return  Whether or not the point overlaps this object.
   */
  public override function pixelsOverlapPoint(point:FlxPoint, Mask:Int = 0xFF, Camera:FlxCamera = null):Bool
  {
    var result:Bool = false;
    if (this.mainSprite != null && this.mainSprite.exists && this.mainSprite.visible)
    {
      result = this.mainSprite.pixelsOverlapPoint(point, Mask, Camera);
    }
    return result;
  }

  public override function update(elapsed:Float):Void
  {
    this.mainSprite.update(elapsed);

    if (moves) updateMotion(elapsed);
  }

  public override function draw():Void
  {
    this.mainSprite.draw();

    #if FLX_DEBUG
    if (FlxG.debugger.drawDebug) drawDebug();
    #end
  }

  inline function xTransform(sprite:FlxSprite, x:Float):Void
    sprite.x += x; // addition

  inline function yTransform(sprite:FlxSprite, y:Float):Void
    sprite.y += y; // addition

  inline function angleTransform(sprite:FlxSprite, angle:Float):Void
    sprite.angle += angle; // addition

  inline function alphaTransform(sprite:FlxSprite, alpha:Float):Void
  {
    if (sprite.alpha != 0 || alpha == 0)
    {
      sprite.alpha *= alpha; // multiplication
    }
    else
    {
      sprite.alpha = 1 / alpha; // direct set to avoid stuck sprites
    }
  }

  inline function directAlphaTransform(sprite:FlxSprite, alpha:Float):Void
    sprite.alpha = alpha; // direct set

  inline function facingTransform(sprite:FlxSprite, facing:FlxDirectionFlags):Void
    sprite.facing = facing;

  inline function flipXTransform(sprite:FlxSprite, flipX:Bool):Void
    sprite.flipX = flipX;

  inline function flipYTransform(sprite:FlxSprite, flipY:Bool):Void
    sprite.flipY = flipY;

  inline function movesTransform(sprite:FlxSprite, moves:Bool):Void
    sprite.moves = moves;

  inline function pixelPerfectTransform(sprite:FlxSprite, pixelPerfect:Bool):Void
    sprite.pixelPerfectRender = pixelPerfect;

  inline function gColorTransform(sprite:FlxSprite, color:Int):Void
    sprite.color = color;

  inline function blendTransform(sprite:FlxSprite, blend:BlendMode):Void
    sprite.blend = blend;

  inline function immovableTransform(sprite:FlxSprite, immovable:Bool):Void
    sprite.immovable = immovable;

  inline function visibleTransform(sprite:FlxSprite, visible:Bool):Void
    sprite.visible = visible;

  inline function activeTransform(sprite:FlxSprite, active:Bool):Void
    sprite.active = active;

  inline function solidTransform(sprite:FlxSprite, solid:Bool):Void
    sprite.solid = solid;

  inline function aliveTransform(sprite:FlxSprite, alive:Bool):Void
    sprite.alive = alive;

  inline function existsTransform(sprite:FlxSprite, exists:Bool):Void
    sprite.exists = exists;

  inline function cameraTransform(sprite:FlxSprite, camera:FlxCamera):Void
    sprite.camera = camera;

  inline function camerasTransform(sprite:FlxSprite, cameras:Array<FlxCamera>):Void
    sprite.cameras = cameras;

  inline function offsetTransform(sprite:FlxSprite, offset:FlxPoint):Void
    sprite.offset.copyFrom(offset);

  inline function originTransform(sprite:FlxSprite, origin:FlxPoint):Void
    sprite.origin.copyFrom(origin);

  inline function scaleTransform(sprite:FlxSprite, scale:FlxPoint):Void
    sprite.scale.copyFrom(scale);

  inline function scrollFactorTransform(sprite:FlxSprite, scrollFactor:FlxPoint):Void
    sprite.scrollFactor.copyFrom(scrollFactor);

  inline function clipRectTransform(sprite:FlxSprite, clipRect:FlxRect):Void
  {
    if (clipRect == null)
    {
      sprite.clipRect = null;
    }
    else
    {
      sprite.clipRect = FlxRect.get(clipRect.x - sprite.x + x, clipRect.y - sprite.y + y, clipRect.width, clipRect.height);
    }
  }

  var resS:FlxPoint = new FlxPoint();

  /**
   * Reset the character so it can be used at the start of the level.
   * Call this when restarting the level.
   */
  override public function resetCharacter(resetCamera:Bool = true):Void
  {
    trace("RESETTING ATLAS " + characterName);

    // Reset the animation offsets. This will modify x and y to be the absolute position of the character.
    // this.animOffsets = [0, 0];

    // Now we can set the x and y to be their original values without having to account for animOffsets.
    this.resetPosition();
    mainSprite.setPosition(originalPosition.x, originalPosition.y);

    // Then reapply animOffsets...
    // applyAnimationOffsets(getCurrentAnimation());

    // Make sure we are playing the idle animation
    // ...then update the hitbox so that this.width and this.height are correct.

    mainSprite.scale.set(1, 1);
    mainSprite.alpha = 0.0001;
    mainSprite.width = 0;
    mainSprite.height = 0;
    this.dance(true); // Force to avoid the old animation playing with the wrong offset at the start of the song.

    mainSprite.draw(); // refresh frame

    if (resS.x == 0)
    {
      resS.x = mainSprite.width; // clunky bizz
      resS.y = mainSprite.height;
    }

    mainSprite.alpha = alpha;

    mainSprite.width = resS.x;
    mainSprite.height = resS.y;
    frameWidth = 0;
    frameHeight = 0;

    scaleCallback(scale);
    this.updateHitbox();

    // Reset the camera focus point while we're at it.
    if (resetCamera) this.resetCameraFocusPoint();
  }

  inline function offsetCallback(offset:FlxPoint):Void
    transformChildren(offsetTransform, offset);

  inline function originCallback(origin:FlxPoint):Void
    transformChildren(originTransform, origin);

  inline function scaleCallback(scale:FlxPoint):Void
    transformChildren(scaleTransform, scale);

  inline function scrollFactorCallback(scrollFactor:FlxPoint):Void
    transformChildren(scrollFactorTransform, scrollFactor);

  override function set_camera(value:FlxCamera):FlxCamera
  {
    if (camera != value) transformChildren(cameraTransform, value);
    return super.set_camera(value);
  }

  override function set_cameras(value:Array<FlxCamera>):Array<FlxCamera>
  {
    if (cameras != value) transformChildren(camerasTransform, value);
    return super.set_cameras(value);
  }

  override function set_exists(value:Bool):Bool
  {
    if (exists != value) transformChildren(existsTransform, value);
    return super.set_exists(value);
  }

  override function set_visible(value:Bool):Bool
  {
    if (exists && visible != value) transformChildren(visibleTransform, value);
    return super.set_visible(value);
  }

  override function set_active(value:Bool):Bool
  {
    if (exists && active != value) transformChildren(activeTransform, value);
    return super.set_active(value);
  }

  override function set_alive(value:Bool):Bool
  {
    if (alive != value) transformChildren(aliveTransform, value);
    return super.set_alive(value);
  }

  override function set_x(value:Float):Float
  {
    if (!exists || x == value) return x; // early return (no need to transform)

    transformChildren(xTransform, value - x); // offset
    return x = value;
  }

  override function set_y(value:Float):Float
  {
    if (exists && y != value) transformChildren(yTransform, value - y); // offset
    return y = value;
  }

  override function set_angle(value:Float):Float
  {
    if (exists && angle != value) transformChildren(angleTransform, value - angle); // offset
    return angle = value;
  }

  override function set_alpha(value:Float):Float
  {
    value = FlxMath.bound(value, 0, 1);

    if (exists && alpha != value)
    {
      transformChildren(directAlphaTransform, value);
    }
    return alpha = value;
  }

  override function set_facing(value:FlxDirectionFlags):FlxDirectionFlags
  {
    if (exists && facing != value) transformChildren(facingTransform, value);
    return facing = value;
  }

  override function set_flipX(value:Bool):Bool
  {
    if (exists && flipX != value) transformChildren(flipXTransform, value);
    return flipX = value;
  }

  override function set_flipY(value:Bool):Bool
  {
    if (exists && flipY != value) transformChildren(flipYTransform, value);
    return flipY = value;
  }

  override function set_moves(value:Bool):Bool
  {
    if (exists && moves != value) transformChildren(movesTransform, value);
    return moves = value;
  }

  override function set_immovable(value:Bool):Bool
  {
    if (exists && immovable != value) transformChildren(immovableTransform, value);
    return immovable = value;
  }

  override function set_solid(value:Bool):Bool
  {
    if (exists && solid != value) transformChildren(solidTransform, value);
    return super.set_solid(value);
  }

  override function set_color(value:Int):Int
  {
    if (exists && color != value) transformChildren(gColorTransform, value);
    return color = value;
  }

  override function set_blend(value:BlendMode):BlendMode
  {
    if (exists && blend != value) transformChildren(blendTransform, value);
    return blend = value;
  }

  override function set_clipRect(rect:FlxRect):FlxRect
  {
    if (exists) transformChildren(clipRectTransform, rect);
    return super.set_clipRect(rect);
  }

  override function set_pixelPerfectRender(value:Bool):Bool
  {
    if (exists && pixelPerfectRender != value) transformChildren(pixelPerfectTransform, value);
    return super.set_pixelPerfectRender(value);
  }

  override function set_width(value:Float):Float
  {
    return value;
  }

  override function get_width():Float
  {
    if (this.mainSprite == null) return 0;

    return this.mainSprite.width;
  }

  /**
   * Returns the left-most position of the left-most member.
   * If there are no members, x is returned.
   *
   * @since 5.0.0
   * @return the left-most position of the left-most member
   */
  public function findMinX():Float
  {
    return this.mainSprite == null ? x : findMinXHelper();
  }

  function findMinXHelper():Float
  {
    return this.mainSprite.x;
  }

  /**
   * Returns the right-most position of the right-most member.
   * If there are no members, x is returned.
   *
   * @since 5.0.0
   * @return the right-most position of the right-most member
   */
  public function findMaxX():Float
  {
    return this.mainSprite == null ? x : findMaxXHelper();
  }

  function findMaxXHelper():Float
  {
    return this.mainSprite.x + this.mainSprite.width;
  }

  /**
   * This functionality isn't supported in SpriteGroup
   */
  override function set_height(value:Float):Float
  {
    return value;
  }

  override function get_height():Float
  {
    if (this.mainSprite == null) return 0;

    return this.mainSprite.height;
  }

  /**
   * Returns the top-most position of the top-most member.
   * If there are no members, y is returned.
   *
   * @since 5.0.0
   * @return the top-most position of the top-most member
   */
  public function findMinY():Float
  {
    return this.mainSprite == null ? y : findMinYHelper();
  }

  function findMinYHelper():Float
  {
    return this.mainSprite.y;
  }

  /**
   * Returns the top-most position of the top-most member.
   * If there are no members, y is returned.
   *
   * @since 5.0.0
   * @return the bottom-most position of the bottom-most member
   */
  public function findMaxY():Float
  {
    return this.mainSprite == null ? y : findMaxYHelper();
  }

  function findMaxYHelper():Float
  {
    return this.mainSprite.y + this.mainSprite.height;
  }

  /**
   * This functionality isn't supported in SpriteGroup
   * @return this sprite group
   */
  public override function loadGraphicFromSprite(Sprite:FlxSprite):FunkinSprite
  {
    #if FLX_DEBUG
    throw "This function is not supported in FlxSpriteGroup";
    #end
    return this;
  }

  /**
   * This functionality isn't supported in SpriteGroup
   * @return this sprite group
   */
  public override function loadGraphic(Graphic:FlxGraphicAsset, Animated:Bool = false, Width:Int = 0, Height:Int = 0, Unique:Bool = false,
      ?Key:String):FlxSprite
  {
    return this;
  }

  /**
   * This functionality isn't supported in SpriteGroup
   * @return this sprite group
   */
  public override function loadRotatedGraphic(Graphic:FlxGraphicAsset, Rotations:Int = 16, Frame:Int = -1, AntiAliasing:Bool = false, AutoBuffer:Bool = false,
      ?Key:String):FlxSprite
  {
    #if FLX_DEBUG
    throw "This function is not supported in FlxSpriteGroup";
    #end
    return this;
  }

  /**
   * This functionality isn't supported in SpriteGroup
   * @return this sprite group
   */
  public override function makeGraphic(Width:Int, Height:Int, Color:Int = FlxColor.WHITE, Unique:Bool = false, ?Key:String):FlxSprite
  {
    #if FLX_DEBUG
    throw "This function is not supported in FlxSpriteGroup";
    #end
    return this;
  }

  override function set_pixels(value:BitmapData):BitmapData
  {
    return value;
  }

  override function set_frame(value:FlxFrame):FlxFrame
  {
    return value;
  }

  override function get_pixels():BitmapData
  {
    return null;
  }

  /**
   * Internal function to update the current animation frame.
   *
   * @param	RunOnCpp	Whether the frame should also be recalculated if we're on a non-flash target
   */
  override inline function calcFrame(RunOnCpp:Bool = false):Void
  {
    // Nothing to do here
  }

  /**
   * This functionality isn't supported in SpriteGroup
   */
  override inline function resetHelpers():Void {}

  /**
   * This functionality isn't supported in SpriteGroup
   */
  public override inline function stamp(Brush:FlxSprite, X:Int = 0, Y:Int = 0):Void {}

  override function set_frames(Frames:FlxFramesCollection):FlxFramesCollection
  {
    return Frames;
  }

  /**
   * This functionality isn't supported in SpriteGroup
   */
  override inline function updateColorTransform():Void {}
}
