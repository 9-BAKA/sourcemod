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

public Action playerDeath(Handle event, const char[] name, const bool dontBroadcast)
{
    if (!auto_defib_enable) return Plugin_Handled;

    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (client == 0 || !IsClientInGame(client) || GetClientTeam(client) != 2) return Plugin_Handled;

    float loc[3];
    GetClientAbsOrigin(client, loc);

    int entity_weapon = -1;
    entity_weapon = CreateEntityByName("weapon_defibrillator");
    if (entity_weapon == -1) PrintToChatAll("创造电击器失败");
    else PrintToChatAll("电击器已生成");

    DispatchKeyValue(entity_weapon, "solid", "6");
    DispatchKeyValue(entity_weapon, "model", "models/w_models/weapons/w_eq_defibrillator.mdl");
    DispatchKeyValue(entity_weapon, "rendermode", "3");
    DispatchKeyValue(entity_weapon, "disableshadows", "1");
    DispatchKeyValue(entity_weapon, "count", "1");
    TeleportEntity(entity_weapon, loc, NULL_VECTOR, NULL_VECTOR);
    DispatchSpawn(entity_weapon);
    SetEntityMoveType(entity_weapon, MOVETYPE_NONE);

    int Red = 0, Green = 255, Blue = 0, Type = 3, Range = 0;
    int Color = Blue * 65536 + Green * 256 + Red;
    SetEntProp(entity_weapon, PropType:0, "m_iGlowType", Type, 4, 0);
    SetEntProp(entity_weapon, PropType:0, "m_nGlowRange", Range, 4, 0);
    SetEntProp(entity_weapon, PropType:0, "m_glowColorOverride", Color, 4, 0);

    return Plugin_Continue;
}