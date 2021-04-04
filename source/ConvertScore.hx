class ConvertScore
{
    public static function convertScore(noteDiff:Float):Int
    {
        var daRating:String = Ratings.CalculateRating(noteDiff, 166);

        switch(daRating)
			{
				case 'shit':
					return -300;
				case 'bad':
					return 0;
				case 'good':
					return 200;
				case 'sick':
					return 350;
            }
        return 0;
    }

}