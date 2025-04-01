package funkin.play.cutscene.dialogue;

/**
 * A script that can be tied to a Conversation.
 * Create a scripted class that extends Conversation to use this.
 * This allows you to customize how a specific conversation appears and behaves.
 * Someone clever could use this to add branching dialogue I think.
 */
@:hscriptClass
class ScriptedConversation extends Conversation implements polymod.hscript.HScriptedClass {}
