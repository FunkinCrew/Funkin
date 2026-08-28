package funkin.graphics;

import haxe.io.Bytes;
import lime.graphics.AnimationDecoder;
import lime.graphics.AnimationDecoderFrame;
import lime.graphics.AnimationDecoderType;
import lime.system.ThreadPool;
import lime.system.WorkOutput;
import openfl.Lib;
import openfl.display.BitmapData;
import openfl.display3D.textures.Texture;

@:access(openfl.display3D.textures.TextureBase)
@:access(openfl.display3D.Context3D)
@:access(openfl.display.BitmapData)
class FunkinAnimationDecoder
{
  static var localThreadPool:ThreadPool;

  var frameTimer:Float = 0.0;
  var currentFrameIndex:Int = 0;
  var decoder:AnimationDecoder;
  var decodedFrames:Array<AnimationDecoderFrame> = [];

  public var bitmapData:BitmapData;

  public function new(bytes:Bytes, type:AnimationDecoderType):Void
  {
    if (bytes != null && bytes.length > 0)
    {
      decoder = AnimationDecoder.fromBytes(bytes, type);

      if (decoder != null)
      {
        decodedFrames = [];
        currentFrameIndex = 0;
        frameTimer = 0.0;

        if (decoder.getStatus() == OK)
        {
          onFrameDecoded(decoder.getFrame());
        }

        if (localThreadPool == null)
        {
          localThreadPool = new ThreadPool(0, 2);
          localThreadPool.onProgress.add(localThreadPool_onProgress);
        }

        localThreadPool.run(localThreadPool_doWork, {
          instance: this
        });
      }
    }
  }

  public function update(elapsed:Float):Void
  {
    if (decodedFrames.length <= 1)
    {
      return;
    }

    frameTimer += elapsed;

    var currentFrame:AnimationDecoderFrame = decodedFrames[currentFrameIndex];

    if (currentFrame == null)
    {
      return;
    }

    var duration:Float = (currentFrame.duration <= 0 ? 100.0 : cast currentFrame.duration) / 1000.0;

    while (frameTimer >= duration)
    {
      frameTimer -= duration;

      if (decodedFrames.length == 0)
      {
        return;
      }

      currentFrameIndex = (currentFrameIndex + 1) % decodedFrames.length;

      currentFrame = decodedFrames[currentFrameIndex];

      if (currentFrame == null)
      {
        break;
      }

      duration = (currentFrame.duration <= 0 ? 100.0 : cast currentFrame.duration) / 1000.0;
    }

    if (currentFrame != null)
    {
      ensureBitmapData(currentFrame);
      uploadFrameTexture(currentFrame);
    }
  }

  public function destroy():Void
  {
    decoder = null;
    decodedFrames = [];
    currentFrameIndex = 0;
    frameTimer = 0.0;

    if (bitmapData != null)
    {
      bitmapData.dispose();
      bitmapData = null;
    }
  }

  function ensureBitmapData(frame:AnimationDecoderFrame):Void
  {
    if (frame == null || frame.buffer == null) return;

    if (Lib.current.stage == null || Lib.current.stage.context3D == null) return;

    final w:Int = frame.buffer.width;
    final h:Int = frame.buffer.height;

    if (bitmapData != null && bitmapData.width == w && bitmapData.height == h) return;

    if (bitmapData != null) bitmapData.dispose();

    bitmapData = BitmapData.fromTexture(Lib.current.stage.context3D.createTexture(w, h, RGBA, true), false);
  }

  function uploadFrameTexture(frame:AnimationDecoderFrame):Void
  {
    if (bitmapData?.__texture == null || frame?.buffer?.data == null) return;

    cast(bitmapData.__texture, Texture).uploadFromTypedArray(frame.buffer.data);
  }

  function onFrameDecoded(frame:AnimationDecoderFrame):Void
  {
    if (decoder == null || frame == null) return;

    decodedFrames.push(frame);

    if (decodedFrames.length == 1)
    {
      ensureBitmapData(frame);
      uploadFrameTexture(frame);
    }
  }

  static function localThreadPool_doWork(state:Dynamic, output:WorkOutput):Void
  {
    final instance:FunkinAnimationDecoder = state.instance;

    if (instance != null && instance.decoder != null)
    {
      while (instance.decoder != null && instance.decoder.getStatus() == OK)
      {
        final frame:AnimationDecoderFrame = instance.decoder.getFrame();

        if (frame != null && instance.decoder != null)
        {
          output.sendProgress({
            instance: instance,
            frame: frame
          });
        }
        else
        {
          break;
        }
      }
    }

    output.sendComplete({
      instance: instance
    });
  }

  static function localThreadPool_onProgress(state:Dynamic):Void
  {
    final instance:FunkinAnimationDecoder = state.instance;

    final frame:AnimationDecoderFrame = state.frame;

    if (instance != null && instance.decoder != null && frame != null) instance.onFrameDecoded(frame);
  }
}
