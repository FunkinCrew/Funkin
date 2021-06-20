package ratings;

class Ratings
{
    private static var timings:Array<Dynamic> = [
        [50, 'sick'],
        [100, 'good'],
        [125, 'bad'],
        [1000, 'shit'],
    ];

    private static var scores:Array<Dynamic> = [
        ['sick', 350],
        ['good', 200],
        ['bad', 100],
        ['shit', 50]
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