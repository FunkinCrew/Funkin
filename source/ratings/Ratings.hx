package ratings;

class Ratings
{
    private static var timings:Array<Dynamic> = [
        [50, 'sick'],
        [110, 'good'],
        [150, 'bad'],
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