#if sys
package smTools;

class SMHeader
{
    private var _header:Array<String>;

    public var TITLE = "";
    public var SUBTITLE = "";
    public var ARTIST = "";
    public var GENRE = "";
    public var CREDIT = "";
    public var MUSIC = "";
    public var BANNER = "";
    public var BACKGROUND = "";
    public var CDTITLE = "";
    public var OFFSET = "";
    public var BPMS = ""; // time=bpm 

    public var changeEvents:Array<Song.Event>;

    public function new(headerData:Array<String>)
    {
        _header = headerData;
    
        for (i in headerData)
        {
            readHeaderLine(i);
        }

        trace(BPMS);

        MUSIC = StringTools.replace(MUSIC," ", "_");

        changeEvents = [];

        getBPM(0,true);
    }

    public function getBeatFromBPMIndex(index):Float
    {
        var bpmSplit = BPMS.split(',');
        var beat = 0;
        for(ii in 0...bpmSplit.length)
        {
            if (ii == index)
                return Std.parseFloat(StringTools.replace(bpmSplit[ii].split('=')[0],",",""));
        }
        return 0.0;
    }

    public function getBPM(beat:Float, printAllBpms:Bool = false)
    {
        var bpmSplit = BPMS.split(',');
        if (printAllBpms)
        {
            TimingStruct.clearTimings();
            var currentIndex = 0;
            for(i in bpmSplit)
            {
                var bpm:Float = Std.parseFloat(i.split('=')[1]);
                var beat:Float = Std.parseFloat(StringTools.replace(i.split('=')[0],",",""));

                var endBeat:Float = Math.POSITIVE_INFINITY;

                TimingStruct.addTiming(beat,bpm,endBeat, -Std.parseFloat(OFFSET));

                if (changeEvents.length != 0)
                {
                    var data = TimingStruct.AllTimings[currentIndex - 1];
                    data.endBeat = beat;
                    data.length = (data.endBeat - data.startBeat) / (data.bpm / 60);
                    var step = ((60 / data.bpm) * 1000) / 4;
					TimingStruct.AllTimings[currentIndex].startStep = Math.floor(((data.endBeat / (data.bpm / 60)) * 1000) / step);
                    TimingStruct.AllTimings[currentIndex].startTime = data.startTime + data.length;
                }

                changeEvents.push(new Song.Event(HelperFunctions.truncateFloat(beat,0) + "SM",beat,bpm,"BPM Change"));

                if (bpmSplit.length == 1)
                    break;
                currentIndex++;
            }

            trace(changeEvents.length + " - BPM CHANGES");
            return 0.0;
        }
        var returningBPM = Std.parseFloat(bpmSplit[0].split('=')[1]);
        for(i in bpmSplit)
        {
            var bpm:Float = Std.parseFloat(i.split('=')[1]);
            var beatt:Float = Std.parseFloat(StringTools.replace(i.split('=')[0],",",""));
            if (beatt <= beat)
                returningBPM = bpm;
        }
        return returningBPM;
    }

    function readHeaderLine(line:String)
    {
        var propName = line.split('#')[1].split(':')[0];
        var value = line.split(':')[1].split(';')[0];
        var prop = Reflect.getProperty(this,propName);

        if (prop != null)
        {
            Reflect.setProperty(this,propName,value);
        }
    }
}
#end