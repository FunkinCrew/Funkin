package vlc.bitmap;

#if cpp
import cpp.NativeArray;
import cpp.UInt8;
#end
import flixel.FlxG;
import openfl.Lib;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display3D.textures.RectangleTexture;
import openfl.errors.Error;
import openfl.events.Event;
import openfl.geom.Rectangle;
import vlc.lib.LibVLC;

/**
 * ...
 * @author Tommy S
 */
@:cppFileCode('#include "LibVLC.cpp"')
class VlcBitmap extends Bitmap
{
	/////////////////////////////////////////////////////////////////////////////////////
	// ===================================================================================
	// Consts
	//-----------------------------------------------------------------------------------
	// ===================================================================================
	// Properties
	//-----------------------------------------------------------------------------------
	public var videoWidth:Int;
	public var videoHeight:Int;
	public var repeat:Int = 0;
	public var duration:Float;
	public var length:Float;
	public var initComplete:Bool;
	public var volume(default, set):Float = 1;

	public var isDisposed:Bool;
	public var isPlaying:Bool;
	public var disposeOnStop:Bool = false;
	public var time:Int;

	public var onVideoReady:Void->Void;
	public var onPlay:Void->Void;
	public var onStop:Void->Void;
	public var onPause:Void->Void;
	public var onResume:Void->Void;
	public var onSeek:Void->Void;
	public var onBuffer:Void->Void;
	public var onProgress:Void->Void;
	public var onOpening:Void->Void;
	public var onComplete:Void->Void;
	public var onError:Void->Void;

	// ===================================================================================
	// Declarations
	//-----------------------------------------------------------------------------------
	#if cpp
	var bufferMem:Array<UInt8>;
	#end

	var libvlc:LibVLC;

	// ===================================================================================
	// Variables
	//-----------------------------------------------------------------------------------
	var frameSize:Int;
	var oldTime:Int;
	var _width:Null<Float>;
	var _height:Null<Float>;
	var texture:RectangleTexture;
	var frameRect:Rectangle;

	/////////////////////////////////////////////////////////////////////////////////////

	public function new(width:Float = 320, height:Float = 240, ?autoScale:Bool = true)
	{
		super(null, null, true);

		if (autoScale)
		{
			this.width = getVideoWidth();
			this.height = getVideoHeight();
		}
		else
		{
			this.width = width;
			this.height = height;
		}

		init();
	}

	function mThread()
	{
		init();
	}

	/////////////////////////////////////////////////////////////////////////////////////

	function init()
	{
		addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
	}

	function onAddedToStage(e:Event):Void
	{
		removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);

		libvlc = LibVLC.create();
		stage.addEventListener(Event.RESIZE, onResize);
		stage.addEventListener(Event.ENTER_FRAME, vLoop);
	}

	function onResize(e:Event)
	{
		width = getVideoWidth();
		height = getVideoHeight();
	}

	function getVideoWidth():Float
	{
		if (FlxG.stage.stageHeight / 9 < FlxG.stage.stageWidth / 16)
		{
			#if HXC_DEBUG_TRACE
			trace(FlxG.stage.stageHeight * (16 / 9));
			#end

			return FlxG.stage.stageHeight * (16 / 9);
		}
		else
		{
			#if HXC_DEBUG_TRACE
			trace(FlxG.stage.stageWidth);
			#end

			return FlxG.stage.stageWidth;
		}
	}

	function getVideoHeight():Float
	{
		if (FlxG.stage.stageHeight / 9 < FlxG.stage.stageWidth / 16)
		{
			#if HXC_DEBUG_TRACE
			trace(FlxG.stage.stageHeight);
			#end

			return FlxG.stage.stageHeight;
		}
		else
		{
			#if HXC_DEBUG_TRACE
			trace(FlxG.stage.stageWidth / (16 / 9));
			#end

			return FlxG.stage.stageWidth / (16 / 9);
		}
	}

	/////////////////////////////////////////////////////////////////////////////////////

	public function play(?source:String)
	{
		libvlc.setRepeat(repeat);

		if (source != null)
			libvlc.play(source);
		else
			libvlc.play();

		#if HXC_DEBUG_TRACE
		trace("the video is playing");
		#end

		if (onPlay != null)
			onPlay();
	}

	public function stop()
	{
		isPlaying = false;
		libvlc.stop();

		#if HXC_DEBUG_TRACE
		trace("the video is stopping");
		#end

		if (onStop != null)
			onStop();
	}

	public function pause()
	{
		isPlaying = false;
		libvlc.pause();

		#if HXC_DEBUG_TRACE
		trace("the video is pausing");
		#end

		if (onPause != null)
			onPause();
	}

	public function resume()
	{
		isPlaying = true;
		libvlc.resume();

		#if HXC_DEBUG_TRACE
		trace("the video is resuming");
		#end

		if (onResume != null)
			onResume();
	}

	public function seek(seekTotime:Float)
	{
		libvlc.setPosition(seekTotime);

		#if HXC_DEBUG_TRACE
		trace("new position: " + seekTotime);
		#end

		if (onSeek != null)
			onSeek();
	}

	public function getFPS():Float
	{
		if (libvlc != null && initComplete)
		{
			#if HXC_DEBUG_TRACE
			trace(libvlc.getFPS());
			#end

			return libvlc.getFPS();
		}
		else
			return 0;
	}

	public function setTime(time:Int)
	{
		#if HXC_DEBUG_TRACE
		trace("the new time is: " + time);
		#end

		libvlc.setTime(time);
	}

	public function getTime():Int
	{
		if (libvlc != null && initComplete)
		{
			#if HXC_DEBUG_TRACE
			trace(libvlc.getTime());
			#end

			return libvlc.getTime();
		}
		else
			return 0;
	}

	/////////////////////////////////////////////////////////////////////////////////////

	function checkFlags()
	{
		if (!isDisposed)
		{
			if (untyped __cpp__('libvlc->flags[1]') == 1)
			{
				untyped __cpp__('libvlc->flags[1]=-1');
				statusOnPlaying();
			}
			if (untyped __cpp__('libvlc->flags[2]') == 1)
			{
				untyped __cpp__('libvlc->flags[2]=-1');
				statusOnPaused();
			}
			if (untyped __cpp__('libvlc->flags[3]') == 1)
			{
				untyped __cpp__('libvlc->flags[3]=-1');
				statusOnStopped();
			}
			if (untyped __cpp__('libvlc->flags[4]') == 1)
			{
				untyped __cpp__('libvlc->flags[4]=-1');
				statusOnEndReached();
			}
			if (untyped __cpp__('libvlc->flags[5]') != -1)
			{
				statusOnTimeChanged(untyped __cpp__('libvlc->flags[5]'));
			}
			if (untyped __cpp__('libvlc->flags[6]') != -1)
			{
				statusOnPositionChanged(untyped __cpp__('libvlc->flags[9]'));
			}
			if (untyped __cpp__('libvlc->flags[9]') == 1)
			{
				untyped __cpp__('libvlc->flags[9]=-1');
				statusOnError();
			}
			if (untyped __cpp__('libvlc->flags[10]') == 1)
			{
				untyped __cpp__('libvlc->flags[10]=-1');
				statusOnSeekableChanged(0);
			}
			if (untyped __cpp__('libvlc->flags[11]') == 1)
			{
				untyped __cpp__('libvlc->flags[11]=-1');
				statusOnOpening();
			}
			if (untyped __cpp__('libvlc->flags[12]') == 1)
			{
				untyped __cpp__('libvlc->flags[12]=-1');
				statusOnBuffering();
			}
			if (untyped __cpp__('libvlc->flags[13]') == 1)
			{
				untyped __cpp__('libvlc->flags[13]=-1');
				statusOnForward();
			}
			if (untyped __cpp__('libvlc->flags[14]') == 1)
			{
				untyped __cpp__('libvlc->flags[14]=-1');
				statusOnBackward();
			}
		}
	}

	/////////////////////////////////////////////////////////////////////////////////////

	function videoInitComplete()
	{
		#if HXC_DEBUG_TRACE
		trace("the video is starting");
		#end

		videoWidth = libvlc.getWidth();
		videoHeight = libvlc.getHeight();

		duration = libvlc.getDuration();
		length = libvlc.getLength();

		if (bitmapData != null)
			bitmapData.dispose();

		if (texture != null)
			texture.dispose();

		// BitmapData
		bitmapData = new BitmapData(Std.int(videoWidth), Std.int(videoHeight), true, 0);
		frameRect = new Rectangle(0, 0, Std.int(videoWidth), Std.int(videoHeight));

		smoothing = true;

		if (_width != null)
			width = _width;
		else
			width = videoWidth;

		if (_height != null)
			height = _height;
		else
			height = videoHeight;

		#if cpp
		bufferMem = [];
		#end
		frameSize = videoWidth * videoHeight * 4;

		setVolume(volume);

		initComplete = true;

		if (onVideoReady != null)
			onVideoReady();
	}

	/////////////////////////////////////////////////////////////////////////////////////

	function vLoop(e)
	{
		checkFlags();
		render();
	}

	/////////////////////////////////////////////////////////////////////////////////////

	function render()
	{
		var cTime = Lib.getTimer();

		if ((cTime - oldTime) > 8.3) // min 8.3 ms between renders, but this is not a good way to do it...
		{
			oldTime = cTime;

			if (isPlaying)
			{
				try
				{
					#if cpp
					#if HXC_DEBUG_TRACE
					trace("rendering...");
					#end

					NativeArray.setUnmanagedData(bufferMem, libvlc.getPixelData(), frameSize);
					if (bufferMem != null)
					{
						// BitmapData
						// libvlc.getPixelData() sometimes is null and the exe hangs ...
						if (libvlc.getPixelData() != null)
							bitmapData.setPixels(frameRect, haxe.io.Bytes.ofData(bufferMem));
					}
					#end
				}
				catch (e:Error)
				{
					trace("error: " + e);
					throw new Error("render broke xd");
				}
			}
		}
	}

	/////////////////////////////////////////////////////////////////////////////////////

	function setVolume(vol:Float)
	{
		if (libvlc != null && initComplete)
		{
			#if HXC_DEBUG_TRACE
			trace("new volume: " + vol * 100);
			#end

			libvlc.setVolume(vol * 100);
		}
	}

	public function getVolume():Float
	{
		if (libvlc != null && initComplete)
		{
			#if HXC_DEBUG_TRACE
			trace("the volume is: " + libvlc.getVolume());
			#end

			return libvlc.getVolume();
		}
		else
			return 0;
	}

	/////////////////////////////////////////////////////////////////////////////////////

	function statusOnOpening()
	{
		#if HXC_DEBUG_TRACE
		trace("the video is open");
		#end

		if (onOpening != null)
			onOpening();
	}

	function statusOnBuffering()
	{
		#if HXC_DEBUG_TRACE
		trace("buffering");
		#end

		if (onBuffer != null)
			onBuffer();
	}

	function statusOnPlaying()
	{
		if (!initComplete)
		{
			isPlaying = true;
			initComplete = true;
			videoInitComplete();
		}
	}

	function statusOnPaused()
	{
		if (isPlaying)
			isPlaying = false;

		#if HXC_DEBUG_TRACE
		trace("the video is paused");
		#end

		if (onPause != null)
			onPause();
	}

	function statusOnStopped()
	{
		if (isPlaying)
			isPlaying = false;

		#if HXC_DEBUG_TRACE
		trace("the video stopped");
		#end

		if (onStop != null)
			onStop();
	}

	function statusOnEndReached()
	{
		if (isPlaying)
			isPlaying = false;

		#if HXC_DEBUG_TRACE
		trace("end reached!");
		#end

		if (onComplete != null)
			onComplete();
	}

	function statusOnTimeChanged(newTime:Int)
	{
		time = newTime;

		#if HXC_DEBUG_TRACE
		trace("new Time: " + newTime);
		#end

		if (onProgress != null)
			onProgress();
	}

	function statusOnPositionChanged(newPos:Int){
		#if HXC_DEBUG_TRACE
		trace("new Pos: " + newPos);
		#end
	}

	function statusOnSeekableChanged(newPos:Int)
	{
		#if HXC_DEBUG_TRACE
		trace("new Seeked Pos: " + newPos);
		#end

		if (onSeek != null)
			onSeek();
	}

	function statusOnForward(){}

	function statusOnBackward(){}

	function onDisplay(){}

	function statusOnError()
	{
		#if debug
		trace("VLC ERROR - File not found?");
		#end

		if (onError != null)
			onError();
	}

	/////////////////////////////////////////////////////////////////////////////////////

	private override function get_width():Float
	{
		#if HXC_DEBUG_TRACE
		trace(_width);
		#end

		return _width;
	}

	public override function set_width(value:Float):Float
	{
		_width = value;

		#if HXC_DEBUG_TRACE
		trace("new width is " + value);
		#end

		return super.set_width(value);
	}

	private override function get_height():Float
	{
		#if HXC_DEBUG_TRACE
		trace(_height);
		#end

		return _height;
	}

	public override function set_height(value:Float):Float
	{
		_height = value;

		#if HXC_DEBUG_TRACE
		trace("new height is " + value);
		#end

		return super.set_height(value);
	}

	function get_volume():Float
	{
		#if HXC_DEBUG_TRACE
		trace("the volume is " + volume);
		#end

		return volume;
	}

	function set_volume(value:Float):Float
	{
		#if HXC_DEBUG_TRACE
		trace("the new volume is " + value);
		#end

		setVolume(value);
		return volume = value;
	}

	// ===================================================================================
	// Dispose
	//-----------------------------------------------------------------------------------

	public function dispose()
	{
		#if HXC_DEBUG_TRACE
		trace("disposing the whole thing lol");
		#end

		libvlc.stop();

		stage.removeEventListener(Event.ENTER_FRAME, vLoop);
		stage.removeEventListener(Event.RESIZE, onResize);

		if (texture != null)
		{
			texture.dispose();
			texture = null;
		}
		onVideoReady = null;
		onComplete = null;
		onPause = null;
		onPlay = null;
		onResume = null;
		onSeek = null;
		onStop = null;
		onBuffer = null;
		onProgress = null;
		onError = null;
		#if cpp
		bufferMem = null;
		#end
		isDisposed = true;

		while (!isPlaying && !isDisposed)
		{
			libvlc = null;
		}
	}

	/////////////////////////////////////////////////////////////////////////////////////
}
