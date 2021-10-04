package utilities;

import flixel.FlxG;
import utilities.NoteHandler;

class NoteVariables
{
    public static var Square_Key:String = "SPACE";

    public static var Player_Binds:Array<String> = ["1","2","3","4"];

    public static var Note_Count_Directions:Array<Array<NoteDirection>> = [ // haha hardcoded stuff go brrrr
        [SQUARE], // GD
        [LEFT, RIGHT], // GD 2P
        [LEFT, SQUARE, RIGHT], // 3
        [LEFT, DOWN, UP, RIGHT], // 4
        [LEFT, DOWN, SQUARE, UP, RIGHT], // GH
        [LEFT, UP, RIGHT, LEFT, DOWN, RIGHT], // S
        [LEFT, UP, RIGHT, SQUARE, LEFT, DOWN, RIGHT], // 7
        [LEFT, DOWN, UP, RIGHT, LEFT, DOWN, UP, RIGHT], // 8
        [LEFT, DOWN, UP, RIGHT, SQUARE, LEFT, DOWN, UP, RIGHT], // THS
        [LEFT, DOWN, UP, RIGHT, RUP, RDOWN, LEFT, DOWN, UP, RIGHT], // 10
        [LEFT, DOWN, UP, RIGHT, RUP, PLUS, RDOWN, LEFT, DOWN, UP, RIGHT], // 11
        [LEFT, DOWN, UP, RIGHT, RLEFT, RDOWN, RUP, RRIGHT, LEFT, DOWN, UP, RIGHT], // 12
        [LEFT, DOWN, UP, RIGHT, RLEFT, RRIGHT, SQUARE, RLEFT, RRIGHT,LEFT, DOWN, UP, RIGHT], // 13
        [LEFT, DOWN, UP, RIGHT, RLEFT, RRIGHT, SQUARE, PLUS, RLEFT, RRIGHT, LEFT, DOWN, UP, RIGHT], // 14
        [LEFT, DOWN, UP, RIGHT, RLEFT, RRIGHT, RUP, PLUS, RUP, RLEFT, RRIGHT, LEFT, DOWN, UP, RIGHT], // 15
        [LEFT, DOWN, UP, RIGHT, RLEFT, RRIGHT, RLEFT, RRIGHT, RUP, RDOWN, RUP, RDOWN, LEFT, DOWN, UP, RIGHT], // 16
        [LEFT, DOWN, UP, RIGHT, PLUS, RLEFT, SQUARE, RDOWN, PLUS, RUP, SQUARE, RRIGHT, PLUS, LEFT, DOWN, UP, RIGHT], // 17
        [LEFT, DOWN, UP, RIGHT, LEFT, DOWN, UP, RIGHT, SQUARE, PLUS, RLEFT, RDOWN, RUP, RRIGHT, RLEFT, RDOWN, RUP, RRIGHT] // 18
    ];

    public static var Note_Count_Keybinds:Array<Array<String>> = [
        [Square_Key], // Geometry Dash
        [Player_Binds[0], Player_Binds[3]], // Geometry Dash 2P
        [Player_Binds[0], Square_Key, Player_Binds[3]], // 3
        [Player_Binds[0], Player_Binds[1], Player_Binds[2], Player_Binds[3]], // 4
        [Player_Binds[0], Player_Binds[1], Square_Key, Player_Binds[2], Player_Binds[3]], // Guitar Hero
        ["S","D","F","J","K","L"], // Shag
        ["S","D","F", Square_Key, "J","K","L"], // 7
        ["A","S","D","F", "H","J","K","L"], // 8
        ["A","S","D","F", Square_Key, "H","J","K","L"], // Tryhard Shag
        ["Q","W","E","R","V","N","U","I","O","P"], // 10
        ["Q","W","E","R","V",Square_Key,"N","U","I","O","P"], // 11
        ["Q","W","E","R","D","F","J","K","U","I","O","P"], // 12
        ["Q","W","E","R","D","F",Square_Key,"J","K","U","I","O","P"], // 13
        ["Q","W","E","R","S","D","F","J","K","L","U","I","O","P"], // 14
        ["Q","W","E","R","S","D","F",Square_Key,"J","K","L","U","I","O","P"], // 15
        ["Q","W","E","R","A","S","D","F","H","J","K","L","U","I","O","P"], // 16
        ["Q","W","E","R","A","S","D","F",Square_Key,"H","J","K","L","U","I","O","P"], // 17
        ["Q","W","E","R","A","S","D","F","V","B","H","J","K","L","U","I","O","P"] // doh tree ding doh tree ultimate (18)
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
        ["left", "down", "up", "right", "rup", "rdown", "left2", "down2", "up2", "right2"],
        ["left", "down", "up", "right", "rup", "plus", "rdown", "left2", "down2", "up2", "right2"], // 11 
        ["left", "down", "up", "right", "rleft", "rdown", "rup", "rright", "left2", "down2", "up2", "right2"], // 12
        ["left", "down", "up", "right", "rleft", "rright", "square", "rleft2", "rright2", "left2", "down2", "up2", "right2"], // 13
        ["left", "down", "up", "right", "rleft", "rright", "square", "plus", "rleft2", "rright2", "left2", "down2", "up2", "right2"], // 14
        ["left", "down", "up", "right", "rleft", "rright", "rup", "plus", "rup2", "rleft2", "rright2", "left2", "down2", "up2", "right2"], // 15
        ["left", "down", "up", "right", "rleft", "rright2", "rleft2", "rright", "rup", "rdown2", "rup2", "rdown", "left2", "down2", "up2", "right2"], // 16
        ["left", "down", "up", "right", "plus", "rleft", "square", "rdown", "plus", "rup", "square", "rright", "plus", "left2", "down2", "up2", "right2"], // 17
        ["left", "down", "up", "right", "left2", "down2", "up2", "right2", "square", "plus", "rleft", "rdown", "rup", "rright", "rleft2", "rdown2", "rup2", "rright2"] // uhh 18
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
        ["singLEFT", "singDOWN", "singUP", "singRIGHT", "singUP", "singDOWN", "singLEFT", "singDOWN", "singUP", "singRIGHT"], // 10
        ["singLEFT", "singDOWN", "singUP", "singRIGHT", "singUP", "singDOWN", "singLEFT", "singDOWN", "singUP", "singRIGHT","singLEFT"], // 11
        ["singLEFT", "singDOWN", "singUP", "singRIGHT", "singUP", "singDOWN", "singLEFT", "singDOWN", "singUP", "singRIGHT","singLEFT", "singDOWN"], // 12
        ["singLEFT", "singDOWN", "singUP", "singRIGHT", "singUP", "singDOWN", "singLEFT", "singDOWN", "singUP", "singRIGHT","singLEFT", "singDOWN", "singUP"], // 13
        ["singLEFT", "singDOWN", "singUP", "singRIGHT", "singUP", "singDOWN", "singLEFT", "singDOWN", "singUP", "singRIGHT","singLEFT", "singDOWN", "singUP", "singRIGHT"], // 14
        ["singLEFT", "singDOWN", "singUP", "singRIGHT", "singUP", "singDOWN", "singLEFT", "singDOWN", "singUP", "singRIGHT","singLEFT", "singDOWN", "singUP", "singRIGHT","singLEFT"], // 15
        ["singLEFT", "singDOWN", "singUP", "singRIGHT", "singUP", "singDOWN", "singLEFT", "singDOWN", "singUP", "singRIGHT","singLEFT", "singDOWN", "singUP", "singRIGHT","singLEFT", "singDOWN"], // 16
        ["singLEFT", "singDOWN", "singUP", "singRIGHT", "singUP", "singDOWN", "singLEFT", "singDOWN", "singUP", "singRIGHT","singLEFT", "singDOWN", "singUP", "singRIGHT","singLEFT", "singDOWN","singUP"], // 17
        ["singLEFT", "singDOWN", "singUP", "singRIGHT", "singLEFT", "singDOWN", "singUP", "singRIGHT", "singUP", "singDOWN", "singLEFT", "singDOWN", "singUP", "singRIGHT", "singLEFT", "singDOWN", "singUP", "singRIGHT"] // 18
    ];

    public static function updateStuffs()
    {
        Player_Binds = [FlxG.save.data.leftBind,FlxG.save.data.downBind,FlxG.save.data.upBind,FlxG.save.data.rightBind];

        Note_Count_Keybinds = [
            [Square_Key], // Geometry Dash
            [Player_Binds[0], Player_Binds[3]], // Geometry Dash 2P
            [Player_Binds[0], Square_Key, Player_Binds[3]], // 3
            [Player_Binds[0], Player_Binds[1], Player_Binds[2], Player_Binds[3]], // 4
            [Player_Binds[0], Player_Binds[1], Square_Key, Player_Binds[2], Player_Binds[3]], // Guitar Hero
            ["S","D","F","J","K","L"], // Shag
            ["S","D","F", Square_Key, "J","K","L"], // 7
            ["A","S","D","F", "H","J","K","L"], // 8
            ["A","S","D","F", Square_Key, "H","J","K","L"], // Tryhard Shag
            ["Q","W","E","R","V", "N","U","I","O","P"], // 10
            ["Q","W","E","R","V","B","N","U","I","O","P"], // 11
            ["Q","W","E","R","D","F","J","K","U","I","O","P"], // 12
            ["Q","W","E","R","D","F",Square_Key,"J","K","U","I","O","P"], // 13
            ["Q","W","E","R","S","D","F","J","K","L","U","I","O","P"], // 14
            ["Q","W","E","R","S","D","F",Square_Key,"J","K","L","U","I","O","P"], // 15
            ["Q","W","E","R","A","S","D","F","H","J","K","L","U","I","O","P"], // 16
            ["Q","W","E","R","A","S","D","F",Square_Key,"H","J","K","L","U","I","O","P"], // 17
            ["Q","W","E","R","A","S","D","F","V","N","H","J","K","L","U","I","O","P"], // 18
            ["Q","W","E","R","A","S","D","F","V","B","N","H","J","K","L","U","I","O","P"], // 19
            ["Q","W","E","R","A","S","D","F","C","V","N","M","H","J","K","L","U","I","O","P"], // 20
            ["Q","W","E","R","A","S","D","F","C","V",Square_Key,"N","M","H","J","K","L","U","I","O","P"] // 21, Holy shit..
        ];
    }
}