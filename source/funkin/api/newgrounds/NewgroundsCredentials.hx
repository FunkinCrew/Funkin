package funkin.api.newgrounds;

class NewgroundsCredentials
{
  public static final APP_ID:String = #if API_NG_APP_ID haxe.macro.Compiler.getDefine("API_NG_APP_ID") #else '58004:a1GXEVhr' #end;
  public static final ENCRYPTION_KEY:String = #if API_NG_ENC_KEY haxe.macro.Compiler.getDefine("API_NG_ENC_KEY") #else 'pxl4MHYpT737Fe0/7qNBEQ==' #end;
}
