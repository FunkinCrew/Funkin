import flixel.util.FlxColor;
import flixel.text.FlxText;

class NumberDisplay extends FlxText {
    public var value:Float = 0.0;
    public var precision:Float = 1.0;

    public function new(X:Float = 0, Y:Float = 0, defaultValue:Float = 0.0, usePrecision:Float = 1) {
        super(X, Y);
        value = defaultValue;
        precision = usePrecision;
        // lol
        text = "" + value;
		setFormat("assets/fonts/vcr.ttf", 20, FlxColor.WHITE, RIGHT, OUTLINE, FlxColor.BLACK);
    }
    public function changeAmount(increase:Bool) {
        if (increase) {
            value += precision;
        } else {
            value -= precision;
        }
        text = "" + value;
    }
}