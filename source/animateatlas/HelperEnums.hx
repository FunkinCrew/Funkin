package animateatlas;

enum abstract LoopMode(String) from String to String {
	public static inline var LOOP:String = "loop";
	public static inline var PLAY_ONCE:String = "playonce";
	public static inline var SINGLE_FRAME:String = "singleframe";

	public static function isValid(value:String):Bool {
		return value == LOOP || value == PLAY_ONCE || value == SINGLE_FRAME;
	}
}

enum abstract SymbolType(String) from String to String {
	public static inline var GRAPHIC:String = "graphic";
	public static inline var MOVIE_CLIP:String = "movieclip";
	public static inline var BUTTON:String = "button";

	public static function isValid(value:String):Bool {
		return value == GRAPHIC || value == MOVIE_CLIP || value == BUTTON;
	}
}
