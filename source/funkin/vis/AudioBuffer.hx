package funkin.vis;

import lime.utils.UInt16Array;

class AudioBuffer
{
    public var data(default, null):UInt16Array;
    public var sampleRate(default, null):Float;

    public function new(data:UInt16Array, sampleRate:Float)
    {
        this.data = data;
        this.sampleRate = sampleRate;
        trace(sampleRate);

    }
}