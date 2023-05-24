package game.data.scripts;

#if HSCRIPT_ALLOWED
import hscript.Expr;
import hscript.Interp;
import hscript.Parser;
#end

#if sys
import sys.FileSystem;
import sys.io.File;
#end

import openfl.utils.Assets;

import game.state.PlayState;

using StringTools;

/*
    Class That Handles Everything Related To Scripts.

    @author Zyflx
*/

#if HSCRIPT_ALLOWED
class Script
{ 
    public var interp:Interp;
    public var parser:Parser;
    
    public var scriptName:String = '';
    
    public function new(scriptName:String)
    {  
        // Initialize the interpreter and the script parser
        interp = new Interp();
        parser = new Parser();
        
        var scriptFile:String = scriptName;
        if (!FileSystem.exists(scriptFile))
            scriptFile = null;
        else
            this.scriptName = scriptName;
            
        try {
            if (scriptFile != null)
            {
                parser.allowJSON = true;
                parser.allowTypes = true;
                parser.allowMetadata = true;
                
                // Predefined imports for scripts.

                // Haxe Stuff
                set('Math', Math);
                set('Std', Std);
                set('Type', Type);
                set('Date', Date);

                // Flixel Stuff
                set('FlxG', flixel.FlxG);
                set('FlxSprite', flixel.FlxSprite);
                set('FlxCamera', flixel.FlxCamera);
                set('FlxText', flixel.text.FlxText);
                set('FlxSound', flixel.system.FlxSound);
                set('FlxTween', flixel.tweens.FlxTween);
                set('FlxEase', flixel.tweens.FlxEase);
                set('FlxTimer', flixel.util.FlxTimer);

                // Engine Stuff
                set('Paths', Paths);
                set('CoolUtil', CoolUtil);
                set('PlayState', game.state.PlayState);
                set('game', game.state.PlayState.instance);
                set('Conductor', game.data.backend.Conductor);
                set('Character', game.objects.Character);
                set('Boyfriend', game.objects.Boyfriend);
                set('Preferences', game.state.menus.options.PreferencesMenu); // just in case you ever want to check if downscroll if on or somethin in a script
            
                interp.execute(parser.parseString(Paths.getContent(scriptFile)));
            }
        } catch(e:haxe.Exception) {
            trace('Something went wrong while trying to initialize script $scriptName');
        }
    }

    /*
        Runs scripts from the desired folder/folders.
        
        @param scriptArr The array you want to push the scripts to. (NOTE: Make sure that the array you want to push the scripts to is a Array<Script>)
        @param folder The folder/folders you want the function to check for scripts.
        
        Example Usage:
        Since you are gonna be using this function in other classes, it should look something like this:
        Script.runScripts(theArray, ['folderName']) // you also can put more than one folder in the arg if needed:
        ['folder', 'folder2']
    */
    public static function runScripts(scriptArr:Array<Script>, folders:Array<String>)
    {
        var foldersToCheck:Array<String> = folders;

        for (i in 0...foldersToCheck.length)
        {
            var scriptList:Array<Array<String>> = [getScriptsFromFolder(foldersToCheck[i])];
            for (list in scriptList)
            {
                for (script in list)
                {
                    if (list != null && list.length > 0)
                    {
                        if (script != null && script.endsWith('.hx'))
                        {
                            scriptArr.push(new Script(Paths.getPreloadPath(foldersToCheck[i] + '/$script')));
                            trace('succesfully ran ' + scriptArr.length + ' scripts.');   
                        }
                    }
                }
            }
        }
        if (scriptArr != null) for (scripts in scriptArr) { scripts.callFunction('create'); }
        return scriptArr;
    }
    
    /*
        Sets a gloabal variable on all scripts.
        
        @param variable The variable you want to set
        @param value The value you want to apply to the variable
    */
    public function set(variable:String, value:Dynamic)
    {
        if (interp == null) return;
        interp.variables.set(variable, value);
    }
    
    public function get(variable:String)
    {
        if (interp == null) return;
        interp.variables.get(variable);
    }
    
    /*
        Calls a function on all scripts.
        
        @param func The function you want to call
        @param args The arguments in the script if any
    */
    public function callFunction(func:String, ?args:Array<Dynamic>)
    {
        if (interp == null) return;
        if (args == null) args = [];
        
        var func:Dynamic = interp.variables.get(func);
        if (func != null && Reflect.isFunction(func))
        {
            try {
                Reflect.callMethod(null, func, args);
            }
            catch(e:haxe.Exception) {
                trace('Something went wrong when trying to call function $func on script $scriptName');
            }
        }
    }

    /*
        Grabs scripts from the specified folder.
        
        @param folder The Folder you want to grab scripts from
        @return An array containing all of the scripts in the folder
    */
    public static function getScriptsFromFolder(folder:String)
    {
        if (!folder.endsWith('/'))
            folder = '$folder/';

        var scriptPath:String = Paths.getPath(folder);
        var absPath:String = FileSystem.absolutePath(scriptPath);
        var dir:Array<String> = FileSystem.readDirectory(absPath);
        return (dir != null ? dir : []); // Returns an empty array if the folder specified doesn't exist to prevent a crash
    }
}
#else
/*
    HScript doesn't work on your platform
    L Bozo
*/
class Script
{
    public function new(scriptName:String) {}
    public function get(var:String) { return null; }
    public function set(var:String, val:Dynamic) { return null; }
    public function callFunction(func:String, args:Array<Dynamic>) { return null; }
}
#end