package animateatlas.tilecontainer;

import openfl.display.Tileset;
import haxe.Constraints.Constructible;
import openfl.display.BitmapData;
import animateatlas.JSONData.AnimationData;
import animateatlas.JSONData.ElementData;
import animateatlas.JSONData.LayerFrameData;
import animateatlas.JSONData.LayerData;
import animateatlas.JSONData.SymbolTimelineData;
import animateatlas.JSONData.Matrix3DData;
import animateatlas.JSONData.AtlasData;
import animateatlas.JSONData.SymbolData;
import animateatlas.JSONData.SpriteData;
import animateatlas.HelperEnums.LoopMode;
import animateatlas.HelperEnums.SymbolType;
import openfl.errors.ArgumentError;

/**
 * Since we can extract symbols from the exported timeline and instance them separatedly, this keeps track of all symbols.
 * Also, this is a "more readable" way of understanding the AnimationData
 */
class TileAnimationLibrary {
	public var frameRate:Float;

	private var _atlas:Map<String, SpriteData>;
	private var _symbolData:Map<String, SymbolData>;
	private var _symbolPool:Map<String, Array<TileContainerSymbol>>;
	private var _defaultSymbolName:String;
	private var _texture:Tileset;

	public static inline var BITMAP_SYMBOL_NAME:String = "___atlas_sprite___";

	private static var STD_MATRIX3D_DATA:Matrix3DData = {
		m00: 1,
		m01: 0,
		m02: 0,
		m03: 0,
		m10: 0,
		m11: 1,
		m12: 0,
		m13: 0,
		m20: 0,
		m21: 0,
		m22: 1,
		m23: 0,
		m30: 0,
		m31: 0,
		m32: 0,
		m33: 1
	};

	public function new(data:AnimationData, atlas:AtlasData, texture:BitmapData) {
		parseAnimationData(data);
		parseAtlasData(atlas);
		_texture = new Tileset(texture);
		_symbolPool = new Map();
	}

	public function hasAnimation(name:String):Bool {
		return hasSymbol(name);
	}

	public function createAnimation(symbol:String = null):TileContainerMovieClip {
		symbol = (symbol != null) ? symbol : _defaultSymbolName;
		if (!hasSymbol(symbol)) {
			throw new ArgumentError("Symbol not found: " + symbol);
		}
		return new TileContainerMovieClip(getSymbol(symbol));
	}

	public function getAnimationNames(prefix:String = ""):Array<String> {
		var out = new Array<String>();

		for (name in _symbolData.keys()) {
			if (name != BITMAP_SYMBOL_NAME && name.indexOf(prefix) == 0) {
				out.push(name);
			}
		}

		// but... why?
		out.sort(function(a1, a2):Int {
			a1 = a1.toLowerCase();
			a2 = a2.toLowerCase();
			if (a1 < a2) {
				return -1;
			} else if (a1 > a2) {
				return 1;
			} else {
				return 0;
			}
		});
		return out;
	}

	private function getSpriteData(name:String):SpriteData {
		return _atlas.get(name);
	}

	private function hasSymbol(name:String):Bool {
		return _symbolData.exists(name);
	}

	// # region Pooling
	// todo migrate this to lime pool

	@:access(animateatlas)
	private function getSymbol(name:String):TileContainerSymbol {
		var pool:Array<TileContainerSymbol> = getSymbolPool(name);
		if (pool.length == 0) {
			return new TileContainerSymbol(getSymbolData(name), this, _texture);
		} else {
			return pool.pop();
		}
	}

	private function putSymbol(symbol:TileContainerSymbol):Void {
		symbol.reset();
		var pool:Array<TileContainerSymbol> = getSymbolPool(symbol.symbolName);
		pool.push(symbol);
		symbol.currentFrame = 0;
	}

	private function getSymbolPool(name:String):Array<TileContainerSymbol> {
		var pool:Array<TileContainerSymbol> = _symbolPool.get(name);
		if (pool == null) {
			pool = [];
			_symbolPool.set(name, pool);
		}
		return pool;
	}

	// # end region
	// # region helpers
	private function parseAnimationData(data:AnimationData):Void {
		var metaData = data.metadata;

		if (metaData != null && metaData.framerate != null && metaData.framerate > 0) {
			frameRate = (metaData.framerate);
		} else {
			frameRate = 24;
		}

		_symbolData = new Map();

		// the actual symbol dictionary
		var symbols = data.SYMBOL_DICTIONARY.Symbols;
		for (symbolData in symbols) {
			_symbolData[symbolData.SYMBOL_name] = preprocessSymbolData(symbolData);
		}

		// the main animation
		var defaultSymbolData:SymbolData = preprocessSymbolData(data.ANIMATION);
		_defaultSymbolName = defaultSymbolData.SYMBOL_name;
		_symbolData.set(_defaultSymbolName, defaultSymbolData);

		// a purely internal symbol for bitmaps - simplifies their handling
		_symbolData.set(BITMAP_SYMBOL_NAME, {
			SYMBOL_name: BITMAP_SYMBOL_NAME,
			TIMELINE: {
				LAYERS: []
			}
		});
	}

	private function preprocessSymbolData(symbolData:SymbolData):SymbolData {
		var timeLineData:SymbolTimelineData = symbolData.TIMELINE;
		var layerDates:Array<LayerData> = timeLineData.LAYERS;

		// In Animate CC, layers are sorted front to back.
		// In Starling, it's the other way round - so we simply reverse the layer data.

		if (!timeLineData.sortedForRender) {
			timeLineData.sortedForRender = true;
			layerDates.reverse();
		}

		// We replace all "ATLAS_SPRITE_instance" elements with symbols of the same contents.
		// That way, we are always only dealing with symbols.

		for (layerData in layerDates) {
			var frames:Array<LayerFrameData> = layerData.Frames;

			for (frame in frames) {
				var elements:Array<ElementData> = frame.elements;
				for (e in 0...elements.length) {
					var element:ElementData = elements[e];
					if (element.ATLAS_SPRITE_instance != null) {
						element = elements[e] = {
							SYMBOL_Instance: {
								SYMBOL_name: BITMAP_SYMBOL_NAME,
								Instance_Name: "InstName",
								bitmap: element.ATLAS_SPRITE_instance,
								symbolType: SymbolType.GRAPHIC,
								firstFrame: 0,
								loop: LoopMode.LOOP,
								transformationPoint: {
									x: 0,
									y: 0
								},
								Matrix3D: STD_MATRIX3D_DATA
							}
						};
					}
				}
			}
		}

		return symbolData;
	}

	private function parseAtlasData(atlas:AtlasData):Void {
		_atlas = new Map<String, SpriteData>();
		if (atlas.ATLAS != null && atlas.ATLAS.SPRITES != null) {
			for (s in atlas.ATLAS.SPRITES) {
				_atlas.set(s.SPRITE.name, s.SPRITE);
			}
		}
	}

	private function getSymbolData(name:String):SymbolData {
		return _symbolData.get(name);
	}

	// # end region
}
