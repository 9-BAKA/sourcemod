#include <sourcemod>
#include <sdktools>
#include <voiceannounce_ex>
#include <basecomm>

Handle g_voice_show = INVALID_HANDLE;
int voice_show_enable;
bool player_speaking[MAXPLAYERS + 1]

public Plugin:myinfo =
{
    name = "显示谁在用麦说话",
    author = "BAKA",
    description = "在屏幕上显示谁在用麦克风说话",
    version = "1.0",
    url = "baka.cirno.cn"
};

public OnPluginStart()
{
    g_voice_show = CreateConVar("sm_voice_show", "1", "是否在屏幕上显示");
    voice_show_enable = GetConVarInt(g_voice_show);
    HookConVarChange(g_voice_show, OnCVarChange);
}

public OnMapStart()
{
    for (int i = 0; i < MAXPLAYERS + 1; i++)
        player_speaking[i] = false;
}

public OnCVarChange(Handle convar_hndl, const char[] oldValue, const char[] newValue)
{
    voice_show_enable = GetConVarInt(g_voice_show);
}

public OnClientSpeakingEx(client)
{
    char buffer[1024];
    player_speaking[client] = true;
    if (voice_show_enable)
    {
        for (int i = 0; i < MAXPLAYERS + 1; i++)
        {
            if (player_speaking[i])
            {
                Format(buffer, 1024, "%s\n%N 正在说话", buffer, i);
            }
        }
        PrintCenterTextAll(buffer);
    }
}

public OnClientSpeakingEnd(client)
{
    player_speaking[client] = false;
}

public OnClientDisconnect(client)
{
	player_speaking[client] = false;
}
