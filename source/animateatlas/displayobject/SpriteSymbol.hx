package animateatlas.displayobject;

import openfl.filters.GlowFilter;
import openfl.filters.BlurFilter;
import openfl.display.PixelSnapping;
import openfl.geom.Point;
import openfl.display.BitmapData;
import openfl.display.Bitmap;
import openfl.display.Sprite;
import openfl.errors.ArgumentError;
import openfl.geom.Rectangle;
import openfl.errors.Error;
import animateatlas.JSONData.ElementData;
import animateatlas.HelperEnums.LoopMode;
import animateatlas.HelperEnums.SymbolType;
import openfl.display.FrameLabel;
import animateatlas.JSONData.SymbolData;
import animateatlas.JSONData.SymbolInstanceData;
import animateatlas.JSONData.LayerData;
import animateatlas.JSONData.BitmapPosData;
import animateatlas.JSONData.Matrix3DData;
import animateatlas.JSONData.LayerFrameData;
import animateatlas.JSONData.ColorData;
import openfl.geom.Matrix;
import openfl.geom.ColorTransform;
import animateatlas.JSONData.FilterData;

class SpriteSymbol extends Sprite {
	public var currentLabel(get, never):String;
	public var currentFrame(get, set):Int;
	public var type(get, set):String;
	public var loopMode(get, set):String;
	public var symbolName(get, never):String;
	public var numLayers(get, never):Int;
	public var numFrames(get, never):Int;

	private var _data:SymbolData;
	private var _library:SpriteAnimationLibrary;
	private var _symbolName:String;
	private var _type:String;
	private var _loopMode:String;
	
	private var _currentFrame:Int;
	private var _composedFrame:Int;
	private var _bitmap:Bitmap;
	private var _numFrames:Int;
	private var _numLayers:Int;
	private var _frameLabels:Array<FrameLabel>;
	private var _colorTransform:ColorTransform;
	private var _layers:Array<Sprite>;
	private var _texture:BitmapData;
	private var _tempRect = new Rectangle();
	private var _zeroPoint = new Point(0, 0);
	private var filterHelper:BitmapData;
	public var smoothing:Bool = true;

	private static var sMatrix:Matrix = new Matrix();

	private function new(data:SymbolData, library:SpriteAnimationLibrary, texture:BitmapData) {
		super();
		_data = data;
		_library = library;
		_composedFrame = -1;
		_numLayers = data.TIMELINE.LAYERS.length;
		_numFrames = getNumFrames();
		_frameLabels = _getFrameLabels();
		_symbolName = data.SYMBOL_name;
		_type = SymbolType.GRAPHIC;
		_loopMode = LoopMode.LOOP;
		_texture = texture;

		createLayers();

		// Create FrameMap caches if don't exist
		for (layer in data.TIMELINE.LAYERS) {
			if (layer.FrameMap != null)
				return;

			var map = new Map();

			for (i in 0...layer.Frames.length) {
				var frame = layer.Frames[i];
				for (j in 0...frame.duration) {
					map.set(i + j, frame);
				}
			}

			layer.FrameMap = map;
		}
	}

	public function reset():Void {
		sMatrix.identity();
		transform.matrix = sMatrix.clone();
		alpha = 1.0;
		_currentFrame = 0;
		_composedFrame = -1;
	}

	public function nextFrame():Void {
		if (_loopMode != LoopMode.SINGLE_FRAME) {
			currentFrame += 1;
		}

		moveMovieclip_MovieClips(1);
	}

	public function prevFrame():Void {
		if (_loopMode != LoopMode.SINGLE_FRAME) {
			currentFrame -= 1;
		}

		moveMovieclip_MovieClips(-1);
	}

	/** Moves all movie clips n frames, recursively. */
	private function moveMovieclip_MovieClips(direction:Int = 1):Void {
		if (_type == SymbolType.MOVIE_CLIP) {
			currentFrame += direction;
		}

		for (l in 0..._numLayers) {
			var layer:Sprite = getLayer(l);
			var numElements:Int = layer.numChildren;

			for (e in 0...numElements) {
				(try cast(layer.getChildAt(e), SpriteSymbol) catch (e:Dynamic) null).moveMovieclip_MovieClips(direction);
			}
		}
	}

	public function update():Void {
		for (i in 0..._numLayers) {
			updateLayer(i);
		}

		_composedFrame = _currentFrame;
	}

	@:access(animateatlas)
	private function updateLayer(layerIndex:Int):Void {
		var layer:Sprite = getLayer(layerIndex);
		var frameData:LayerFrameData = getFrameData(layerIndex, _currentFrame);
		var elements:Array<ElementData> = (frameData != null) ? frameData.elements : null;
		var numElements:Int = (elements != null) ? elements.length : 0;
		for (i in 0...numElements) {
			var elementData:SymbolInstanceData = elements[i].SYMBOL_Instance;

			if (elementData == null) {
				continue;
			}

			// this is confusing but needed :(
			var oldSymbol:SpriteSymbol = (layer.numChildren > i) ? try
				cast(layer.getChildAt(i), SpriteSymbol)
			catch (e:Dynamic)
				null : null;

			var newSymbol:SpriteSymbol = null;

			var symbolName:String = elementData.SYMBOL_name;

			if (!_library.hasSymbol(symbolName)) {
				symbolName = SpriteAnimationLibrary.BITMAP_SYMBOL_NAME;
			}

			if (oldSymbol != null && oldSymbol._symbolName == symbolName) {
				newSymbol = oldSymbol;
			} else {
				if (oldSymbol != null) {
					if (oldSymbol.parent != null)
						oldSymbol.removeChild(oldSymbol);
					_library.putSymbol(oldSymbol);
				}

				newSymbol = cast(_library.getSymbol(symbolName));
				layer.addChildAt(newSymbol, i);
			}

			newSymbol.setTransformationMatrix(elementData.Matrix3D);
			newSymbol.setBitmap(elementData.bitmap);
			newSymbol.setFilterData(elementData.filters);
			newSymbol.setColor(elementData.color);
			newSymbol.setLoop(elementData.loop);
			newSymbol.setType(elementData.symbolType);
			
		

			if (newSymbol.type == SymbolType.GRAPHIC) {
				var firstFrame:Int = elementData.firstFrame;
				var frameAge:Int = Std.int(_currentFrame - frameData.index);

				if (newSymbol.loopMode == LoopMode.SINGLE_FRAME) {
					newSymbol.currentFrame = firstFrame;
				} else if (newSymbol.loopMode == LoopMode.LOOP) {
					newSymbol.currentFrame = (firstFrame + frameAge) % newSymbol._numFrames;
				} else {
					newSymbol.currentFrame = firstFrame + frameAge;
				}
			}
			
		}

		var numObsoleteSymbols:Int = (layer.numChildren - numElements);

		for (i in 0...numObsoleteSymbols) {
			try {
				var oldSymbol = cast(layer.removeChildAt(numElements), SpriteSymbol);
				if (oldSymbol != null)
					_library.putSymbol(oldSymbol);
			} catch (e:Dynamic) {};
		}
	}

	private function createLayers():Void {
		// todo safety check for not initialiing twice
		if (_layers != null) {
			throw new Error("You must not call this twice");
		}
		_layers = new Array<Sprite>();

		if (_numLayers <= 1) {
			_layers.push(this);
		} else {
			for (i in 0..._numLayers) {
				var layer:Sprite = new Sprite();
				layer.name = getLayerData(i).Layer_name;
				addChild(layer);
				_layers.push(layer);
			}
		}
	}

	@:access(animateatlas)
	public function setBitmap(data:BitmapPosData):Void {
		if (data != null) {
			var spriteData = _library.getSpriteData(data.name + "");

			if (_bitmap == null) {
				_bitmap = new Bitmap(new BitmapData(1, 1), PixelSnapping.AUTO, smoothing);
				addChild(_bitmap);
			}

			if (_tempRect.x != spriteData.x || _tempRect.y != spriteData.y || _tempRect.width != spriteData.w || _tempRect.height != spriteData.h) {
				var clippedTexture = new BitmapData(spriteData.w, spriteData.h);
				_tempRect.setTo(spriteData.x, spriteData.y, spriteData.w, spriteData.h);
				clippedTexture.copyPixels(_texture, _tempRect, _zeroPoint);
				_bitmap.bitmapData = clippedTexture;
				_bitmap.smoothing = smoothing;
				
	
			}
			// aditional checks for rotation
			if (spriteData.rotated) {
				_bitmap.rotation = -90;
				_bitmap.x = data.Position.x;
				_bitmap.y = data.Position.y + spriteData.w;
			} else {
				_bitmap.rotation = 0;
				_bitmap.x = data.Position.x;
				_bitmap.y = data.Position.y;
			}

			addChildAt(_bitmap, 0);
		} else if (_bitmap != null) {
			if (_bitmap.parent != null)
				_bitmap.parent.removeChild(_bitmap);
		}
	}
	@:access(animateatlas)
	private function setFilterData(data:FilterData):Void{
		var blur:BlurFilter;
		var glow:GlowFilter;
		if (data != null){
			if (data.BlurFilter != null){
				blur = new BlurFilter();
				blur.blurX = data.BlurFilter.blurX;
				blur.blurY = data.BlurFilter.blurY;
				blur.quality = data.BlurFilter.quality;
				//_bitmap.bitmapData.applyFilter(_bitmap.bitmapData,new Rectangle(0,0,_bitmap.bitmapData.width,_bitmap.bitmapData.height),new Point(0,0),blur);
				//filters.push(blur);
			}
			if (data.GlowFilter != null){
				//trace('GLOW' + data.GlowFilter);
				//glow = new GlowFilter();
				//glow.blurX = data.GlowFilter.blurX;
				//glow.blurY = data.GlowFilter.blurY;
				//glow.color = data.GlowFilter.color;
				//glow.alpha = data.GlowFilter.alpha;
				//glow.quality = data.GlowFilter.quality;
				//glow.strength = data.GlowFilter.strength;
				//glow.knockout = data.GlowFilter.knockout;
				//glow.inner = data.GlowFilter.inner;
				//filters.push(glow);




			}

		}
		
	}

	private function setTransformationMatrix(data:Matrix3DData):Void {
		sMatrix.setTo(data.m00, data.m01, data.m10, data.m11, data.m30, data.m31);
		if (sMatrix.a != transform.matrix.a || sMatrix.b != transform.matrix.b || sMatrix.c != transform.matrix.c || sMatrix.d != transform.matrix.d
			|| sMatrix.tx != transform.matrix.tx || sMatrix.ty != transform.matrix.ty)
			transform.matrix = sMatrix.clone(); // todo stop the cloning :(
	}

	private function setColor(data:ColorData):Void {
		var newTransform = new ColorTransform();
		if (data != null) {
			newTransform.redOffset = (data.redOffset == null ? 0 : data.redOffset);
			newTransform.greenOffset = (data.greenOffset == null ? 0 : data.greenOffset);
			newTransform.blueOffset = (data.blueOffset == null ? 0 : data.blueOffset);
			newTransform.alphaOffset = (data.AlphaOffset == null ? 0 : data.AlphaOffset);

			newTransform.redMultiplier = (data.RedMultiplier == null ? 1 : data.RedMultiplier);
			newTransform.greenMultiplier = (data.greenMultiplier == null ? 1 : data.greenMultiplier);
			newTransform.blueMultiplier = (data.blueMultiplier == null ? 1 : data.blueMultiplier);
			newTransform.alphaMultiplier = (data.alphaMultiplier == null ? 1 : data.alphaMultiplier);
		}
		transform.colorTransform = newTransform;
		
	}

	private function setLoop(data:String):Void {
		if (data != null) {
			_loopMode = data;
		} else {
			_loopMode = LoopMode.LOOP;
		}
	}

	private function setType(data:String):Void {
		if (data != null) {
			_type = data;
		}
	}

	private function getNumFrames():Int {
		var numFrames:Int = 0;

		for (i in 0..._numLayers) {
			var layer = getLayerData(i);
			var frameDates:Array<LayerFrameData> = (layer == null ? [] : layer.Frames);
			var numFrameDates:Int = (frameDates != null) ? frameDates.length : 0;
			var layerNumFrames:Int = (numFrameDates != 0) ? frameDates[0].index : 0;

			for (j in 0...numFrameDates) {
				layerNumFrames += frameDates[j].duration;
			}

			if (layerNumFrames > numFrames) {
				numFrames = layerNumFrames;
			}
		}

		return numFrames == 0 ? 1 : numFrames;
	}

	private function _getFrameLabels():Array<FrameLabel> {
		var labels:Array<FrameLabel> = [];

		for (i in 0..._numLayers) {
			var layer = getLayerData(i);
			var frameDates:Array<LayerFrameData> = (layer == null ? [] : layer.Frames);
			var numFrameDates:Int = (frameDates != null) ? frameDates.length : 0;

			for (j in 0...numFrameDates) {
				var frameData:LayerFrameData = frameDates[j];
				if (frameData.name != null) {
					labels.push(new FrameLabel(frameData.name, frameData.index));
				}
			}
		}
		labels.sort(sortLabels);
		return labels;
	}

	public function getFrameLabels():Array<String> {
		return _frameLabels.map(f -> f.name); // Inlining. I feel a js
	}



	function sortLabels(i1:FrameLabel, i2:FrameLabel):Int {
		var f1 = i1.frame;
		var f2 = i2.frame;
		if (f1 < f2) {
			return -1;
		} else if (f1 > f2) {
			return 1;
		} else {
			return 0;
		}
	}

	private function getLayer(layerIndex:Int):Sprite {
		return _layers[layerIndex];
	}

	public function getTexture():BitmapData{
	//THIS GETS THE ENTIRE THING I'M RETARDED LOL
	return _texture;
	}

	public function getNextLabel(afterLabel:String = null):String {
		var numLabels:Int = _frameLabels.length;
		var startFrame:Int = getFrame(afterLabel == null ? currentLabel : afterLabel);

		for (i in 0...numLabels) {
			var label:FrameLabel = _frameLabels[i];
			if (label.frame > startFrame) {
				return label.name;
			}
		}

		return (_frameLabels != null) ? _frameLabels[0].name : null;
	}

	private function get_currentLabel():String {
		var numLabels:Int = _frameLabels.length;
		var highestLabel:FrameLabel = (numLabels != 0) ? _frameLabels[0] : null;

		for (i in 1...numLabels) {
			var label:FrameLabel = _frameLabels[i];

			if (label.frame <= _currentFrame) {
				highestLabel = label;
			} else {
				break;
			}
		}

		return (highestLabel != null) ? highestLabel.name : null;
	}

	public function getFrame(label:String):Int {
		var numLabels:Int = _frameLabels.length;
		for (i in 0...numLabels) {
			var frameLabel:FrameLabel = _frameLabels[i];
			if (frameLabel.name == label) {
				return frameLabel.frame;
			}
		}
		return -1;
	}

	private function get_currentFrame():Int {
		return _currentFrame;
	}

	private function set_currentFrame(value:Int):Int {
		while (value < 0) {
			value += _numFrames;
		}

		if (_loopMode == LoopMode.PLAY_ONCE) {
			_currentFrame = Std.int(Math.min(Math.max(value, 0), _numFrames - 1));
		} else {
			_currentFrame = Std.int(Math.abs(value % _numFrames));
		}

		if (_composedFrame != _currentFrame) {
			update();
		}
		return value;
	}

	private function get_type():String {
		return _type;
	}

	private function set_type(value:String):String {
		if (SymbolType.isValid(value)) {
			_type = value;
		} else {
			throw new ArgumentError("Invalid symbol type: " + value);
		}
		return value;
	}

	private function get_loopMode():String {
		return _loopMode;
	}

	private function set_loopMode(value:String):String {
		if (LoopMode.isValid(value)) {
			_loopMode = value;
		} else {
			throw new ArgumentError("Invalid loop mode: " + value);
		}
		return value;
	}

	private function get_symbolName():String {
		return _symbolName;
	}

	private function get_numLayers():Int {
		return _numLayers;
	}

	private function get_numFrames():Int {
		return _numFrames;
	}

	// data access

	private function getLayerData(layerIndex:Int):LayerData {
		return _data.TIMELINE.LAYERS[layerIndex];
	}

	private function getFrameData(layerIndex:Int, frameIndex:Int):LayerFrameData {
		var layer = getLayerData(layerIndex);
		if (layer == null)
			return null;

		return layer.FrameMap.get(frameIndex);
	}

}
