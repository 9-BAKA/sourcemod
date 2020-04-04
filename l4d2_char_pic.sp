#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <sdktools_functions>

Handle  hFile;
char output[50][240];

public Plugin:myinfo =
{
    name = "字符画",
    description = "显示字符画",
    author = "BAKA",
    version = "1.0",
    url = "baka.cirno.cn"
};

public void OnPluginStart()
{
    RegConsoleCmd("sm_char", CharPic, "画出字符画");

    OpenConfig();
}

public Action CharPic(int client, int args)
{
    if (args == 0) LoadCharFile("1");
    char posTemp[10];
    GetCmdArg(1, posTemp, sizeof(posTemp));
    LoadCharFile(posTemp);
    return Plugin_Continue;
}

LoadCharFile(char[] posTemp)
{
    if (KvJumpToKey(hFile, posTemp, false))
    {
        int num;
        num = KvGetNum(hFile, "图片数量", 0);
        if (num == 0)
        {
            PrintToChatAll("没有图片数量");
        }
        else
        {
            char temp[10000];
            for (int i = 0; i < num; i++)
            {
                char iTemp[10];
                IntToString(i, iTemp, 10);
                KvGetString(hFile, iTemp, temp, sizeof(temp), "");
                PrintMessage(iTemp);
            }
        }
        KvRewind(hFile);
    }
    else
    {
        PrintToChatAll("没有图片");
        return;
    }
}

PrintMessage(char[] iTemp)
{
    
}

OpenConfig()
{
	char sPath[256];
	BuildPath(PathType:0, sPath, 256, "%s", "data/l4d2_char_pic.txt");
	if (!FileExists(sPath, false, "GAME"))
	{
		SetFailState("找不到文件 data/l4d2_char_pic.txt");
	}
	else
	{
		PrintToServer("[BAKA提示] 文件数据 data/l4d2_char_pic.txt 加载成功");
	}
	hFile = CreateKeyValues("图片包", "", "");
	if (!FileToKeyValues(hFile, sPath))
	{
		CloseHandle(hFile);
		SetFailState("无法载入 data/l4d2_char_pic.txt'");
	}
}

