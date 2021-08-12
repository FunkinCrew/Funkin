package utilities;

class NoteHandler
{
    public static function getBinds(keyCount:Int):Array<String>
    {
        NoteVariables.updateStuffs();
        return NoteVariables.Note_Count_Keybinds[keyCount - 1];
    }
}

enum NoteDirection
{
    UP;
    DOWN;
    LEFT;
    RIGHT;
    SQUARE;
    RUP;
    RDOWN;
    RLEFT;
    RRIGHT;
    PLUS;
}