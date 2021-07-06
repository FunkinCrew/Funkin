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
                    cleanedNotes.push(new SmallNote(ii[0],Math.floor(Math.abs(ii[1]))));
            }
        }

        var handOne:Array<SmallNote> = [];
        var handTwo:Array<SmallNote> = [];
        
        cleanedNotes.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

        var firstNoteTime = cleanedNotes[0].strumTime;
        
        // normalize the notes

        for(i in cleanedNotes)
        {
            i.strumTime = (i.strumTime - firstNoteTime) * 2;
        }

        for (i in cleanedNotes)
        {
            switch(i.noteData)
            {
                case 0:
                    handOne.push(i);
                case 1:
                    handTwo.push(i);
                case 2:
                    handTwo.push(i);
                case 3:
                    handOne.push(i);
            }
        }


        // length in segments of the song
        var length = ((cleanedNotes[cleanedNotes.length - 1].strumTime / 1000) / 0.5);

        // hackey way of creating a array with a length
        var segmentsOne:Array<Int> = new_Array(1,Std.int(length));
        var segmentsTwo:Array<Int> = new_Array(1,Std.int(length));
        
        // algo loop
        for(i in handOne)
        {
            var index = Std.int(((i.strumTime / 1000)));
            if (index + 1 > segmentsOne.length)
                continue;
            segmentsOne[index] = segmentsOne[index] + 1;
        }

        for(i in handTwo)
        {
            var index = Std.int(((i.strumTime / 1000)));
            if (index + 1 > segmentsTwo.length)
                continue;
            segmentsTwo[index] = segmentsTwo[index] + 1;
        }

        // get the average of all of the segments
        var sumOne:Float = 0;
        var sumTwo:Float = 0;


        var lone = segmentsOne.length;
        var ltwo = segmentsOne.length;

        for (i in segmentsOne)
        {
            if (i == 0) // remove empty/breaks
            {
                lone--;
                continue;
            }
            //trace(i);
            sumOne += i / .5; // half it because otherwise instead of nps its just fucking notes per half second which is dumb and stupid
        }

        for (i in segmentsTwo)
        {
            if (i == 0) // remove empty/breaks
            {
                ltwo--;
                continue;
            }
            //trace(i);
            sumTwo += i / .5; // half it because otherwise instead of nps its just fucking notes per half second which is dumb and stupid
        }
        

        var handOneAvg = sumOne / lone;
        var handTwoAvg = sumTwo / ltwo;

        return HelperFunctions.truncateFloat(handOneAvg > handTwoAvg ? handOneAvg : handTwoAvg,2);
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