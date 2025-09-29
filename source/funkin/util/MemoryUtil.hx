package funkin.util;

/**
 * Utilities for working with the garbage collector.
 *
 * HXCPP is built on Immix.
 * HTML5 builds use the browser's built-in mark-and-sweep and JS has no APIs to interact with it.
 * @see https://www.cs.cornell.edu/courses/cs6120/2019fa/blog/immix/
 * @see https://developer.mozilla.org/en-US/docs/Web/JavaScript/Memory_management
 * @see https://betterprogramming.pub/deep-dive-into-garbage-collection-in-javascript-6881610239a
 * @see https://github.com/HaxeFoundation/hxcpp/blob/master/docs/build_xml/Defines.md
 * @see cpp.vm.Gc
 */
@:nullSafety
class MemoryUtil
{
  public static function buildGCInfo():String
  {
    #if cpp
    var result:String = 'HXCPP-Immix:';
    result += '\n- Memory Used: ${cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_USAGE)} bytes';
    result += '\n- Memory Reserved: ${cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_RESERVED)} bytes';
    result += '\n- Memory Current Pool: ${cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_CURRENT)} bytes';
    result += '\n- Memory Large Pool: ${cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_LARGE)} bytes';
    result += '\n- HXCPP Debugger: ${#if HXCPP_DEBUGGER 'Enabled' #else 'Disabled' #end}';
    result += '\n- HXCPP Exp Generational Mode: ${#if HXCPP_GC_GENERATIONAL 'Enabled' #else 'Disabled' #end}';
    result += '\n- HXCPP Exp Moving GC: ${#if HXCPP_GC_MOVING 'Enabled' #else 'Disabled' #end}';
    result += '\n- HXCPP Exp Moving GC: ${#if HXCPP_GC_DYNAMIC_SIZE 'Enabled' #else 'Disabled' #end}';
    result += '\n- HXCPP Exp Moving GC: ${#if HXCPP_GC_BIG_BLOCKS 'Enabled' #else 'Disabled' #end}';
    result += '\n- HXCPP Debug Link: ${#if HXCPP_DEBUG_LINK 'Enabled' #else 'Disabled' #end}';
    result += '\n- HXCPP Stack Trace: ${#if HXCPP_STACK_TRACE 'Enabled' #else 'Disabled' #end}';
    result += '\n- HXCPP Stack Trace Line Numbers: ${#if HXCPP_STACK_LINE 'Enabled' #else 'Disabled' #end}';
    result += '\n- HXCPP Pointer Validation: ${#if HXCPP_CHECK_POINTER 'Enabled' #else 'Disabled' #end}';
    result += '\n- HXCPP Profiler: ${#if HXCPP_PROFILER 'Enabled' #else 'Disabled' #end}';
    result += '\n- HXCPP Local Telemetry: ${#if HXCPP_TELEMETRY 'Enabled' #else 'Disabled' #end}';
    result += '\n- HXCPP C++11: ${#if HXCPP_CPP11 'Enabled' #else 'Disabled' #end}';
    result += '\n- Source Annotation: ${#if annotate_source 'Enabled' #else 'Disabled' #end}';
    #elseif js
    var result:String = 'JS-MNS:';
    result += '\n- Memory Used: ${getGCMemory()} bytes';
    #else
    var result:String = 'Unknown GC';
    #end

    return result;
  }

  public static function supportsTaskMem():Bool
  {
    #if ((cpp && (windows || ios || macos)) || linux || android)
    return true;
    #else
    return false;
    #end
  }

  public static function getTaskMemory():Float
  {
    #if (windows && cpp)
    return funkin.external.windows.WinAPI.getProcessMemoryWorkingSetSize();
    #elseif ((ios || macos) && cpp)
    return funkin.external.apple.MemoryUtil.getCurrentProcessRss();
    #elseif (linux || android)
    try
    {
      #if cpp
      final input:sys.io.FileInput = sys.io.File.read('/proc/${cpp.NativeSys.sys_get_pid()}/status', false);
      #else
      final input:sys.io.FileInput = sys.io.File.read('/proc/self/status', false);
      #end

      final regex:EReg = ~/^VmRSS:\s+(\d+)\s+kB/m;
      var line:String;
      do
      {
        if (input.eof())
        {
          input.close();
          return 0.0;
        }
        line = input.readLine();
      }
      while (!regex.match(line));

      input.close();

      final kb:Float = Std.parseFloat(regex.matched(1));

      if (kb != Math.NaN)
      {
        return kb * 1024.0;
      }
    }
    catch (e:Dynamic) {}
    #end

    return 0.0;
  }

  public static function getGCMemory():Float
  {
    return openfl.system.System.totalMemoryNumber;
  }

  /**
   * Enable garbage collection if it was previously disabled.
   */
  public static function enable():Void
  {
    #if cpp
    cpp.vm.Gc.enable(true);
    #else
    throw 'Not implemented!';
    #end
  }

  /**
   * Disable garbage collection entirely.
   */
  public static function disable():Void
  {
    #if cpp
    cpp.vm.Gc.enable(false);
    #else
    throw 'Not implemented!';
    #end
  }

  /**
   * Manually perform garbage collection once.
   * Should only be called from the main thread.
   * @param major `true` to perform major collection, whatever that means.
   */
  public static function collect(major:Bool = false):Void
  {
    #if cpp
    cpp.vm.Gc.run(major);
    #else
    throw 'Not implemented!';
    #end
  }

  /**
   * Perform major garbage collection repeatedly until less than 16kb of memory is freed in one operation.
   * Should only be called from the main thread.
   *
   * NOTE: This is DIFFERENT from actual compaction,
   */
  public static function compact():Void
  {
    #if cpp
    cpp.vm.Gc.compact();
    #else
    throw 'Not implemented!';
    #end
  }
}
