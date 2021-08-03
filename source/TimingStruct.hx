import flixel.FlxG;

class TimingStruct
{
    public static var AllTimings:Array<TimingStruct> = [];

    public var bpm:Float = 0;

    public var startBeat:Float = 0;
    public var startStep:Int = 0;
    public var endBeat:Float = Math.POSITIVE_INFINITY;
    public var startTime:Float = 0;

    public var length:Float = Math.POSITIVE_INFINITY; // in beats

    public static function clearTimings()
    {
        AllTimings = [];
    }

    public static function addTiming(startBeat,bpm,endBeat:Float, offset:Float)
    {
        var pog = new TimingStruct(startBeat,bpm,endBeat, offset);
        AllTimings.push(pog);
    }

    public function new(startBeat:Float,bpm:Float,endBeat:Float, offset:Float)
    {
        this.bpm = bpm;
        this.startBeat = startBeat;
        if (endBeat != -1)
            this.endBeat = endBeat;
        startTime = offset;
    }

    public static function getTimingAtTimestamp(msTime:Float):TimingStruct
    {
        for(i in AllTimings)
        {
            if (msTime >= i.startTime * 1000 && msTime < (i.startTime + i.length) * 1000)
                return i;
        }
        trace('Apparently ' + msTime + ' is out of any segs');
        return null;
    }

    public static function getTimingAtBeat(beat):TimingStruct
    {
        for(i in AllTimings)
        {
            if (i.startBeat <= beat && i.endBeat >= beat)
                return i;
        }
        return null;
    }
}
