package funkin.graphics;

import animate.FlxAnimate;
import animate.FlxAnimateFrames.FilterQuality;
import animate.FlxAnimateFrames.SpritemapInput;
import animate.FlxAnimateFrames;
import animate.internal.SymbolItem;
import animate.internal.elements.AtlasInstance;
import animate.internal.elements.Element;
import animate.internal.elements.SymbolInstance;
import flixel.FlxCamera;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import funkin.assets.Assets;
import funkin.assets.Paths;
import funkin.graphics.framebuffer.FunkinFilterRenderer;
import haxe.io.Path;
import openfl.display.BitmapData;
import openfl.display3D.textures.TextureBase;
import openfl.filters.BitmapFilter;
import polymod.Polymod;
import polymod.PolymodAssets;

using StringTools;

typedef AtlasSpriteSettings =
{
  /**
   * If true, the texture atlas will behave as if it was exported as an SWF file.
   * Notably, this allows MovieClip symbols to play.
   */
  @:optional
  var swfMode:Bool;

  /**
   * If true, filters and masks will be cached when the atlas is loaded, instead of during runtime.
   */
  @:optional
  var cacheOnLoad:Bool;

  /**
   * The filter quality.
   * Available values are: HIGH, MEDIUM, LOW, and RUDY.
   *
   * If you're making an atlas sprite in HScript, you pass an Int instead:
   *
   * HIGH - 0
   * MEDIUM - 1
   * LOW - 2
   * RUDY - 3
   */
  @:optional
  var filterQuality:FilterQuality;

  /**
   * Optional, an array of spritemaps for the atlas to load.
   */
  @:optional
  var spritemaps:Array<SpritemapInput>;

  /**
   * Optional, string of the metadata.json contents.
   */
  @:optional
  var metadataJson:String;

  /**
   * Optional, force the cache to use a specific key to index the texture atlas.
   */
  @:optional
  var cacheKey:String;

  /**
   * If true, the texture atlas will use a new slot in the cache.
   */
  @:optional
  var uniqueInCache:Bool;

  /**
   * Optional callback for when a symbol is created.
   */
  @:optional
  var onSymbolCreate:animate.internal.SymbolItem->Void;

  /**
   * Whether to apply the stage matrix, if it was exported from a symbol instance.
   * Also positions the Texture Atlas as it displays in Animate.
   * Turning this on is only recommended if you prepositioned the character in Animate.
   * For other cases, it should be turned off to act similarly to a normal FlxSprite.
   */
  @:optional
  var applyStageMatrix:Bool;

  /**
   * Whether to apply the stage matrix of the Texture Atlas before or after FlxSprite calculations.
   * Changes the behaviour of a sprite in relation to the position, scale and rotation of the matrix.
   * When set to ``false`` the stage matrix will apply before other FlxSprite matrix calculations,
   * as if the symbol was contained inside of the sprite.
   * When set to ``true`` the stage matrix will apply after FlxSprite matrix calculations,
   * as if the sprite was contained inside of the symbol.
   */
  @:optional
  var postStageMatrixApply:Bool;

  /**
   * If enabled, the sprite will render as one texture instead of rendering multiple limbs.
   * This is useful for stuff like changing alpha, and shaders that require the whole sprite.
   * Only enable this if your sprite either:
   * - Changes alpha to something other than 1.0
   * - Has a shader or blend mode
   */
  @:optional
  var useRenderTexture:Bool;
}

/**
 * An FlxSprite with additional functionality.
 * - A more efficient method for creating solid color sprites.
 */
@:nullSafety
@:access(animate.FlxAnimateController)
@:access(polymod.Polymod)
class FunkinSprite extends FlxAnimate
{
  public var vcamPoint:Null<FlxPoint> = null;

  /**
   * The filters array to be applied to the sprite.
   */
  public var filters(default, set):Null<Array<BitmapFilter>> = null;

  override function set_clipRect(rect:FlxRect):FlxRect
  {
    if (!isAnimate) return super.set_clipRect(rect);

    if (rect != null) clipRect = rect.round();
    else
      @:nullSafety(Off)
      clipRect = null;

    return rect;
  }

  /**
   * Only used for mods that don't use the new asset system.
   */
  @:unreflective
  var __backwardsCompatibility:Bool = false;

  /**
   * @param x Starting X position
   * @param y Starting Y position
   * @param path The asset path for the graphic
   * @param atlasSettings The optional settings for the texture atlas
   */
  public function new(?x:Float = 0,
    ?y:Float = 0,
    ?path:String,
    ?atlasSettings:AtlasSpriteSettings)
  {
    super(x, y);

    filterRenderer = new FunkinFilterRenderer(this);

    if (path != null)
    {
      var ext:String = Path.extension(path);

      switch (ext)
      {
        case 'png':
          this.loadGraphic(path);

        case '':
          // Do the opposite of Paths.animateAtlas since that function is called in loadTextureAtlas.
          var lib:String = Paths.getLibrary(path);

          if (lib == 'preload')
          {
            path = path.replace('assets/images/', '');
          }
          else
          {
            path = path.replace('$lib:assets/$lib/images/', '');
          }

          this.loadTextureAtlas(path, atlasSettings);

        default:
          FlxG.log.warn('Texture path $path is not a valid path. Make sure the path points to either an image or a folder with the texture atlas files!');
      }
    }
  }

  override function initVars():Void
  {
    super.initVars();

    var newController:FunkinAnimationController = new FunkinAnimationController(this);

    animation = newController;
    anim = newController;
  }

  /**
   * Create a new FunkinSprite with a static texture.
   * @param x The starting X position.
   * @param y The starting Y position.
   * @param key The key of the texture to load.
   * @return The new FunkinSprite.
   */
  public static function create(x:Float = 0.0, y:Float = 0.0, key:String):FunkinSprite
  {
    var sprite:FunkinSprite = new FunkinSprite(x, y);
    sprite.loadTexture(key);
    return sprite;
  }

  /**
   * Create a new FunkinSprite with a Sparrow atlas animated texture.
   * @param x The starting X position.
   * @param y The starting Y position.
   * @param key The key of the texture to load.
   * @return The new FunkinSprite.
   */
  public static function createSparrow(x:Float = 0.0, y:Float = 0.0, key:String):FunkinSprite
  {
    var sprite:FunkinSprite = new FunkinSprite(x, y);
    sprite.loadSparrow(key);
    return sprite;
  }

  /**
   * Create a new FunkinSprite with a Packer atlas animated texture.
   * @param x The starting X position.
   * @param y The starting Y position.
   * @param key The key of the texture to load.
   * @return The new FunkinSprite.
   */
  public static function createPacker(x:Float = 0.0, y:Float = 0.0, key:String):FunkinSprite
  {
    var sprite:FunkinSprite = new FunkinSprite(x, y);
    sprite.loadPacker(key);
    return sprite;
  }

  /**
   * Create a new FunkinSprite with an Adobe Animate texture atlas.
   * @param x The starting X position.
   * @param y The starting Y position.
   * @param key The key of the texture to load.
   * @return The new FunkinSprite.
   */
  public static function createTextureAtlas(x:Float = 0.0, y:Float = 0.0, key:String, ?settings:AtlasSpriteSettings):FunkinSprite
  {
    var sprite:FunkinSprite = new FunkinSprite(x, y);
    sprite.loadTextureAtlas(key, settings);
    return sprite;
  }

  /**
   * Load a static image as the sprite's texture.
   * @param key The key of the texture to load.
   * @return This sprite, for chaining.
   */
  public function loadTexture(key:String):FunkinSprite
  {
    var graphicKey:AssetPath = Paths.image(key);

    if (!Assets.exists(graphicKey.toString(), IMAGE))
    {
      FlxG.log.error('Texture not found, check your path! $graphicKey');
      return this;
    }

    if (!funkin.assets.Assets.isFlxGraphicCached(graphicKey))
    {
      FlxG.log.warn('Texture not cached, may experience stuttering! $graphicKey');
    }

    loadGraphic(funkin.assets.Assets.getFlxGraphic(graphicKey));

    return this;
  }

  /**
   * Load a static image as the sprite's texture asynchronously.
   * If the texture is already cached, it will be loaded immediately.
   * Otherwise, the texture will stay invisible until loading finishes.
   *
   * @param assetPath The path of the texture to load.
   * @param fade If `true`, the sprite will fade in once the texture is loaded.
   * @return A `Future` that resolves when the texture is loaded.
   */
  public function loadTextureAsync(assetPath:funkin.assets.Paths.AssetPath,
    fade:Bool = false):lime.app.Future<FlxGraphic>
  {
    var fadeTween:Null<FlxTween> = null;
    if (fade)
    {
      fadeTween = FlxTween.tween(this, {
        alpha: 0
      }, 0.25);
    }

    trace('[ASYNC] Start loading image (${assetPath})');

    var future = funkin.assets.Assets.loadFlxGraphic(assetPath);

    future.onComplete((graphic:FlxGraphic) ->
    {
      trace('[ASYNC] Finished loading image');
      loadGraphic(graphic);

      if (fadeTween != null)
      {
        fadeTween.cancel();
        FlxTween.tween(this, {
          alpha: 1.0
        }, 0.25);
      }
    });
    future.onError((error:Dynamic) ->
    {
      trace('[ASYNC] Failed to load image: ${error}');
      if (fadeTween != null)
      {
        fadeTween.cancel();
        this.alpha = 1.0;
      }
    });
    future.onProgress((progress:Int, total:Int) ->
    {
      trace('[ASYNC] Loading image progress: ${progress}/${total}');
    });

    return future;
  }

  /**
   * Apply an OpenFL `BitmapData` to this sprite.
   * @param input The OpenFL `BitmapData` to apply
   * @return This sprite, for chaining
   */
  public function loadBitmapData(input:BitmapData, cache:Bool = true):FunkinSprite
  {
    if (cache)
    {
      loadGraphic(input);
    }
    else
    {
      var graphic:FlxGraphic = FlxGraphic.fromBitmapData(input, false, null, false);
      this.graphic = graphic;
      this.frames = this.graphic.imageFrame;
    }

    return this;
  }

  /**
   * Apply an OpenFL `TextureBase` to this sprite.
   * @param input The OpenFL `TextureBase` to apply
   * @return This sprite, for chaining
   */
  public function loadTextureBase(input:TextureBase):Null<FunkinSprite>
  {
    var inputBitmap:Null<BitmapData> = BitmapData.fromTexture(input);
    if (inputBitmap == null)
    {
      FlxG.log.warn('loadTextureBase - input resulted in null bitmap! $input');
      return null;
    }

    return loadBitmapData(inputBitmap);
  }

  /**
   * Loads an Adobe Animate texture atlas as the sprite's texture.
   *
   * @param key The key of the texture to load.
   * @param library DEPRECATED, DOES NOTHING: The library to load the texture atlas from.
   * @param settings Additional settings for loading the atlas.
   * @param modId You can load a texture atlas from a specific mod with this.
   * @return This sprite, for chaining.
   */
  public function loadTextureAtlas(key:Null<String>,
    ?library:String,
    settings:Null<AtlasSpriteSettings> = null,
    modId:String = ''):FunkinSprite
  {
    if (key == null)
    {
      throw 'Null path specified for loadTextureAtlas()!';
    }

    if (settings == null)
    {
      settings = getDefaultAtlasSettings();
    }

    this.applyStageMatrix = settings.applyStageMatrix ?? false;
    this.postStageMatrixApply = settings.postStageMatrixApply ?? false;
    this.useRenderTexture = settings.useRenderTexture ?? false;

    if (modId != '')
    {
      var spritemapCount:Int = 1;
      var spritemaps:Array<SpritemapInput> = [];
      var animationJson:Null<String> = Polymod.assetLibrary.getTextDirectly('assets/$key/Animation.json', modId);

      while (true)
      {
        var bitmap:Null<BitmapData> = Polymod.assetLibrary.getBitmapDataDirectly('assets/$key/spritemap$spritemapCount.png', modId);
        var json:Null<String> = Polymod.assetLibrary.getTextDirectly('assets/$key/spritemap$spritemapCount.json', modId);

        if (json == null || bitmap == null) break;

        // Null-safety kinda dumb #2
        var bNotNull:BitmapData = bitmap;
        var jNotNull:String = json;

        spritemaps.push({
          source: bNotNull,
          json: jNotNull
        });

        spritemapCount++;
      }

      if (animationJson == null)
      {
        throw 'Could not find Animation.json in path "$key" from mod "$modId"';
      }

      frames = FlxAnimateFrames.fromAnimate(animationJson, spritemaps, settings.metadataJson, settings.cacheKey, settings.uniqueInCache, {
        swfMode: settings.swfMode,
        cacheOnLoad: settings.cacheOnLoad,
        filterQuality: settings.filterQuality,
        onSymbolCreate: settings.onSymbolCreate
      });
    }
    else
    {
      frames = Paths.getAnimateAtlas(key, settings);
    }

    if (frames == null)
    {
      var msg:String = 'Could not load FlxAnimateFrames from path "$key"';

      if (modId != '')
      {
        msg += ' with mod "$modId".';
      }
      else
      {
        msg += '.';
      }

      throw msg;
    }

    __backwardsCompatibility = funkin.modding.compat.AnimateAtlas.needsBackwardsCompat(key);

    return this;
  }

  /**
   * Load an animated texture (Sparrow atlas spritesheet) as the sprite's texture.
   * @param key The key of the texture to load.
   * @param modId The mod ID to load the texture from.
   * @return This sprite, for chaining.
   */
  public function loadSparrow(key:String, modId:String = ''):FunkinSprite
  {
    var graphicKey:AssetPath = Paths.image(key);
    if (!funkin.assets.Assets.isFlxGraphicCached(graphicKey))
    {
      trace('Sparrow texture not cached, may experience stuttering! $graphicKey');
      FlxG.log.warn('Sparrow texture not cached, may experience stuttering! $graphicKey');
    }

    this.frames = Paths.getSparrowAtlas(key, null, modId);

    return this;
  }

  /**
   * Load an animated texture (Packer atlas spritesheet) as the sprite's texture.
   * @param key The key of the texture to load.
   * @return This sprite, for chaining.
   */
  public function loadPacker(key:String, modId:String = ''):FunkinSprite
  {
    var graphicKey:AssetPath = Paths.image(key);
    if (!funkin.assets.Assets.isFlxGraphicCached(graphicKey))
    {
      trace('Packer texture not cached, may experience stuttering! $graphicKey');
      FlxG.log.warn('Packer texture not cached, may experience stuttering! $graphicKey');
    }

    this.frames = Paths.getPackerAtlas(key, null, modId);

    return this;
  }

  /**
   * @param id The animation ID to check.
   * @return Whether the animation is dynamic (has multiple frames). `false` for static, one-frame animations.
   */
  public function isAnimationDynamic(id:String):Bool
  {
    var animData = null;
    if (this.animation == null) return false;
    animData = this.animation.getByName(id);
    if (animData == null) return false;
    return animData.numFrames > 1;
  }

  /**
   * Whether or not this sprite has an animation with the given ID.
   * @param id The ID of the animation to check.
   */
  public function hasAnimation(id:String):Bool
  {
    var animationList:Array<String> = this.animation?.getNameList() ?? [];
    if (animationList.contains(id))
    {
      return true;
    }
    else if (__backwardsCompatibility && this.anim.hasAnimateAtlas && !animationList.contains(id))
    {
      return addAnimationIfMissing(id);
    }

    return false;
  }

  /**
   * Adds an animation if it doesn't exist.
   * ONLY used for backwards compatibility.
   *
   * @param id The animation ID to check.
   */
  function addAnimationIfMissing(id:String):Bool
  {
    @:privateAccess
    var symbols:Array<String> = this.library.dictionary.keys().array();
    var frameLabels:Array<String> = listAnimations();

    if (frameLabels.contains(id))
    {
      // Animation exists as a frame label but wasn't added, so we add it
      anim.addByFrameLabel(id, id, this.library.frameRate, false);
      return true;
    }
    else if (symbols.contains(id))
    {
      // Animation exists as a symbol but wasn't added, so we add it
      anim.addBySymbol(id, id, this.library.frameRate, false);
      return true;
    }

    return false;
  }

  /**
   * Gets every frame on every symbol that starts with the given keyword.
   * @param keyword The keyword to search for.
   * @return An array of frames.
   */
  public function getFramesWithKeyword(keyword:String):Array<animate.internal.Frame>
  {
    if (!this.anim.hasAnimateAtlas)
    {
      trace('WARNING: getFramesWithKeyword() only works on texture atlases!');
      return [];
    }

    var symbolItems:Array<animate.internal.SymbolItem> = [];
    var frames:Array<animate.internal.Frame> = [];

    @:privateAccess
    for (symbol in this.library.dictionary.keys())
    {
      var symbolItem:Null<animate.internal.SymbolItem> = this.library.getSymbol(symbol);
      if (symbolItem == null) continue;

      if (symbolItem.name.contains(keyword))
      {
        symbolItems.push(symbolItem);
      }
    }

    for (symbolItem in symbolItems)
    {
      symbolItem.timeline.forEachLayer((layer) ->
      {
        layer.forEachFrame((frame) ->
        {
          frames.push(frame);
        });
      });
    }

    return frames;
  }

  /**
   * Gets the current animation ID.
   */
  public function getCurrentAnimation():String
  {
    return this.animation?.curAnim?.name ?? '';
  }

  /**
   * Whether or not the current animation is finished.
   */
  public function isAnimationFinished():Bool
  {
    return this.animation?.finished ?? false;
  }

  /**
   * Acts similarly to `makeGraphic`, but with improved memory usage,
   * at the expense of not being able to paint onto the resulting sprite.
   *
   * @param width The target width of the sprite.
   * @param height The target height of the sprite.
   * @param color The color to fill the sprite with.
   * @return This sprite, for chaining.
   */
  public function makeSolidColor(width:Int, height:Int, color:FlxColor = FlxColor.WHITE):FunkinSprite
  {
    // Create a tiny solid color graphic and scale it up to the desired size.
    var graphic:FlxGraphic = FlxG.bitmap.create(2, 2, color, false, 'solid#${color.toHexString(true, false)}');
    frames = graphic.imageFrame;
    scale.set(width / 2.0, height / 2.0);
    localScale.set(scale.x, scale.y);
    updateHitbox();

    return this;
  }

  /**
   * @return A list of all the animations this sprite has available.
   */
  public function listAnimations():Array<String>
  {
    var frameLabels:Array<String> = __backwardsCompatibility ? getFrameLabelList() : [];
    var animationList:Array<String> = this.animation?.getNameList() ?? [];

    return frameLabels.concat(animationList);
  }

  /**
   * Gets the length of an animation.
   * @param name The name of the animation.
   * @return The length of the animation.
   */
  public function getAnimationLength(name:String):Int
  {
    var animation:Null<flixel.animation.FlxAnimation> = this.animation.getByName(name);
    return animation?.numFrames ?? 0;
  }

  /**
   * TEXTURE ATLAS-EXCLUSIVE FUNCTIONS
   * These functions only work if the sprite's texture is an Adobe Animate texture atlas.
   * Calling these functions on non-texture atlases will do nothing.
   */
  /**
   * Gets a list of frame labels from the default timeline.
   */
  public function getFrameLabelList():Array<String>
  {
    if (!this.anim.hasAnimateAtlas)
    {
      trace('WARNING: getFrameLabelList() only works on texture atlases!');
      return [];
    }

    var foundLabels:Array<String> = [];
    var mainTimeline:Null<animate.internal.Timeline> = this.library.timeline;

    for (layer in mainTimeline.layers)
    {
      @:nullSafety(Off)
      for (frame in layer.frames)
      {
        if (frame.name.rtrim() != '')
        {
          foundLabels.push(frame.name);
        }
      }
    }

    return foundLabels;
  }

  /**
   * Gets a frame label by its name.
   * @param name The name of the frame label to retrieve.
   * @return The frame label, or null if it doesn't exist.
   */
  public function getFrameLabel(name:String,
    ?timeline:animate.internal.Timeline):Null<animate.internal.Frame>
  {
    if (!this.anim.hasAnimateAtlas)
    {
      trace('WARNING: getFrameLabel() only works on texture atlases!');
      return null;
    }

    for (layer in (timeline ?? this.timeline).layers)
    {
      @:nullSafety(Off)
      for (frame in layer.frames)
      {
        if (frame.name == name)
        {
          return frame;
        }
      }
    }

    return null;
  }

  /**
   * Returns the default symbol in the atlas.
   */
  public function getDefaultSymbol():String
  {
    if (!this.anim.hasAnimateAtlas)
    {
      trace('WARNING: getDefaultSymbol() only works on texture atlases!');
      return '';
    }

    return library.timeline.name;
  }

  /**
   * Replaces the graphic of a symbol in the atlas.
   * @param symbol The symbol to replace.
   * @param graphic The new graphic to use.
   * @param adjustScale Whether to adjust the scale of new frame to match the old one.
   */
  public function replaceSymbolGraphic(symbol:String,
    ?graphic:Null<FlxGraphicAsset>,
    ?adjustScale:Bool = true):Void
  {
    if (!this.anim.hasAnimateAtlas)
    {
      trace('WARNING: replaceSymbolGraphic() only works on texture atlases!');
      return;
    }

    var elements:Array<Element> = getSymbolElements(symbol);

    for (element in elements)
    {
      var atlasInstance:AtlasInstance = element.toAtlasInstance();
      var frame:Null<FlxFrame> = graphic != null ? FlxG.bitmap.add(graphic).imageFrame.frame : null;

      atlasInstance.replaceFrame(frame, adjustScale);
      element = atlasInstance;
    }
  }

  /**
   * Returns the first element of a symbol in the atlas.
   * @param symbol The symbol to get elements from.
   * @return The first element of the symbol. WARNING: Can be null.
   */
  public function getFirstElement(symbol:String):Null<Element>
  {
    if (!this.anim.hasAnimateAtlas)
    {
      trace('WARNING: getFirstElement() only works on texture atlases!');
      return null;
    }

    var symbolElements:Array<Element> = getSymbolElements(symbol);
    return symbolElements.length > 0 ? symbolElements[0] : null;
  }

  /**
   * Returns the elements of a symbol in the atlas.
   * @param symbol The symbol to get elements from.
   */
  public function getSymbolElements(symbol:String):Array<Element>
  {
    if (!this.anim.hasAnimateAtlas)
    {
      trace('WARNING: getSymbolElements() only works on texture atlases!');
      return [];
    }

    var symbolInstance:Null<SymbolItem> = this.library.getSymbol(symbol);

    if (symbolInstance == null)
    {
      throw 'Symbol not found in atlas: ${symbol}';
      return [];
    }

    var elements:Array<Element> = symbolInstance.timeline.getElementsAtIndex(0);

    if (elements?.length == 0)
    {
      trace('WARNING: No Atlas Elements found for "$symbol" symbol.');
    }

    return elements ?? [];
  }

  /**
   * Scales an element by a certain multiplier.
   * @param element The element to scale.
   * @param scale The scale multiplier.
   * @param positionOffset The offset to apply to `tx` and `ty` after scaling.
   * (Or in other words, the position of the element.)
   */
  public function scaleElement(element:Element, scale:Float, positionOffset:Float = 0, scaleEverything:Bool = false):Void
  {
    if (!this.anim.hasAnimateAtlas)
    {
      trace('WARNING: scaleElement() only works on texture atlases!');
      return;
    }

    var elementMatrix:FlxMatrix = element.matrix;

    if (scaleEverything)
    {
      elementMatrix.scale(scale, scale);
      return;
    }

    var symbolInstance:SymbolInstance = element.parentFrame.convertToSymbol(0, 1);
    var transformPoint:FlxPoint = symbolInstance.transformationPoint;

    elementMatrix.a *= scale;
    elementMatrix.d *= scale;

    elementMatrix.tx -= transformPoint.x * scale;
    elementMatrix.ty -= transformPoint.y * scale;

    elementMatrix.tx -= positionOffset;
    elementMatrix.ty -= positionOffset;
  }

  /**
   * Gets the default settings for a texture atlas sprite.
   * @return The default settings for a texture atlas sprite.
   */
  public function getDefaultAtlasSettings():AtlasSpriteSettings
  {
    return {
      swfMode: false,
      cacheOnLoad: false,
      filterQuality: MEDIUM,
      spritemaps: null,
      metadataJson: null,
      cacheKey: null,
      uniqueInCache: false,
      onSymbolCreate: null,
      applyStageMatrix: false,
      useRenderTexture: false
    };
  }

  /**
   * Gets the screen position of the sprite, taking into account the camera scroll and the `vcamPoint` if it exists.
   * @param result An optional `FlxPoint` to store the result in. If null, a new `FlxPoint` will be created.
   * @param camera The camera to calculate the screen position relative to. If null, the default camera will be used.
   * @return The screen position of the sprite.
   */
  override function getScreenPosition(?result:FlxPoint, ?camera:FlxCamera):FlxPoint
  {
    if (result == null) result = FlxPoint.get();
    if (camera == null) camera = getDefaultCamera();
    result.set(x, y);
    if (pixelPerfectPosition) result.floor();

    if (vcamPoint != null) return result.subtract((vcamPoint.x * scrollFactor.x) + camera.scroll.x, (vcamPoint.y * scrollFactor.y) + camera.scroll.y);

    return result.subtract(camera.scroll.x * scrollFactor.x, camera.scroll.y * scrollFactor.y);
  }

  /**
   * Ensure scale is applied when cloning a sprite.
   * The default `clone()` method acts kinda weird TBH.
   * @return A clone of this sprite.
   */
  override public function clone():FunkinSprite
  {
    var result = new FunkinSprite(this.x, this.y);
    result.frames = this.frames;
    result.scale.set(this.scale.x, this.scale.y);
    result.localScale.set(this.localScale.x, this.localScale.y);
    result.updateHitbox();

    return result;
  }

  @:access(flixel.FlxCamera)
  override function getBoundingBox(camera:FlxCamera):FlxRect
  {
    getScreenPosition(_point, camera);

    _rect.set(_point.x, _point.y, width, height);
    _rect = camera.transformRect(_rect);

    if (isPixelPerfectRender(camera))
    {
      _rect.width = _rect.width / this.scale.x;
      _rect.height = _rect.height / this.scale.y;
      _rect.x = _rect.x / this.scale.x;
      _rect.y = _rect.y / this.scale.y;
      _rect.floor();
      _rect.x = _rect.x * this.scale.x;
      _rect.y = _rect.y * this.scale.y;
      _rect.width = _rect.width * this.scale.x;
      _rect.height = _rect.height * this.scale.y;
    }

    return _rect;
  }

  override function preparePixelPerfectMatrix(matrix:FlxMatrix)
  {
    matrix.tx = Math.round(matrix.tx / this.scale.x) * this.scale.x;
    matrix.ty = Math.round(matrix.ty / this.scale.y) * this.scale.y;
  }

  var filterRenderer:FunkinFilterRenderer;
  var filtered:Bool = false;
  var filterOffsets:Array<Float> = [0, 0];

  override function checkRenderTexture():Bool
  {
    // Forcefully enable render texture when we have filters.
    if (filters != null && filters.length > 0) return true;

    if (this.isAnimate && this.clipRect != null) return true;

    return super.checkRenderTexture();
  }

  override function set_frames(value:flixel.graphics.frames.FlxFramesCollection):flixel.graphics.frames.FlxFramesCollection
  {
    return super.set_frames(value);
  }

  override function set_graphic(value:FlxGraphic):FlxGraphic
  {
    if (value == null) return super.set_graphic(value);

    if (value.bitmap == null)
    {
      FlxG.log.warn('FunkinSprite is using disposed FlxGraphic "${value.key}"! Expect graphical glitches!');
      trace(' WARN '.warning() + 'FunkinSprite is using disposed FlxGraphic "${value.key}"! Expect graphical glitches!');
    }

    return super.set_graphic(value);
  }

  function set_filters(value:Null<Array<BitmapFilter>>):Null<Array<BitmapFilter>>
  {
    if (filters != value) _renderTextureDirty = true;
    filters = value;
    return value;
  }

  override public function draw():Void
  {
    for (filter in filters ?? [])
    {
      @:privateAccess
      if (filter.__renderDirty) _renderTextureDirty = true;
    }

    super.draw();
  }

  override function drawFrameComplex(frame:FlxFrame, camera:FlxCamera):Void
  {
    final willUseRenderTexture = checkRenderTexture();
    final matrix = this._matrix;

    frame.prepareMatrix(matrix, FlxFrameAngle.ANGLE_0, checkFlipX(), checkFlipY());
    prepareDrawMatrix(matrix, camera);

    if (willUseRenderTexture)
    {
      var bounds:Array<Int> = [Math.ceil(frame.frame.width), Math.ceil(frame.frame.height)];
      if (_renderTexture == null) _renderTexture = new FunkinRenderTexture(bounds[0], bounds[1], this);

      if (_renderTextureDirty)
      {
        _renderTexture.init(bounds[0], bounds[1]);
        _renderTexture.drawToCamera((camera, mat) ->
        {
          camera.drawPixels(frame, framePixels, mat, null, null, antialiasing, null);
        });

        _renderTexture.render();

        filterRenderer.applyFilters();
        _renderTextureDirty = false;
      }

      if (filtered)
      {
        matrix.translate(filterOffsets[0], filterOffsets[1]);
        camera.drawPixels(filterRenderer.graphic?.imageFrame.frame, null, matrix, colorTransform, blend, antialiasing, shader);
      }
      else
      {
        camera.drawPixels(_renderTexture.graphic.imageFrame.frame, framePixels, matrix, colorTransform, blend, antialiasing, shader);
      }
    }
    else
    {
      camera.drawPixels(frame, framePixels, matrix, colorTransform, blend, antialiasing, shader);
    }
  }

  override function drawAnimate(camera:FlxCamera):Void
  {
    final willUseRenderTexture = checkRenderTexture();
    final matrix = _matrix;
    matrix.identity();

    @:privateAccess
    var bounds = timeline._bounds;
    if (!willUseRenderTexture) matrix.translate(-bounds.x, -bounds.y);

    prepareAnimateMatrix(matrix, camera, bounds);

    if (renderStage) drawStage(camera);

    timeline.currentFrame = animation.frameIndex;

    #if !flash
    if (willUseRenderTexture)
    {
      if (_renderTexture == null)
      {
        _renderTexture = new FunkinRenderTexture(Math.ceil(bounds.width), Math.ceil(bounds.height), this);
      }

      if (_renderTextureDirty)
      {
        _renderTexture.init(Math.ceil(bounds.width), Math.ceil(bounds.height));
        _renderTexture.drawToCamera((camera, matrix) ->
        {
          matrix.translate(-bounds.x, -bounds.y);
          timeline.draw(camera, matrix, null, null, antialiasing, null);
        });
        _renderTexture.render();

        filterRenderer.applyFilters();
        _renderTextureDirty = false;
      }

      if (filtered)
      {
        matrix.translate(filterOffsets[0], filterOffsets[1]);
        camera.drawPixels(filterRenderer.graphic?.imageFrame.frame, null, matrix, colorTransform, blend, antialiasing, shader);
      }
      else
      {
        camera.drawPixels(_renderTexture.graphic.imageFrame.frame, framePixels, matrix, colorTransform, blend, antialiasing, shader);
      }
    }
    else
    #end
    {
      timeline.draw(camera, matrix, colorTransform, blend, antialiasing, shader);
    }
  }

  override public function destroy():Void
  {
    // @:nullSafety(Off)
    // frames = null;
    // ^ Might be useful but its like a micro enhancement in terms of optimization. Keeping it regardless -Moon
    super.destroy();

    filterRenderer.destroy();
    // Cancel all tweens so they don't continue to run on a destroyed sprite.
    // This prevents crashes.
    FlxTween.cancelTweensOf(this);
    super.destroy();
  }
}
