package funkin.util.macro;

import haxe.macro.Expr;
#if macro
import sys.FileSystem;
#end

using StringTools;

class DataMacro
{
  public static macro function listBaseGameStageIds():Expr
  {
    var folder = "assets/preload/data/stages/";
    var files = FileSystem.readDirectory(folder);
    var stages:Array<Expr> = [];

    for (file in files)
      stages.push(macro $v{file.replace(".json", "")});

    return macro $a{stages};
  }

  public static macro function listBaseGameSongIds():Expr
  {
    var folder = "assets/songs/";
    var files = FileSystem.readDirectory(folder);
    var songs:Array<Expr> = [];

    for (file in files)
      songs.push(macro $v{file});

    return macro $a{songs};
  }

  public static macro function listBaseGameLevelIds():Expr
  {
    var folder = "assets/preload/data/levels/";
    var files = FileSystem.readDirectory(folder);
    var levels:Array<Expr> = [];

    for (file in files)
      levels.push(macro $v{file.replace(".json", "")});

    return macro $a{levels};
  }

  public static macro function listBaseGamePlayerIds():Expr
  {
    var folder = "assets/preload/data/players/";
    var files = FileSystem.readDirectory(folder);
    var players:Array<Expr> = [];

    for (file in files)
      players.push(macro $v{file.replace(".json", "")});

    return macro $a{players};
  }
}
