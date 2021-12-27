package utilities;

class NoteVariables
{
    public static var Note_Count_Directions:Array<Array<String>>;

    public static var Default_Binds:Array<Array<String>>;

    public static var Other_Note_Anim_Stuff:Array<Array<String>>;

    public static var Character_Animation_Arrays:Array<Array<String>>;

    public static function init()
    {
        Note_Count_Directions = CoolUtil.coolTextFileOfArrays(Paths.txt("mania data/maniaDirections"));
        Default_Binds = CoolUtil.coolTextFileOfArrays(Paths.txt("mania data/defaultBinds"));
        Other_Note_Anim_Stuff = CoolUtil.coolTextFileOfArrays(Paths.txt("mania data/maniaAnimationDirections"));
        Character_Animation_Arrays = CoolUtil.coolTextFileOfArrays(Paths.txt("mania data/maniaCharacterAnimations"));
    }
}