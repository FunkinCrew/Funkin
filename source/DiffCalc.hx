import Song.SwagSong;

class SmallNote // basically Note.hx but small as fuck
{
    public var strumTime:Float;
    public var noteData:Int;

    public function new(strum,data)
    {
        strumTime = strum;
        noteData = data;
    }
}

class DiffCalc
{
    public static function CalculateDiff(song:SwagSong)
    {
        // cleaned notes
        var cleanedNotes:Array<SmallNote> = [];

        // find all of the notes
        for(i in song.notes) // sections
        {
            for (ii in i.sectionNotes) // notes
            {
                if (ii[2] != 0) // skip helds
                    continue;
                var gottaHitNote:Bool = i.mustHitSection;

				if (ii[1] > 3)
					gottaHitNote = !i.mustHitSection;

                if (gottaHitNote)
                    cleanedNotes.push(new SmallNote(ii[0],ii[1]));
            }
        }

        cleanedNotes.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

        var firstNoteTime = cleanedNotes[0].strumTime;
        
        // normalize the notes
        for(i in cleanedNotes)
        {
            i.strumTime = (i.strumTime - firstNoteTime) * 2;
        }

        // length in segments of the song
        var length = ((cleanedNotes[cleanedNotes.length - 1].strumTime / 1000) / 0.5);

        // hackey way of creating a array with a length
        var segments:Array<Int> = new_Array(1,Std.int(length));

        // algo loop
        for(i in cleanedNotes)
        {
            var index = Std.int(((i.strumTime / 1000)));
            if (index + 1 > segments.length)
                continue;
            segments[index] = segments[index] + 1;
        }

        // get the average of all of the segments
        var sum:Float = 0;

        var newLength = segments.length;

        for (i in segments)
        {
            if (i == 0) // remove empty/breaks
            {
                newLength--;
                continue;
            }
            //trace(i);
            sum += i / .5; // half it because otherwise instead of nps its just fucking notes per half second which is dumb and stupid
        }
        return HelperFunctions.truncateFloat(sum / newLength,2);
    }

    static public function new_Array<T>( ArrayType:T, Length:Int ):Array<T> {
        var empty:Null<T> = null;
        var newArray:Array<T> = new Array<T>();
    
        for ( i in 0...Length ) {
            newArray.push( empty );
        }
    
        return newArray;
    }
}