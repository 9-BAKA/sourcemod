#include <sourcemod>
#include <sdktools_functions>
#include <sdktools>
#include <sdkhooks>

#define VERSION "1.0"

public Plugin:myinfo =
{
	name = "愚人节",
	description = "",
	author = "",
	version = "1.0",
	url = ""
};

public OnPluginStart()
{
	CreateConVar("yurenjie_version", VERSION, "本插件版本", FCVAR_NOTIFY);
}
 
public void OnClientPutInServer(int client)
{
    if (client != 0 && !IsFakeClient(client)){
        char name[65];
        Format(name, 65, "%s", "BAKA");
        // for (int i = 0; i < client; i++){
        //     Format(name, 65, "%s%s", name, " ");
        // }
        SetClientInfo(client, "name", name);
        PrintToServer("%i %s", client, name);
    }
}