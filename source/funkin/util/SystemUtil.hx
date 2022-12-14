package funkin.util;

import haxe.io.Path;
import haxe.io.Bytes;
import haxe.io.BytesOutput;
import haxe.io.Eof;
import haxe.zip.Entry;
import haxe.zip.Writer;
import haxe.Json;
import haxe.Template;
import sys.io.File;
import sys.io.Process;
import sys.FileSystem;

class SystemUtil
{
	public static var hostArchitecture(get, never):HostArchitecture;
	public static var hostPlatform(get, never):HostPlatform;
	public static var processorCores(get, never):Int;
	private static var _hostArchitecture:HostArchitecture;
	private static var _hostPlatform:HostPlatform;
	private static var _processorCores:Int = 0;

	private static function get_hostPlatform():HostPlatform
	{
		if (_hostPlatform == null)
		{
			if (new EReg("window", "i").match(Sys.systemName()))
			{
				_hostPlatform = WINDOWS;
			}
			else if (new EReg("linux", "i").match(Sys.systemName()))
			{
				_hostPlatform = LINUX;
			}
			else if (new EReg("mac", "i").match(Sys.systemName()))
			{
				_hostPlatform = MAC;
			}

			trace("", " - \x1b[1mDetected host platform:\x1b[0m " + Std.string(_hostPlatform).toUpperCase());
		}

		return _hostPlatform;
	}

	private static function get_hostArchitecture():HostArchitecture
	{
		if (_hostArchitecture == null)
		{
			switch (hostPlatform)
			{
				case WINDOWS:
					var architecture = Sys.getEnv("PROCESSOR_ARCHITECTURE");
					var wow64Architecture = Sys.getEnv("PROCESSOR_ARCHITEW6432");

					if (architecture.indexOf("64") > -1 || wow64Architecture != null && wow64Architecture.indexOf("64") > -1)
					{
						_hostArchitecture = X64;
					}
					else
					{
						_hostArchitecture = X86;
					}

				case LINUX, MAC:
					#if nodejs
					switch (js.Node.process.arch)
					{
						case "arm":
							_hostArchitecture = ARMV7;

						case "x64":
							_hostArchitecture = X64;

						default:
							_hostArchitecture = X86;
					}
					#else
					var process = new Process("uname", ["-m"]);
					var output = process.stdout.readAll().toString();
					var error = process.stderr.readAll().toString();
					process.exitCode();
					process.close();

					if (output.indexOf("armv6") > -1)
					{
						_hostArchitecture = ARMV6;
					}
					else if (output.indexOf("armv7") > -1)
					{
						_hostArchitecture = ARMV7;
					}
					else if (output.indexOf("64") > -1)
					{
						_hostArchitecture = X64;
					}
					else
					{
						_hostArchitecture = X86;
					}
					#end

				default:
					_hostArchitecture = ARMV6;
			}

			trace("", " - \x1b[1mDetected host architecture:\x1b[0m " + Std.string(_hostArchitecture).toUpperCase());
		}

		return _hostArchitecture;
	}

	private static function get_processorCores():Int
	{
		if (_processorCores < 1)
		{
			var result = null;

			if (hostPlatform == WINDOWS)
			{
				var env = Sys.getEnv("NUMBER_OF_PROCESSORS");

				if (env != null)
				{
					result = env;
				}
			}
			else if (hostPlatform == LINUX)
			{
				result = runProcess("", "nproc", null, true, true, true);

				if (result == null)
				{
					var cpuinfo = runProcess("", "cat", ["/proc/cpuinfo"], true, true, true);

					if (cpuinfo != null)
					{
						var split = cpuinfo.split("processor");
						result = Std.string(split.length - 1);
					}
				}
			}
			else if (hostPlatform == MAC)
			{
				var cores = ~/Total Number of Cores: (\d+)/;
				var output = runProcess("", "/usr/sbin/system_profiler", ["-detailLevel", "full", "SPHardwareDataType"]);

				if (cores.match(output))
				{
					result = cores.matched(1);
				}
			}

			if (result == null || Std.parseInt(result) < 1)
			{
				_processorCores = 1;
			}
			else
			{
				_processorCores = Std.parseInt(result);
			}
		}

		return _processorCores;
	}

	public static function runProcess(path:String, command:String, args:Array<String> = null, waitForOutput:Bool = true, safeExecute:Bool = true,
			ignoreErrors:Bool = false, print:Bool = false, returnErrorValue:Bool = false):String
	{
		if (print)
		{
			var message = command;

			if (args != null)
			{
				for (arg in args)
				{
					if (arg.indexOf(" ") > -1)
					{
						message += " \"" + arg + "\"";
					}
					else
					{
						message += " " + arg;
					}
				}
			}

			Sys.println(message);
		}

		#if (haxe_ver < "3.3.0")
		command = Path.escape(command);
		#end

		if (safeExecute)
		{
			try
			{
				if (path != null
					&& path != ""
					&& !FileSystem.exists(FileSystem.fullPath(path))
					&& !FileSystem.exists(FileSystem.fullPath(new Path(path).dir)))
				{
					trace("The specified target path \"" + path + "\" does not exist");
				}

				return _runProcess(path, command, args, waitForOutput, safeExecute, ignoreErrors, returnErrorValue);
			}
			catch (e:Dynamic)
			{
				if (!ignoreErrors)
				{
					trace("", e);
				}

				return null;
			}
		}
		else
		{
			return _runProcess(path, command, args, waitForOutput, safeExecute, ignoreErrors, returnErrorValue);
		}
	}

	private static function _runProcess(path:String, command:String, args:Null<Array<String>>, waitForOutput:Bool, safeExecute:Bool, ignoreErrors:Bool,
		returnErrorValue:Bool):String
{
	var oldPath:String = "";

	if (path != null && path != "")
	{
		trace("", " - \x1b[1mChanging directory:\x1b[0m " + path + "");

		oldPath = Sys.getCwd();
		Sys.setCwd(path);
	}

	var argString = "";

	if (args != null)
	{
		for (arg in args)
		{
			if (arg.indexOf(" ") > -1)
			{
				argString += " \"" + arg + "\"";
			}
			else
			{
				argString += " " + arg;
			}
		}
	}

	trace("", " - \x1b[1mRunning process:\x1b[0m " + command + argString);

	var output = "";
	var result = 0;

	var process:Process;

	if (args != null && args.length > 0)
	{
		process = new Process(command, args);
	}
	else
	{
		process = new Process(command);
	}

	if (waitForOutput)
	{
		var buffer = new BytesOutput();
		var waiting = true;

		while (waiting)
		{
			try
			{
				var current = process.stdout.readAll(1024);
				buffer.write(current);

				if (current.length == 0)
				{
					waiting = false;
				}
			}
			catch (e:Eof)
			{
				waiting = false;
			}
		}

		result = process.exitCode();

		output = buffer.getBytes().toString();

		if (output == "")
		{
			var error = process.stderr.readAll().toString();
			process.close();

			if (result != 0 || error != "")
			{
				if (ignoreErrors)
				{
					output = error;
				}
				else if (!safeExecute)
				{
					throw error;
				}
				else
				{
					trace(error);
				}

				if (returnErrorValue)
				{
					return output;
				}
				else
				{
					return null;
				}
			}

			/*if (error != "") {
				trace (error);
			}*/
		}
		else
		{
			process.close();
		}
	}

	if (oldPath != "")
	{
		Sys.setCwd(oldPath);
	}

	return output;
}

	public static function getTempDirectory(extension:String = ""):String
	{
		#if (flash || html5)
		return null;
		#else
		var path = "";

		if (hostPlatform == WINDOWS)
		{
			path = Sys.getEnv("TEMP");
		}
		else
		{
			path = Sys.getEnv("TMPDIR");

			if (path == null)
			{
				path = "/tmp";
			}
		}

		path = Path.join([path, "Funkin"]);

		return path;
		#end
	}
}

enum HostArchitecture
{
	ARMV6;
	ARMV7;
	X86;
	X64;
}

@:enum abstract HostPlatform(String) from String to String
{
	public var WINDOWS = "windows";
	public var MAC = "mac";
	public var LINUX = "linux";
}
