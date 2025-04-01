#if !macro
// Only import these when we aren't in a macro.
import funkin.util.Constants;
import funkin.Paths;
import flixel.FlxG; // This one in particular causes a compile error if you're using macros.

// These are great.
using Lambda;
using StringTools;
using funkin.util.tools.ArrayTools;
using funkin.util.tools.ArraySortTools;
using funkin.util.tools.IteratorTools;
using funkin.util.tools.MapTools;
using funkin.util.tools.StringTools;
#end

// Testing-specific
// Mocking
import mockatoo.Mockatoo.*;

using mockatoo.Mockatoo;
