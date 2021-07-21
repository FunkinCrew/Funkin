#if sys
package smTools;
import sys.io.File;
import haxe.Exception;
import lime.app.Application;
import haxe.Json;

class SMFile
{
    public static function loadFile(path):SMFile
    {
        return new SMFile(File.getContent(path).split('\n'));
    }
    
    private var _fileData:Array<String>;

    public var isDouble:Bool = false;

    public var isValid:Bool = true;

    public var _readTime:Float = 0;

    public var header:SMHeader;
    public var measures:Array<SMMeasure>;

    public function new(data:Array<String>)
    {
        try
        {
            _fileData = data;

            // Gather header data
            var headerData = "";
            var inc = 0;
            while(!StringTools.contains(data[inc + 1],"//"))
            {
                headerData += data[inc];
                inc++;
                // trace(data[inc]);
            }

            header = new SMHeader(headerData.split(';'));

            if (!StringTools.contains(header.MUSIC,"ogg"))
            {
                Application.current.window.alert("The music MUST be an OGG File.","SM File loading (" + header.TITLE + ")");
                isValid = false;
                return;
            }

            // check if this is a valid file, it should be a dance double file.
            inc += 3; // skip three lines down
            if (!StringTools.contains(data[inc],"dance-double:") && !StringTools.contains(data[inc],"dance-single"))
            {
                Application.current.window.alert("The file you are loading is neither a Dance Double chart or a Dance Single chart","SM File loading (" + header.TITLE + ")");
                isValid = false;
                return;
            }
            if (StringTools.contains(data[inc],"dance-double:"))
                isDouble = true;
            if (isDouble)
                trace('this is dance double');

            inc += 5; // skip 5 down to where da notes @

            measures = [];

            var measure = "";

            trace(data[inc - 1]);

            for (ii in inc...data.length)
            {
                var i = data[ii];
                if (StringTools.contains(i,",") || StringTools.contains(i,";"))
                {
                    measures.push(new SMMeasure(measure.split('\n')));
                    //trace(measures.length);
                    measure = "";
                    continue;
                }
                measure += i + "\n";
            }
            trace(measures.length + " Measures");
        }
        catch(e:Exception)
        {
            Application.current.window.alert("Failure to load file.\n" + e,"SM File loading");
        }
    }
    
    public function convertToFNF(saveTo:String):String
    {

        // array's for helds
        var heldNotes:Array<Array<Dynamic>>;

        
        if (isDouble) // held storage lanes
            heldNotes = [[],[],[],[],[],[],[],[]];
        else
            heldNotes = [[],[],[],[]];


        // variables

        var measureIndex = 0;
        var currentBeat:Float = 0;
        var output = "";

        // init a fnf song

        var song = {
            song: header.TITLE,
            notes: [],
            eventObjects: [],
            bpm: header.getBPM(0),
            needsVoices: true,
            player1: 'bf',
            player2: 'gf',
            gfVersion: 'gf',
            noteStyle: 'normal',
            stage: 'stage',
            speed: 1.0,
            validScore: false
        };

        // lets check if the sm loading was valid

        if (!isValid)
        {
            var json = {
                "song": song
            };

            var data:String = Json.stringify(json,null," ");
            File.saveContent(saveTo,data);
            return data;
        }

        // aight time to convert da measures

        trace("Converting measures");

        for(measure in measures)
        {
            // private access since _measure is private
            @:privateAccess
            var lengthInRows = 192 / (measure._measure.length - 1);

            var rowIndex = 0;

            // section declaration

            var section = {
                sectionNotes: [],
                lengthInSteps: 16,
                typeOfSection: 0,
                startTime: 0.0,
                endTime: 0.0,
                mustHitSection: false,
                bpm: header.getBPM(0),
                changeBPM: false,
                altAnim: false
            };

            // if it's not a double always set this to true

            if (!isDouble)
                section.mustHitSection = true;

            @:privateAccess
            for(i in 0...measure._measure.length - 1)
            {
                var noteRow = (measureIndex * 192) + (lengthInRows * rowIndex);

                var notes:Array<String> = [];

                for(note in measure._measure[i].split(''))
                {
                    //output += note;
                    notes.push(note);
                }

                currentBeat = noteRow / 48;

                var seg = TimingStruct.getTimingAtBeat(currentBeat);

                var timeInSec:Float = (seg.startTime + ((currentBeat - seg.startBeat) / (seg.bpm/60)));

                var rowTime = timeInSec * 1000;

                //output += " - Row " + noteRow + " - Time: " + rowTime + " (" + timeInSec + ") - Beat: " + currentBeat + " - Current BPM: " + header.getBPM(currentBeat) + "\n";

                var index = 0;

                for(i in notes)
                {
                    // if its a mine lets skip (maybe add mines in the future??)
                    if (i == "M")
                    {
                        index++;
                        continue;
                    }

                    // get the lane and note type
                    var lane = index;
                    var numba = Std.parseInt(i);

                    // switch through the type and add the note

                    switch(numba)
                    {
                        case 1: // normal
                            section.sectionNotes.push([rowTime,lane ,0]);
                        case 2: // held head
                            heldNotes[lane] = [rowTime,lane,0];
                        case 3: // held tail
                            var data = heldNotes[lane];
                            var timeDiff = rowTime - data[0];
                            section.sectionNotes.push([data[0],lane,timeDiff]);
                            heldNotes[index] = [];
                        case 4: // roll head
                            heldNotes[lane] = [rowTime,lane,0];
                    }
                    index++;
                }


                rowIndex++;
            }

            // push the section

            song.notes.push(section);

            //output += ",\n";

            measureIndex++;
        }

        for (i in 0...song.notes.length) // loops through sections
			{
				var section = song.notes[i];

				var currentBeat = 4 * i;

				var currentSeg = TimingStruct.getTimingAtBeat(currentBeat);

				var start:Float = (currentBeat - currentSeg.startBeat) / (currentSeg.bpm / 60);

				section.startTime = (currentSeg.startTime + start) * 1000;

				if (i != 0)
					song.notes[i - 1].endTime = section.startTime;
				section.endTime = Math.POSITIVE_INFINITY;

			}

        //File.saveContent("fuac" + header.TITLE,output);

        if (header.changeEvents.length != 0)
        {
            song.eventObjects = header.changeEvents;
        }

        // save da song

		var json = {
			"song": song
		};

		var data:String = Json.stringify(json,null," ");
        File.saveContent(saveTo,data);
        return data;
    }
}
#end