package funkin.ui.debug.charting;

import haxe.ui.components.DropDown;
import haxe.ui.containers.Group;
import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.events.UIEvent;

/**
 * Available tools for the chart editor state.
 */
enum ChartEditorToolMode
{
	Select;
	Place;
}

class ChartEditorToolboxHandler
{
	public static function setToolboxState(state:ChartEditorState, id:String, shown:Bool):Void
	{
		if (shown)
			showToolbox(state, id);
		else
			hideToolbox(state, id);
	}

	public static function showToolbox(state:ChartEditorState, id:String)
	{
		var toolbox:Dialog = state.activeToolboxes.get(id);

		if (toolbox == null)
			toolbox = initToolbox(state, id);

		if (toolbox != null)
		{
			toolbox.showDialog(false);
		}
		else
		{
			trace('ChartEditorToolboxHandler.showToolbox() - Could not retrieve toolbox: $id');
		}
	}

	public static function hideToolbox(state:ChartEditorState, id:String):Void
	{
		var toolbox:Dialog = state.activeToolboxes.get(id);

		if (toolbox == null)
			toolbox = initToolbox(state, id);

		if (toolbox != null)
		{
			toolbox.hideDialog(DialogButton.CANCEL);
		}
		else
		{
			trace('ChartEditorToolboxHandler.hideToolbox() - Could not retrieve toolbox: $id');
		}
	}

	public static function minimizeToolbox(state:ChartEditorState, id:String):Void
	{
	}

	public static function maximizeToolbox(state:ChartEditorState, id:String):Void
	{
	}

	public static function initToolbox(state:ChartEditorState, id:String):Dialog
	{
		var toolbox:Dialog = null;
		switch (id)
		{
			case ChartEditorState.CHART_EDITOR_TOOLBOX_TOOLS_LAYOUT:
				toolbox = buildToolboxToolsLayout(state);
			case ChartEditorState.CHART_EDITOR_TOOLBOX_NOTEDATA_LAYOUT:
				toolbox = buildToolboxNoteDataLayout(state);
			case ChartEditorState.CHART_EDITOR_TOOLBOX_EVENTDATA_LAYOUT:
				toolbox = buildToolboxEventDataLayout(state);
			case ChartEditorState.CHART_EDITOR_TOOLBOX_SONGDATA_LAYOUT:
				toolbox = buildToolboxSongDataLayout(state);
			default:
				trace('ChartEditorToolboxHandler.initToolbox() - Unknown toolbox ID: $id');
				toolbox = null;
		}

		state.activeToolboxes.set(id, toolbox);

		return toolbox;
	}

	static function buildToolboxToolsLayout(state:ChartEditorState):Dialog
	{
		var toolbox:Dialog = cast state.buildComponent(ChartEditorState.CHART_EDITOR_TOOLBOX_TOOLS_LAYOUT);

		// Starting position.
		toolbox.x = 50;
		toolbox.y = 50;

		toolbox.onDialogClosed = (event:DialogEvent) ->
		{
			state.setUISelected('menubarItemToggleToolboxTools', false);
		}

		var toolsGroup:Group = toolbox.findComponent("toolboxToolsGroup", Group);

		toolsGroup.onChange = (event:UIEvent) ->
		{
			switch (event.target.id)
			{
				case 'toolboxToolsGroupSelect':
					state.currentToolMode = ChartEditorToolMode.Select;
				case 'toolboxToolsGroupPlace':
					state.currentToolMode = ChartEditorToolMode.Place;
				default:
					trace('ChartEditorToolboxHandler.buildToolboxToolsLayout() - Unknown toolbox tool selected: $event.target.id');
			}
		}

		return toolbox;
	}

	static function buildToolboxNoteDataLayout(state:ChartEditorState):Dialog
	{
		var toolbox:Dialog = cast state.buildComponent(ChartEditorState.CHART_EDITOR_TOOLBOX_NOTEDATA_LAYOUT);

		// Starting position.
		toolbox.x = 75;
		toolbox.y = 100;

		toolbox.onDialogClosed = (event:DialogEvent) ->
		{
			state.setUISelected('menubarItemToggleToolboxNotes', false);
		}

		var toolboxNotesNoteKind:DropDown = toolbox.findComponent("toolboxNotesNoteKind", DropDown);

		toolboxNotesNoteKind.onChange = (event:UIEvent) ->
		{
			state.selectedNoteKind = event.data.id;
		}

		return toolbox;
	}

	static function buildToolboxEventDataLayout(state:ChartEditorState):Dialog
	{
		var toolbox:Dialog = cast state.buildComponent(ChartEditorState.CHART_EDITOR_TOOLBOX_EVENTDATA_LAYOUT);

		// Starting position.
		toolbox.x = 100;
		toolbox.y = 150;

		toolbox.onDialogClosed = (event:DialogEvent) ->
		{
			state.setUISelected('menubarItemToggleToolboxEvents', false);
		}

		return toolbox;
	}

	static function buildToolboxSongDataLayout(state:ChartEditorState):Dialog
	{
		var toolbox:Dialog = cast state.buildComponent(ChartEditorState.CHART_EDITOR_TOOLBOX_SONGDATA_LAYOUT);

		// Starting position.
		toolbox.x = 950;
		toolbox.y = 50;

		toolbox.onDialogClosed = (event:DialogEvent) ->
		{
			state.setUISelected('menubarItemToggleToolboxSong', false);
		}

		return toolbox;
	}

	static function buildDialog(state:ChartEditorState, id:String):Dialog
	{
		var dialog:Dialog = cast state.buildComponent(id);
		dialog.destroyOnClose = false;
		return dialog;
	}
}
