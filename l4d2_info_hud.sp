#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "0.3"

public Plugin:myinfo = 
{
  name = "信息hud", 
  author = "BAKA", 
  description = "在游戏中显示信息hud", 
  version = PLUGIN_VERSION, 
  url = "baka.cirno.cn"
}

public OnPluginStart()
{
  RegConsoleCmd("sm_hud", ShowHud, "显示Hud", 0);
}

public Action ShowHud(int client, int args)
{
  decl String:Buffer[100] = "This is a Hud"
  PrintToChatAll(Buffer);
  SetHudTextParams( 1.0, 1.0, 5.0, 255, 255, 255, 255 );
  ShowHudText(client, -1, Buffer);
}
