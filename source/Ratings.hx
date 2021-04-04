class Ratings
{
    public static function CalculateRating(noteDiff:Float, ?customSafeZone:Float):String
    {

        if (customSafeZone == null)
        {
            Conductor.safeZoneOffset = (Conductor.safeFrames / 60) * 1000;
            customSafeZone = Conductor.safeZoneOffset;
        }


        // I HATE THIS IF CONDITION
        // IF LEMON SEES THIS I'M SORRY :(

        if (noteDiff > customSafeZone * 0.50) // way early
            return "shit";
        else if (noteDiff > customSafeZone * 0.26) // early
            return "bad";
        else if (noteDiff > customSafeZone * 0.20) // your kinda there
            return "good";
        else if (noteDiff < customSafeZone * -0.20) // little late
            return "good";
        else if (noteDiff < customSafeZone * -0.26) // late
            return "bad";
        else if (noteDiff < customSafeZone * -0.50) // late as fuck
            return "shit";
        return "sick";
    }
}