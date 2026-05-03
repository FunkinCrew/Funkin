package funkin.ui.debug.cameraeditor.components;

#if FEATURE_CAMERA_EDITOR
import haxe.ui.containers.dialogs.Dialog;

/**
 * The dialog that displays when the user accesses the User Guide to learn how to use the Camera Editor.
 */
@:build(haxe.ui.macros.ComponentMacros.build('assets/exclude/data/ui/camera-editor/dialogs/user-guide.xml'))
class UserGuideDialog extends Dialog
{
}
#end
