package utilities;

import flixel.FlxG;
import utilities.NoteHandler;

class NoteVariables
{
    public static var Square_Key:String = "SPACE";

    public static var Player_Binds:Array<String> = ["1","2","3","4"];

    public static var Note_Count_Directions:Array<Array<NoteDirection>> = [
        [SQUARE],
        [LEFT, RIGHT],
        [LEFT, SQUARE, RIGHT],
        [LEFT, DOWN, UP, RIGHT],
        [LEFT, DOWN, SQUARE, UP, RIGHT],
        [LEFT, UP, RIGHT, LEFT, DOWN, RIGHT],
        [LEFT, UP, RIGHT, SQUARE, LEFT, DOWN, RIGHT],
        [LEFT, DOWN, UP, RIGHT, LEFT, DOWN, UP, RIGHT],
        [LEFT, DOWN, UP, RIGHT, SQUARE, LEFT, DOWN, UP, RIGHT],
        [LEFT, DOWN, UP, RIGHT, UP, DOWN, LEFT, DOWN, UP, RIGHT]
    ];

    public static var Note_Count_Keybinds:Array<Array<String>> = [
        [Square_Key],
        [Player_Binds[1], Player_Binds[2]],
        [Player_Binds[1], Square_Key, Player_Binds[2]],
        [Player_Binds[0], Player_Binds[1], Player_Binds[2], Player_Binds[3]],
        [Player_Binds[0], Player_Binds[1], Square_Key, Player_Binds[2], Player_Binds[3]],
        ["S","D","F","J","K","L"],
        ["S","D","F", Square_Key, "J","K","L"],
        ["A","S","D","F", "H","J","K","L"],
        ["A","S","D","F", Square_Key, "H","J","K","L"],
        ["Q","W","E","R","V", "N","U","I","O","P"]
    ];

    public static var Other_Note_Anim_Stuff:Array<Array<String>> = [
        ["square"],
        ["left", "right"],
        ["left", "square", "right"],
        ["left", "down", "up", "right"],
        ["left", "down", "square", "up", "right"],
        ["left", "up", "right", "left2", "down", "right2"],
        ["left", "up", "right", "square", "left2", "down", "right2"],
        ["left", "down", "up", "right", "left2", "down2", "up2", "right2"],
        ["left", "down", "up", "right", "square", "left2", "down2", "up2", "right2"],
        ["left", "down", "up", "right", "up2", "down2", "left2", "down2", "up2", "right2"]
    ];

    public static var Character_Animation_Arrays:Array<Array<String>> = [
        ["singUP"],
        ["singLEFT", "singRIGHT"],
        ["singLEFT", "singUP", "singRIGHT"],
        ["singLEFT", "singDOWN", "singUP", "singRIGHT"],
        ["singLEFT", "singDOWN", "singUP", "singUP", "singRIGHT"],
        ["singLEFT", "singUP", "singRIGHT", "singLEFT", "singDOWN", "singRIGHT"],
        ["singLEFT", "singUP", "singRIGHT", "singUP", "singLEFT", "singDOWN", "singRIGHT"],
        ["singLEFT", "singDOWN", "singUP", "singRIGHT", "singLEFT", "singDOWN", "singUP", "singRIGHT"],
        ["singLEFT", "singDOWN", "singUP", "singRIGHT", "singUP", "singLEFT", "singDOWN", "singUP", "singRIGHT"],
        ["singLEFT", "singDOWN", "singUP", "singRIGHT", "singUP", "singDOWN", "singLEFT", "singDOWN", "singUP", "singRIGHT"]
    ];

    public static function updateStuffs()
    {
        Player_Binds = [FlxG.save.data.leftBind,FlxG.save.data.downBind,FlxG.save.data.upBind,FlxG.save.data.rightBind];

        Note_Count_Keybinds = [
            [Square_Key],
            [Player_Binds[0], Player_Binds[3]],
            [Player_Binds[0], Square_Key, Player_Binds[3]],
            [Player_Binds[0], Player_Binds[1], Player_Binds[2], Player_Binds[3]],
            [Player_Binds[0], Player_Binds[1], Square_Key, Player_Binds[2], Player_Binds[3]],
            ["S","D","F","J","K","L"],
            ["S","D","F", Square_Key, "J","K","L"],
            ["A","S","D","F", "H","J","K","L"],
            ["A","S","D","F", Square_Key, "H","J","K","L"],
            ["Q","W","E","R","V", "N","U","I","O","P"]
        ];
    }
}