package utilities;

import states.PlayState;
import flixel.FlxG;

class Ratings
{
    private static var timings:Array<Dynamic> = [
        [50, 'sick'],
        [70, 'good'],
        [100, 'bad']
    ];

    private static var scores:Array<Dynamic> = [
        ['sick', 350],
        ['good', 200],
        ['bad', 50],
        ['shit', -150]
    ];

    public static function getRating(time:Float)
    {
        var rating:String = 'bruh';

        for(x in timings)
        {
            if(time <= x[0] * PlayState.songMultiplier && rating == 'bruh')
            {
                rating = x[1];
            }
        }

        if(rating == 'bruh')
            rating = "shit";

        return rating;
    }

    public static function getRank(accuracy:Float, ?misses:Int)
    {
        // yeah this is kinda taken from kade engine but i didnt use the etterna 'wife3' ranking system (instead just my own custom values)
        var conditions:Array<Bool> = [
            accuracy == 100, // FC
            accuracy >= 98, // SSS
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

        var missesRating:String = "";

        if(misses != null)
        {
            if(misses == 0)
                missesRating = "FC - ";
            if(misses > 0 && misses < 10)
                missesRating = "SDCB - ";
            if(misses >= 10)
                missesRating = "CLEAR - ";
        }

        if(FlxG.save.data.accuracyMode == "simple")
        {
            for(condition in 0...conditions.length)
            {
                var rating_success = conditions[condition];

                if(rating_success)
                {
                    switch(condition)
                    {
                        case 0:
                            return "MFC";
                        case 1:
                            return missesRating + "SSS";
                        case 2:
                            return missesRating + "S";
                        case 3:
                            return missesRating + "AA";
                        case 4:
                            return missesRating + "A";
                        case 5:
                            return missesRating + "B+";
                        case 6:
                            return missesRating + "B";
                        case 7:
                            return missesRating + "C";
                        case 8:
                            return missesRating + "D";
                        case 9:
                            return missesRating + "E";
                        case 10:
                            return missesRating + "F";
                        case 11:
                            return missesRating + "G";
                    }
                }
            }
        }
        else
        {
            conditions[0] = accuracy >= 99;
            
            for(condition in 0...conditions.length)
            {
                var rating_success = conditions[condition];

                if(rating_success)
                {
                    switch(condition)
                    {
                        case 0:
                            return missesRating + "SSSS";
                        case 1:
                            return missesRating + "SSS";
                        case 2:
                            return missesRating + "S";
                        case 3:
                            return missesRating + "AA";
                        case 4:
                            return missesRating + "A";
                        case 5:
                            return missesRating + "B+";
                        case 6:
                            return missesRating + "B";
                        case 7:
                            return missesRating + "C";
                        case 8:
                            return missesRating + "D";
                        case 9:
                            return missesRating + "E";
                        case 10:
                            return missesRating + "F";
                        case 11:
                            return missesRating + "G";
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

    public static function rankToString(rank:SongRank)
    {
        if(rank != B_PLUS)
            return Std.string(rank);
        else
            return "B+";
    }

    public static function rankToInt(rank:SongRank)
    {
        return rank.getIndex();
    }

    public static function stringToRank(string_Rank:String)
    {
        var ranks = SongRank.getConstructors();

        for(rank_Index in 0...ranks.length)
        {
            var rank = ranks[rank_Index];

            if(rank.toLowerCase() == string_Rank.toLowerCase() || string_Rank == "B+" && rank == "B_PLUS")
                switch(rank.toUpperCase())
                {
                    case "MFC":
                        return MFC;
                    case "FC":
                        return FC;
                    case "SSSS":
                        return SSSS;
                    case "SSS":
                        return SSS;
                    case "S":
                        return S;
                    case "AA":
                        return AA;
                    case "A":
                        return A;
                    case "B_PLUS":
                        return B_PLUS;
                    case "B":
                        return B;
                    case "C":
                        return C;
                    case "D":
                        return D;
                    case "E":
                        return E;
                    case "F":
                        return F;
                    case "G":
                        return G;
                }
        }

        return UNKNOWN;
    }
}

enum SongRank
{
    MFC;
    FC;
    SSSS;
    SSS;
    S;
    AA;
    A;
    B_PLUS;
    B;
    C;
    D;
    E;
    F;
    G;
    UNKNOWN;
}