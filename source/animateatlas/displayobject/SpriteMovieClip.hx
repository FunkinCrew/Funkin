package animateatlas.displayobject;

import openfl.display.Sprite;
import animateatlas.HelperEnums.LoopMode;
import animateatlas.HelperEnums.SymbolType;

@:access(animateatlas.displayobject.SpriteSymbol)
class SpriteMovieClip extends Sprite {
	public var framerate(get, set):Float;
	public var currentLabel(get, set):String;
	public var currentFrame(get, set):Int;
	public var type(get, set):String;
	public var loopMode(get, set):String;
	public var symbolName(get, never):String;
	public var numLayers(get, never):Int;
	public var numFrames(get, never):Int;
	public var layers(get, never):Array<Sprite>; // ! Dangerous AF.

	private var symbol:SpriteSymbol;
	private var _framerate:Null<Float> = null;

	private var frameElapsed:Float = 0;

	public function new(symbol:SpriteSymbol) {
		super();
		this.symbol = symbol;
		addChild(this.symbol);
	}

	public function update(dt:Int) {
		//
		var frameDuration:Float = 1000 / framerate;
		frameElapsed += dt;

		while (frameElapsed > frameDuration) {
			frameElapsed -= frameDuration;
			symbol.nextFrame();
		}
		while (frameElapsed < -frameDuration) {
			frameElapsed += frameDuration;
			symbol.prevFrame();
		}
	}

	public function getFrameLabels():Array<String> {
		return symbol.getFrameLabels();
	}

	public function getFrame(label:String):Int {
		return symbol.getFrame(label);
	}

	// # region Property setter and getter

	private function set_currentLabel(value:String):String {
		symbol.currentFrame = symbol.getFrame(value);
		return value;
	}

	private function get_currentLabel():String {
		return symbol.currentLabel;
	}
	

	private function set_currentFrame(value:Int):Int {
		symbol.currentFrame = value;
		return value;
	}

	private function get_currentFrame():Int {
		return symbol.currentFrame;
	}

	private function set_type(value:SymbolType):SymbolType {
		symbol.type = value;
		return value;
	}

	private function get_type():SymbolType {
		return symbol.type;
	}

	private function set_loopMode(value:LoopMode):LoopMode {
		symbol.loopMode = value;
		return value;
	}

	private function get_loopMode():LoopMode {
		return symbol.loopMode;
	}

	private function get_symbolName():String {
		return symbol.symbolName;
	}

	private function get_numLayers():Int {
		return symbol.numLayers;
	}

	private function get_numFrames():Int {
		return symbol.numFrames;
	}

	private function get_layers():Array<Sprite> {
		return symbol._layers;
	}

	private function set_framerate(value:Float):Float {
		return _framerate = value;
	}

	private function get_framerate():Float {
		return _framerate == null ? symbol._library.frameRate : _framerate;
	}

	// # end region
}
