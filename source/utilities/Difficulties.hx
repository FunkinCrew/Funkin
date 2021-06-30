package utilities;

enum Difficulty
{
    Easy;
    Normal;
    Hard;
    Undefined;
}

class Difficulties
{
    public static function numToDiff(number:Int):Difficulty
    {
        var selected_Difficulty:Difficulty = Undefined;

        switch(number)
        {
            case 0:
                selected_Difficulty = Easy;
            case 1:
                selected_Difficulty = Normal;
            case 2:
                selected_Difficulty = Hard;
        }

        return selected_Difficulty;
    }
}