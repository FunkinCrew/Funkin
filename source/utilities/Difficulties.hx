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

    public static function stringToNum(string:String):Int
    {
        var selected_Difficulty:Int = 1;

        switch(string.toLowerCase())
        {
            case 'easy':
                selected_Difficulty = 0;
            case 'normal':
                selected_Difficulty = 1;
            case 'hard':
                selected_Difficulty = 2;
        }

        return selected_Difficulty;
    }
}