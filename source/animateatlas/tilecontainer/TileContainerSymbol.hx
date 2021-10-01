package animateatlas.tilecontainer;

import openfl.display.Tileset;
import animateatlas.JSONData.PointData;
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
import openfl.display.DisplayObjectContainer;
import openfl.display.TileContainer;
import openfl.display.Tile;

class TileContainerSymbol extends TileContainer {
	public var currentLabel(get, never):String;
	public var currentFrame(get, set):Int;
	public var type(get, set):String;
	public var loopMode(get, set):String;
	public var symbolName(get, never):String;
	public var numLayers(get, never):Int;
	public var numFrames(get, never):Int;

	private var _data:SymbolData;
	private var _library:TileAnimationLibrary;
	private var _symbolName:String;
	private var _type:String;
	private var _loopMode:String;
	private var _currentFrame:Int;
	private var _composedFrame:Int;
	private var _bitmap:Tile;
	private var _numFrames:Int;
	private var _numLayers:Int;
	private var _frameLabels:Array<FrameLabel>;
	private var _colorTransform:ColorTransform;
	private var _layers:Array<TileContainer>;

	private function new(data:SymbolData, library:TileAnimationLibrary, tileset:Tileset) {
		super();
		this.tileset = tileset;
		_data = data;
		_library = library;
		_composedFrame = -1;
		_numLayers = data.TIMELINE.LAYERS.length;
		_numFrames = getNumFrames();
		_frameLabels = _getFrameLabels();
		_symbolName = data.SYMBOL_name;
		_type = SymbolType.GRAPHIC;
		_loopMode = LoopMode.LOOP;

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
		matrix.identity();

		// copied from the setter for tile so we don't create a new matrix.
		__rotation = null;
		__scaleX = null;
		__scaleY = null;
		__setRenderDirty();

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
			var layer:TileContainer = getLayer(l);
			var numElements:Int = layer.numTiles;

			for (e in 0...numElements) {
				(try cast(layer.getTileAt(e), TileContainerSymbol) catch (e:Dynamic) null).moveMovieclip_MovieClips(direction);
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
		var layer:TileContainer = getLayer(layerIndex);
		var frameData:LayerFrameData = getFrameData(layerIndex, _currentFrame);
		var elements:Array<ElementData> = (frameData != null) ? frameData.elements : null;
		var numElements:Int = (elements != null) ? elements.length : 0;
		for (i in 0...numElements) {
			var elementData:SymbolInstanceData = elements[i].SYMBOL_Instance;
			if (elementData == null) {
				continue;
			}
			// this is confusing but needed :(
			var oldSymbol:TileContainerSymbol = (layer.numTiles > i) ? try
				cast(layer.getTileAt(i), TileContainerSymbol)
			catch (e:Dynamic)
				null : null;

			var newSymbol:TileContainerSymbol = null;
			var symbolName:String = elementData.SYMBOL_name;

			if (!_library.hasSymbol(symbolName)) {
				symbolName = TileAnimationLibrary.BITMAP_SYMBOL_NAME;
			}

			if (oldSymbol != null && oldSymbol._symbolName == symbolName) {
				newSymbol = oldSymbol;
			} else {
				if (oldSymbol != null) {
					if (oldSymbol.parent != null)
						oldSymbol.removeTile(oldSymbol);
					_library.putSymbol(oldSymbol);
				}

				newSymbol = cast(_library.getSymbol(symbolName));
				layer.addTileAt(newSymbol, i);
			}

			newSymbol.setTransformationMatrix(elementData.Matrix3D);
			newSymbol.setBitmap(elementData.bitmap);
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

		var numObsoleteSymbols:Int = (layer.numTiles - numElements);

		for (i in 0...numObsoleteSymbols) {
			try {
				var oldSymbol = cast(layer.removeTileAt(numElements), TileContainerSymbol);
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
		_layers = new Array<TileContainer>();

		if (_numLayers <= 1) {
			_layers.push(this);
		} else {
			for (i in 0..._numLayers) {
				var layer:TileContainer = new TileContainer();
				if (layer.data == null) {
					layer.data = {layerName: getLayerData(i).Layer_name};
				} else {
					layer.data.layerName = getLayerData(i).Layer_name;
				}
				addTile(layer);
				_layers.push(layer);
			}
		}
	}

	@:access(animateatlas)
	public function setBitmap(data:BitmapPosData):Void {
		if (data != null) {
			var spriteData = _library.getSpriteData(data.name + "");

			if (_bitmap == null) {
				_bitmap = new Tile(-1);
				_bitmap.rect = new Rectangle();
				addTile(_bitmap);
			}

			_bitmap.rect.setTo(spriteData.x, spriteData.y, spriteData.w, spriteData.h);
			_bitmap.__setRenderDirty(); // setTo() doesn't trigger the renderdirty

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

			addTileAt(_bitmap, 0);
		} else if (_bitmap != null) {
			if (_bitmap.parent != null)
				_bitmap.parent.removeTile(_bitmap);
		}
	}

	private function setTransformationMatrix(data:Matrix3DData):Void {
		if (data.m00 != matrix.a || data.m01 != matrix.b || data.m10 != matrix.c || data.m11 != matrix.d || data.m30 != matrix.tx || data.m31 != matrix.ty) {
			matrix.setTo(data.m00, data.m01, data.m10, data.m11, data.m30, data.m31);

			// copied from the setter for tile so we don't create a new matrix.
			__rotation = null;
			__scaleX = null;
			__scaleY = null;
			__setRenderDirty();
		}
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
		colorTransform = newTransform;
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

	private function getLayer(layerIndex:Int):TileContainer {
		return _layers[layerIndex];
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

	public function get_numLayers():Int {
		return _numLayers;
	}

	public function get_numFrames():Int {
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
