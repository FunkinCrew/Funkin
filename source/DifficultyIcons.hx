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
import tjson.TJSON;
import haxe.format.JsonParser;
using StringTools;
typedef DiffInfo = {
  var difficulty:Int;
  var text:String;
}
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
    var diffJson = CoolUtil.parseJson(Assets.getText("assets/images/custom_difficulties/difficulties.json"));
    trace(diff.length);
    for( level in 0...difficulties.length ) {
      var sprDiff = new FlxSprite(x,y);
      sprDiff.offset.x = diffJson.difficulties[level].offset;
      var diffPic:BitmapData;
      var diffXml:String;
      if (FNFAssets.exists('assets/images/custom_difficulties/'+diffJson.difficulties[level].name+".png")) {
         diffPic = FNFAssets.getBitmapData('assets/images/custom_difficulties/'+diffJson.difficulties[level].name+".png");
      } else {
         // fall back on base game file to avoid crashes
         diffPic = FNFAssets.getBitmapData("assets/images/campaign_menu_UI_assets.png");
      }
      if (FNFAssets.exists('assets/images/custom_difficulties/'+diffJson.difficulties[level].name+".xml")) {
         diffXml = FNFAssets.getText('assets/images/custom_difficulties/'+diffJson.difficulties[level].name+".xml");
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
  public function changeDifficulty(?change:Int = 0, ?week:Int=0):Void {
    difficulty = DifficultyManager.changeDiffStorySans(difficulty, change, week).difficulty; 
    group.forEach(function (sprite:FlxSprite) {
      sprite.visible = false;
    });
    group.members[difficulty].visible = true;
  }
  public static function changeDifficultyFreeplay(difficultyFP:Int, ?change:Int = 0):DiffInfo {
    return DifficultyManager.changeDifficulty(difficultyFP, change);
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
    return DifficultyManager.getDiffEnding(fpDiff);
  }
  public static function getDefaultDiffFP():Int {
    return DifficultyManager.getDefaultDiff();
  }
}
