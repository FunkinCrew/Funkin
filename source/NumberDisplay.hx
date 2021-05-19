import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.text.FlxText;

class NumberDisplay extends FlxText {
    public var value(default, set):Float = 0.0;
    public var precision:Float = 1.0;
    public var changedBy:Int = 0;
    public var useDefaultValue:Float = 0.0;
    public var lowerBound:Float = Math.NEGATIVE_INFINITY;
    public var upperBound:Float = Math.POSITIVE_INFINITY;
    public function new(X:Float = 0, Y:Float = 0, defaultValue:Float = 0.0, usePrecision:Float = 1, ?mini:Float, ?maxi:Float) {
        super(X, Y);
        value = defaultValue;
        precision = usePrecision;
        useDefaultValue = defaultValue;
        lowerBound = mini == null ? Math.NEGATIVE_INFINITY : mini;
		upperBound = maxi == null ? Math.POSITIVE_INFINITY : maxi;
        // lol
        text = "" + value;
		setFormat("assets/fonts/vcr.ttf", 20, FlxColor.WHITE, RIGHT, OUTLINE, FlxColor.BLACK);
    }
    function set_value(x:Float) {
		value = FlxMath.bound(x, lowerBound, upperBound);
        var diff = value - useDefaultValue;
        diff /= precision;
        changedBy = Std.int(diff);
		text = "" + value;
        return value;
    }
    public function changeAmount(increase:Bool) {
        if (increase) {
            value += precision;
            if (value > upperBound) {
                value -= precision;
                return;
            }
        } else {
            value -= precision;
            if (value < lowerBound) {
                value += precision;
                return;
            }
        }
        text = "" + value;
    }
    public function resetValues() {
        value = useDefaultValue;
        changedBy = 0;
        text = "" + value;
    }
}