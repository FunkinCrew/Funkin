package utilities;

import game.Conductor;
import states.PlayState;
import flixel.FlxG;

class Ratings
{
    private static var scores:Array<Dynamic> = [
        ['marvelous', 400],
        ['sick', 350],
        ['good', 200],
        ['bad', 50],
        ['shit', -150]
    ];

    public static function getRating(time:Float)
    {
        var judges = FlxG.save.data.judgementTimings;

        var timings:Array<Array<Dynamic>> = [
            [judges[0], "marvelous"],
            [judges[1], "sick"],
            [judges[2], "good"],
            [judges[3], "bad"]
        ];

        var rating:String = 'bruh';

        for(x in timings)
        {
            if(x[1] == "marvelous" && FlxG.save.data.marvelousRatings || x[1] != "marvelous")
            {
                if(time <= x[0] * PlayState.songMultiplier && rating == 'bruh')
                {
                    rating = x[1];
                }
            }
        }

        if(rating == 'bruh')
            rating = "shit";

        return rating;
    }

    public static function returnPreset(name:String = "leather engine"):Array<Int>
    {
        switch(name.toLowerCase())
        {
            case "leather engine":
                return [25, 50, 70, 100];
            case "psych engine":
                return [Std.int(Conductor.safeZoneOffset * 0.125), Std.int(Conductor.safeZoneOffset * 0.25), Std.int(Conductor.safeZoneOffset * 0.5), Std.int(Conductor.safeZoneOffset * 0.75)];
            case "kade engine":
                /* 22.5 but rounded */
                return [23, 45, 90, 135];
            case "friday night funkin'":
                return [Std.int(Conductor.safeZoneOffset * 0.1), Std.int(Conductor.safeZoneOffset * 0.2), Std.int(Conductor.safeZoneOffset * 0.75), Std.int(Conductor.safeZoneOffset * 0.9)];
        }

        return [25, 50, 70, 100];
    }

    public static function getRank(accuracy:Float, ?misses:Int)
    {
        // yeah this is kinda taken from kade engine but i didnt use the etterna 'wife3' ranking system (instead just my own custom values)
        var conditions:Array<Bool>;

        if(FlxG.save.data.ratingMode == "complex")
        {
            conditions = [
                accuracy == 100, // MFC
                accuracy >= 98, // SSS
                accuracy >= 95, // SS
                accuracy >= 92, // S
                accuracy >= 89, // AA
                accuracy >= 85, // A
                accuracy >= 80, // B+
                accuracy >= 70, // B
                accuracy >= 65, // C
                accuracy >= 50, // D
                accuracy >= 10, // E
                accuracy >= 5, // F
                accuracy < 4, // G
            ];
        }
        else // simple
        {
            conditions = [
                accuracy == 100, // PERFECT
                accuracy >= 85, // SICK
                accuracy >= 60, // GOOD
                accuracy >= 50, // OK
                accuracy >= 35, // BAD
                accuracy >= 10, // REALLY BAD
                accuracy >= 2, // OOF
                accuracy >= 0 // wow you really suck
            ];
        }

        var missesRating:String = "";

        if(misses != null)
        {
            var ratingsArray:Array<Int> = [
                PlayState.instance.ratings.get("marvelous"),
                PlayState.instance.ratings.get("sick"),
                PlayState.instance.ratings.get("good"),
                PlayState.instance.ratings.get("bad"),
                PlayState.instance.ratings.get("shit")
            ];

            if(misses == 0)
            {
                missesRating = "FC - ";

                if(ratingsArray[3] < 10 && ratingsArray[4] == 0)
                    missesRating = "SDB - ";

                if(ratingsArray[3] == 0 && ratingsArray[4] == 0)
                    missesRating = "GFC - ";

                if(ratingsArray[2] < 10 && ratingsArray[3] == 0 && ratingsArray[4] == 0)
                    missesRating = "SDG - ";

                if(ratingsArray[2] == 0 && ratingsArray[3] == 0 && ratingsArray[4] == 0)
                    missesRating = "PFC - ";

                if(ratingsArray[1] < 10 && ratingsArray[2] == 0 && ratingsArray[3] == 0 && ratingsArray[4] == 0)
                    missesRating = "SDP - ";

                if(ratingsArray[1] == 0 && ratingsArray[2] == 0 && ratingsArray[3] == 0 && ratingsArray[4] == 0)
                    missesRating = "MFC - ";
            }

            if(misses > 0 && misses < 10)
                missesRating = "SDCB - ";

            if(misses >= 10)
                missesRating = "CLEAR - ";
        }

        for(condition in 0...conditions.length)
        {
            var rating_success = conditions[condition];

            if(rating_success)
            {
                switch(FlxG.save.data.ratingMode)
                {
                    case "complex":
                        switch(condition)
                        {
                            case 0:
                                return missesRating + "SSSS";
                            case 1:
                                return missesRating + "SSS";
                            case 2:
                                return missesRating + "SS";
                            case 3:
                                return missesRating + "S";
                            case 4:
                                return missesRating + "AA";
                            case 5:
                                return missesRating + "A";
                            case 6:
                                return missesRating + "B+";
                            case 7:
                                return missesRating + "B";
                            case 8:
                                return missesRating + "C";
                            case 9:
                                return missesRating + "D";
                            case 10:
                                return missesRating + "E";
                            case 11:
                                return missesRating + "F";
                            case 12:
                                return missesRating + "G";
                        }
                    default:
                        switch(condition)
                        {
                            case 0:
                                return missesRating + "Perfect";
                            case 1:
                                return missesRating + "Sick";
                            case 2:
                                return missesRating + "Good";
                            case 3:
                                return missesRating + "Ok";
                            case 4:
                                return missesRating + "Bad";
                            case 5:
                                return missesRating + "Really Bad";
                            case 6:
                                return missesRating + "OOF";
                            case 7:
                                return missesRating + "how tf u this bad";
                        }
                }
            }
        }

        return "N/A";
    }

    public static function getScore(rating:String)
    {
        var score:Int = 0;

        for(x in scores)
        {
            if(rating == x[0])
            {
                score = x[1];
            }
        }

        return score;
    }
}