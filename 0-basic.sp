#include <sourcemod>
#include <sdktools>

Handle g_auto_defib = INVALID_HANDLE;
bool auto_defib_enable;

public Plugin:myinfo =
{
        name = "人物死亡时自动生成电击器",
        author = "BAKA",
        description = "当人物死亡时，自动生成电击器让队友电击",
        version = "1.0",
        url = "baka.cirno.cn"
}

public OnPluginStart()
{
    g_auto_defib = CreateConVar("sm_auto_defib", "1", "是否开启自动生成电击器");
    auto_defib_enable = GetConVarBool(g_auto_defib);
    HookConVarChange(g_auto_defib, OnCVarChange);
    HookEvent("player_death", playerDeath, EventHookMode:1);
}

public OnCVarChange(Handle convar_hndl, const char[] oldValue, const char[] newValue)
{
    auto_defib_enable = GetConVarBool(g_auto_defib);
}
