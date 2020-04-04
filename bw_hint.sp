#include <sourcemod>
#pragma semicolon 1
#define PLUGIN_VERSION "1.31"

#define ZOEY 0
#define LOUIS 1
#define FRANCIS 2
#define BILL 3
#define ROCHELLE 4
#define COACH 5
#define ELLIS 6
#define NICK 7


public Plugin:myinfo =
{
        name = "[L4D&L4D2]人物黑白提示",
        author = "未知 修复：motawc",
        description = "当玩家进入黑白状态时，给其他队友文本提示并标记轮廓。",
        version = PLUGIN_VERSION,
        url = "http://steamcommunity.com/id/666-233"
}

new Handle:h_cvarNoticeType=INVALID_HANDLE;
new Handle:h_cvarPrintType=INVALID_HANDLE;
new Handle:h_cvarGlowEnable=INVALID_HANDLE;
new bandw_notice;
new bandw_type;
new bandw_glow;
new bool:status[8];

public OnPluginStart()
{
    //create version convar
    CreateConVar("l4d_blackandwhite_version", PLUGIN_VERSION, "Version of L4D Black and White Notifier", FCVAR_REPLICATED|FCVAR_NOTIFY);

    //hook some events
    HookEvent("revive_success", EventReviveSuccess);
    HookEvent("heal_success", EventHealSuccess);
    HookEvent("player_death", EventPlayerDeath);

    //create option convars
    h_cvarPrintType = CreateConVar("l4d_bandw_type", "0", "0 聊天框通知, 1 中间框通知.", 0, true, 0.0, true, 1.0);
    h_cvarGlowEnable = CreateConVar("l4d_bandw_glow", "1", "0 没有发光轮廓, 1 有发光轮廓", 0, true, 0.0, true, 1.0);
    h_cvarNoticeType = CreateConVar("l4d_bandw_notice", "2", "0 关闭通知, 1 仅通知幸存者, 2 通知所有人, 3 仅通知感染者.", 0, true, 0.0, true, 3.0);

    //read values from convars initially
    bandw_notice = GetConVarInt(h_cvarNoticeType);
    bandw_type = GetConVarInt(h_cvarPrintType);
    bandw_glow = GetConVarInt(h_cvarGlowEnable);

    //hook changes to those convars
    HookConVarChange(h_cvarNoticeType, ChangeVars);
    HookConVarChange(h_cvarPrintType, ChangeVars);
    HookConVarChange(h_cvarGlowEnable, ChangeVars);
}

public EventReviveSuccess(Handle:event, const String:name[], bool:dontBroadcast)
{
    if(GetEventBool(event, "lastlife"))
    {
        new target = GetClientOfUserId(GetEventInt(event, "subject"));
        decl String:targetName[64];
        decl String:targetModel[128]; 
        decl String:charName[32];

        if(target == 0) return;

        //get client name and model
        GetClientName(target, targetName, sizeof(targetName));
        GetClientModel(target, targetModel, sizeof(targetModel));

        if(bandw_glow)
        {
            //PrintToChatAll("%d",GetEntProp(target, Prop_Send, "m_glowColorOverride"));//normally 0. cant be overwritten?
            SetEntProp(target, Prop_Send, "m_iGlowType", 3);//Set a steady glow(scavenger like)
            SetEntProp(target, Prop_Send, "m_nGlowRange", 666);
            SetEntProp(target, Prop_Send, "m_glowColorOverride", 16777215);//16777215 white? 
        }

        //fill string with character names
        if(StrContains(targetModel, "teenangst", false) > 0) 
        {
            strcopy(charName, sizeof(charName), "Zoey");
            status[ZOEY] = true;
        }
        else if(StrContains(targetModel, "biker", false) > 0)
        {
            strcopy(charName, sizeof(charName), "Francis");
            status[FRANCIS] = true;
        }
        else if(StrContains(targetModel, "manager", false) > 0)
        {
            strcopy(charName, sizeof(charName), "Louis");
            status[LOUIS] = true;
        }
        else if(StrContains(targetModel, "namvet", false) > 0)
        {
            strcopy(charName, sizeof(charName), "Bill");
            status[BILL] = true;
        }
        else if(StrContains(targetModel, "producer", false) > 0)
        {
            strcopy(charName, sizeof(charName), "Rochelle");
            status[ROCHELLE] = true;
        }
        else if(StrContains(targetModel, "mechanic", false) > 0)
        {
            strcopy(charName, sizeof(charName), "Ellis");
            status[ELLIS] = true;
        }
        else if(StrContains(targetModel, "coach", false) > 0)
        {
            strcopy(charName, sizeof(charName), "Coach");
            status[COACH] = true;
        }
        else if(StrContains(targetModel, "gambler", false) > 0)
        {
            strcopy(charName, sizeof(charName), "Nick");
            status[NICK] = true;
        }
        else
        {
            strcopy(charName, sizeof(charName), "Unknown");
        }

        //turned off
        if(bandw_notice == 0) return;

        //print to all
        else if(bandw_notice == 2) 
        {
            if(bandw_type == 1) PrintHintTextToAll("\x05[危险警告] \x04%s\x01 进入了黑白状态!现在正在发\x04 [白光] \x01谁来帮帮忙!", targetName, charName);
            else PrintToChatAll("\x05[危险警告] \x04%s\x01 进入了黑白状态!现在正在发\x04 [白光] \x01谁来帮帮忙!", targetName, charName);
        }
        //print to infected
        else if(bandw_notice == 3)
        {
            for( new x = 1; x <= GetMaxClients(); x++)
            {
                if(!IsClientInGame(x) || GetClientTeam(x) == GetClientTeam(target) || x == target || IsFakeClient(x))
                continue;
                if(bandw_type == 1) PrintHintText(x, "[危险警告] -%s 进入黑白状态!现在正在发白光!赶紧干掉它!", targetName, charName);
                else PrintToChat(x, "[危险警告] -%s 进入黑白状态!现在正在发白光!赶紧干掉它!", targetName, charName);
            }
        }
        //print to survivors
        else
        {
            for( new x = 1; x <= GetMaxClients(); x++)
            {
                if(!IsClientInGame(x) || GetClientTeam(x) != GetClientTeam(target) || x == target || IsFakeClient(x)) 
                continue;

                if(bandw_type == 1) PrintHintText(x, "[危险警告] -%s 进入黑白状态!现在正在发白光!急需治疗!", targetName, charName);
                else PrintToChat(x, "[危险警告] -%s 进入黑白状态!现在正在发白光!急需治疗!", targetName, charName);
            }
        }        
    }
    return;
}

public EventHealSuccess(Handle:event, const String:name[], bool:dontBroadcast)
{
    new healeeID = GetEventInt(event, "subject");
    new healee = GetClientOfUserId(healeeID);

    if(healee == 0) return;

    decl String:healeeModel[128]; 
    GetClientModel(healee, healeeModel, sizeof(healeeModel));

    if(healee != 0 && IsClientInGame(healee) && bandw_glow)
    {        
        SetEntProp(healee, Prop_Send, "m_iGlowType", 0);
        SetEntProp(healee, Prop_Send, "m_glowColorOverride", 0);                //16777215 white?
    }

    //fill string with character names
    if(StrContains(healeeModel, "teenangst", false) > 0) 
    {
        if(status[ZOEY]) status[ZOEY] = false;
    }
    else if(StrContains(healeeModel, "biker", false) > 0)
    {
        status[FRANCIS] = false;
    }
    else if(StrContains(healeeModel, "manager", false) > 0)
    {
        status[LOUIS] = false;
    }
    else if(StrContains(healeeModel, "namvet", false) > 0)
    {
        status[BILL] = false;
    }
    else if(StrContains(healeeModel, "producer", false) > 0) 
    {
        status[ROCHELLE] = false;
    }
    else if(StrContains(healeeModel, "mechanic", false) > 0)
    {
        status[ELLIS] = false;
    }
    else if(StrContains(healeeModel, "coach", false) > 0)
    {
        status[COACH] = false;
    }
    else if(StrContains(healeeModel, "gambler", false) > 0)
    {
        status[NICK] = false;
    }
    return;
}

public EventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (client != 0 && IsClientInGame(client) && GetClientTeam(client) == 2)
    {
        SetEntProp(client, Prop_Send, "m_iGlowType", 0);//Set a steady glow(scavenger like)
        SetEntProp(client, Prop_Send, "m_glowColorOverride", 0);//16777215 white? 
    }
    /*if (g_bPlayerGlowed[client][0][0])
    {
        g_bPlayerGlowed[client] = 0;
        SetEntProp(client, PropType:0, "m_iGlowType", any:0, 4, 0);
        SetEntProp(client, PropType:0, "m_glowColorOverride", any:0, 4, 0);
    }*/
    if(client == 0) return;
    
    decl String:deadModel[128];
    GetClientModel(client, deadModel, sizeof(deadModel));

    //fill string with character names
    if(StrContains(deadModel, "teenangst", false) >= 0) 
    {
        if(status[ZOEY]) status[ZOEY] = false;
    }
    else if(StrContains(deadModel, "biker", false) >= 0)
    {
        status[FRANCIS] = false;
    }
    else if(StrContains(deadModel, "manager", false) >= 0)
    {
        status[LOUIS] = false;
    }
    else if(StrContains(deadModel, "namvet", false) >= 0)
    {
        status[BILL] = false;
    }
    else if(StrContains(deadModel, "producer", false) >= 0)
    {
        status[ROCHELLE] = false;
    }
    else if(StrContains(deadModel, "mechanic", false) >= 0)
    {
        status[ELLIS] = false;
    }
    else if(StrContains(deadModel, "coach", false) >= 0)
    {
        status[COACH] = false;
    }
    else if(StrContains(deadModel, "gambler", false) >= 0)
    {
        status[NICK] = false;
    }
    return;
}
//could possibly get away with hooking player_bot_replace and bot_player_replace for names?
//failing that, hook player_team?

//get cvar changes during game
public ChangeVars(Handle:cvar, const String:oldVal[], const String:newVal[])
{
    //read values from convars
    bandw_notice = GetConVarInt(h_cvarNoticeType);
    bandw_type = GetConVarInt(h_cvarPrintType);
    bandw_glow = GetConVarInt(h_cvarGlowEnable);
}

/*public PerformGlow(client)
{
    SetEntProp(client, Prop_Send, "m_iGlowType", 0);                                         //Set a steady glow(scavenger like)
    SetEntProp(client, Prop_Send, "m_glowColorOverride", 0);
}*/