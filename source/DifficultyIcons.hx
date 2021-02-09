package;

import flixel.FlxSprite;
import flixel.animation.FlxBaseAnimation;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flash.display.BitmapData;
import lime.utils.Assets;
import lime.system.System;
#if sys
import sys.io.File;
import haxe.io.Path;
import openfl.utils.ByteArray;
import sys.FileSystem;
#end
import haxe.Json;
import haxe.format.JsonParser;
using StringTools;
class DifficultyIcons {
  public var group:FlxTypedGroup<FlxSprite>;
  public var width:Float = 0;
  public var difficulty(default,null):Int = 1;
  public final defaultDiff:Int;
  public final difficulties:Array<String>;
  public var activeDiff(get,never):FlxSprite;
  public function new(diff:Array<String>, ?defaultDifficulty:Int = 1,x:Float = 0, y:Float = 0) {
    group = new FlxTypedGroup<FlxSprite>();
    difficulties = diff;
    defaultDiff = defaultDifficulty;
    var diffJson = Json.parse(Assets.getText("assets/images/custom_difficulties/difficulties.json"));
    trace(diff.length);
    for( level in 0...difficulties.length ) {
      var sprDiff = new FlxSprite(x,y);
      sprDiff.offset.x = diffJson.difficulties[level].offset;
      var diffPic:BitmapData;
      var diffXml:String;
      if (FileSystem.exists('assets/images/custom_difficulties/'+diffJson.difficulties[level].name+".png")) {
         diffPic = BitmapData.fromFile('assets/images/custom_difficulties/'+diffJson.difficulties[level].name+".png");
      } else {
         // fall back on base game file to avoid crashes
         diffPic = BitmapData.fromImage(Assets.getImage("assets/images/campaign_menu_UI_assets.png"));
      }
      if (FileSystem.exists('assets/images/custom_difficulties/'+diffJson.difficulties[level].name+".xml")) {
         diffXml = File.getContent('assets/images/custom_difficulties/'+diffJson.difficulties[level].name+".xml");
      } else {
         // fall back on base game file to avoid crashes
         diffXml = Assets.getText("assets/images/campaign_menu_UI_assets.xml");
      }
      sprDiff.frames = FlxAtlasFrames.fromSparrow(diffPic,diffXml);
      sprDiff.animation.addByPrefix('diff', diffJson.difficulties[level].anim);
      sprDiff.animation.play('diff');
      if (defaultDifficulty != level) {
        sprDiff.visible = false;
      }
      trace(sprDiff);
      group.add(sprDiff);
    }
    difficulty = defaultDiff;
    changeDifficulty();
  }
  public function changeDifficulty(?change:Int = 0):Void {
    trace("line 58");
    difficulty += change;
    if (difficulty > difficulties.length - 1) {
      difficulty = 0;
    }
    if (difficulty < 0) {
      difficulty = difficulties.length - 1;
    }
    group.forEach(function (sprite:FlxSprite) {
      sprite.visible = false;
    });
    trace(difficulty);
    trace(group.members);
    group.members[difficulty].visible = true;
    trace("hello");
  }
  public static function changeDifficultyFreeplay(difficultyFP:Int, ?change:Int = 0):Dynamic {
    trace("line 73");
    var diffJson = Json.parse(Assets.getText("assets/images/custom_difficulties/difficulties.json"));
    var difficultiesFP:Array<Dynamic> = diffJson.difficulties;
    var freeplayDiff = difficultyFP;
    freeplayDiff += change;
    if (freeplayDiff > difficultiesFP.length - 1) {
      freeplayDiff = 0;
    }
    if (freeplayDiff < 0) {
      freeplayDiff = difficultiesFP.length - 1;
    }
    trace("line 84");
    var text = difficultiesFP[freeplayDiff].name.toUpperCase();
    trace("lube :flushed:");
    return {difficulty: freeplayDiff, text: text};
  }
  function get_activeDiff():FlxSprite {
    trace("91");
    return group.members[difficulty];
  }
  public function getDiffEnding():String {
    var ending = "";
    if (difficulty != defaultDiff) {
      ending = "-"+difficulties[difficulty];
    }
    return ending;
  }
  public static function getEndingFP(fpDiff:Int):String {
    var diffJson = Json.parse(Assets.getText("assets/images/custom_difficulties/difficulties.json"));
    var difficultiesFP:Array<Dynamic> = diffJson.difficulties;
    var ending = "";
    if (fpDiff != diffJson.defaultDiff) {
      ending = "-"+difficultiesFP[fpDiff].name;
    }
    trace(ending);
    return ending;
  }
  public static function getDefaultDiffFP():Int {
    var diffJson = Json.parse(Assets.getText("assets/images/custom_difficulties/difficulties.json"));
    return diffJson.defaultDiff;
  }
}
