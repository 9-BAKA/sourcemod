#include <sourcemod>
#include <sdktools>
#include <sdktools_functions>

public Plugin:myinfo =
{
    name = "物体生成次数增加",
    description = "增加准星处物体的生成次数",
    author = "BAKA",
    version = "1.0",
    url = "https://baka.cirno.cn"
};

public void OnPluginStart()
{
    RegConsoleCmd("sm_whatis", Whatis, "显示准星处物体的classname");
    RegConsoleCmd("sm_remain", Remain, "剩余生成次数");
    RegConsoleCmd("sm_motto", Motto, "增加准星处物体的生成次数");
    RegConsoleCmd("sm_more", Motto, "增加准星处物体的生成次数");
    RegAdminCmd("sm_reproduce",     Cmd_ReproduceProp,        ADMFLAG_ROOT,    "Clone properties on aim target based on the properties previously saved by sm_ted_select of tEntDev");
}

public Action Cmd_ReproduceProp(int client, int args)
{
    int ent = GetClientAimTarget(client, false);
    
    if (ent < 0) { // || !IsTank(ent)) {
        PrintToChat(client, "Not aimed or not a tank! Ent = %i", ent);
        return Plugin_Handled;
    }

    PrintToChat(client, "Reproducing properties on %i ...", ent);

    KeyValues kv;
    char sItem[16], sName[64], sValue[64];
    int iValue;
    float fValue, vValue[3];
    
    kv = CreateKeyValues("tank");
    
    if (FileToKeyValues(kv, "kvtest.txt")) { // tEntDev report file (root of game folder)
        PrintToChat(client, "kvtest.txt is Loaded");
        
        kv.Rewind();
        kv.GotoFirstSubKey();
        
        do
        {
            kv.GetSectionName(sItem, sizeof(sItem)); // compare to full list
            
            kv.GetString("Name", sName, sizeof(sName));
            
            if (HasEntProp(ent, Prop_Send, sName)) {
            
                PrintToConsole(client, "Name: %s", sName);
                
                switch(kv.GetNum("type")) {
                    case 0: { // integer
                        iValue = kv.GetNum("value");
                        SetEntProp(ent, Prop_Send, sName, iValue);
                        PrintToConsole(client, "%s = %i", sName, iValue);
                    }
                    case 1: { // float
                        fValue = kv.GetFloat("value");
                        SetEntPropFloat(ent, Prop_Send, sName, fValue);
                        PrintToConsole(client, "%s = %f", sName, fValue);
                    }
                    case 2: { // vector
                        kv.GetVector("value", vValue);
                        SetEntPropVector(ent, Prop_Send, sName, vValue);
                        PrintToConsole(client, "%s = %f %f %f", sName, vValue[0], vValue[1], vValue[2]);
                    }
                    case 3: { // ??
                    }
                    case 4: { // string
                        kv.GetString("value", sValue, sizeof(sValue), "error");
                        if (!StrEqual(sValue, "error")) {
                            SetEntPropString(ent, Prop_Send, sName, sValue);
                            PrintToConsole(client, "%s = %s", sName, sValue);
                        }
                    }
                }
            }
        } while (kv.GotoNextKey());
        
        ChangeEdictState(ent, 0);
    }
    else {
        PrintToChat(client, "kvtest.txt file is not found!");
    }
    PrintToChat(client, "Finished");
    return Plugin_Handled;
} 

public Action Whatis(int client, int args)
{
    int Ent = GetClientAimTarget(client, false);
    if (IsValidEntity(Ent))
    {
        char modelname[128];
        GetEntPropString(Ent, PropType:1, "m_ModelName", modelname, 128, 0);
        PrintToChat(client, "\x04[Motto]\x05 准星处物体为:\x01 %s", modelname);
    }
    else
    {
        PrintToChat(client, "\x04[Motto]\x05 准星处找不到实体.");
    }
    return Plugin_Continue;
}

public Action Remain(int client, int args)
{
    int Ent = GetClientAimTarget(client, false);
    if (IsValidEntity(Ent))
    {
        int i_Offset = FindDataMapInfo(Ent, "m_itemCount");
        if (i_Offset == -1){
            PrintToChat(client, "\x04[Motto]\x05 物体无剩余生成次数属性.");
            return Plugin_Continue;
        }
        int i_Value = GetEntData(Ent, i_Offset, 4);
        PrintToChat(client, "\x04[Motto]\x05 物体剩余生成次数: \x04%d\x05.", i_Value);
    }
    else
    {
        PrintToChat(client, "\x04[Motto]\x05 准星处找不到实体.");
    }
    return Plugin_Continue;
}

public Action Motto(int client, int args)
{
    int num = 1;
    if (args > 0)
    {
        char arg[4];
        GetCmdArg(1, arg, sizeof(arg));
        num = StringToInt(arg, 10);
        if (num > 10 || num < 1)
        {
            PrintToChat(client, "\x04[Motto]\x05 请输入1-10以内的数.");
            return Plugin_Continue;
        }
    }

    int Ent = GetClientAimTarget(client, false);
    if (IsValidEntity(Ent))
    {
        int i_Offset = FindDataMapInfo(Ent, "m_itemCount");
        int i_Value;
        if (i_Offset == -1) 
        {
            char modelname[128];
            GetEntPropString(Ent, PropType:1, "m_ModelName", modelname, 128, 0);
            CreateEntityByName(modelname);
            PrintToChat(client, "\x04[Motto]\x05 摩多摩多！");
        }
        else 
        {
            i_Value = GetEntData(Ent, i_Offset, 4);
            char increase_num[4];
            if (i_Value + num > 30)
            {
                Format(increase_num, 4, "%d", 30);
                DispatchKeyValue(Ent, "count", increase_num);
                PrintToChat(client, "\x04[Motto]\x05 已达到允许设置的拿取次数上限\x0430\x05.");
            }
            else
            {
                Format(increase_num, 4, "%d", i_Value + num);
                DispatchKeyValue(Ent, "count", increase_num);
                PrintToChat(client, "\x04[Motto]\x05 增加准星处物体\x03%d\x05次拿取次数,剩余可拿\x04%d\x05次", num, i_Value + num);
            }
        }
    }
    else
    {
        PrintToChat(client, "\x04[Motto]\x05 准星处找不到实体.");
    }
    return Plugin_Continue;
}