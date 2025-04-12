package funkin.ui.debug.stageeditor.handlers;

import funkin.play.character.BaseCharacter.CharacterType;
import funkin.ui.debug.stageeditor.handlers.AssetDataHandler.StageEditorObjectData;
import funkin.ui.debug.stageeditor.StageEditorState.StageEditorDialogType;

class UndoRedoHandler
{
  public static function performLastAction(state:StageEditorState, redo:Bool = false):Void
  {
    if (state == null || (state.undoArray.length <= 0 && !redo) || (state.redoArray.length <= 0 && redo)) return;
    var actionToDo = redo ? state.redoArray.pop() : state.undoArray.pop();

    switch (actionToDo.type)
    {
      case CHARACTER_MOVED:
        createAndPushAction(state, actionToDo.type, !redo);

        var type = actionToDo.data.type == null ? CharacterType.BF : actionToDo.data.type;
        var pos = actionToDo.data.pos == null ? [0, 0] : actionToDo.data.pos;

        for (char in state.getCharacters())
        {
          if (char.characterType == type) state.selectedChar = char;
        }

        state.selectedChar.x = pos[0] - state.selectedChar.characterOrigin.x + state.selectedChar.globalOffsets[0];
        state.selectedChar.y = pos[1] - state.selectedChar.characterOrigin.y + state.selectedChar.globalOffsets[1];

        state.updateMarkerPos();
        state.updateDialog(StageEditorDialogType.CHARACTER);

      case OBJECT_MOVED:
        var id = actionToDo.data.ID ?? -1;
        var pos = actionToDo.data.pos ?? [0, 0];

        for (obj in state.spriteArray)
        {
          if (obj.ID == id) state.selectedSprite = obj;
        }

        if (state.selectedSprite != null)
        {
          createAndPushAction(state, actionToDo.type, !redo);

          state.selectedSprite.x = pos[0];
          state.selectedSprite.y = pos[1];

          state.updateDialog(StageEditorDialogType.OBJECT_PROPERTIES);
        }

      case OBJECT_CREATED: // this removes the object
        var id = actionToDo.data.ID ?? -1;

        for (obj in state.spriteArray)
        {
          if (obj.ID == id)
          {
            state.selectedSprite = obj;
            createAndPushAction(state, OBJECT_DELETED, !redo);

            state.selectedSprite = null;

            obj.kill();
            state.remove(obj, true);
            obj.destroy();

            state.updateArray();
            state.updateDialog(StageEditorDialogType.OBJECT_GRAPHIC);
            state.updateDialog(StageEditorDialogType.OBJECT_ANIMS);
            state.updateDialog(StageEditorDialogType.OBJECT_PROPERTIES);
            trace("found object");

            continue;
          }
        }

      case OBJECT_DELETED: // this creates the object
        if (actionToDo.data.data == null) return;

        var id = actionToDo.data.ID ?? -1;
        var data:StageEditorObjectData = cast actionToDo.data.data;

        var obj = new StageEditorObject().fromData(data);
        obj.ID = id;
        state.selectedSprite = obj;

        createAndPushAction(state, OBJECT_CREATED, !redo);
        state.add(obj);

        state.updateDialog(StageEditorDialogType.OBJECT_GRAPHIC);
        state.updateDialog(StageEditorDialogType.OBJECT_ANIMS);
        state.updateDialog(StageEditorDialogType.OBJECT_PROPERTIES);
        state.updateArray();

      case OBJECT_ROTATED: // primarily copied from OBJECT_MOVED
        var id = actionToDo.data.ID ?? -1;
        var angle = actionToDo.data.angle ?? 0;

        for (obj in state.spriteArray)
        {
          if (obj.ID == id) state.selectedSprite = obj;
        }

        if (state.selectedSprite != null)
        {
          createAndPushAction(state, actionToDo.type, !redo);
          state.selectedSprite.angle = angle;
          state.updateDialog(StageEditorDialogType.OBJECT_PROPERTIES);
        }

      default: // do nothing dumbass
    }
  }

  public static function createAndPushAction(state:StageEditorState, action:UndoActionType, redo:Bool = false)
  {
    if (state == null) return;

    var finalAction:UndoAction = {type: action, data: null};

    if (!redo && state.redoArray.length > 0) state.redoArray = []; // incorporate resetting as well

    switch (action)
    {
      case CHARACTER_MOVED:
        var char = state.selectedChar.characterType;
        finalAction.data = {type: char, pos: state.charPos[char].copy()};

      case OBJECT_MOVED:
        finalAction.data = {ID: state.selectedSprite.ID, pos: [state.selectedSprite.x, state.selectedSprite.y]}

      case OBJECT_CREATED:
        finalAction.data = {ID: state.selectedSprite.ID}

      case OBJECT_DELETED:
        finalAction.data =
          {
            ID: state.selectedSprite.ID,
            data: state.selectedSprite.toData(true)
          }

      case OBJECT_ROTATED:
        finalAction.data = {ID: state.selectedSprite.ID, angle: state.selectedSprite.angle}

      default: // nop
    }

    if (finalAction.data == null) return;

    if (redo) state.redoArray.push(finalAction);
    else if (!redo) state.undoArray.push(finalAction);
  }
}

typedef UndoAction =
{
  /**
   * The Type of Undo Action to store.
   */
  var type:UndoActionType;

  /**
   * The added Data of the Action.
   */
  var data:Dynamic;
}

enum abstract UndoActionType(String) from String
{
  /**
   * Triggerred when an Object is deleted.
   */
  var OBJECT_DELETED = "object_deleted";

  /**
   * Triggerred when an Object is created.
   */
  var OBJECT_CREATED = "object_created";

  /**
   * Triggerred when an Object is moved.
   */
  var OBJECT_MOVED = "object_moved";

  /**
   * Triggerred when a Character is moved.
   */
  var CHARACTER_MOVED = "character_moved";

  /**
   * Triggerred when an Object is rotated.
   */
  var OBJECT_ROTATED = "object_rotated";
}
