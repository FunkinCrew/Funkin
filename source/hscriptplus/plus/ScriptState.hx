package hscriptplus.plus;

import haxe.CallStack;
import hscriptplus.Expr;

using StringTools;

class ScriptState {
	public var variables(get, null):Map<String, Dynamic>; function get_variables() return _interp.variables;

	public var getFileContent:String->String 
	#if sys = sys.io.File.getContent 
	#elseif openfl = openfl.Assets.getText
	#end; 

	public var getScriptPaths:Void->Array<String> #if openfl = () -> openfl.Assets.list() #end;

	public var getScriptPathsFromDirectory:String->Array<String> #if sys = sys.FileSystem.readDirectory #end;

	public var scriptDirectory(default, set):String;

	/**
	 *  If set to `true`, rethrow errors
	 *  or just trace the errors when set to `false`
	 */
	public var rethrowError:Bool = #if debug true #else false #end;

	/**
	 *  The last Expr executed
	 *  Used for debugging
	 */
	public var ast(default, null):Expr;

	/**
	 *  The last path whose text was executed
	 *  Used for debugging
	 */
	public var path(default, null):String;

	/**
	 *  Map<PackageName, Path>
	 */
	var _scriptPathMap = new Map<String, String>();

	var _parser:ParserPlus;
	var _interp:InterpPlus;

	public function new() {
		_parser = new ParserPlus();
		_parser.allowTypes = true;
		
		_interp = new InterpPlus();
		_interp.setResolveImportFunction(resolveImport);
	}

	function resolveImport(packageName:String):Dynamic {
		var scriptPath = _scriptPathMap.get(packageName);
		executeFile(scriptPath);
		var className = packageName.split(".").pop();
		return get(className);
	}
	
	public inline function get(name:String):Dynamic {
		return _interp.variables.get(name);
	}
	
 	public inline function set(name:String, val:Dynamic) {
		_interp.variables.set(name, val);
	}

	public function executeFile(path:String) {
		if (getFileContent == null) {
			error("Provide a getFileContent function first!");
			if (!rethrowError)
				return null;
		}
		this.path = path;
		var script = getFileContent(path);
		return executeString(script);
	}

	public function executeString(script:String):Dynamic {
		ast = parseScript(script);
		return execute(ast);
	}

	function parseScript(script:String):Null<Expr> {
		try {
			return _parser.parseString(script, path);
		}
		catch (e:Dynamic) {
			#if hscriptPos 
			error('$path:${e.line}: characters ${e.pmin} - ${e.pmax}: $e'); 
			#else 
			error(e); 
			#end 
			return null;
		}
	}
	
	function execute(ast:Expr):Dynamic {
		try {
			var val = _interp.execute(ast);
			var main = get("main");
			
			if (main != null && Reflect.isFunction(main))
				return main();
			else return val;
		}
		catch (e:Dynamic) {
			error(e + CallStack.toString(CallStack.exceptionStack()));
			trace('Debug AST: $ast');
		}
		return null;
	}

	function error(e:Dynamic) {
		if (rethrowError)
			throw e;
		else trace(e);
	}

	function set_scriptDirectory(newDirectory:String) {
		if (!newDirectory.endsWith("/"))
			newDirectory += "/";
		loadScriptFromDirectory(scriptDirectory = newDirectory);
		return newDirectory;
	}

	/**
	 *  Create a map of package name as keys to paths
	 *  @param directory The directory containing the script files
	 */
	function loadScriptFromDirectory(directory:String) {
		var paths:Array<String> = null;
		
		if (getScriptPaths != null)
			paths = getScriptPaths();
		else if (getScriptPathsFromDirectory != null)
			paths = getScriptPathsFromDirectory(directory);
		else error('Provide a function for getScriptPaths or getScriptPathsFromDirectory');

		// filter out paths not ending with ".hx"
		paths = paths.filter(path -> path.endsWith(".hx"));
		// prepend the directory to the path if it doesn't start with the directory
		paths = paths.map(path ->{
			return
			if (path.startsWith(directory))
				path
			else directory + path;
		});
		
		_scriptPathMap = [ for (path in paths) getPackageName(path) => path ];
	}
	
	function getPackageName(path:String) {
		path = path.replace(scriptDirectory, "");
		path = path.replace(".hx", "");
		return path.replace("/", ".");
	}
}