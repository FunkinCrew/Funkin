package utilities;

import flixel.FlxG;
import states.PlayState;
import lime.utils.Assets;

using StringTools;

class CoolUtil
{
	public static var difficultyArray:Array<String> = ['EASY', "NORMAL", "HARD"];

	public static function difficultyString():String
	{
		return difficultyArray[PlayState.storyDifficulty];
	}

	public static function boundTo(value:Float, min:Float, max:Float):Float {
		var newValue:Float = value;

		if(newValue < min)
			newValue = min;
		else if(newValue > max)
			newValue = max;
		
		return newValue;
	}

	public static function coolTextFile(path:String):Array<String>
	{
		var daList:Array<String> = Assets.getText(path).trim().split('\n');

		for (i in 0...daList.length)
		{
			daList[i] = daList[i].trim();
		}

		return daList;
	}

	public static function coolTextFileOfArrays(path:String, ?delimeter:String = " "):Array<Array<String>>
	{
		var daListOg = coolTextFile(path);

		var daList:Array<Array<String>> = [];

		for(line in daListOg)
		{
			daList.push(line.split(delimeter));
		}

		return daList;
	}

	#if sys
	public static function coolTextFileFromSystem(path:String):Array<String>
	{
		return coolTextFile(path);
		/*
		var daList:Array<String> = File.getContent(Sys.getCwd() + "assets/" + path + ".txt").trim().split('\n');

		for (i in 0...daList.length)
		{
			daList[i] = daList[i].trim();
		}

		return daList;*/
	}

	public static function coolTextFilePolymod(path:String):Array<String>
	{
		return coolTextFile(path);
		/*
		var daList:Array<String> = PolymodAssets.getText(path).trim().split('\n');

		for (i in 0...daList.length)
		{
			daList[i] = daList[i].trim();
		}

		return daList;*/
	}
	#end

	public static function numberArray(max:Int, ?min = 0):Array<Int>
	{
		var dumbArray:Array<Int> = [];
		for (i in min...max)
		{
			dumbArray.push(i);
		}
		return dumbArray;
	}

	public static function openURL(url:String)
	{
		#if linux
		Sys.command('/usr/bin/xdg-open', [url, "&"]);
		#else
		FlxG.openURL(url);
		#end
	}

	public static function coolTextCase(text:String):String
	{
		var returnText:String = "";

		var textArray:Array<String> = text.split(" ");

		for(text in textArray) {
			var textStuffs = text.split("");

			for(i in 0...textStuffs.length)
			{
				if(i != 0)
					returnText += textStuffs[i].toLowerCase();
				else
					returnText += textStuffs[i].toUpperCase();
			}

			returnText += " ";
		}

		return returnText;
	}

	// stolen from psych lmao cuz i'm lazy
	public static function dominantColor(sprite:flixel.FlxSprite):Int
	{
		var countByColor:Map<Int, Int> = [];

		for(col in 0...sprite.frameWidth)
		{
			for(row in 0...sprite.frameHeight)
			{
				var colorOfThisPixel:Int = sprite.pixels.getPixel32(col, row);

				if(colorOfThisPixel != 0)
				{
					if(countByColor.exists(colorOfThisPixel))
						countByColor[colorOfThisPixel] =  countByColor[colorOfThisPixel] + 1;
					else if(countByColor[colorOfThisPixel] != 13520687 - (2*13520687))
						countByColor[colorOfThisPixel] = 1;
				}
			}
		}

		var maxCount = 0;
		var maxKey:Int = 0; // after the loop this will store the max color

		countByColor[flixel.util.FlxColor.BLACK] = 0;

		for(key in countByColor.keys())
		{
			if(countByColor[key] >= maxCount)
			{
				maxCount = countByColor[key];
				maxKey = key;
			}
		}

		return maxKey;
	}
}
