package funkin.ui.haxeui;

import flixel.FlxCamera;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxMatrix;
import haxe.ui.backend.flixel.IComponentRenderCache;
import haxe.ui.core.Component;
import haxe.ui.focus.FocusManager;
import openfl.Lib;
import openfl.display.BitmapData;
import openfl.display.OpenGLRenderer;
import openfl.geom.ColorTransform;
import openfl.geom.Matrix;

/**
 * Create one texture for a component and its children, and draw that texture every frame instead of the whole ass render stack.
 */
@:access(flixel.FlxBasic)
@:access(flixel.FlxCamera)
@:access(openfl.display.BitmapData)
@:access(openfl.display.DisplayObject)
@:access(openfl.display.OpenGLRenderer)
@:access(openfl.display3D.Context3D)
@:access(openfl.display3D.textures.TextureBase)
@:access(openfl.geom.ColorTransform)
@:access(haxe.ui.backend.ComponentImpl)
class ComponentRenderCache implements IComponentRenderCache
{
  /**
   * Extra room around the component, for borders and shadows drawn past its edges.
   */
  static final PADDING:Int = 16;

  static final MAX_SIZE:Int = 4096;

  var renderer:Null<OpenGLRenderer> = null;
  var camera:Null<FlxCamera> = null;
  var bitmap:Null<BitmapData> = null;
  var graphic:Null<FlxGraphic> = null;
  var matrix:FlxMatrix = new FlxMatrix();

  var stale:Bool = true;

  var lastScaleX:Float = 0;
  var lastScaleY:Float = 0;
  var lastWidth:Float = 0;
  var lastHeight:Float = 0;

  public function new() {}

  public function drawCached(component:Component):Bool
  {
    var changed:Bool = component.renderCacheDirty;
    component.renderCacheDirty = false;

    // A focused component can change its appearance without changing its size or position.
    if (!changed && hasFocusInside(component)) changed = true;

    if (component.componentWidth == null || component.componentHeight == null) return false;
    var width:Float = component.componentWidth * haxe.ui.Toolkit.scaleX;
    var height:Float = component.componentHeight * haxe.ui.Toolkit.scaleY;
    var scaleX:Float = FlxG.scaleMode.scale.x;
    var scaleY:Float = FlxG.scaleMode.scale.y;
    if (width != lastWidth || height != lastHeight || scaleX != lastScaleX || scaleY != lastScaleY)
    {
      changed = true;
      lastWidth = width;
      lastHeight = height;
      lastScaleX = scaleX;
      lastScaleY = scaleY;
    }

    // While things keep changing, drawing normally is cheaper than rendering the texture every frame.
    if (changed)
    {
      stale = true;
      return false;
    }

    var originX:Float = Math.floor(component.cachedScreenX) - PADDING;
    var originY:Float = Math.floor(component.cachedScreenY) - PADDING;

    if (stale)
    {
      var texWidth:Int = Std.int(Math.min(MAX_SIZE, Math.ceil((width + PADDING * 2) * scaleX)));
      var texHeight:Int = Std.int(Math.min(MAX_SIZE, Math.ceil((height + PADDING * 2) * scaleY)));
      if (texWidth <= 0 || texHeight <= 0) return false;
      render(component, originX, originY, scaleX, scaleY, texWidth, texHeight);
      stale = false;
    }

    var g:Null<FlxGraphic> = graphic;
    if (g == null) return false;

    matrix.identity();
    matrix.scale(1 / scaleX, 1 / scaleY);
    matrix.translate(originX, originY);
    var smooth:Bool = scaleX != 1 || scaleY != 1;
    for (target in component.cameras)
    {
      if (!target.visible || !target.exists) continue;
      target.drawPixels(g.imageFrame.frame, g.bitmap, matrix, null, null, smooth);
    }
    return true;
  }

  static function hasFocusInside(component:Component):Bool
  {
    var focus:Null<Component> = cast FocusManager.instance.focus;
    while (focus != null)
    {
      if (focus == component) return true;
      focus = focus.parentComponent;
    }
    return false;
  }

  function render(component:Component, originX:Float, originY:Float, scaleX:Float, scaleY:Float, texWidth:Int, texHeight:Int):Void
  {
    prepareTexture(texWidth, texHeight);
    var target:Null<BitmapData> = bitmap;
    if (target == null) return;

    var cam:FlxCamera = camera ?? (camera = new FlxCamera(0, 0, FlxG.width, FlxG.height, 1));
    if (cam.width != FlxG.width || cam.height != FlxG.height) cam.setSize(FlxG.width, FlxG.height);
    cam.clearDrawStack();
    cam.canvas.graphics.clear();

    // Send the whole tree's draws to our camera instead of the screen.
    var savedCameras:Null<Array<FlxCamera>> = component._cameras;
    component.cameras = [cam];
    component.drawUncached();
    component.cameras = savedCameras;

    cam.render();
    cam.canvas.__update(false, true);

    var r:OpenGLRenderer = renderer ?? (renderer = createRenderer());
    r.__cleanup();
    r.setShader(r.__defaultShader);
    r.__allowSmoothing = true;
    r.__pixelRatio = #if openfl_disable_hdpi 1 #else Lib.current.stage.window.scale #end;
    r.__worldAlpha = 1 / cam.canvas.__worldAlpha;

    // Undo the camera's own transform, then move the component's corner to the texture's corner at screen resolution.
    r.__worldTransform.copyFrom(cam.canvas.__renderTransform);
    r.__worldTransform.invert();
    r.__worldTransform.translate(-originX, -originY);
    r.__worldTransform.scale(scaleX, scaleY);
    r.__worldColorTransform.__copyFrom(cam.canvas.__worldColorTransform);
    r.__worldColorTransform.__invert();
    r.__setRenderTarget(target);

    var context = r.__context3D;
    var cacheRTT = context.__state.renderToTexture;
    var cacheRTTDepthStencil = context.__state.renderToTextureDepthStencil;
    var cacheRTTAntiAlias = context.__state.renderToTextureAntiAlias;
    var cacheRTTSurfaceSelector = context.__state.renderToTextureSurfaceSelector;

    context.setRenderToTexture(target.getTexture(context), true);
    context.clear(0, 0, 0, 0);
    r.__render(cam.canvas);

    if (cacheRTT != null)
    {
      context.setRenderToTexture(cacheRTT, cacheRTTDepthStencil, cacheRTTAntiAlias, cacheRTTSurfaceSelector);
    }
    else
    {
      context.setRenderToBackBuffer();
    }

    cam.clearDrawStack();
    cam.canvas.graphics.clear();
  }

  static function createRenderer():OpenGLRenderer
  {
    var r:OpenGLRenderer = new OpenGLRenderer(FlxG.stage.context3D);
    r.__worldTransform = new Matrix();
    r.__worldColorTransform = new ColorTransform();
    return r;
  }

  function prepareTexture(width:Int, height:Int):Void
  {
    var current:Null<BitmapData> = bitmap;
    if (current != null && current.width == width && current.height == height) return;
    disposeTexture();
    var created:BitmapData = BitmapData.fromTexture(FlxG.stage.context3D.createRectangleTexture(width, height, BGRA, true));
    bitmap = created;
    graphic = FlxGraphic.fromBitmapData(created, false, null, false);
  }

  function disposeTexture():Void
  {
    var g:Null<FlxGraphic> = graphic;
    graphic = null;
    var b:Null<BitmapData> = bitmap;
    bitmap = null;
    if (b != null)
    {
      if (b.__texture != null) b.__texture.dispose();
      b.dispose();
    }
    if (g != null) g.destroy();
  }

  public function destroy():Void
  {
    disposeTexture();
    renderer?.__cleanup();
    renderer = null;
    camera?.destroy();
    camera = null;
  }
}
