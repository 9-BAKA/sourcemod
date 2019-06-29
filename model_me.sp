#include <sourcemod>
#include <sdktools>


new g_iSubCategory[MAXPLAYERS+1] = 0;
new g_iFileCategory[MAXPLAYERS+1] = 0;
new Handle:g_cvarVehicles = INVALID_HANDLE;
new Handle:g_cvarFoliage = INVALID_HANDLE;
new Handle:g_cvarInterior = INVALID_HANDLE;
new Handle:g_cvarExterior = INVALID_HANDLE;
new Handle:g_cvarDecorative = INVALID_HANDLE;
new Handle:g_cvarMisc = INVALID_HANDLE;
new Handle:StopTime[66];
char ModelNames[1000][256];
char ModelTags[1000][256];
int ModelRa[66][3];
int ModelRaSe[66];
int ModelNum = 0;
float ang[66][3];
bool rolled[66];
bool sift[66];
bool Stopped[66];

public Plugin:myinfo =
{
	name = "变模型插件",
	description = "L4D2变模型",
	author = "BAKA",
	version = "1.0",
	url = ""
};

public OnPluginStart()
{
	g_cvarVehicles = CreateConVar("l4d2_spawn_props_category_vehicles", "1", "Enable the Vehicles category", 0);
	g_cvarFoliage = CreateConVar("l4d2_spawn_props_category_foliage", "1", "Enable the Foliage category", 0);
	g_cvarInterior = CreateConVar("l4d2_spawn_props_category_interior", "1", "Enable the Interior category", 0);
	g_cvarExterior = CreateConVar("l4d2_spawn_props_category_exterior", "1", "Enable the Exterior category", 0);
	g_cvarDecorative = CreateConVar("l4d2_spawn_props_category_decorative", "1", "Enable the Decorative category", 0);
	g_cvarMisc = CreateConVar("l4d2_spawn_props_category_misc", "1", "Enable the Misc category", 0);

	RegAdminCmd("sm_modme", Command_modme, 32, "", "", 0);
	RegAdminCmd("sm_modse", Command_modse, 32, "", "", 0);
	RegAdminCmd("sm_modra", Command_modra, 32, "", "", 0);
	RegAdminCmd("sm_stop", Command_stop, 32, "", "", 0);
	RegAdminCmd("sm_refresh", Command_refresh, 32, "", "", 0);

	PrecacheSound("ui/littlereward.wav", true);
	PrecacheSound("level/gnomeftw.wav", true);
	PrecacheSound("npc/moustachio/strengthattract05.wav", true);
	PrecacheSound("buttons/button14.wav", true);

	GetModelNames();
}

public void GetModelNames()
{
	new Handle:file = INVALID_HANDLE;
	decl String:FileName[256], String:ItemModel[256], String:ItemTag[256], String:buffer[256];
	BuildPath(Path_SM, FileName, sizeof(FileName), "data/l4d2_modme_models.txt");
	new len;
	if(!FileExists(FileName))
	{
		SetFailState("Unable to find the l4d2_modme_models.txt file");
	}
	file = OpenFile(FileName, "r");
	if(file == INVALID_HANDLE)
	{
		SetFailState("Error opening the models file");
	}

	ModelNum = 0;
	while(ReadFileLine(file, buffer, sizeof(buffer)))
	{
		len = strlen(buffer);
		if (buffer[len-1] == '\n')
		{
			buffer[--len] = '\0';
		}
		SplitString(buffer, " TAG-", ItemModel, sizeof(ItemModel));
		
		strcopy(ItemTag, sizeof(ItemTag), buffer);
		
		ReplaceString(ItemTag, sizeof(ItemTag), ItemModel, "", false);
		ReplaceString(ItemTag, sizeof(ItemTag), " TAG- ", "", false);

		strcopy(ModelNames[ModelNum], 256, ItemModel);
		strcopy(ModelTags[ModelNum], 256, ItemTag);
		
		if(IsEndOfFile(file))
		{
			break;
		}
		ModelNum += 1;
	}
}

public Action:Command_modme(client, args)
{
	new Ent = GetClientAimTarget(client, false);
	if (IsValidEntity(Ent))
	{
		decl String:modelname[128];
		GetEntPropString(Ent, PropType:1, "m_ModelName", modelname, 128, 0);
		SetEntityModel(client, modelname);
		PrintToChat(client, "\x04[model]\x05 把自己变成:\x01 %s", modelname);
	}
	else
	{
		PrintToChat(client, "\x04[model]\x05 准星处找不到实体.");
	}
	return Action:0;
}


public Action:Command_modse(client, args)
{
	new Handle:menu = CreateMenu(MenuHandler_PhysicsCursor);
	SetMenuTitle(menu, "Select a Category:");
	SetMenuExitBackButton(menu, true);
	if(g_cvarVehicles)
	{
		AddMenuItem(menu, "vehicles", "车辆类");
	}
	if(g_cvarFoliage)
	{
		AddMenuItem(menu, "foliage", "植物类");
	}
	if(g_cvarInterior)
	{
		AddMenuItem(menu, "interior", "内部类");
	}
	if(g_cvarExterior)
	{
		AddMenuItem(menu, "exterior", "外部类");
	}
	if(g_cvarDecorative)
	{
		AddMenuItem(menu, "decorative", "装饰类");
	}
	if(g_cvarMisc)
	{
		AddMenuItem(menu, "misc", "杂项");
	}
	DisplayMenu(menu, client, MENU_TIME_FOREVER);	
}

public MenuHandler_PhysicsCursor(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			decl String:menucmd[256];
			GetMenuItem(menu, param2, menucmd, sizeof(menucmd));
			if(StrEqual(menucmd, "vehicles"))
			{
				DisplayVehiclesMenu(param1);
			}
			else if(StrEqual(menucmd, "foliage"))
			{
				DisplayFoliageMenu(param1);
			}
			else if(StrEqual(menucmd, "interior"))
			{
				DisplayInteriorMenu(param1);
			}
			else if(StrEqual(menucmd, "exterior"))
			{
				DisplayExteriorMenu(param1);
			}
			else if(StrEqual(menucmd, "decorative"))
			{
				DisplayDecorativeMenu(param1);
			}
			else if(StrEqual(menucmd, "misc"))
			{
				DisplayMiscMenu(param1);
			}
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

stock DisplayVehiclesMenu(client)
{
	g_iSubCategory[client] =  1;
	new Handle:menu = CreateMenu(MenuHandler_DoAction);
	new Handle:file = INVALID_HANDLE;
	decl String:FileName[256], String:ItemModel[256], String:ItemTag[256], String:buffer[256];
	BuildPath(Path_SM, FileName, sizeof(FileName), "data/l4d2_spawn_props_models.txt");
	new len;
	if(!FileExists(FileName))
	{
		SetFailState("Unable to find the l4d2_spawn_props_models.txt file");
	}
	file = OpenFile(FileName, "r");
	if(file == INVALID_HANDLE)
	{
		SetFailState("Error opening the models file");
	}
	g_iFileCategory[client] = 0;
	while(ReadFileLine(file, buffer, sizeof(buffer)))
	{
		len = strlen(buffer);
		if (buffer[len-1] == 'n')
		{
			buffer[--len] = '0';
		}
		if(StrContains(buffer, "//Category Vehicles") >= 0)
		{
			g_iFileCategory[client] = 1;
			continue;
		}
		else if(StrContains(buffer, "//Category Foliage") >= 0)
		{
			g_iFileCategory[client] = 2;
			continue;
		}
		else if(StrContains(buffer, "//Category Interior") >= 0)
		{
			g_iFileCategory[client] = 3;
			continue;
		}
		else if(StrContains(buffer, "//Category Exterior") >= 0)
		{
			g_iFileCategory[client] = 4;
			continue;
		}
		else if(StrContains(buffer, "//Category Decorative") >= 0)
		{
			g_iFileCategory[client] = 5;
			continue;
		}
		else if(StrContains(buffer, "//Category Misc") >= 0)
		{
			g_iFileCategory[client] = 6;
			continue;
		}
		if(StrEqual(buffer, ""))
		{
			continue;
		}
		if(g_iFileCategory[client] != 1)
		{
			continue;
		}
		SplitString(buffer, " TAG-", ItemModel, sizeof(ItemModel));
	
		strcopy(ItemTag, sizeof(ItemTag), buffer);
		
		ReplaceString(ItemTag, sizeof(ItemTag), ItemModel, "", false);
		ReplaceString(ItemTag, sizeof(ItemTag), " TAG- ", "", false);
		AddMenuItem(menu, ItemModel, ItemTag);
		
		if(IsEndOfFile(file))
		{
			break;
		}
	}
	SetMenuTitle(menu, "Vehicles");
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	CloseHandle(file);
}

stock DisplayFoliageMenu(client)
{
	g_iSubCategory[client] =  2;
	new Handle:menu = CreateMenu(MenuHandler_DoAction);
	new Handle:file = INVALID_HANDLE;
	decl String:FileName[256], String:ItemModel[256], String:ItemTag[256], String:buffer[256];
	BuildPath(Path_SM, FileName, sizeof(FileName), "data/l4d2_spawn_props_models.txt");
	new len;
	if(!FileExists(FileName))
	{
		SetFailState("Unable to find the l4d2_spawn_props_models.txt file");
	}
	file = OpenFile(FileName, "r");
	if(file == INVALID_HANDLE)
	{
		SetFailState("Error opening the models file");
	}
	g_iFileCategory[client] = 0;
	while(ReadFileLine(file, buffer, sizeof(buffer)))
	{
		len = strlen(buffer);
		if (buffer[len-1] == '\n')
		{
			buffer[--len] = '\0';
		}
		if(StrContains(buffer, "//Category Vehicles") >= 0)
		{
			g_iFileCategory[client] = 1;
			continue;
		}
		else if(StrContains(buffer, "//Category Foliage") >= 0)
		{
			g_iFileCategory[client] = 2;
			continue;
		}
		else if(StrContains(buffer, "//Category Interior") >= 0)
		{
			g_iFileCategory[client] = 3;
			continue;
		}
		else if(StrContains(buffer, "//Category Exterior") >= 0)
		{
			g_iFileCategory[client] = 4;
			continue;
		}
		else if(StrContains(buffer, "//Category Decorative") >= 0)
		{
			g_iFileCategory[client] = 5;
			continue;
		}
		else if(StrContains(buffer, "//Category Misc") >= 0)
		{
			g_iFileCategory[client] = 6;
			continue;
		}
		if(StrEqual(buffer, ""))
		{
			continue;
		}
		if(g_iFileCategory[client] != 2)
		{
			continue;
		}
		SplitString(buffer, " TAG-", ItemModel, sizeof(ItemModel));
	
		strcopy(ItemTag, sizeof(ItemTag), buffer);
		
		ReplaceString(ItemTag, sizeof(ItemTag), ItemModel, "", false);
		ReplaceString(ItemTag, sizeof(ItemTag), " TAG- ", "", false);
		AddMenuItem(menu, ItemModel, ItemTag);
		
		if(IsEndOfFile(file))
		{
			break;
		}
	}
	SetMenuTitle(menu, "Foliage");
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	CloseHandle(file);
}

stock DisplayInteriorMenu(client)
{
	g_iSubCategory[client] =  3;
	new Handle:menu = CreateMenu(MenuHandler_DoAction);
	new Handle:file = INVALID_HANDLE;
	decl String:FileName[256], String:ItemModel[256], String:ItemTag[256], String:buffer[256];
	BuildPath(Path_SM, FileName, sizeof(FileName), "data/l4d2_spawn_props_models.txt");
	new len;
	if(!FileExists(FileName))
	{
		SetFailState("Unable to find the l4d2_spawn_props_models.txt file");
	}
	file = OpenFile(FileName, "r");
	if(file == INVALID_HANDLE)
	{
		SetFailState("Error opening the models file");
	}
	g_iFileCategory[client] = 0;
	while(ReadFileLine(file, buffer, sizeof(buffer)))
	{
		len = strlen(buffer);
		if (buffer[len-1] == '\n')
		{
			buffer[--len] = '\0';
		}
		if(StrContains(buffer, "//Category Vehicles") >= 0)
		{
			g_iFileCategory[client] = 1;
			continue;
		}
		else if(StrContains(buffer, "//Category Foliage") >= 0)
		{
			g_iFileCategory[client] = 2;
			continue;
		}
		else if(StrContains(buffer, "//Category Interior") >= 0)
		{
			g_iFileCategory[client] = 3;
			continue;
		}
		else if(StrContains(buffer, "//Category Exterior") >= 0)
		{
			g_iFileCategory[client] = 4;
			continue;
		}
		else if(StrContains(buffer, "//Category Decorative") >= 0)
		{
			g_iFileCategory[client] = 5;
			continue;
		}
		else if(StrContains(buffer, "//Category Misc") >= 0)
		{
			g_iFileCategory[client] = 6;
			continue;
		}
		if(StrEqual(buffer, ""))
		{
			continue;
		}
		if(g_iFileCategory[client] != 3)
		{
			continue;
		}
		SplitString(buffer, " TAG-", ItemModel, sizeof(ItemModel));
	
		strcopy(ItemTag, sizeof(ItemTag), buffer);
		
		ReplaceString(ItemTag, sizeof(ItemTag), ItemModel, "", false);
		ReplaceString(ItemTag, sizeof(ItemTag), " TAG- ", "", false);
		AddMenuItem(menu, ItemModel, ItemTag);
		
		if(IsEndOfFile(file))
		{
			break;
		}
	}
	SetMenuTitle(menu, "Interior");
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	CloseHandle(file);
}

stock DisplayExteriorMenu(client)
{
	g_iSubCategory[client] =  4;
	new Handle:menu = CreateMenu(MenuHandler_DoAction);
	new Handle:file = INVALID_HANDLE;
	decl String:FileName[256], String:ItemModel[256], String:ItemTag[256], String:buffer[256];
	BuildPath(Path_SM, FileName, sizeof(FileName), "data/l4d2_spawn_props_models.txt");
	new len;
	if(!FileExists(FileName))
	{
		SetFailState("Unable to find the l4d2_spawn_props_models.txt file");
	}
	file = OpenFile(FileName, "r");
	if(file == INVALID_HANDLE)
	{
		SetFailState("Error opening the models file");
	}
	g_iFileCategory[client] = 0;
	while(ReadFileLine(file, buffer, sizeof(buffer)))
	{
		len = strlen(buffer);
		if (buffer[len-1] == '\n')
		{
			buffer[--len] = '\0';
		}
		if(StrContains(buffer, "//Category Vehicles") >= 0)
		{
			g_iFileCategory[client] = 1;
			continue;
		}
		else if(StrContains(buffer, "//Category Foliage") >= 0)
		{
			g_iFileCategory[client] = 2;
			continue;
		}
		else if(StrContains(buffer, "//Category Interior") >= 0)
		{
			g_iFileCategory[client] = 3;
			continue;
		}
		else if(StrContains(buffer, "//Category Exterior") >= 0)
		{
			g_iFileCategory[client] = 4;
			continue;
		}
		else if(StrContains(buffer, "//Category Decorative") >= 0)
		{
			g_iFileCategory[client] = 5;
			continue;
		}
		else if(StrContains(buffer, "//Category Misc") >= 0)
		{
			g_iFileCategory[client] = 6;
			continue;
		}
		if(StrEqual(buffer, ""))
		{
			continue;
		}
		if(g_iFileCategory[client] != 4)
		{
			continue;
		}
		SplitString(buffer, " TAG-", ItemModel, sizeof(ItemModel));
	
		strcopy(ItemTag, sizeof(ItemTag), buffer);
		
		ReplaceString(ItemTag, sizeof(ItemTag), ItemModel, "", false);
		ReplaceString(ItemTag, sizeof(ItemTag), " TAG- ", "", false);
		AddMenuItem(menu, ItemModel, ItemTag);
		
		if(IsEndOfFile(file))
		{
			break;
		}
	}
	SetMenuTitle(menu, "Exterior");
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	CloseHandle(file);
}

stock DisplayDecorativeMenu(client)
{
	g_iSubCategory[client] =  5;
	new Handle:menu = CreateMenu(MenuHandler_DoAction);
	new Handle:file = INVALID_HANDLE;
	decl String:FileName[256], String:ItemModel[256], String:ItemTag[256], String:buffer[256];
	BuildPath(Path_SM, FileName, sizeof(FileName), "data/l4d2_spawn_props_models.txt");
	new len;
	if(!FileExists(FileName))
	{
		SetFailState("Unable to find the l4d2_spawn_props_models.txt file");
	}
	file = OpenFile(FileName, "r");
	if(file == INVALID_HANDLE)
	{
		SetFailState("Error opening the models file");
	}
	g_iFileCategory[client] = 0;
	while(ReadFileLine(file, buffer, sizeof(buffer)))
	{
		len = strlen(buffer);
		if (buffer[len-1] == '\n')
		{
			buffer[--len] = '\0';
		}
		if(StrContains(buffer, "//Category Vehicles") >= 0)
		{
			g_iFileCategory[client] = 1;
			continue;
		}
		else if(StrContains(buffer, "//Category Foliage") >= 0)
		{
			g_iFileCategory[client] = 2;
			continue;
		}
		else if(StrContains(buffer, "//Category Interior") >= 0)
		{
			g_iFileCategory[client] = 3;
			continue;
		}
		else if(StrContains(buffer, "//Category Exterior") >= 0)
		{
			g_iFileCategory[client] = 4;
			continue;
		}
		else if(StrContains(buffer, "//Category Decorative") >= 0)
		{
			g_iFileCategory[client] = 5;
			continue;
		}
		else if(StrContains(buffer, "//Category Misc") >= 0)
		{
			g_iFileCategory[client] = 6;
			continue;
		}
		if(StrEqual(buffer, ""))
		{
			continue;
		}
		if(g_iFileCategory[client] != 5)
		{
			continue;
		}
		SplitString(buffer, " TAG-", ItemModel, sizeof(ItemModel));
	
		strcopy(ItemTag, sizeof(ItemTag), buffer);
		
		ReplaceString(ItemTag, sizeof(ItemTag), ItemModel, "", false);
		ReplaceString(ItemTag, sizeof(ItemTag), " TAG- ", "", false);
		AddMenuItem(menu, ItemModel, ItemTag);
		
		if(IsEndOfFile(file))
		{
			break;
		}
	}
	SetMenuTitle(menu, "Decorative");
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	CloseHandle(file);
}

stock DisplayMiscMenu(client)
{
	g_iSubCategory[client] =  6;
	new Handle:menu = CreateMenu(MenuHandler_DoAction);
	new Handle:file = INVALID_HANDLE;
	decl String:FileName[256], String:ItemModel[256], String:ItemTag[256], String:buffer[256];
	BuildPath(Path_SM, FileName, sizeof(FileName), "data/l4d2_spawn_props_models.txt");
	new len;
	if(!FileExists(FileName))
	{
		SetFailState("Unable to find the l4d2_spawn_props_models.txt file");
	}
	file = OpenFile(FileName, "r");
	if(file == INVALID_HANDLE)
	{
		SetFailState("Error opening the models file");
	}
	g_iFileCategory[client] = 0;
	while(ReadFileLine(file, buffer, sizeof(buffer)))
	{
		len = strlen(buffer);
		if (buffer[len-1] == '\n')
		{
			buffer[--len] = '\0';
		}
		if(StrContains(buffer, "//Category Vehicles") >= 0)
		{
			g_iFileCategory[client] = 1;
			continue;
		}
		else if(StrContains(buffer, "//Category Foliage") >= 0)
		{
			g_iFileCategory[client] = 2;
			continue;
		}
		else if(StrContains(buffer, "//Category Interior") >= 0)
		{
			g_iFileCategory[client] = 3;
			continue;
		}
		else if(StrContains(buffer, "//Category Exterior") >= 0)
		{
			g_iFileCategory[client] = 4;
			continue;
		}
		else if(StrContains(buffer, "//Category Decorative") >= 0)
		{
			g_iFileCategory[client] = 5;
			continue;
		}
		else if(StrContains(buffer, "//Category Misc") >= 0)
		{
			g_iFileCategory[client] = 6;
			continue;
		}
		if(StrEqual(buffer, ""))
		{
			continue;
		}
		if(g_iFileCategory[client] != 6)
		{
			continue;
		}
		SplitString(buffer, " TAG-", ItemModel, sizeof(ItemModel));
	
		strcopy(ItemTag, sizeof(ItemTag), buffer);
		
		ReplaceString(ItemTag, sizeof(ItemTag), ItemModel, "", false);
		ReplaceString(ItemTag, sizeof(ItemTag), " TAG- ", "", false);
		AddMenuItem(menu, ItemModel, ItemTag);
		
		if(IsEndOfFile(file))
		{
			break;
		}
	}
	SetMenuTitle(menu, "Misc");
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	CloseHandle(file);
}

public MenuHandler_DoAction(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			decl String:model[256];
			GetMenuItem(menu, param2, model, sizeof(model));
			if(!IsModelPrecached(model))
			{
				PrecacheModel(model);
			}
			if(IsModelPrecached(model))
			{
				SetEntityModel(param1, model);
				PrintToChat(param1, "\x04[model]\x05 把自己变成:\x01 %s", model);
			}
			else
			{
				PrintToChat(param1, "\x04[model]\x05 模型未加载!", model);
			}
			switch(g_iSubCategory[param1])
			{
				case 1:
				{
					DisplayVehiclesMenu(param1);
				}
				case 2:
				{
					DisplayFoliageMenu(param1);
				}
				case 3:
				{
					DisplayInteriorMenu(param1);
				}
				case 4:
				{
					DisplayExteriorMenu(param1);
				}
				case 5:
				{
					DisplayDecorativeMenu(param1);
				}
				case 6:
				{
					DisplayMiscMenu(param1);
				}
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
			{
				FakeClientCommand(param1, "sm_modse");
			}
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

public Action:Command_modra(client, args)
{
	if (GetClientTeam(client) == 2)
	{
		draw_function(client);
	}
	else
	{
		PrintToChat(client, "此功能只有幸存者可以使用!");
	}
	return Action:0;
}

public Action:draw_function(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel(Handle:0);
	if (!rolled[Client])
	{
		Format(line, 256, "   -抽奖系统列表-");
		SetPanelTitle(menu, line, false);
		Format(line, 256, "开始抽奖");
		DrawPanelItem(menu, line, 0);
		DrawPanelItem(menu, "Exit", 1);
		SendPanelToClient(menu, Client, ModelRaMenuHandler, 0);
		CloseHandle(menu);
	}
	else
	{
		Format(line, 256, "  -祝您好运-");
		SetPanelTitle(menu, line, false);
		Format(line, 256, "~~~~~~~~~~~~~~");
		DrawPanelText(menu, line);
		Format(line, 256, "   抽奖中...  ");
		DrawPanelText(menu, line);
		Format(line, 256, "~~~~~~~~~~~~~~");
		DrawPanelText(menu, line);
		Format(line, 256, "-停-");
		DrawPanelItem(menu, line, 0);
		DrawPanelItem(menu, "如果列表关闭,请再次打开,选择:-停-", 1);
		SendPanelToClient(menu, Client, Stop, 0);
		CloseHandle(menu);
	}
	return Action:0;
}

public ModelRaMenuHandler(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction:4)
	{
		switch (param)
		{
			case 1:
			{
				Award_List(Client);
			}
			case 2:
			{
				draw_function(Client);
				EmitSoundToClient(Client, "buttons/button14.wav", -2, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
			}
			case 3:
			{
				draw_function(Client);
				EmitSoundToClient(Client, "buttons/button14.wav", -2, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
			}
			default:
			{
			}
		}
	}
	return 0;
}

public Action:Award_List(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel(Handle:0);
	Format(line, 256, "-前一次的模型-");
	SetPanelTitle(menu, line, false);
	Format(line, 256, "%s", ModelTags[ModelRaSe[Client]]);
	DrawPanelText(menu, line);
	Format(line, 256, "开始抽奖");
	DrawPanelItem(menu, line, 0);
	Format(line, 256, "返回");
	DrawPanelItem(menu, line, 0);
	DrawPanelItem(menu, "Exit", 1);
	SendPanelToClient(menu, Client, Start, 0);
	CloseHandle(menu);
	return Action:0;
}

public Start(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction:4)
	{
		switch (param)
		{
			case 1:
			{
				StopTime[Client] = CreateTimer(0.04, Roll, Client, 1);
				rolled[Client] = true;
				draw_function(Client);
			}
			case 2:
			{
				draw_function(Client);
			}
			default:
			{
			}
		}
	}
	return 0;
}

public Stop(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction:4)
	{
		switch (param)
		{
			case 1:
			{
				KillTimer(StopTime[Client], false);
				rolled[Client] = false;
				sift[Client] = true;
				Model_List(Client);
			}
			default:
			{
			}
		}
	}
	return 0;
}

public Action:Roll(Handle:timer, any:Client)
{
	new n1 = GetRandomInt(0, ModelNum);
	new n2 = GetRandomInt(0, ModelNum);
	new n3 = GetRandomInt(0, ModelNum);
	ModelRa[Client][0] = n1;
	ModelRa[Client][1] = n2;
	ModelRa[Client][2] = n3;
	ModelRaSe[Client] = n1;
	PrintCenterText(Client, "★抽奖中★\n%s%s%s请在列表中选择: -停- ", ModelTags[n1], ModelTags[n2], ModelTags[n3]);
	EmitSoundToClient(Client, "ui/littlereward.wav", -2, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	return Action:0;
}

public Action:Model_List(Client)
{
	PrintToChat(Client, "\x03你抽到了\n\x02%s%s%s", Client, 
		ModelTags[ModelRa[Client][0]], ModelTags[ModelRa[Client][1]], ModelTags[ModelRa[Client][2]]);
	EmitSoundToClient(Client, "level/gnomeftw.wav", -2, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	decl String:line[256];
	new Handle:menu = CreatePanel(Handle:0);
	Format(line, 256, "-抽到的模型-");
	SetPanelTitle(menu, line, false);
	Format(line, 256, "%s", ModelTags[ModelRa[Client][0]]);
	DrawPanelItem(menu, line);
	Format(line, 256, "%s", ModelTags[ModelRa[Client][1]]);
	DrawPanelItem(menu, line, 0);
	Format(line, 256, "%s", ModelTags[ModelRa[Client][2]]);
	DrawPanelItem(menu, line, 0);
	SendPanelToClient(menu, Client, ModelSelect, 0);
	CloseHandle(menu);
	return Action:0;
}

public ModelSelect(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction:4)
	{
		decl String:model[256];
		ModelRaSe[Client] = ModelRa[Client][param-1]
		strcopy(model, sizeof(model), ModelNames[ModelRaSe[Client]]);
		if(!IsModelPrecached(model))
		{
			PrecacheModel(model);
		}
		SetEntityModel(Client, model);
		RemoveWeapon(Client)
		PrintToChat(Client, "\x04[model]\x05 把自己变成:\x01 %s", ModelTags[ModelRaSe[Client]]);
	}
	return 0;
}

public Action:RemoveWeapon(Client)
{
	for (int i = 0; i < 5; i++)
	{
		int ent = GetPlayerWeaponSlot(Client, i);
		if (IsValidEnt(ent))
		{
			RemoveEdict(ent);
		}
	}
	return Action:0;
}

IsValidEnt(ent)
{
	if (ent > 0 && IsValidEdict(ent) && IsValidEntity(ent))
	{
		return 1;
	}
	return 0;
}

public Action:Command_stop(client, args)
{
	if (GetClientTeam(client) == 2)
	{
		if (Stopped[client])
		{
			SetEntityMoveType(client, MOVETYPE_WALK);
			Stopped[client] = false;
		}
		else
		{
			SetEntityMoveType(client, MOVETYPE_NONE);
			GetEntPropVector(client, PropType:0, "m_angRotation", ang[client], 0);
			SetEntPropVector(client, PropType:0, "m_angRotation", ang[client], 0);
			Stopped[client] = true;
			// DispatchKeyValueVector(prop, "angles", ang[client]);
		}
		
	}
	else
	{
		PrintToChat(client, "此功能只有幸存者可以使用!");
	}
	return Action:0;
}

public Action:Command_refresh(client, args)
{
	if (GetClientTeam(client) == 2)
	{
		
	}
	else
	{
		PrintToChat(client, "此功能只有幸存者可以使用!");
	}
	return Action:0;
}

