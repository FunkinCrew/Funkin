package funkin.ui.debug.stageeditor.components;

#if FEATURE_STAGE_EDITOR
import haxe.ui.containers.dialogs.Dialog;

@:build(haxe.ui.macros.ComponentMacros.build("assets/exclude/data/ui/stage-editor/dialogs/user-guide.xml"))
class UserGuideDialog extends Dialog {}
#end
