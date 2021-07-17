package utilities;

class Ratings
{
    private static var timings:Array<Dynamic> = [
        [50, 'sick'],
        [70, 'good'],
        [100, 'bad'],
        [10000, 'shit'],
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
            if(time <= x[0] && rating == 'bruh')
            {
                rating = x[1];
            }
        }

        return rating;
    }

    public static function getRank(accuracy:Float)
    {
        // yeah this is kinda taken from kade engine but i didnt use the etterna 'wife' ranking system (instead just my own custom values)
        var conditions:Array<Bool> = [
            accuracy == 100, // FC
            accuracy >= 98, // GFC
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

        for(condition in 0...conditions.length)
        {
            var rating_success = conditions[condition];

            if(rating_success)
            {
                switch(condition)
                {
                    case 0:
                        return "FC";
                    case 1:
                        return "GFC";
                    case 2:
                        return "S";
                    case 3:
                        return "AA";
                    case 4:
                        return "A";
                    case 5:
                        return "B+";
                    case 6:
                        return "B";
                    case 7:
                        return "C";
                    case 8:
                        return "D";
                    case 9:
                        return "E";
                    case 10:
                        return "F";
                    case 11:
                        return "G";
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
                    case "FC":
                        return FC;
                    case "GFC":
                        return GFC;
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
    FC;
    GFC;
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