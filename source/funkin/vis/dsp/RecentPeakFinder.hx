package funkin.vis.dsp;

// It would be great to make this parameterizable but haxe doesn't seem to have a way to do 
// a numeric type constraint afaict
class RecentPeakFinder
{
    private var buffer:Array<Float>;
    private var bufferIndex:Int = 0; // We circle arround to avoid reallocating
    public var peak(default, null):Float = 0;
    public var lastValue(get, never):Float;

    public function new(length:Int = 30) {
        buffer = new Array<Float>();
        buffer.resize(length);
    }

    public function push(value:Float) {
        buffer[bufferIndex] = value;
        if (value > peak) peak = value;
        else peak = Signal.max(buffer);
        bufferIndex = if (bufferIndex + 1 == buffer.length) 0;
        else bufferIndex + 1;
    }

    private function get_lastValue():Float {
        return if (bufferIndex == 0) buffer[buffer.length - 1];
        else buffer[bufferIndex - 1];
    }
}