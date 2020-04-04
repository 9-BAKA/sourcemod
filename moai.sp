#include <sourcemod>
#include <sdktools_functions>
#include <sdktools>
#include <sdkhooks>

#define VERSION "1.0"

public Plugin:myinfo =
{
    name = "默哀",
    description = "",
    author = "",
    version = "1.0",
    url = ""
};

public OnPluginStart()
{
    CreateConVar("yurenjie_version", VERSION, "本插件版本", FCVAR_NOTIFY);
    RegConsoleCmd("sm_daojishi", Command_Daojishi, "倒计时");
}
 
public Action Command_Daojishi(int client, int args)
{
    char arg[10];
    GetCmdArg(1, arg, sizeof(arg));
    PrintToChatAll("\x05【公告】\x03【4月4日全国哀悼日】");
    PrintToChatAll("\x04为表达全国各族人民对抗击新冠肺炎疫情斗争牺牲烈士和逝世同胞");
    PrintToChatAll("\x04的深切哀悼，国务院今天发布公告,决定2020年4月4日举行全国性");
    PrintToChatAll("\x04哀悼活动。在此期间,全国和驻外使领馆下半旗志哀，全国停止公共");
    PrintToChatAll("\x04娱乐活动。4月4日10时起，全国人民默哀3分钟，汽车、舰船鸣笛，");
    PrintToChatAll("\x04防空警报鸣响。");
    PrintToChatAll("\x05本服将于\x03 %s \x05分钟后关闭", arg);
}
