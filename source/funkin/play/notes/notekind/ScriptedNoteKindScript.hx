package funkin.play.notes.notekind;

/**
 * A script that can be tied to a NoteKindScript.
 * Create a scripted class that extends NoteKindScript,
 * then call `super('noteKind')` in the constructor to use this.
 */
@:hscriptClass
class ScriptedNoteKindScript extends NoteKindScript implements polymod.hscript.HScriptedClass {}
