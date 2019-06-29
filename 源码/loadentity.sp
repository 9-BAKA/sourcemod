#include <sourcemod>
#include <sdktools>
#include <float>

#define PLUGIN_NAME					"加载造物及特殊造物"
#define PLUGIN_AUTHOR				"Tony G."
#define PLUGIN_DESCRIPTION	"SourceMod replacement for the Mani teleport functionality"
#define PLUGIN_VERSION			"1.11"
#define PLUGIN_URL					"http://www.i3d.net/"

new Handle:g_hCvar_JumpModEnabled;
new NowEntity;
new SpawnFlags[2150];
new bool:liftshowbeam[100];
new EntTypeCount;

public Plugin:myinfo = {name = PLUGIN_NAME, author = PLUGIN_AUTHOR, description = PLUGIN_DESCRIPTION, version = PLUGIN_VERSION, url = PLUGIN_URL};

public OnPluginStart()
{

	RegAdminCmd("sm_etp", CmdLoadAndSave, 16384, "打开保存和读取菜单.", "", 0);
	RegAdminCmd("sm_etload", CmdEtLoad, 16384, "载入数据.", "", 0);
	
	g_hCvar_JumpModEnabled = CreateConVar("sm_jump_enable", "1", "开启跳跃服", FCVAR_NOTIFY);

	AutoExecConfig(true, "loadentity");

}

public Action:CmdEtLoad(client, args)
{
	if (args < 1)
	{
		decl String:map[256];
		decl String:FileNameS[256];
		GetCurrentMap(map, 256);
		BuildPath(PathType:0, FileNameS, 256, "data/EntType/%s", map);
		new map_number = GetNextMapNumber(FileNameS);
		PrintToChat(client, "{olive} 请输入正确的编号!\n{olive}最大编号数为：{red}%i", map_number + -1);
		return Action:0;
	}
	decl String:arg[8];
	GetCmdArgString(arg, 5);
	new number = StringToInt(arg, 10);
	LoadFromFile(number);
	return Action:0;
}

LoadFromFileInfo(client)
{
	decl String:map[256];
	decl String:FileNameS[256];
	GetCurrentMap(map, 256);
	BuildPath(PathType:0, FileNameS, 256, "data/EntType/%s.txt", map);
	new map_number = GetNextMapNumber(FileNameS);
	PrintToChat(client, "请输入\x05!etload 编号\n\x03最大编号数为：\x05%i", map_number + -1);
	return 0;
}

LoadFromFile(number)
{
	PrintToChatAll("{olive} 载入特殊实体编号：{red}%i", number);
	new Handle:keyvalues;
	decl String:KvFileName[256];
	decl String:map[256];
	decl String:name[256];
	GetCurrentMap(map, 256);
	BuildPath(PathType:0, KvFileName, 256, "data/EntType/%s_%i.txt", map, number);
	if (!FileExists(KvFileName, false))
	{
		return 0;
	}
	keyvalues = CreateKeyValues("EntType", "", "");
	FileToKeyValues(keyvalues, KvFileName);
	KvRewind(keyvalues);
	if (KvJumpToKey(keyvalues, "total_cache", false))
	{
		new max = KvGetNum(keyvalues, "total", 0);
		if (0 >= max)
		{
			return 0;
		}
		decl String:model[256];
		decl Float:vecOrigin[3];
		KvRewind(keyvalues);
		new count = 1;
		while (count <= max)
		{
			Format(name, 256, "EntType_%i", count);
			if (KvJumpToKey(keyvalues, name, false))
			{
				new type;
				KvGetVector(keyvalues, "origin", vecOrigin);
				KvGetString(keyvalues, "model", model, 256, "");
				type = KvGetNum(keyvalues, "Type", 0);
				if (0 < type)
				{
					new Float:pos[3] = 0.0;
					new entity = MaxClients;
					while (entity < 2150)
					{
						if (IsValidEdict(entity))
						{
							SpawnFlags[entity] = KvGetNum(keyvalues, "SpawnFlags", 0);
							decl String:clsname[256];
							GetEdictClassname(entity, clsname, 256);
							new id = FindIdEntPropByEntity(entity);
							new var1;
							if (id == -1 && StrContains(clsname, "prop_", true) != -1)
							{
								decl String:sModel[256];
								GetEntPropString(entity, PropType:1, "m_ModelName", sModel, 256, 0);
								GetEntPropVector(entity, PropType:0, "m_vecOrigin", pos, 0);
								new var2;
								if (RoundToFloor(pos[0]) == RoundToFloor(vecOrigin[0]) && RoundToFloor(pos[1]) == RoundToFloor(vecOrigin[1]) && RoundToFloor(pos[2]) == RoundToFloor(vecOrigin[2]) && StrEqual(sModel, model, true))
								{
									switch (type)
									{
										case 1:
										{
											BecomeIntoFire(entity);
										}
										case 2:
										{
											BecomeIntoIce(entity, KvGetFloat(keyvalues, "Ice_Speed", 0.0));
										}
										case 3:
										{
											BecomeIntoJump(entity, KvGetFloat(keyvalues, "Jump_power", 0.0));
										}
										case 4:
										{
											BecomeIntoThrow(entity, KvGetFloat(keyvalues, "Throw_Power", 0.0));
										}
										case 5:
										{
											BecomeIntoBreak(entity, KvGetNum(keyvalues, "Break_Helth", 0));
										}
										case 6:
										{
											new Float:tele[3] = 0.0;
											KvGetVector(keyvalues, "TP_Pos", tele);
											BecomeIntoTeleport(entity, tele);
										}
										case 7:
										{
											BecomeIntoDie(entity);
										}
										case 8:
										{
											BecomeIntoShake(entity);
										}
										case 9:
										{
											BecomeIntoRun(entity);
										}
										case 10:
										{
											BecomeIntoHeavy(entity, KvGetFloat(keyvalues, "Heavy", 0.0));
										}
										case 11:
										{
											new shot;
											new touch;
											new bool:s;
											new bool:t;
											shot = KvGetNum(keyvalues, "IsShot", 0);
											touch = KvGetNum(keyvalues, "IsTouch", 0);
											if (shot == 1)
											{
												s = true;
											}
											if (touch == 1)
											{
												t = true;
											}
											BecomeIntoBreakEx(entity, s, t);
										}
										case 12:
										{
											new speed;
											new pacount;
											new Float:papos[20][3] = {8.5899346e9,5.6294995e14,3.6893488e19,2.4178516e24,1.58456325e29,1.0384594e34,-0.0,-3.85186e-34,-2.5243549e-29,-1.6543612e-24,-1.0842022e-19,-7.1054274e-15,-4.656613e-10,-3.0517578e-5,-2.0,-131072.0,-8.5899346e9,-5.6294995e14,-3.6893488e19,-2.4178516e24};
											new bool:showbeam;
											new bool:bDamage;
											pacount = KvGetNum(keyvalues, "PathCount", 0);
											showbeam = KvGetBool(keyvalues, "ShowBeam");
											speed = KvGetNum(keyvalues, "LiftSpeed", 0);
											bDamage = KvGetBool(keyvalues, "LiftDamage");
											new path;
											while (path < pacount)
											{
												decl String:sTemp2[256];
												Format(sTemp2, 256, "PathPos_%d", path);
												KvGetVector(keyvalues, sTemp2, papos[path]);
												path++;
											}
											liftshowbeam[EntTypeCount] = showbeam;
											BecomeIntoLift(entity, speed, pacount, papos, bDamage, SpawnFlags[entity]);
										}
										case 13:
										{
											new Float:endpos[3] = 0.0;
											new ldamage;
											new lwidth;
											ldamage = KvGetNum(keyvalues, "LaserDamage", 0);
											lwidth = KvGetNum(keyvalues, "LaserWidth", 0);
											KvGetVector(keyvalues, "LaserEndPos", endpos);
											BecomeIntoLaser(entity, ldamage, lwidth, endpos);
										}
										case 14:
										{
											decl ringspeed;
											new pacount;
											ringspeed = KvGetNum(keyvalues, "RotatingSpeed", pacount);
											new Float:point[3] = 0.0;
											new Float:entpoint[3] = 0.0;
											KvGetVector(keyvalues, "RotatingPoint", point);
											KvGetVector(keyvalues, "RotatingEntPoint", entpoint);
											BecomeIntoRotating(entity, ringspeed, point, entpoint, SpawnFlags[entity]);
										}
										case 15:
										{
											new String:msg[256];
											new String:ico[256];
											new Float:cl[3] = 0.0;
											new cl2[3];
											KvGetString(keyvalues, "InfoMessage", msg, 256, "");
											KvGetString(keyvalues, "InfoIcon", ico, 256, "");
											KvGetVector(keyvalues, "InfoColor", cl);
											cl2[0] = RoundToFloor(cl[0]);
											cl2[1] = RoundToFloor(cl[1]);
											cl2[2] = RoundToFloor(cl[2]);
											BecomeIntoInfo(entity, msg, ico, cl2, 5);
										}
										case 16:
										{
											new String:command[1024];
											new String:namearg[256];
											new Float:epos[3] = 0.0;
											new eventcount = KvGetNum(keyvalues, "TargetEventCount", 0);
											new event;
											while (event < eventcount)
											{
												new String:sTemp2[256];
												Format(sTemp2, 256, "EventObject_%d", event);
												KvGetVector(keyvalues, sTemp2, epos);
												new object1 = FindEntityByPos(epos);
												if (!(object1 == -1))
												{
													Format(sTemp2, 256, "Event_%d", event);
													KvGetString(keyvalues, sTemp2, namearg, 256, "");
													new var3;
													if (!StrEqual(namearg, "", true) && IsValidEdict(object1))
													{
														new String:nowCmd[64];
														Format(nowCmd, 64, "%d,%s\n", object1, namearg);
														StrCat(command, 1024, nowCmd);
													}
												}
												event++;
											}
											BecomeIntoTarget(entity, command, 1024);
										}
										case 17:
										{
											BecomeIntoHaiMian(entity);
										}
										case 18:
										{
											new speed = 1140457472;
											BecomeIntoXiWu(entity, speed);
										}
										case 19:
										{
											new speed = 1140457472;
											BecomeIntoTuiWu(entity, speed);
										}
										case 20:
										{
											BecomeIntoJiaXue(entity);
										}
										case 21:
										{
											BecomeIntoShuFu(entity);
										}
										case 22:
										{
											BecomeIntoColors(entity);
										}
										case 23:
										{
											BecomeIntoAlpha(entity);
										}
										case 24:
										{
										}
										case 25:
										{
											BecomeIntoJianyin(entity);
										}
										case 26:
										{
											BecomeIntoJianxian(entity);
										}
										case 27:
										{
											BecomeIntoFuHuo(entity);
										}
										case 28:
										{
											BecomeIntoLucky(entity);
										}
										case 29:
										{
											new pacount = 1198824;
											BecomeIntoJumpEx(entity, KvGetFloat(keyvalues, pacount));
										}
										case 30:
										{
											new pacount = 1198840;
											BecomeIntoThrowex(entity, KvGetFloat(keyvalues, pacount));
										}
										case 31:
										{
											new Float:teleex[3] = 0.0;
											KvGetVector(keyvalues, "TP_Posex", teleex);
											BecomeIntoTeleportex(entity, teleex);
										}
										case 32:
										{
											BecomeIntoDieShot(entity);
										}
										case 33:
										{
											new Float:telenocolors[3] = 0.0;
											KvGetVector(keyvalues, "TP_Posnocolors", telenocolors);
											BecomeIntoTeleportnocolors(entity, telenocolors);
										}
										case 34:
										{
											new Float:telenocolorstouch[3] = 0.0;
											KvGetVector(keyvalues, "TP_Posnocolorstouch", telenocolorstouch);
											BecomeIntoTeleportnocolorstouch(entity, telenocolorstouch);
										}
										case 35:
										{
											new pacount = 1198904;
											BecomeIntoBlind(entity, KvGetFloat(keyvalues, pacount));
										}
										case 36:
										{
											BecomeIntoSavePos(entity);
										}
										case 37:
										{
											BecomeIntoLights(entity);
										}
										default:
										{
										}
									}
								}
							}
						}
						entity++;
					}
				}
				KvRewind(keyvalues);
				count++;
			}
		}
	}
	CloseHandle(keyvalues);
	new max = 1198916;
	PrintToChatAll(max);
	return 0;
}

FindEntityByPos(Float:pos[3])
{
	new entity = MaxClients;
	while (entity < 2150)
	{
		if (IsValidEdict(entity))
		{
			decl String:clsname[256];
			GetEdictClassname(entity, clsname, 256);
			if (StrContains(clsname, "prop_", true) != -1)
			{
				decl Float:vecOrigin[3];
				GetEntPropVector(entity, PropType:0, "m_vecOrigin", vecOrigin, 0);
				new var1;
				if (RoundToFloor(pos[0]) == RoundToFloor(vecOrigin[0]) && RoundToFloor(pos[1]) == RoundToFloor(vecOrigin[1]) && RoundToFloor(pos[2]) == RoundToFloor(vecOrigin[2]))
				{
					return entity;
				}
			}
		}
		entity++;
	}
	return -1;
}

GetNextMapNumber(String:FileName[])
{
	decl String:FileNameS[256];
	new i = 1;
	while (i <= 20)
	{
		Format(FileNameS, 256, "%s_%i.txt", FileName, i);
		if (!(FileExists(FileNameS, false)))
		{
			return i;
		}
		i++;
	}
	return -1;
}

public Action:CmdLoadAndSave(client, args)
{
	new Handle:menu = CreateMenu(MenuHandler_LoadAndSave, MenuAction:28);
	SetMenuTitle(menu, "保存/读取菜单");
	SetMenuExitButton(menu, true);
	AddMenuItem(menu, "item1", "保存当前地图文件", 0);
	AddMenuItem(menu, "item2", "读取当前地图文件", 0);
	AddMenuItem(menu, "item3", "让所有的电梯板都显示路径", 0);
	AddMenuItem(menu, "item4", "让所有的电梯板都隐藏路径", 0);
	AddMenuItem(menu, "item5", "让所有的电梯板都停下来", 0);
	AddMenuItem(menu, "item6", "让所有的电梯板都继续", 0);
	DisplayMenu(menu, client, 0);
	return Action:0;
}

public MenuHandler_LoadAndSave(Handle:menu, MenuAction:action, client, item)
{
	switch (action)
	{
		case 4:
		{
			switch (item)
			{
				case 0:
				{
					SaveToFile(client);
				}
				case 1:
				{
					LoadFromFileInfo(client);
				}
				case 2:
				{
					new id;
					while (id < EntTypeCount)
					{
						new var4;
						if (IsValidEdict(EntProp[id]) && nType[id] == 12 && liftinfo[id][2] >= 2)
						{
							liftshowbeam[id] = 1;
						}
						id++;
					}
				}
				case 3:
				{
					new id;
					while (id < EntTypeCount)
					{
						new var3;
						if (IsValidEdict(EntProp[id]) && nType[id] == 12 && liftinfo[id][2] >= 2)
						{
							liftshowbeam[id] = 0;
						}
						id++;
					}
				}
				case 4:
				{
					new id;
					while (id < EntTypeCount)
					{
						new var2;
						if (IsValidEdict(EntProp[id]) && nType[id] == 12 && IsValidEdict(liftinfo[id][0]))
						{
							AcceptEntityInput(liftinfo[id][0], "Stop", -1, -1, 0);
						}
						id++;
					}
				}
				case 5:
				{
					new id;
					while (id < EntTypeCount)
					{
						new var1;
						if (IsValidEdict(EntProp[id]) && nType[id] == 12 && IsValidEdict(liftinfo[id][0]))
						{
							AcceptEntityInput(liftinfo[id][0], "Resume", -1, -1, 0);
						}
						id++;
					}
				}
				default:
				{
				}
			}
		}
		case 8:
		{
		}
		default:
		{
		}
	}
	return 0;
}

public GetClientAimTargetEx(client)
{
	decl Float:VecOrigin[3];
	decl Float:VecAngles[3];
	GetClientEyePosition(client, VecOrigin);
	GetClientEyeAngles(client, VecAngles);
	TR_TraceRayFilter(VecOrigin, VecAngles, 33636363, RayType:1, TraceRayDontHitSelf, client);
	if (TR_DidHit(Handle:0))
	{
		return TR_GetEntityIndex(Handle:0);
	}
	return -1;
}

FindIdEntPropByEntity(entity)
{
	new id;
	while (id < EntTypeCount)
	{
		if (entity == EntProp[id])
		{
			return id;
		}
		id++;
	}
	return -1;
}

SetEntitySpecialType(client, entity, type)
{
	if (type)
	{
		switch (type)
		{
			case 1:
			{
				BecomeIntoFire(entity);
			}
			case 2:
			{
				ShowChooseIceSpeedMenu(client, entity);
			}
			case 3:
			{
				ShowChooseJumpPowerMenu(client, entity);
			}
			case 4:
			{
				ShowChooseThrowPowerMenu(client, entity);
			}
			case 5:
			{
				ShowChooseBreakHealthMenu(client, entity);
			}
			case 6:
			{
				ShowChooseTelePosMenu(client, entity);
			}
			case 7:
			{
				BecomeIntoDie(entity);
			}
			case 8:
			{
				BecomeIntoShake(entity);
			}
			case 9:
			{
				BecomeIntoRun(entity);
			}
			case 10:
			{
				ShowChooseHeaPowerMenu(client, entity);
			}
			case 11:
			{
				ShowChooseBreakExFlagsMenu(client, entity);
			}
			case 12:
			{
				ShowChooseLiftFlagsMenu(client, entity);
			}
			case 13:
			{
				ShowChooseLaserFlagsMenu(client, entity);
			}
			case 14:
			{
				ShowChooseRotFlagsMenu(client, entity);
			}
			case 15:
			{
				ShowChooseInfoFlagsMenu(client, entity);
			}
			case 16:
			{
				ShowChooseTargetFlagsMenu(client, entity);
			}
			case 17:
			{
				BecomeIntoHaiMian(entity);
			}
			case 18:
			{
				BecomeIntoXiWu(entity, 800.0);
			}
			case 19:
			{
				BecomeIntoTuiWu(entity, 800.0);
			}
			case 20:
			{
				BecomeIntoJiaXue(entity);
			}
			case 21:
			{
				BecomeIntoShuFu(entity);
			}
			case 22:
			{
				BecomeIntoColors(entity);
			}
			case 23:
			{
				BecomeIntoAlpha(entity);
			}
			case 24:
			{
				BecomeIntoBaoZha(entity);
			}
			case 25:
			{
				BecomeIntoJianyin(entity);
			}
			case 26:
			{
				BecomeIntoJianxian(entity);
			}
			case 27:
			{
				BecomeIntoFuHuo(entity);
			}
			case 28:
			{
				BecomeIntoLucky(entity);
			}
			case 29:
			{
				ShowChooseJumpPowerMenuEx(client, entity);
			}
			case 30:
			{
				ShowChooseThrowPowerMenuex(client, entity);
			}
			case 31:
			{
				ShowChooseTelePosMenuex(client, entity);
			}
			case 32:
			{
				BecomeIntoDieShot(entity);
			}
			case 33:
			{
				ShowChooseTelePosMenunocolors(client, entity);
			}
			case 34:
			{
				ShowChooseTelePosMenunocolorstouch(client, entity);
			}
			case 35:
			{
				ShowChooseBlindMenu(client, entity);
			}
			case 36:
			{
				BecomeIntoSavePos(entity);
			}
			case 37:
			{
				BecomeIntoLights(entity);
			}
			default:
			{
			}
		}
		return 1;
	}
	new id = FindIdEntPropByEntity(entity);
	LogMessage("SetEntType:%d,id:%d", entity, id);
	new var1;
	if (id != -1 && nType[id] > 0)
	{
		if (nType[id] == 12)
		{
			new var2;
			if (liftinfo[id][0] > MaxClients && IsValidEdict(entity))
			{
				RemoveEdict(liftinfo[id][0]);
			}
			if (0 < liftinfo[id][2])
			{
				new i;
				while (liftinfo[id][2] > i)
				{
					new var3;
					if (liftpath[id][i] > MaxClients && IsValidEdict(liftpath[id][i]))
					{
						if (i)
						{
							if (liftinfo[id][2][0] == i)
							{
								UnhookSingleEntityOutput(liftpath[id][i], "OnPass", EntityOutput_OnPass_End);
							}
						}
						else
						{
							UnhookSingleEntityOutput(liftpath[id][i], "OnPass", EntityOutput_OnPass_Start);
						}
						RemoveEdict(liftpath[id][i]);
					}
					i++;
				}
			}
		}
		else
		{
			if (nType[id] == 14)
			{
				new var4;
				if (rotrot[id] > MaxClients && IsValidEdict(rotrot[id]))
				{
					RemoveEdict(rotrot[id]);
				}
				new var5;
				if (rotent[id] > MaxClients && IsValidEdict(rotent[id]))
				{
					RemoveEdict(rotent[id]);
				}
			}
			if (nType[id] == 13)
			{
				new var6;
				if (laserprop[id] > MaxClients && IsValidEdict(laserprop[id]))
				{
					RemoveEdict(laserprop[id]);
				}
			}
			if (nType[id] == 16)
			{
				new j;
				while (TargetEventCount[id] > j)
				{
					TargetObject[id][j] = 0;
					strcopy(TargetEventName[id][j], 256, "");
					strcopy(TargetEventArg[id][j], 256, "");
					j++;
				}
				TargetEventCount[id] = 0;
				new var7;
				if (!IsValidEdict(TargetButton[id]) && TargetButton[id])
				{
					RemoveEdict(TargetButton[id]);
					TargetButton[id] = 0;
				}
			}
			if (nType[id] == 37)
			{
				PrintToChat(client, "\x04[凡梦]\x05 移除后还是有显示属于正常，重新加载地图就好了。");
			}
		}
		nType[id] = 0;
		EntProp[id] = 0;
		icespeed[id] = 0;
		jumppower[id] = 0;
		throwpower[id] = 0;
		MaxHealth[id] = 0;
		Health[id] = 0;
		liftinfo[id][1] = 0;
		liftinfo[id][0] = 0;
		liftinfo[id][2] = 0;
		liftshowbeam[id] = 0;
		liftdamage[id] = 0;
		CopyVector(Pos[id], NULL_VECTOR, 3);
		CopyVector(Posex[id], NULL_VECTOR, 3);
		CopyVector(Posnocolors[id], NULL_VECTOR, 3);
		CopyVector(Posnocolorstouch[id], NULL_VECTOR, 3);
		rotspeed[id] = 0;
		rotrot[id] = 0;
		rotent[id] = 0;
		Blind[id] = 0;
		strcopy(InfoMessage[id], 256, "");
		strcopy(InfoIcon[id], 256, "");
		CopyVector(InfoColor[id], NULL_VECTOR, 3);
		PrintToChat(client, "\x04[凡梦]\x05 移除成功!\x04编号：%d", entity);
		SetEntityRenderColor(entity, 255, 255, 255, 255);
		SetEntityRenderFx(entity, RenderFx:0);
		SetEntProp(entity, PropType:0, "m_iGlowType", any:0, 4, 0);
		return 1;
	}
	return 0;
}

BecomeIntoFire(entity)
{
	new var1;
	if (entity <= 0 || !IsValidEdict(entity))
	{
		return 0;
	}
	SetEntityRenderColor(entity, 255, 0, 0, 255);
	nType[EntTypeCount] = 1;
	EntProp[EntTypeCount] = entity;
	EntTypeCount += 1;
	SDKUnhook(entity, SDKHookType:10, SDKCallBackFire_Touched);
	SDKHook(entity, SDKHookType:10, SDKCallBackFire_Touched);
	return 0;
}

FirePerson(victim, Float:damage)
{
	if (0 < PointHurt)
	{
		if (IsValidEdict(PointHurt))
		{
			new var1;
			if (victim > 0 && IsValidEdict(victim))
			{
				decl String:N[20];
				Format(N, 20, "target%d", victim);
				DispatchKeyValue(victim, "targetname", N);
				DispatchKeyValue(PointHurt, "DamageTarget", N);
				DispatchKeyValueFloat(PointHurt, "Damage", damage);
				DispatchKeyValue(PointHurt, "DamageType", "8");
				AcceptEntityInput(PointHurt, "Hurt", -1, -1, 0);
			}
		}
		else
		{
			PointHurt = CreatePointHurt();
			FirePerson(victim, damage);
		}
	}
	else
	{
		PointHurt = CreatePointHurt();
		FirePerson(victim, damage);
	}
	return 0;
}

public SDKCallBackFire_Touched(entity, toucher)
{
	new id = FindIdEntPropByEntity(entity);
	if (id == -1)
	{
		return 0;
	}
	if (nType[id] != 1)
	{
		SDKUnhook(entity, SDKHookType:10, SDKCallBackFire_Touched);
		return 0;
	}
	new var1;
	if (toucher < MaxClients && IsPlayerAlive(toucher))
	{
		FireTime[toucher]++;
		if (FireTime[toucher] <= 15)
		{
			return 0;
		}
		FireTime[toucher] = 0;
	}
	FirePerson(toucher, 5.0);
	return 0;
}

CreatePointHurt()
{
	new pointHurt = CreateEntityByName("point_hurt", -1);
	if (pointHurt)
	{
		DispatchKeyValue(pointHurt, "Damage", "10");
		DispatchSpawn(pointHurt);
	}
	return pointHurt;
}

BecomeIntoIce(entity, Float:speed)
{
	new var1;
	if (entity <= 0 || !IsValidEdict(entity))
	{
		return 0;
	}
	SetEntityRenderColor(entity, 0, 0, 100, 255);
	icespeed[EntTypeCount] = speed;
	nType[EntTypeCount] = 2;
	EntProp[EntTypeCount] = entity;
	EntTypeCount += 1;
	SDKUnhook(entity, SDKHookType:10, SDKCallBackIce_Touched);
	SDKHook(entity, SDKHookType:10, SDKCallBackIce_Touched);
	return 0;
}

SetPlayerSpeed(client, Float:speed)
{
	SetEntPropFloat(client, PropType:1, "m_flLaggedMovementValue", speed, 0);
	return 0;
}

ShowChooseIceSpeedMenu(client, entity)
{
	new Handle:menu = CreateMenu(MenuHandler_ChooseIceSpeed, MenuAction:28);
	SetMenuExitButton(menu, true);
	SetMenuTitle(menu, "请选择滑冰板的速度,编号:%d", entity);
	AddMenuItem(menu, "0.2", "0.2", 0);
	AddMenuItem(menu, "0.8", "0.8", 0);
	AddMenuItem(menu, "1.0", "标准速度", 0);
	AddMenuItem(menu, "1.5", "1.5", 0);
	AddMenuItem(menu, "5.0", "5.0", 0);
	AddMenuItem(menu, "10.0", "10.0", 0);
	DisplayMenu(menu, client, 0);
	NowEntity = entity;
	return 0;
}

public MenuHandler_ChooseIceSpeed(Handle:menu, MenuAction:action, client, item)
{
	switch (action)
	{
		case 4:
		{
			new var1;
			if (NowEntity <= 0 || !IsValidEdict(NowEntity))
			{
				return 0;
			}
			decl String:sType[64];
			new Float:speed = 0.0;
			GetMenuItem(menu, item, sType, 64, 0, "", 0);
			speed = StringToFloat(sType);
			if (speed < 0.0)
			{
				return 0;
			}
			BecomeIntoIce(NowEntity, speed);
		}
		case 8:
		{
		}
		default:
		{
		}
	}
	return 0;
}

public SDKCallBackIce_Touched(entity, toucher)
{
	new id = FindIdEntPropByEntity(entity);
	if (id == -1)
	{
		return 0;
	}
	if (nType[id] != 2)
	{
		SDKUnhook(entity, SDKHookType:10, SDKCallBackIce_Touched);
		return 0;
	}
	new var1;
	if (toucher < MaxClients && IsPlayerAlive(toucher))
	{
		SetPlayerSpeed(toucher, icespeed[id]);
	}
	return 0;
}

BecomeIntoJump(entity, Float:power)
{
	new var1;
	if (entity <= 0 || !IsValidEdict(entity))
	{
		return 0;
	}
	SetEntityRenderColor(entity, 255, 165, 0, 255);
	jumppower[EntTypeCount] = power;
	nType[EntTypeCount] = 3;
	EntProp[EntTypeCount] = entity;
	EntTypeCount += 1;
	SDKUnhook(entity, SDKHookType:10, SDKCallBackJump_Touched);
	SDKHook(entity, SDKHookType:10, SDKCallBackJump_Touched);
	return 0;
}

JumpPerson(person, Float:power)
{
	new var1;
	if (person > MaxClients && IsValidEdict(person))
	{
		return 0;
	}
	new Handle:pack = CreateDataPack();
	WritePackCell(pack, person);
	WritePackFloat(pack, power);
	CreateTimer(0.2, TimerJump, pack, 0);
	return 0;
}

public Action:TimerJump(Handle:timer, any:pack)
{
	ResetPack(pack, false);
	new person = ReadPackCell(pack);
	new Float:power = ReadPackFloat(pack);
	new Float:velo[3] = 0.0;
	velo[0] = GetEntPropFloat(person, PropType:0, "m_vecVelocity[0]", 0);
	velo[1] = GetEntPropFloat(person, PropType:0, "m_vecVelocity[1]", 0);
	velo[2] = GetEntPropFloat(person, PropType:0, "m_vecVelocity[2]", 0);
	if (velo[2] != 0.0)
	{
		return Action:0;
	}
	new Float:vec[3] = 0.0;
	vec[0] = velo[0];
	vec[1] = velo[1];
	vec[2] = velo[2] + power * 300.0;
	TeleportEntity(person, NULL_VECTOR, NULL_VECTOR, vec);
	EmitSoundFromPlayer(person, "buttons/blip1.wav");
	return Action:0;
}

ShowChooseJumpPowerMenu(client, entity)
{
	new Handle:menu = CreateMenu(MenuHandler_ChooseJumpPower, MenuAction:28);
	SetMenuExitButton(menu, true);
	SetMenuTitle(menu, "请选择弹跳板的力度,编号:%d", entity);
	AddMenuItem(menu, "1.0", "小", 0);
	AddMenuItem(menu, "1.7", "较小", 0);
	AddMenuItem(menu, "3.4", "中", 0);
	AddMenuItem(menu, "4.0", "大", 0);
	AddMenuItem(menu, "5.0", "最大", 0);
	AddMenuItem(menu, "25.0", "最大x5", 0);
	AddMenuItem(menu, "50.0", "最大x10", 0);
	DisplayMenu(menu, client, 0);
	NowEntity = entity;
	return 0;
}

public MenuHandler_ChooseJumpPower(Handle:menu, MenuAction:action, client, item)
{
	switch (action)
	{
		case 4:
		{
			new var1;
			if (NowEntity <= 0 || !IsValidEdict(NowEntity))
			{
				return 0;
			}
			decl String:sType[64];
			new Float:power = 0.0;
			GetMenuItem(menu, item, sType, 64, 0, "", 0);
			power = StringToFloat(sType);
			if (power < 0.0)
			{
				return 0;
			}
			BecomeIntoJump(NowEntity, power);
		}
		case 8:
		{
		}
		default:
		{
		}
	}
	return 0;
}

public SDKCallBackJump_Touched(entity, toucher)
{
	new id = FindIdEntPropByEntity(entity);
	if (id == -1)
	{
		return 0;
	}
	if (nType[id] != 3)
	{
		SDKUnhook(entity, SDKHookType:10, SDKCallBackJump_Touched);
		return 0;
	}
	new var1;
	if (toucher < MaxClients && !IsPlayerAlive(toucher))
	{
		return 0;
	}
	JumpPerson(toucher, jumppower[id]);
	return 0;
}

BecomeIntoThrow(entity, Float:power)
{
	new var1;
	if (entity <= 0 || !IsValidEdict(entity))
	{
		return 0;
	}
	SetEntityRenderColor(entity, 0, 255, 0, 255);
	throwpower[EntTypeCount] = power;
	nType[EntTypeCount] = 4;
	EntProp[EntTypeCount] = entity;
	EntTypeCount += 1;
	SDKUnhook(entity, SDKHookType:10, SDKCallBackThrow_Touched);
	SDKHook(entity, SDKHookType:10, SDKCallBackThrow_Touched);
	SDKUnhook(entity, SDKHookType:0, SDKCallBackThrow_EndTouch);
	SDKHook(entity, SDKHookType:0, SDKCallBackThrow_EndTouch);
	return 0;
}

ThrowPerson(person, Float:power, Float:origin[3], Float:angles[3])
{
	new var1;
	if (person > MaxClients || bThrow[person])
	{
		return 0;
	}
	new Handle:pack = CreateDataPack();
	WritePackCell(pack, person);
	WritePackFloat(pack, power);
	WritePackFloat(pack, origin[0]);
	WritePackFloat(pack, origin[1]);
	WritePackFloat(pack, origin[2]);
	WritePackFloat(pack, angles[0]);
	WritePackFloat(pack, angles[1]);
	WritePackFloat(pack, angles[2]);
	CreateTimer(0.3, TimerThrow, pack, 0);
	bThrow[person] = 1;
	return 0;
}

public Action:TimerThrow(Handle:timer, any:pack)
{
	ResetPack(pack, false);
	decl Float:vAngles[3];
	decl Float:vOrigin[3];
	new person = ReadPackCell(pack);
	if (!bThrow[person])
	{
		return Action:0;
	}
	new Float:power = ReadPackFloat(pack) * 3.0;
	vOrigin[0] = ReadPackFloat(pack);
	vOrigin[1] = ReadPackFloat(pack);
	vOrigin[2] = ReadPackFloat(pack);
	vAngles[0] = ReadPackFloat(pack);
	vAngles[1] = ReadPackFloat(pack);
	vAngles[2] = ReadPackFloat(pack);
	decl Float:VecOrigin[3];
	decl Float:pos[3];
	GetClientEyePosition(person, VecOrigin);
	TR_TraceRayFilter(VecOrigin, vAngles, 16513, RayType:1, TraceRayDontHitSelf, person);
	if (TR_DidHit(Handle:0))
	{
		TR_GetEndPosition(pos, Handle:0);
	}
	decl Float:volicity[3];
	SubtractVectors(pos, vOrigin, volicity);
	ScaleVector(volicity, power);
	volicity[2] = FloatAbs(volicity[2]);
	TeleportEntity(person, NULL_VECTOR, NULL_VECTOR, volicity);
	bThrow[person] = 0;
	EmitSoundFromPlayer(person, "buttons/blip1.wav");
	return Action:0;
}

public SDKCallBackThrow_Touched(entity, toucher)
{
	new id = FindIdEntPropByEntity(entity);
	if (id == -1)
	{
		return 0;
	}
	if (nType[id] != 4)
	{
		SDKUnhook(entity, SDKHookType:10, SDKCallBackThrow_Touched);
		SDKUnhook(entity, SDKHookType:0, SDKCallBackThrow_EndTouch);
		return 0;
	}
	new var1;
	if (toucher < MaxClients && !IsPlayerAlive(toucher))
	{
		return 0;
	}
	decl Float:ori[3];
	decl Float:ang[3];
	GetEntPropVector(entity, PropType:0, "m_vecOrigin", ori, 0);
	GetEntPropVector(entity, PropType:0, "m_angRotation", ang, 0);
	ThrowPerson(toucher, throwpower[id], ori, ang);
	return 0;
}

public SDKCallBackThrow_EndTouch(entity, toucher)
{
	new id = FindIdEntPropByEntity(entity);
	if (id == -1)
	{
		return 0;
	}
	if (nType[id] != 4)
	{
		SDKUnhook(entity, SDKHookType:10, SDKCallBackThrow_Touched);
		SDKUnhook(entity, SDKHookType:0, SDKCallBackThrow_EndTouch);
		return 0;
	}
	if (toucher < MaxClients)
	{
		bThrow[toucher] = 0;
	}
	return 0;
}

ShowChooseThrowPowerMenu(client, entity)
{
	new Handle:menu = CreateMenu(MenuHandler_ChooseThrowPower, MenuAction:28);
	SetMenuExitButton(menu, true);
	SetMenuTitle(menu, "请选择投掷板的力度,编号:%d", entity);
	AddMenuItem(menu, "1.0", "小", 0);
	AddMenuItem(menu, "1.3", "较小", 0);
	AddMenuItem(menu, "2.0", "中", 0);
	AddMenuItem(menu, "2.5", "大", 0);
	AddMenuItem(menu, "3.0", "最大", 0);
	AddMenuItem(menu, "25.0", "最大x5", 0);
	AddMenuItem(menu, "50.0", "最大x10", 0);
	DisplayMenu(menu, client, 0);
	NowEntity = entity;
	return 0;
}

public MenuHandler_ChooseThrowPower(Handle:menu, MenuAction:action, client, item)
{
	switch (action)
	{
		case 4:
		{
			new var1;
			if (NowEntity <= 0 || !IsValidEdict(NowEntity))
			{
				return 0;
			}
			decl String:sType[64];
			new Float:power = 0.0;
			GetMenuItem(menu, item, sType, 64, 0, "", 0);
			power = StringToFloat(sType);
			if (power < 0.0)
			{
				return 0;
			}
			BecomeIntoThrow(NowEntity, power);
		}
		case 8:
		{
		}
		default:
		{
		}
	}
	return 0;
}

public bool:TraceRayDontHit(entity, mask, any:data)
{
	if (data == entity)
	{
		return false;
	}
	return true;
}

BecomeIntoBreak(entity, health)
{
	new var1;
	if (entity <= 0 || !IsValidEdict(entity))
	{
		return 0;
	}
	Health[EntTypeCount] = health;
	MaxHealth[EntTypeCount] = health;
	SetEntityRenderFx(entity, RenderFx:17);
	nType[EntTypeCount] = 5;
	EntProp[EntTypeCount] = entity;
	EntTypeCount += 1;
	SDKUnhook(entity, SDKHookType:3, SDKCallBackBreak_Damage);
	SDKHook(entity, SDKHookType:3, SDKCallBackBreak_Damage);
	return 0;
}

ShowChooseBreakHealthMenu(client, entity)
{
	new Handle:menu = CreateMenu(MenuHandler_ChooseBreakHealth, MenuAction:28);
	SetMenuExitButton(menu, true);
	SetMenuTitle(menu, "请选择血量板的耐久度,编号:%d", entity);
	AddMenuItem(menu, "100", "100HP", 0);
	AddMenuItem(menu, "1000", "1000HP", 0);
	AddMenuItem(menu, "5000", "5000HP", 0);
	AddMenuItem(menu, "10000", "10000HP", 0);
	AddMenuItem(menu, "20000", "20000HP", 0);
	DisplayMenu(menu, client, 0);
	NowEntity = entity;
	return 0;
}

public MenuHandler_ChooseBreakHealth(Handle:menu, MenuAction:action, client, item)
{
	switch (action)
	{
		case 4:
		{
			new var1;
			if (NowEntity <= 0 || !IsValidEdict(NowEntity))
			{
				return 0;
			}
			decl String:sType[64];
			new power;
			GetMenuItem(menu, item, sType, 64, 0, "", 0);
			power = StringToInt(sType, 10);
			if (0 > power)
			{
				return 0;
			}
			BecomeIntoBreak(NowEntity, power);
		}
		case 8:
		{
		}
		default:
		{
		}
	}
	return 0;
}

public SDKCallBackBreak_Damage(entity, attacker, inflictor, Float:damage, damagetype)
{
	new id = FindIdEntPropByEntity(entity);
	if (id == -1)
	{
		return 0;
	}
	if (nType[id] != 5)
	{
		SDKUnhook(entity, SDKHookType:3, SDKCallBackBreak_Damage);
		return 0;
	}
	Health[id] -= RoundToFloor(damage);
	if (0 >= Health[id])
	{
		BreakIt(entity);
	}
	PrintCenterText(attacker, "这堵墙还有 %d 耐久度", Health[id]);
	return 0;
}

BreakIt(entity)
{
	if (!IsSoundPrecached("physics/glass/glass_sheet_break3.wav"))
	{
		PrecacheSound("physics/glass/glass_sheet_break3.wav", false);
	}
	EmitSoundToAll("physics/glass/glass_sheet_break3.wav", -2, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	RemoveEdict(entity);
	SDKUnhook(entity, SDKHookType:3, SDKCallBackBreak_Damage);
	new id = FindIdEntPropByEntity(entity);
	if (id == -1)
	{
		return 0;
	}
	Health[id] = 0;
	EntProp[id] = 0;
	nType[id] = 0;
	return 0;
}

BecomeIntoTeleport(entity, Float:pos[3])
{
	new var1;
	if (entity <= 0 || !IsValidEdict(entity))
	{
		return 0;
	}
	SetEntityRenderColor(entity, 0, 0, 150, 255);
	nType[EntTypeCount] = 6;
	EntProp[EntTypeCount] = entity;
	EntTypeCount += 1;
	SDKUnhook(entity, SDKHookType:10, SDKCallBackTele_Touched);
	SDKHook(entity, SDKHookType:10, SDKCallBackTele_Touched);
	return 0;
}

TeleportPlayer(entity, Float:pos[3])
{
	TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
	if (entity < MaxClients)
	{
		EmitSoundFromPlayer(entity, "level/startwam.wav");
	}
	return 0;
}

public SDKCallBackTele_Touched(entity, toucher)
{
	new id = FindIdEntPropByEntity(entity);
	if (id == -1)
	{
		return 0;
	}
	if (nType[id] != 6)
	{
		SDKUnhook(entity, SDKHookType:10, SDKCallBackTele_Touched);
		return 0;
	}
	TeleportPlayer(toucher, Pos[id]);
	return 0;
}

ShowChooseTelePosMenu(client, entity)
{
	new Handle:menu = CreateMenu(MenuHandler_ChooseTelePos, MenuAction:28);
	SetMenuExitButton(menu, true);
	SetMenuTitle(menu, "请移动到要传送的地方,然后选择。编号:%d", entity);
	AddMenuItem(menu, "item1", "把当前位置当作传送点", 0);
	AddMenuItem(menu, "item2", "把鼠标位置当作传送点", 0);
	DisplayMenu(menu, client, 0);
	NowEntity = entity;
	return 0;
}

public MenuHandler_ChooseTelePos(Handle:menu, MenuAction:action, client, item)
{
	switch (action)
	{
		case 4:
		{
			new var1;
			if (NowEntity <= 0 || !IsValidEdict(NowEntity))
			{
				return 0;
			}
			decl Float:pos[3];
			switch (item)
			{
				case 0:
				{
					GetClientAbsOrigin(client, pos);
				}
				case 1:
				{
					GetClientCurPos(client, pos);
				}
				default:
				{
				}
			}
			BecomeIntoTeleport(NowEntity, pos);
		}
		case 8:
		{
		}
		default:
		{
		}
	}
	return 0;
}

BecomeIntoDie(entity)
{
	new var1;
	if (entity <= 0 || !IsValidEdict(entity))
	{
		return 0;
	}
	SetEntityRenderColor(entity, 0, 0, 0, 255);
	nType[EntTypeCount] = 7;
	EntProp[EntTypeCount] = entity;
	EntTypeCount += 1;
	SDKUnhook(entity, SDKHookType:10, SDKCallBackDie_Touched);
	SDKHook(entity, SDKHookType:10, SDKCallBackDie_Touched);
	return 0;
}

KillPerson(person)
{
	if (!IsValidEdict(person))
	{
		return 0;
	}
	decl String:clsname[64];
	GetEdictClassname(person, clsname, 64);
	if (person > MaxClients)
	{
		if (StrEqual(clsname, "infected", true))
		{
			AcceptEntityInput(person, "Kill", -1, -1, 0);
		}
		return 0;
	}
	else
	{
		CheatCommand(person, "kill", NULL_STRING);
	}
	return 0;
}

public SDKCallBackDie_Touched(entity, toucher)
{
	new id = FindIdEntPropByEntity(entity);
	if (id == -1)
	{
		return 0;
	}
	if (nType[id] != 7)
	{
		SDKUnhook(entity, SDKHookType:10, SDKCallBackDie_Touched);
		return 0;
	}
	KillPerson(toucher);
	return 0;
}

BecomeIntoShake(entity)
{
	new var1;
	if (entity <= 0 || !IsValidEdict(entity))
	{
		return 0;
	}
	SetEntityRenderColor(entity, 255, 0, 255, 255);
	nType[EntTypeCount] = 8;
	EntProp[EntTypeCount] = entity;
	SDKUnhook(entity, SDKHookType:10, SDKCallBackShake_Touched);
	SDKHook(entity, SDKHookType:10, SDKCallBackShake_Touched);
	EntTypeCount += 1;
	return 0;
}

ShakePlayer(client)
{
	new var1;
	if (client > MaxClients || !IsPlayerAlive(client))
	{
		return 0;
	}
	decl Float:vecOrigin[3];
	GetClientAbsOrigin(client, vecOrigin);
	new entity = CreateEntityByName("env_shake", -1);
	if (entity == -1)
	{
		return 0;
	}
	DispatchKeyValue(entity, "amplitude", "16");
	DispatchKeyValue(entity, "duration", "1");
	DispatchKeyValue(entity, "frequency", "2.5");
	DispatchKeyValue(entity, "radius", "40");
	DispatchSpawn(entity);
	TeleportEntity(entity, vecOrigin, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(entity, "StartShake", entity, entity, 0);
	AcceptEntityInput(entity, "kill", -1, -1, 0);
	return 0;
}

public SDKCallBackShake_Touched(entity, toucher)
{
	new id = FindIdEntPropByEntity(entity);
	if (id == -1)
	{
		return 0;
	}
	if (nType[id] != 8)
	{
		SDKUnhook(entity, SDKHookType:10, SDKCallBackShake_Touched);
		return 0;
	}
	ShakePlayer(toucher);
	return 0;
}

BecomeIntoRun(entity)
{
	new var1;
	if (entity <= 0 || !IsValidEdict(entity))
	{
		return 0;
	}
	SetEntityRenderColor(entity, 153, 153, 0, 255);
	nType[EntTypeCount] = 9;
	EntTypeCount += 1;
	SDKUnhook(entity, SDKHookType:10, SDKCallBackAuto_Touched);
	SDKHook(entity, SDKHookType:10, SDKCallBackAuto_Touched);
	return 0;
}

RunPerson(person, Float:origin[3], Float:angles[3])
{
	new var1;
	if (person > MaxClients || bRun[person])
	{
		return 0;
	}
	new Handle:pack = CreateDataPack();
	WritePackCell(pack, person);
	WritePackFloat(pack, origin[0]);
	WritePackFloat(pack, origin[1]);
	WritePackFloat(pack, origin[2]);
	WritePackFloat(pack, angles[0]);
	WritePackFloat(pack, angles[1]);
	WritePackFloat(pack, angles[2]);
	CreateTimer(0.1, TimerRun, pack, 0);
	bRun[person] = 1;
	return 0;
}

public Action:TimerRun(Handle:timer, any:pack)
{
	ResetPack(pack, false);
	decl Float:vAngles[3];
	decl Float:vOrigin[3];
	new person = ReadPackCell(pack);
	if (!bRun[person])
	{
		return Action:0;
	}
	vOrigin[0] = ReadPackFloat(pack);
	vOrigin[1] = ReadPackFloat(pack);
	vOrigin[2] = ReadPackFloat(pack);
	vAngles[0] = ReadPackFloat(pack);
	vAngles[1] = ReadPackFloat(pack);
	vAngles[2] = ReadPackFloat(pack);
	decl Float:VecOrigin[3];
	decl Float:pos[3];
	GetClientEyePosition(person, VecOrigin);
	TR_TraceRayFilter(VecOrigin, vAngles, 16513, RayType:1, TraceRayDontHitSelf, person);
	if (TR_DidHit(Handle:0))
	{
		TR_GetEndPosition(pos, Handle:0);
	}
	decl Float:volicity[3];
	new Float:velo[3] = 0.0;
	velo[0] = GetEntPropFloat(person, PropType:0, "m_vecVelocity[0]", 0);
	velo[1] = GetEntPropFloat(person, PropType:0, "m_vecVelocity[1]", 0);
	velo[2] = GetEntPropFloat(person, PropType:0, "m_vecVelocity[2]", 0);
	SubtractVectors(pos, vOrigin, volicity);
	ScaleVector(volicity, 0.4);
	volicity[2] = 0.0;
	AddVectors(velo, volicity, volicity);
	TeleportEntity(person, NULL_VECTOR, NULL_VECTOR, volicity);
	bRun[person] = 0;
	return Action:0;
}

public SDKCallBackAuto_Touched(entity, toucher)
{
	new id = FindIdEntPropByEntity(entity);
	if (id == -1)
	{
		return 0;
	}
	if (nType[id] != 9)
	{
		SDKUnhook(entity, SDKHookType:10, SDKCallBackAuto_Touched);
		return 0;
	}
	new var1;
	if (toucher < MaxClients && !IsPlayerAlive(toucher))
	{
		return 0;
	}
	decl Float:ori[3];
	decl Float:ang[3];
	GetEntPropVector(entity, PropType:0, "m_vecOrigin", ori, 0);
	GetEntPropVector(entity, PropType:0, "m_angRotation", ang, 0);
	RunPerson(toucher, ori, ang);
	return 0;
}

BecomeIntoHeavy(entity, Float:power)
{
	new var1;
	if (entity <= 0 || !IsValidEdict(entity))
	{
		return 0;
	}
	SetEntityRenderColor(entity, 50, 150, 100, 255);
	heavypower[EntTypeCount] = power;
	nType[EntTypeCount] = 10;
	EntProp[EntTypeCount] = entity;
	EntTypeCount += 1;
	SDKUnhook(entity, SDKHookType:10, SDKCallBackHea_Touched);
	SDKHook(entity, SDKHookType:10, SDKCallBackHea_Touched);
	return 0;
}

SetPlayerHeavy(client, Float:power)
{
	SetEntityGravity(client, power);
	return 0;
}

public SDKCallBackHea_Touched(entity, toucher)
{
	new id = FindIdEntPropByEntity(entity);
	if (id == -1)
	{
		return 0;
	}
	if (nType[id] != 10)
	{
		SDKUnhook(entity, SDKHookType:10, SDKCallBackHea_Touched);
		return 0;
	}
	new var1;
	if (toucher < MaxClients && IsPlayerAlive(toucher))
	{
		SetPlayerHeavy(toucher, heavypower[id]);
	}
	return 0;
}

BecomeIntoBreakEx(entity, bool:shot, bool:touch)
{
	new var1;
	if (entity <= 0 || !IsValidEdict(entity))
	{
		return 0;
	}
	bShot[EntTypeCount] = shot;
	bTouch[EntTypeCount] = touch;
	nType[EntTypeCount] = 11;
	EntProp[EntTypeCount] = entity;
	EntTypeCount += 1;
	SDKUnhook(entity, SDKHookType:3, SDKCallBackBreakEx_Damage);
	SDKHook(entity, SDKHookType:3, SDKCallBackBreakEx_Damage);
	SDKUnhook(entity, SDKHookType:10, SDKCallBackBreakEx_Touch);
	SDKHook(entity, SDKHookType:10, SDKCallBackBreakEx_Touch);
	return 0;
}

public bool:KvGetBool(Handle:kv, String:key[])
{
	new i = KvGetNum(kv, key, 0);
	return i == 1;
}

BecomeIntoLift(entity, speed, pathcount, Float:pos[][3], bool:damage, sp)
{
	new var1;
	if (entity <= 0 || !IsValidEdict(entity))
	{
		return 0;
	}
	decl String:sTemp[256];
	decl String:sFirst[256];
	decl Float:ang[3];
	decl String:model[256];
	decl String:sName[256];
	GetEntPropVector(entity, PropType:1, "m_angRotation", ang, 0);
	GetEntPropString(entity, PropType:1, "m_ModelName", model, 256, 0);
	if (!IsValidEdict(entity))
	{
		return 0;
	}
	new lift = CreateEntityByName("func_tracktrain", -1);
	if (lift == -1)
	{
		return 0;
	}
	Format(sName, 256, "train_%d", entity);
	new i;
	while (i < pathcount)
	{
		new path = CreateEntityByName("path_track", -1);
		if (!(path == -1))
		{
			Format(sTemp, 256, "path%d_%d", entity, i);
			if (!i)
			{
				strcopy(sFirst, 256, sTemp);
				HookSingleEntityOutput(path, "OnPass", EntityOutput_OnPass_Start, false);
			}
			DispatchKeyValue(path, "targetname", sTemp);
			if (pathcount + -1 > i)
			{
				Format(sTemp, 256, "path%d_%d", entity, i + 1);
				DispatchKeyValue(path, "target", sTemp);
			}
			else
			{
				if (pathcount + -1 == i)
				{
					Format(sTemp, 256, "path%d_%d", entity, 0);
					HookSingleEntityOutput(path, "OnPass", EntityOutput_OnPass_End, false);
				}
			}
			DispatchKeyValue(path, "parentname", sName);
			DispatchSpawn(path);
			TeleportEntity(path, pos[i], NULL_VECTOR, NULL_VECTOR);
			liftpath[EntTypeCount][i] = path;
			CopyVector(liftpathpos[EntTypeCount][i], pos[i], 3);
		}
		i++;
	}
	new b;
	while (b < pathcount)
	{
		ActivateEntity(liftpath[EntTypeCount][b]);
		b++;
	}
	DispatchKeyValue(lift, "targetname", sName);
	new prop = CreateEntityByName("prop_dynamic", -1);
	DispatchKeyValue(prop, "model", model);
	DispatchKeyValue(prop, "parentname", sName);
	DispatchKeyValue(prop, "solid", "6");
	DispatchSpawn(prop);
	SetVariantString(sName);
	AcceptEntityInput(prop, "SetParent", prop, prop, 0);
	Format(sTemp, 256, "%d", speed);
	DispatchKeyValue(lift, "speed", sTemp);
	DispatchKeyValue(lift, "target", sFirst);
	if (damage)
	{
		DispatchKeyValue(lift, "dmg", "1");
	}
	DispatchKeyValue(lift, "spawnflags", "17");
	DispatchSpawn(lift);
	ActivateEntity(lift);
	SetEntityModel(lift, model);
	TeleportEntity(lift, pos[0], ang, NULL_VECTOR);
	SetEntProp(lift, PropType:0, "m_nSolidType", any:2, 4, 0);
	new enteffects = GetEntProp(lift, PropType:0, "m_fEffects", 4, 0);
	enteffects |= 32;
	SetEntProp(lift, PropType:0, "m_fEffects", enteffects, 4, 0);
	AcceptEntityInput(lift, "StartForward", -1, -1, 0);
	if (StringToInt("0", 10) != sp)
	{
		AcceptEntityInput(lift, "Toggle", -1, -1, 0);
	}
	SpawnFlags[entity] = sp;
	nType[EntTypeCount] = 12;
	liftinfo[EntTypeCount][0] = lift;
	liftinfo[EntTypeCount][1] = speed;
	liftinfo[EntTypeCount][2] = pathcount;
	liftdamage[EntTypeCount] = damage;
	EntProp[EntTypeCount] = entity;
	EntTypeCount += 1;
	return 0;
}

public EntityOutput_OnPass_Start(String:output[], path, lift, Float:delay)
{
	if (IsValidEdict(lift))
	{
		AcceptEntityInput(lift, "StartForward", -1, -1, 0);
	}
	return 0;
}

public EntityOutput_OnPass_End(String:output[], path, lift, Float:delay)
{
	if (IsValidEdict(lift))
	{
		AcceptEntityInput(lift, "StartBackward", -1, -1, 0);
	}
	return 0;
}

ShowChooseLiftFlagsMenu(client, entity)
{
	new Handle:menu = CreateMenu(MenuHandler_ChooseLiftFlags, MenuAction:28);
	SetMenuExitButton(menu, true);
	decl String:sTemp[256];
	SetMenuTitle(menu, "请设置电梯板的类型。编号:%d", entity);
	Format(sTemp, 256, "<重要>速度+10.目前:%d", liftinfo[EntTypeCount][1]);
	AddMenuItem(menu, "item1", sTemp, 0);
	Format(sTemp, 256, "<重要>速度-10.目前:%d", liftinfo[EntTypeCount][1]);
	AddMenuItem(menu, "item2", sTemp, 0);
	Format(sTemp, 256, "是否显示路径(不建议):%d", liftshowbeam[EntTypeCount]);
	AddMenuItem(menu, "item3", sTemp, 0);
	Format(sTemp, 256, "卡住时伤害(防止玩家卡电梯):%d", liftdamage[EntTypeCount]);
	AddMenuItem(menu, "item4", sTemp, 0);
	Format(sTemp, 256, "<重要>添加路径点,目前有%d个(MAX:%d).选择它们可以删除", liftinfo[EntTypeCount][2], 20);
	AddMenuItem(menu, "item5", sTemp, 0);
	if (0 < liftinfo[EntTypeCount][2])
	{
		new i;
		while (liftinfo[EntTypeCount][2] > i)
		{
			Format(sTemp, 256, "路径点%d:坐标->%d,%d,%d", i, RoundToFloor(liftpathpos[EntTypeCount][i][0]), RoundToFloor(liftpathpos[EntTypeCount][i][1]), RoundToFloor(liftpathpos[EntTypeCount][i][2]));
			decl String:sTemp2[256];
			Format(sTemp2, 256, "%d", i);
			AddMenuItem(menu, sTemp2, sTemp, 0);
			i++;
		}
	}
	AddMenuItem(menu, "item6", "完成", 0);
	DisplayMenu(menu, client, 0);
	NowEntity = entity;
	return 0;
}

public MenuHandler_ChooseLiftFlags(Handle:menu, MenuAction:action, client, item)
{
	switch (action)
	{
		case 4:
		{
			new var1;
			if (NowEntity <= 0 || !IsValidEdict(NowEntity))
			{
				return 0;
			}
			switch (item)
			{
				case 0:
				{
					liftinfo[EntTypeCount][1] += 10;
					ShowChooseLiftFlagsMenu(client, NowEntity);
				}
				case 1:
				{
					if (liftinfo[EntTypeCount][1] > 10)
					{
						liftinfo[EntTypeCount][1] += -10;
					}
					ShowChooseLiftFlagsMenu(client, NowEntity);
				}
				case 2:
				{
					liftshowbeam[EntTypeCount] = !liftshowbeam[EntTypeCount];
					ShowChooseLiftFlagsMenu(client, NowEntity);
				}
				case 3:
				{
					liftdamage[EntTypeCount] = !liftdamage[EntTypeCount];
					ShowChooseLiftFlagsMenu(client, NowEntity);
				}
				case 4:
				{
					if (liftinfo[EntTypeCount][2] >= 20)
					{
						PrintToChat(client, "\x03没有空余的路径点了。");
						ShowChooseLiftFlagsMenu(client, NowEntity);
						return 0;
					}
					GetClientAbsOrigin(client, liftpathpos[EntTypeCount][liftinfo[EntTypeCount][2]]);
					liftinfo[EntTypeCount][2]++;
					ShowChooseLiftFlagsMenu(client, NowEntity);
				}
				default:
				{
				}
			}
			new var2;
			if (item > 4 && item < GetMenuItemCount(menu) + -1)
			{
				decl String:sItem[256];
				decl item2;
				GetMenuItem(menu, item, sItem, 256, 0, "", 0);
				item2 = StringToInt(sItem, 10);
				new i = item2;
				while (liftinfo[EntTypeCount][2] - item2 > i)
				{
					if (!(liftinfo[EntTypeCount][2][0] == i))
					{
						liftpathpos[EntTypeCount][i][0] = liftpathpos[EntTypeCount][i + 1][0];
						liftpathpos[EntTypeCount][i][1] = liftpathpos[EntTypeCount][i + 1][1];
						liftpathpos[EntTypeCount][i][2] = liftpathpos[EntTypeCount][i + 1][2];
					}
					i++;
				}
				liftinfo[EntTypeCount][2]--;
				ShowChooseLiftFlagsMenu(client, NowEntity);
			}
			else
			{
				if (GetMenuItemCount(menu) + -1 == item)
				{
					if (liftinfo[EntTypeCount][2] > 20)
					{
						PrintToChat(client, "\x03创建失败!太多的路径点了。");
						ShowChooseLiftFlagsMenu(client, NowEntity);
						return 0;
					}
					if (liftinfo[EntTypeCount][1] < 10)
					{
						PrintToChat(client, "\x03创建失败!速度不正确。");
						ShowChooseLiftFlagsMenu(client, NowEntity);
						return 0;
					}
					if (liftinfo[EntTypeCount][2] < 2)
					{
						PrintToChat(client, "\x03创建失败!路径点不足(>=2)。");
						ShowChooseLiftFlagsMenu(client, NowEntity);
						return 0;
					}
					BecomeIntoLift(NowEntity, liftinfo[EntTypeCount][1], liftinfo[EntTypeCount][2], liftpathpos[EntTypeCount], liftdamage[EntTypeCount], SpawnFlags[NowEntity]);
				}
			}
		}
		case 8:
		{
		}
		default:
		{
		}
	}
	return 0;
}

ShowLiftPathBeam()
{
	new id;
	while (id < 100)
	{
		new var1;
		if (liftshowbeam[id] && liftinfo[id][2] >= 2)
		{
			new path;
			while (liftinfo[id][2] > path)
			{
				if (!(liftinfo[id][2][0] == path))
				{
					TE_SetupBeamPoints(liftpathpos[id][path], liftpathpos[id][path + 1], g_sprite, 0, 0, 0, 0.1, 2.0, 2.0, 1, 0.0, liftbeamcolor, 0);
					TE_SendToAll(0.0);
				}
				path++;
			}
		}
		id++;
	}
	return 0;
}

BecomeIntoLaser(entity, damage, width, Float:pos[3])
{
	new var1;
	if (entity <= 0 || !IsValidEdict(entity))
	{
		return 0;
	}
	decl String:sTemp[64];
	new laser = CreateEntityByName("env_laser", -1);
	if (laser == -1)
	{
		ThrowError("创建射线失败!");
	}
	Format(sTemp, 64, "%d", damage);
	DispatchKeyValue(laser, "damage", sTemp);
	DispatchKeyValue(laser, "texture", "sprites/laserbeam.spr");
	Format(sTemp, 64, "%d %d %d", GetRandomInt(0, 255), GetRandomInt(0, 255), GetRandomInt(0, 255));
	DispatchKeyValue(laser, "rendercolor", sTemp);
	Format(sTemp, 64, "%d", width);
	DispatchKeyValue(laser, "width", sTemp);
	DispatchKeyValue(laser, "NoiseAmplitude", "1");
	Format(sTemp, 64, "postar_%d", entity);
	DispatchKeyValue(entity, "targetname", sTemp);
	DispatchKeyValue(laser, "LaserTarget", sTemp);
	DispatchSpawn(entity);
	DispatchSpawn(laser);
	ActivateEntity(laser);
	TeleportEntity(laser, pos, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(laser, "TurnOn", -1, -1, 0);
	nType[EntTypeCount] = 13;
	laserprop[EntTypeCount] = laser;
	laserdamage[EntTypeCount] = damage;
	laserwidth[EntTypeCount] = width;
	EntProp[EntTypeCount] = entity;
	EntTypeCount += 1;
	return 0;
}

ShowChooseLaserFlagsMenu(client, entity)
{
	new Handle:menu = CreateMenu(MenuHandler_ChooseLaserFlags, MenuAction:28);
	SetMenuExitButton(menu, true);
	decl String:sTemp[256];
	SetMenuTitle(menu, "请设置激光板的类型。编号:%d", entity);
	Format(sTemp, 256, "高度+1.目前:%d", laserwidth[EntTypeCount]);
	AddMenuItem(menu, "item1", sTemp, 0);
	Format(sTemp, 256, "高度-1.目前:%d", laserwidth[EntTypeCount]);
	AddMenuItem(menu, "item2", sTemp, 0);
	Format(sTemp, 256, "伤害+10.目前:%d", laserdamage[EntTypeCount]);
	AddMenuItem(menu, "item3", sTemp, 0);
	Format(sTemp, 256, "伤害-10.目前:%d", laserdamage[EntTypeCount]);
	AddMenuItem(menu, "item4", sTemp, 0);
	Format(sTemp, 256, "<重要>把当前位置定为路径点(%d %d %d)", RoundToFloor(laserpos[EntTypeCount][0]), RoundToFloor(laserpos[EntTypeCount][1]), RoundToFloor(laserpos[EntTypeCount][2]));
	AddMenuItem(menu, "item5", sTemp, 0);
	AddMenuItem(menu, "item6", "完成", 0);
	DisplayMenu(menu, client, 0);
	NowEntity = entity;
	return 0;
}

public MenuHandler_ChooseLaserFlags(Handle:menu, MenuAction:action, client, item)
{
	switch (action)
	{
		case 4:
		{
			new var1;
			if (NowEntity <= 0 || !IsValidEdict(NowEntity))
			{
				return 0;
			}
			switch (item)
			{
				case 0:
				{
					laserwidth[EntTypeCount] += 1;
					ShowChooseLaserFlagsMenu(client, NowEntity);
				}
				case 1:
				{
					if (laserwidth[EntTypeCount] > 1)
					{
						laserwidth[EntTypeCount] += -1;
					}
					ShowChooseLaserFlagsMenu(client, NowEntity);
				}
				case 2:
				{
					laserdamage[EntTypeCount] += 10;
					ShowChooseLaserFlagsMenu(client, NowEntity);
				}
				case 3:
				{
					if (0 < laserdamage[EntTypeCount])
					{
						laserdamage[EntTypeCount] += -10;
					}
					ShowChooseLaserFlagsMenu(client, NowEntity);
				}
				case 4:
				{
					GetClientAbsOrigin(client, laserpos[EntTypeCount]);
					ShowChooseLaserFlagsMenu(client, NowEntity);
				}
				case 5:
				{
					new var2;
					if (0.0 == laserpos[EntTypeCount][0] && 0.0 == laserpos[EntTypeCount][1] && 0.0 == laserpos[EntTypeCount][2])
					{
						PrintToChat(client, "\x03请先定义好激光的路径点!");
						ShowChooseLaserFlagsMenu(client, NowEntity);
						return 0;
					}
					if (!laserwidth[EntTypeCount])
					{
						laserwidth[EntTypeCount] = 2;
					}
					BecomeIntoLaser(NowEntity, laserdamage[EntTypeCount], laserwidth[EntTypeCount], laserpos[EntTypeCount]);
				}
				default:
				{
				}
			}
		}
		case 8:
		{
		}
		default:
		{
		}
	}
	return 0;
}

BecomeIntoRotating(entity, speed, Float:point[3], Float:entpoint[3], sp)
{
	decl String:sTemp[256];
	decl Float:ang[3];
	decl String:model[256];
	GetEntPropVector(entity, PropType:1, "m_angRotation", ang, 0);
	GetEntPropString(entity, PropType:1, "m_ModelName", model, 256, 0);
	new prop = CreateEntityByName("prop_dynamic", -1);
	DispatchKeyValue(prop, "model", model);
	DispatchKeyValueVector(prop, "angles", ang);
	DispatchKeyValue(prop, "solid", "6");
	Format(sTemp, 256, "prop_%d_%d", entity, prop);
	DispatchKeyValue(prop, "targetname", sTemp);
	DispatchSpawn(prop);
	TeleportEntity(prop, entpoint, ang, NULL_VECTOR);
	new rot = CreateEntityByName("func_rotating", -1);
	Format(sTemp, 256, "%d", speed);
	DispatchKeyValue(rot, "maxspeed", sTemp);
	DispatchKeyValue(rot, "fanfriction", "20");
	DispatchKeyValueVector(rot, "origin", point);
	Format(sTemp, 256, "rot_%d_%d", entity, rot);
	DispatchKeyValue(rot, "targetname", sTemp);
	DispatchSpawn(rot);
	TeleportEntity(rot, point, NULL_VECTOR, NULL_VECTOR);
	SetVariantString(sTemp);
	AcceptEntityInput(prop, "SetParent", prop, prop, 0);
	if (StringToInt("0", 10) == sp)
	{
		AcceptEntityInput(rot, "Start", -1, -1, 0);
	}
	SpawnFlags[entity] = sp;
	nType[EntTypeCount] = 14;
	rotspeed[EntTypeCount] = speed;
	rotrot[EntTypeCount] = rot;
	rotent[EntTypeCount] = prop;
	EntProp[EntTypeCount] = entity;
	EntTypeCount += 1;
	return 0;
}

ShowChooseRotFlagsMenu(client, entity)
{
	new Handle:menu = CreateMenu(MenuHandler_ChooseRotFlags, MenuAction:28);
	SetMenuExitButton(menu, true);
	decl String:sTemp[256];
	SetMenuTitle(menu, "请设置旋转板的类型。编号:%d\n地球(实体点)绕着太阳(圆心)转且自转", EntTypeCount);
	Format(sTemp, 256, "<重要>旋转速度+10,目前:%d", rotspeed[EntTypeCount]);
	AddMenuItem(menu, "item1", sTemp, 0);
	Format(sTemp, 256, "<重要>旋转速度-10,目前:%d", rotspeed[EntTypeCount]);
	AddMenuItem(menu, "item2", sTemp, 0);
	Format(sTemp, 256, "<重要>把当前位置定义为圆心(%d %d %d)", RoundToFloor(rotpoint[EntTypeCount][0]), RoundToFloor(rotpoint[EntTypeCount][1]), RoundToFloor(rotpoint[EntTypeCount][2]));
	AddMenuItem(menu, "item3", sTemp, 0);
	Format(sTemp, 256, "<重要>把当前位置定义为实体点(%d %d %d)", RoundToFloor(rotentpoint[EntTypeCount][0]), RoundToFloor(rotentpoint[EntTypeCount][1]), RoundToFloor(rotentpoint[EntTypeCount][2]));
	AddMenuItem(menu, "item4", sTemp, 0);
	AddMenuItem(menu, "item5", "完成", 0);
	DisplayMenu(menu, client, 0);
	NowEntity = entity;
	return 0;
}

public MenuHandler_ChooseRotFlags(Handle:menu, MenuAction:action, client, item)
{
	switch (action)
	{
		case 4:
		{
			new var1;
			if (NowEntity <= 0 || !IsValidEdict(NowEntity))
			{
				return 0;
			}
			switch (item)
			{
				case 0:
				{
					rotspeed[EntTypeCount] += 10;
					ShowChooseRotFlagsMenu(client, NowEntity);
				}
				case 1:
				{
					if (rotspeed[EntTypeCount] > 10)
					{
						rotspeed[EntTypeCount] += -10;
					}
					ShowChooseRotFlagsMenu(client, NowEntity);
				}
				case 2:
				{
					GetClientAbsOrigin(client, rotpoint[EntTypeCount]);
					ShowChooseRotFlagsMenu(client, NowEntity);
				}
				case 3:
				{
					GetClientAbsOrigin(client, rotentpoint[EntTypeCount]);
					ShowChooseRotFlagsMenu(client, NowEntity);
				}
				case 4:
				{
					if (rotspeed[EntTypeCount] < 10)
					{
						PrintToChat(client, "\x03创建失败!速度不正确.");
						ShowChooseRotFlagsMenu(client, NowEntity);
						return 0;
					}
					new var2;
					if (0.0 == rotpoint[EntTypeCount][0] && 0.0 == rotpoint[EntTypeCount][1] && 0.0 == rotpoint[EntTypeCount][2])
					{
						PrintToChat(client, "\x03创建失败!圆心不正确.");
						ShowChooseRotFlagsMenu(client, NowEntity);
						return 0;
					}
					new var3;
					if (0.0 == rotentpoint[EntTypeCount][0] && 0.0 == rotentpoint[EntTypeCount][1] && 0.0 == rotentpoint[EntTypeCount][2])
					{
						PrintToChat(client, "\x03创建失败!实体点不正确.");
						ShowChooseRotFlagsMenu(client, NowEntity);
						return 0;
					}
					BecomeIntoRotating(NowEntity, rotspeed[EntTypeCount], rotpoint[EntTypeCount], rotentpoint[EntTypeCount], SpawnFlags[NowEntity]);
				}
				default:
				{
				}
			}
		}
		case 8:
		{
		}
		default:
		{
		}
	}
	return 0;
}

BecomeIntoInfo(entity, String:sMessage[], String:sIcon[], color[3], showtime)
{
	new var1;
	if (entity <= 0 || !IsValidEdict(entity))
	{
		return 0;
	}
	nType[EntTypeCount] = 15;
	EntProp[EntTypeCount] = entity;
	strcopy(InfoMessage[EntTypeCount], 256, sMessage);
	strcopy(InfoIcon[EntTypeCount], 256, sIcon);
	CopyVector(InfoColor[EntTypeCount], color, 3);
	InfoTime[EntTypeCount] = showtime;
	EntTypeCount += 1;
	SDKUnhook(entity, SDKHookType:8, SDKCallBackInfo_Touch);
	SDKHook(entity, SDKHookType:8, SDKCallBackInfo_Touch);
	return 0;
}

public Action:CmdText(client, args)
{
	new var1;
	if (NowEntity <= 0 || !IsValidEdict(NowEntity))
	{
		return Action:0;
	}
	decl String:clsname[256];
	GetEdictClassname(NowEntity, clsname, 256);
	if (StrEqual(clsname, "player", true))
	{
		PrintToChat(client, "\x03不能把玩家作为你的目标!");
		return Action:0;
	}
	new id = FindIdEntPropByEntity(NowEntity);
	if (id == -1)
	{
		new var2;
		if (args < 1 && StrEqual(InfoMessage[EntTypeCount], "", true))
		{
			PrintToChat(client, "\x03用法:!ett <消息>.\n例:!ett \"abcdefg\"");
			return Action:0;
		}
		new var3;
		if (args < 1 && !StrEqual(InfoMessage[EntTypeCount], "", true))
		{
			strcopy(InfoMessage[EntTypeCount], 256, "");
			PrintToChat(client, "\x03成功清空文本(编号:%d)", NowEntity);
			ShowChooseInfoFlagsMenu(client, NowEntity);
			return Action:0;
		}
		decl String:text[256];
		GetCmdArg(1, text, 256);
		StrCat(InfoMessage[EntTypeCount], 256, text);
		PrintToChat(client, "\x03成功输入文本(编号:%d):\x04%s", NowEntity, InfoMessage[EntTypeCount]);
		ShowChooseInfoFlagsMenu(client, NowEntity);
	}
	return Action:0;
}

ShowChooseInfoFlagsMenu(client, entity)
{
	decl String:sTemp[256];
	new Handle:menu = CreateMenu(MenuHandler_ChooseInfoFlags, MenuAction:28);
	SetMenuExitButton(menu, true);
	SetMenuTitle(menu, "请选择讯息板的类型,编号:%d (输入!ett设置文本)", entity);
	Format(sTemp, 256, "文本:%s", InfoMessage[EntTypeCount]);
	AddMenuItem(menu, "item1", sTemp, 1);
	if (StrEqual(InfoIcon[EntTypeCount], "", true))
	{
		Format(sTemp, 256, "消息图标(选择可切换):无");
	}
	else
	{
		if (StrEqual(InfoIcon[EntTypeCount], "icon_tip", true))
		{
			Format(sTemp, 256, "消息图标(选择可切换):提示");
		}
		if (StrEqual(InfoIcon[EntTypeCount], "icon_info", true))
		{
			Format(sTemp, 256, "消息图标(选择可切换):信息");
		}
		if (StrEqual(InfoIcon[EntTypeCount], "icon_shield", true))
		{
			Format(sTemp, 256, "消息图标(选择可切换):防御");
		}
		if (StrEqual(InfoIcon[EntTypeCount], "icon_alert", true))
		{
			Format(sTemp, 256, "消息图标(选择可切换):警告");
		}
		if (StrEqual(InfoIcon[EntTypeCount], "icon_alert_red", true))
		{
			Format(sTemp, 256, "消息图标(选择可切换):强制警告");
		}
		if (StrEqual(InfoIcon[EntTypeCount], "icon_skull", true))
		{
			Format(sTemp, 256, "消息图标(选择可切换):骷髅头");
		}
		if (StrEqual(InfoIcon[EntTypeCount], "icon_no", true))
		{
			Format(sTemp, 256, "消息图标(选择可切换):禁止");
		}
		if (StrEqual(InfoIcon[EntTypeCount], "icon_arrow_up", true))
		{
			Format(sTemp, 256, "消息图标(选择可切换):前面");
		}
		if (StrEqual(InfoIcon[EntTypeCount], "+jump", true))
		{
			Format(sTemp, 256, "消息图标(选择可切换):跳跃键");
		}
		if (StrEqual(InfoIcon[EntTypeCount], "+attack", true))
		{
			Format(sTemp, 256, "消息图标(选择可切换):攻击键1");
		}
		if (StrEqual(InfoIcon[EntTypeCount], "+attack2", true))
		{
			Format(sTemp, 256, "消息图标(选择可切换):攻击键2");
		}
		if (StrEqual(InfoIcon[EntTypeCount], "+duck", true))
		{
			Format(sTemp, 256, "消息图标(选择可切换):蹲键");
		}
		if (StrEqual(InfoIcon[EntTypeCount], "+speed", true))
		{
			Format(sTemp, 256, "消息图标(选择可切换):Shift键");
		}
		if (StrEqual(InfoIcon[EntTypeCount], "+reload", true))
		{
			Format(sTemp, 256, "消息图标(选择可切换):装弹键");
		}
	}
	AddMenuItem(menu, "item2", sTemp, 0);
	new var1;
	if (InfoColor[EntTypeCount][0] == 255 && InfoColor[EntTypeCount][1] == 255 && InfoColor[EntTypeCount][2] == 255)
	{
		Format(sTemp, 256, "消息颜色(选择可切换):白色");
	}
	else
	{
		new var2;
		if (InfoColor[EntTypeCount][0] && InfoColor[EntTypeCount][1] && InfoColor[EntTypeCount][2])
		{
			Format(sTemp, 256, "消息颜色(选择可切换):黑色");
		}
		new var3;
		if (InfoColor[EntTypeCount][0] && InfoColor[EntTypeCount][1] && InfoColor[EntTypeCount][2] == 255)
		{
			Format(sTemp, 256, "消息颜色(选择可切换):蓝色");
		}
		new var4;
		if (InfoColor[EntTypeCount][0] && InfoColor[EntTypeCount][1] == 255 && InfoColor[EntTypeCount][2])
		{
			Format(sTemp, 256, "消息颜色(选择可切换):绿色");
		}
		new var5;
		if (InfoColor[EntTypeCount][0] == 255 && InfoColor[EntTypeCount][1] && InfoColor[EntTypeCount][2])
		{
			Format(sTemp, 256, "消息颜色(选择可切换):红色");
		}
	}
	AddMenuItem(menu, "item3", sTemp, 0);
	AddMenuItem(menu, "item4", "完成", 0);
	DisplayMenu(menu, client, 0);
	NowEntity = entity;
	return 0;
}

public MenuHandler_ChooseInfoFlags(Handle:menu, MenuAction:action, client, item)
{
	switch (action)
	{
		case 4:
		{
			new var1;
			if (NowEntity <= 0 || !IsValidEdict(NowEntity))
			{
				return 0;
			}
			switch (item)
			{
				case 1:
				{
					if (StrEqual(InfoIcon[EntTypeCount], "", true))
					{
						Format(InfoIcon[EntTypeCount], 256, "icon_tip");
					}
					else
					{
						if (StrEqual(InfoIcon[EntTypeCount], "icon_tip", true))
						{
							Format(InfoIcon[EntTypeCount], 256, "icon_info");
						}
						if (StrEqual(InfoIcon[EntTypeCount], "icon_info", true))
						{
							Format(InfoIcon[EntTypeCount], 256, "icon_shield");
						}
						if (StrEqual(InfoIcon[EntTypeCount], "icon_shield", true))
						{
							Format(InfoIcon[EntTypeCount], 256, "icon_alert");
						}
						if (StrEqual(InfoIcon[EntTypeCount], "icon_alert", true))
						{
							Format(InfoIcon[EntTypeCount], 256, "icon_alert_red");
						}
						if (StrEqual(InfoIcon[EntTypeCount], "icon_alert_red", true))
						{
							Format(InfoIcon[EntTypeCount], 256, "icon_skull");
						}
						if (StrEqual(InfoIcon[EntTypeCount], "icon_skull", true))
						{
							Format(InfoIcon[EntTypeCount], 256, "icon_no");
						}
						if (StrEqual(InfoIcon[EntTypeCount], "icon_no", true))
						{
							Format(InfoIcon[EntTypeCount], 256, "icon_arrow_up");
						}
						if (StrEqual(InfoIcon[EntTypeCount], "icon_arrow_up", true))
						{
							Format(InfoIcon[EntTypeCount], 256, "+jump");
						}
						if (StrEqual(InfoIcon[EntTypeCount], "+jump", true))
						{
							Format(InfoIcon[EntTypeCount], 256, "+attack");
						}
						if (StrEqual(InfoIcon[EntTypeCount], "+attack", true))
						{
							Format(InfoIcon[EntTypeCount], 256, "+attack2");
						}
						if (StrEqual(InfoIcon[EntTypeCount], "+attack2", true))
						{
							Format(InfoIcon[EntTypeCount], 256, "+duck");
						}
						if (StrEqual(InfoIcon[EntTypeCount], "+duck", true))
						{
							Format(InfoIcon[EntTypeCount], 256, "+speed");
						}
						if (StrEqual(InfoIcon[EntTypeCount], "+speed", true))
						{
							Format(InfoIcon[EntTypeCount], 256, "+reload");
						}
						if (StrEqual(InfoIcon[EntTypeCount], "+reload", true))
						{
							Format(InfoIcon[EntTypeCount], 256, "");
						}
					}
					ShowChooseInfoFlagsMenu(client, NowEntity);
				}
				case 2:
				{
					new var2;
					if (InfoColor[EntTypeCount][0] && InfoColor[EntTypeCount][1] && InfoColor[EntTypeCount][2])
					{
					}
					else
					{
						new var3;
						if (!(InfoColor[EntTypeCount][0] == 255 && InfoColor[EntTypeCount][1] == 255 && InfoColor[EntTypeCount][2] == 255))
						{
							new var4;
							if (!(InfoColor[EntTypeCount][0] && InfoColor[EntTypeCount][1] && InfoColor[EntTypeCount][2] == 255))
							{
								new var5;
								if (!(InfoColor[EntTypeCount][0] && InfoColor[EntTypeCount][1] == 255 && InfoColor[EntTypeCount][2]))
								{
									new var6;
									if (InfoColor[EntTypeCount][0] == 255 && InfoColor[EntTypeCount][1] && InfoColor[EntTypeCount][2])
									{
									}
								}
							}
						}
					}
					ShowChooseInfoFlagsMenu(client, NowEntity);
				}
				case 3:
				{
					if (StrEqual(InfoMessage[EntTypeCount], "", true))
					{
						PrintToChat(client, "\x03创建失败!消息文本为空!");
						return 0;
					}
					BecomeIntoInfo(NowEntity, InfoMessage[EntTypeCount], InfoIcon[EntTypeCount], InfoColor[EntTypeCount], 5);
				}
				default:
				{
				}
			}
		}
		case 8:
		{
		}
		default:
		{
		}
	}
	return 0;
}

public SDKCallBackInfo_Touch(entity, toucher)
{
	new id = FindIdEntPropByEntity(entity);
	if (id == -1)
	{
		return 0;
	}
	if (nType[id] != 15)
	{
		SDKUnhook(entity, SDKHookType:8, SDKCallBackInfo_Touch);
		return 0;
	}
	new var1;
	if (toucher < MaxClients && IsPlayerAlive(toucher))
	{
		if (StrContains(InfoIcon[id], "+", true) != -1)
		{
			DisplayInstructorHint(toucher, InfoMessage[id], "use_binding", InfoIcon[id], InfoColor[id], InfoTime[id]);
		}
		DisplayInstructorHint(toucher, InfoMessage[id], InfoIcon[id], "", InfoColor[id], InfoTime[id]);
	}
	return 0;
}

DisplayInstructorHint(client, String:s_Message[256], String:s_Icon[], String:s_Binding[], color[3], showtime)
{
	if (IsClientInGame(client))
	{
		ClientCommand(client, "gameinstructor_enable 1");
	}
	decl i_Ent;
	decl String:s_TargetName[32];
	decl Handle:h_RemovePack;
	decl String:sTemp[64];
	i_Ent = CreateEntityByName("env_instructor_hint", -1);
	FormatEx(s_TargetName, 32, "hint%d", client);
	ReplaceString(s_Message, 256, "\n", "", true);
	DispatchKeyValue(client, "targetname", s_TargetName);
	DispatchKeyValue(i_Ent, "hint_target", s_TargetName);
	Format(sTemp, 64, "%d", showtime);
	DispatchKeyValue(i_Ent, "hint_timeout", sTemp);
	DispatchKeyValue(i_Ent, "hint_range", "0.01");
	Format(sTemp, 64, "%d %d %d", color, color[1], color[2]);
	DispatchKeyValue(i_Ent, "hint_color", sTemp);
	DispatchKeyValue(i_Ent, "hint_caption", s_Message);
	new var1;
	if (StrEqual(s_Icon, "use_binding", true) && !StrEqual(s_Binding, "", true))
	{
		DispatchKeyValue(i_Ent, "hint_icon_onscreen", "use_binding");
		DispatchKeyValue(i_Ent, "hint_binding", s_Binding);
	}
	else
	{
		DispatchKeyValue(i_Ent, "hint_icon_onscreen", s_Icon);
	}
	DispatchSpawn(i_Ent);
	AcceptEntityInput(i_Ent, "ShowHint", -1, -1, 0);
	h_RemovePack = CreateDataPack();
	WritePackCell(h_RemovePack, client);
	WritePackCell(h_RemovePack, i_Ent);
	CreateTimer(float(showtime), RemoveInstructorHint, h_RemovePack, 0);
	return 0;
}

public Action:RemoveInstructorHint(Handle:h_Timer, Handle:h_Pack)
{
	decl i_Ent;
	decl i_Client;
	ResetPack(h_Pack, false);
	i_Client = ReadPackCell(h_Pack);
	i_Ent = ReadPackCell(h_Pack);
	CloseHandle(h_Pack);
	new var1;
	if (!i_Client || !IsClientInGame(i_Client))
	{
		return Action:3;
	}
	if (IsValidEntity(i_Ent))
	{
		RemoveEdict(i_Ent);
	}
	DispatchKeyValue(i_Client, "targetname", "");
	return Action:0;
}

BecomeIntoTarget(entity, String:command[], maxlen)
{
	if (0 >= maxlen)
	{
		maxlen = 1024;
	}
	new String:sArrayCmd[20][64] = "P";
	new String:sArrayCmd2[3][64] = "\x0C";
	new c = SplitStringEx(command, "\n", sArrayCmd, 20);
	new b;
	if (0 > c)
	{
		ThrowError("机关板没有事件或语法不对!");
	}
	new bool:btn;
	new i;
	while (i < c)
	{
		b = SplitStringEx(sArrayCmd[i], ",", sArrayCmd2, 3);
		if (0 > b)
		{
			ThrowError("事件或语法不对!序列号:%d", b);
		}
		TargetObject[EntTypeCount][i] = StringToInt(sArrayCmd2[0][sArrayCmd2], 10);
		strcopy(TargetEventName[EntTypeCount][i], 256, sArrayCmd2[1]);
		strcopy(TargetEventArg[EntTypeCount][i], 256, sArrayCmd2[2]);
		if (StrEqual(TargetEventName[EntTypeCount][i], "Use", true))
		{
			btn = true;
		}
		LogMessage("%d:%d:%s:%s", i, TargetObject[EntTypeCount][i], TargetEventName[EntTypeCount][i], TargetEventArg[EntTypeCount][i]);
		i++;
	}
	if (btn)
	{
		TargetButton[EntTypeCount] = CreateButton(entity);
		SetEntProp(entity, PropType:0, "m_iGlowType", any:3, 4, 0);
		SetEntProp(entity, PropType:0, "m_nGlowRange", any:150, 4, 0);
	}
	TargetEventCount[EntTypeCount] = c;
	nType[EntTypeCount] = 16;
	EntProp[EntTypeCount] = entity;
	EntTypeCount += 1;
	SDKUnhook(entity, SDKHookType:8, SDKCallBackTarget_StartTouch);
	SDKHook(entity, SDKHookType:8, SDKCallBackTarget_StartTouch);
	SDKUnhook(entity, SDKHookType:10, SDKCallBackTarget_Touch);
	SDKHook(entity, SDKHookType:10, SDKCallBackTarget_Touch);
	return 0;
}

ShowChooseTargetFlagsMenu(client, entity)
{
	new Handle:menu = CreateMenu(MenuHandler_ChooseTargetFlags, MenuAction:28);
	SetMenuExitButton(menu, true);
	SetMenuTitle(menu, "请设置机关板的类型。编号:%d", entity);
	AddMenuItem(menu, "item1", "<重要>设置触发事件", 0);
	AddMenuItem(menu, "item2", "完成", 0);
	DisplayMenu(menu, client, 0);
	NowEntity = entity;
	return 0;
}

public MenuHandler_ChooseTargetFlags(Handle:menu, MenuAction:action, client, item)
{
	switch (action)
	{
		case 4:
		{
			new var1;
			if (NowEntity <= 0 || !IsValidEdict(NowEntity))
			{
				return 0;
			}
			switch (item)
			{
				case 0:
				{
					ShowChooseTargetEventMenu(client, NowEntity);
				}
				case 1:
				{
					if (0 >= TargetEventCount[EntTypeCount])
					{
						PrintToChat(client, "创建失败!没有事件响应.");
						ShowChooseTargetFlagsMenu(client, NowEntity);
					}
					else
					{
						new String:sCmd[256];
						new i;
						while (TargetEventCount[EntTypeCount] > i)
						{
							new var2;
							if (!StrEqual(TargetEventName[EntTypeCount][i], "", true) && TargetObject[EntTypeCount][i] > MaxClients && IsValidEdict(TargetObject[EntTypeCount][i]))
							{
								new String:nowCmd[64];
								Format(nowCmd, 64, "%d,%s,%s\n", TargetObject[EntTypeCount][i], TargetEventName[EntTypeCount][i], TargetEventArg[EntTypeCount][i]);
								LogMessage(nowCmd);
								StrCat(sCmd, 256, nowCmd);
							}
							i++;
						}
						BecomeIntoTarget(NowEntity, sCmd, 256);
					}
				}
				default:
				{
				}
			}
		}
		case 8:
		{
		}
		default:
		{
		}
	}
	return 0;
}

ShowChooseTargetEventMenu(client, entity)
{
	new String:sTemp[256];
	new Handle:menu = CreateMenu(MenuHandler_TargetEventFlags, MenuAction:28);
	SetMenuExitButton(menu, true);
	SetMenuTitle(menu, "请设置机关板的事件。选择事件可以删除事件。编号:%d", entity);
	Format(sTemp, 256, "添加事件:目前有%d个", TargetEventCount[EntTypeCount]);
	AddMenuItem(menu, "item1", sTemp, 0);
	new i;
	while (TargetEventCount[EntTypeCount] > i)
	{
		new var1;
		if (TargetObject[EntTypeCount][i] > MaxClients && IsValidEdict(TargetObject[EntTypeCount][i]) && !StrEqual(TargetEventName[EntTypeCount][i], "", true))
		{
			new String:sTemp2[256];
			if (StrEqual(TargetEventName[EntTypeCount][i], "StartTouch", true))
			{
				Format(sTemp2, 256, "首次被碰到");
			}
			else
			{
				if (StrEqual(TargetEventName[EntTypeCount][i], "Touch", true))
				{
					Format(sTemp2, 256, "碰到");
				}
				if (StrEqual(TargetEventName[EntTypeCount][i], "Use", true))
				{
					Format(sTemp2, 256, "使用");
				}
			}
			Format(sTemp, 256, "事件对象:%d,事件名:%s,事件参数:%s", TargetObject[EntTypeCount][i], sTemp2, TargetEventArg[EntTypeCount][i]);
			Format(sTemp2, 256, "%d", i);
			AddMenuItem(menu, sTemp2, sTemp, 0);
		}
		else
		{
			TargetObject[EntTypeCount][i] = 0;
		}
		i++;
	}
	AddMenuItem(menu, "item3", "完成", 0);
	DisplayMenu(menu, client, 0);
	NowEntity = entity;
	return 0;
}

public MenuHandler_TargetEventFlags(Handle:menu, MenuAction:action, client, item)
{
	switch (action)
	{
		case 4:
		{
			new var1;
			if (NowEntity <= 0 || !IsValidEdict(NowEntity))
			{
				return 0;
			}
			switch (item)
			{
				case 0:
				{
					ShowChooseTargetAddEventMenu(client, NowEntity);
				}
				default:
				{
				}
			}
			new var2;
			if (item > 0 && item < GetMenuItemCount(menu) + -1)
			{
				decl String:sItem[256];
				decl item2;
				GetMenuItem(menu, item, sItem, 256, 0, "", 0);
				item2 = StringToInt(sItem, 10);
				new i = item2;
				while (TargetEventCount[EntTypeCount] - item2 > i)
				{
					if (!(TargetEventCount[EntTypeCount][0] == i))
					{
						TargetObject[EntTypeCount][i] = TargetObject[EntTypeCount][i + 1];
						strcopy(TargetEventName[EntTypeCount][i], 256, TargetEventName[EntTypeCount][i + 1]);
						strcopy(TargetEventArg[EntTypeCount][i], 256, TargetEventArg[EntTypeCount][i + 1]);
					}
					i++;
				}
				TargetEventCount[EntTypeCount]--;
				ShowChooseTargetEventMenu(client, NowEntity);
			}
			else
			{
				if (GetMenuItemCount(menu) + -1 == item)
				{
					ShowChooseTargetFlagsMenu(client, NowEntity);
				}
			}
		}
		case 8:
		{
		}
		default:
		{
		}
	}
	return 0;
}


ShowChooseTargetAddEventMenu(client, entity)
{
	new index = TargetEventCount[EntTypeCount];
	new String:sTemp[256];
	new Handle:menu = CreateMenu(MenuHandler_TargetAddEventFlags, MenuAction:28);
	SetMenuExitButton(menu, true);
	SetMenuTitle(menu, "请编辑事件(选择它们可以变换),编号:%d,事件编号:%d", EntTypeCount, index);
	Format(sTemp, 256, "<重要>触发对象(可以是自己):%d", TargetObject[EntTypeCount][index]);
	AddMenuItem(menu, "item1", sTemp, 0);
	if (StrEqual(TargetEventName[EntTypeCount][index], "StartTouch", true))
	{
		Format(sTemp, 256, "首次被碰到");
	}
	else
	{
		if (StrEqual(TargetEventName[EntTypeCount][index], "Touch", true))
		{
			Format(sTemp, 256, "碰到(会连续触发)");
		}
		if (StrEqual(TargetEventName[EntTypeCount][index], "Use", true))
		{
			Format(sTemp, 256, "使用(玩家按下使用键)");
		}
		Format(sTemp, 256, "无");
	}
	Format(sTemp, 256, "事件名:%s", sTemp);
	AddMenuItem(menu, "name", sTemp, 0);
	if (StrEqual(TargetEventArg[EntTypeCount][index], "", true))
	{
		Format(sTemp, 256, "无");
	}
	else
	{
		Format(sTemp, 256, TargetEventArg[EntTypeCount][index]);
	}
	Format(sTemp, 256, "事件参数(每个数字代表不同效果):%s", sTemp);
	AddMenuItem(menu, "arg", sTemp, 0);
	AddMenuItem(menu, "item3", "完成", 0);
	DisplayMenu(menu, client, 0);
	NowEntity = entity;
	return 0;
}

public MenuHandler_TargetAddEventFlags(Handle:menu, MenuAction:action, client, item)
{
	switch (action)
	{
		case 4:
		{
			new var1;
			if (NowEntity <= 0 || !IsValidEdict(NowEntity))
			{
				return 0;
			}
			new index = TargetEventCount[EntTypeCount];
			switch (item)
			{
				case 0:
				{
					TargetObject[EntTypeCount][index] = GetClientAimTargetEx(client);
					if (TargetObject[EntTypeCount][index] <= MaxClients)
					{
						TargetObject[EntTypeCount][index] = 0;
						PrintToChat(client, "\x03无效的对象!");
					}
					ShowChooseTargetAddEventMenu(client, NowEntity);
				}
				case 1:
				{
					if (StrEqual(TargetEventName[EntTypeCount][index], "", true))
					{
						Format(TargetEventName[EntTypeCount][index], 256, "StartTouch");
					}
					else
					{
						if (StrEqual(TargetEventName[EntTypeCount][index], "StartTouch", true))
						{
							Format(TargetEventName[EntTypeCount][index], 256, "Touch");
						}
						if (StrEqual(TargetEventName[EntTypeCount][index], "Touch", true))
						{
							Format(TargetEventName[EntTypeCount][index], 256, "Use");
						}
						if (StrEqual(TargetEventName[EntTypeCount][index], "Use", true))
						{
							Format(TargetEventName[EntTypeCount][index], 256, "");
						}
					}
					ShowChooseTargetAddEventMenu(client, NowEntity);
				}
				case 2:
				{
					if (StrEqual(TargetEventArg[EntTypeCount][index], "", true))
					{
						Format(TargetEventArg[EntTypeCount][index], 256, "0");
					}
					else
					{
						if (StrEqual(TargetEventArg[EntTypeCount][index], "0", true))
						{
							Format(TargetEventArg[EntTypeCount][index], 256, "1");
						}
						if (StrEqual(TargetEventArg[EntTypeCount][index], "1", true))
						{
							Format(TargetEventArg[EntTypeCount][index], 256, "4");
						}
						if (StrEqual(TargetEventArg[EntTypeCount][index], "4", true))
						{
							Format(TargetEventArg[EntTypeCount][index], 256, "6");
						}
						if (StrEqual(TargetEventArg[EntTypeCount][index], "6", true))
						{
							Format(TargetEventArg[EntTypeCount][index], 256, "8");
						}
						if (StrEqual(TargetEventArg[EntTypeCount][index], "8", true))
						{
							Format(TargetEventArg[EntTypeCount][index], 256, "");
						}
					}
					ShowChooseTargetAddEventMenu(client, NowEntity);
				}
				case 3:
				{
					new var2;
					if (TargetObject[EntTypeCount][TargetEventCount[EntTypeCount]] > MaxClients && IsValidEdict(TargetObject[EntTypeCount][TargetEventCount[EntTypeCount]]) && !StrEqual(TargetEventName[EntTypeCount][TargetEventCount[EntTypeCount]], "", true))
					{
						TargetEventCount[EntTypeCount]++;
					}
					ShowChooseTargetEventMenu(client, NowEntity);
				}
				default:
				{
				}
			}
		}
		case 8:
		{
		}
		default:
		{
		}
	}
	return 0;
}

CreateButton(entity)
{
	decl String:sTemp[16];
	new button;
	new bool:type = 1;
	if (type)
	{
		button = CreateEntityByName("func_button", -1);
	}
	else
	{
		button = CreateEntityByName("func_button_timed", -1);
	}
	if (type)
	{
		DispatchKeyValue(button, "spawnflags", "1025");
		DispatchKeyValue(button, "wait", "1");
	}
	else
	{
		DispatchKeyValue(button, "spawnflags", "0");
		DispatchKeyValue(button, "auto_disable", "1");
		Format(sTemp, 16, "%f", 5.0);
		DispatchKeyValue(button, "use_time", sTemp);
	}
	DispatchSpawn(button);
	AcceptEntityInput(button, "Enable", -1, -1, 0);
	ActivateEntity(button);
	Format(sTemp, 16, "ft%d", button);
	DispatchKeyValue(button, "targetname", sTemp);
	SetVariantString(sTemp);
	AcceptEntityInput(entity, "SetParent", button, button, 0);
	TeleportEntity(button, 1180872, NULL_VECTOR, NULL_VECTOR);
	Format(sTemp, 16, "target%d", button);
	DispatchKeyValue(entity, "targetname", sTemp);
	DispatchKeyValue(button, "glow", sTemp);
	SetEntProp(button, PropType:0, "m_nSolidType", any:0, 1, 0);
	SetEntProp(button, PropType:0, "m_usSolidFlags", any:4, 2, 0);
	decl Float:vMins[3];
	decl Float:vMaxs[3];
	SetEntPropVector(button, PropType:0, "m_vecMins", vMins, 0);
	SetEntPropVector(button, PropType:0, "m_vecMaxs", vMaxs, 0);
	if (L4D2Version)
	{
		SetEntProp(button, PropType:1, "m_CollisionGroup", any:1, 4, 0);
		SetEntProp(button, PropType:0, "m_CollisionGroup", any:1, 4, 0);
	}
	if (type)
	{
		HookSingleEntityOutput(button, "OnPressed", OnPressed, false);
	}
	else
	{
		SetVariantString("OnTimeUp !self:Enable::1:-1");
		AcceptEntityInput(button, "AddOutput", -1, -1, 0);
		HookSingleEntityOutput(button, "OnTimeUp", OnPressed, false);
	}
	return button;
}

public OnPressed(String:output[], caller, client, Float:delay)
{
	new id = FindIdByButton(caller);
	if (id == -1)
	{
		return 0;
	}
	if (nType[id] != 16)
	{
		return 0;
	}
	if (0 < TargetEventCount[id])
	{
		new i;
		while (TargetEventCount[id] > i)
		{
			if (StrEqual(TargetEventName[id][i], "Use", true))
			{
				EntityCommand(TargetObject[id][i], TargetEventArg[id][i], caller, client);
			}
			i++;
		}
	}
	EmitSoundFromPlayer(client, "player/suit_denydevice.wav");
	return 0;
}

public SDKCallBackTarget_StartTouch(entity, toucher)
{
	new id = FindIdEntPropByEntity(entity);
	if (id == -1)
	{
		return 0;
	}
	if (nType[id] != 16)
	{
		SDKUnhook(entity, SDKHookType:8, SDKCallBackTarget_StartTouch);
		return 0;
	}
	if (0 < TargetEventCount[id])
	{
		new i;
		while (TargetEventCount[id] > i)
		{
			if (StrEqual(TargetEventName[id][i], "StartTouch", true))
			{
				EntityCommand(TargetObject[id][i], TargetEventArg[id][i], entity, toucher);
			}
			i++;
		}
	}
	return 0;
}

public SDKCallBackTarget_Touch(entity, toucher)
{
	new id = FindIdEntPropByEntity(entity);
	if (id == -1)
	{
		return 0;
	}
	if (nType[id] != 16)
	{
		SDKUnhook(entity, SDKHookType:10, SDKCallBackTarget_Touch);
		return 0;
	}
	if (0 < TargetEventCount[id])
	{
		new i;
		while (TargetEventCount[id] > i)
		{
			if (StrEqual(TargetEventName[id][i], "Touch", true))
			{
				EntityCommand(TargetObject[id][i], TargetEventArg[id][i], entity, toucher);
			}
			i++;
		}
	}
	return 0;
}

EntityCommand(entity, String:command[], caller, any:data)
{
	LogMessage("entity:%d,command:%s,caller:%d,data:%d", entity, command, caller, data);
	if (IsValidEdict(entity))
	{
		if (StrEqual(command, "0", true))
		{
			SpawnFlags[entity] = StringToInt("0", 10);
		}
		if (StrEqual(command, "1", true))
		{
			SpawnFlags[entity] = StringToInt("1", 10);
		}
		if (StrEqual(command, "4", true))
		{
			new id = FindIdEntPropByEntity(entity);
			if (id == -1)
			{
				return 0;
			}
			switch (nType[id])
			{
				case 5:
				{
					BreakIt(entity);
				}
				case 11:
				{
					BreakItEx(entity);
				}
				case 12:
				{
					TeleportEntity(liftinfo[id][0], liftpathpos[id][0], NULL_VECTOR, NULL_VECTOR);
				}
				default:
				{
				}
			}
		}
		if (StrEqual(command, "6", true))
		{
			new id = FindIdEntPropByEntity(entity);
			if (id == -1)
			{
				return 0;
			}
			switch (nType[id])
			{
				case 6:
				{
					LogMessage("data=%d", data);
					TeleportPlayer(data, Pos[id]);
				}
				case 12:
				{
					AcceptEntityInput(liftinfo[id][0], "Toggle", -1, caller, 0);
				}
				case 13:
				{
					AcceptEntityInput(laserprop[id], "Toggle", -1, caller, 0);
				}
				case 14:
				{
					AcceptEntityInput(rotrot[id], "Toggle", -1, caller, 0);
				}
				default:
				{
				}
			}
		}
		if (StrEqual(command, "8", true))
		{
			AcceptEntityInput(entity, "Kill", -1, caller, 0);
		}
	}
	return 0;
}

FindIdByButton(button)
{
	new i;
	while (i < EntTypeCount)
	{
		if (button == TargetButton[i])
		{
			LogMessage("Find Target:%d", i);
			return i;
		}
		i++;
	}
	return -1;
}

BecomeIntoHaiMian(entity)
{
	new var1;
	if (!IsValidEdict(entity) || !entity)
	{
		return 0;
	}
	new String:szModel[256];
	new Float:vecMaxs[3] = 0.0;
	new Float:vecMins[3] = 0.0;
	new Float:vecOrigin[3] = 0.0;
	new Float:vecAngles[3] = 0.0;
	GetEntPropString(entity, PropType:1, "m_ModelName", szModel, 256, 0);
	GetEntPropVector(entity, PropType:0, "m_vecMaxs", vecMaxs, 0);
	GetEntPropVector(entity, PropType:0, "m_vecMins", vecMins, 0);
	GetEntPropVector(entity, PropType:0, "m_vecOrigin", vecOrigin, 0);
	GetEntPropVector(entity, PropType:0, "m_angRotation", vecAngles, 0);
	new trigger = CreateEntityByName("trigger_multiple", -1);
	if (trigger == -1)
	{
		ThrowError("创建trigger失败!");
	}
	DispatchKeyValue(trigger, "spawnflags", "1");
	DispatchSpawn(trigger);
	ActivateEntity(trigger);
	vecOrigin[2] += 10.0;
	TeleportEntity(trigger, vecOrigin, vecAngles, NULL_VECTOR);
	SetEntityModel(trigger, szModel);
	SetEntPropVector(trigger, PropType:0, "m_vecMins", vecMins, 0);
	SetEntPropVector(trigger, PropType:0, "m_vecMaxs", vecMaxs, 0);
	SetEntProp(trigger, PropType:0, "m_nSolidType", any:2, 4, 0);
	new enteffects = GetEntProp(trigger, PropType:0, "m_fEffects", 4, 0);
	enteffects |= 32;
	SetEntProp(trigger, PropType:0, "m_fEffects", enteffects, 4, 0);
	LogMessage("%.1f,%.1f,%.1f", vecMins, vecMins[1], vecMins[2]);
	LogMessage("%.1f,%.1f,%.1f", vecMaxs, vecMaxs[1], vecMaxs[2]);
	HookSingleEntityOutput(trigger, "OnStartTouch", EntityOutput_OnStartTouch, false);
	nType[EntTypeCount] = 17;
	EntProp[EntTypeCount] = entity;
	EntTypeCount += 1;
	return 0;
}

public EntityOutput_OnStartTouch(String:output[], trigger, client, Float:delay)
{
	new Float:vecOrigin[3] = 0.0;
	GetEntPropVector(client, PropType:0, "m_vecOrigin", vecOrigin, 0);
	decl Float:vec[3];
	vec[0] = GetRandomFloat(-1.0, 1.1);
	vec[1] = GetRandomFloat(-1.0, 1.1);
	vec[2] = GetRandomFloat(-1.0, 1.1);
	TE_SetupSparks(vecOrigin, vec, 10, 3);
	TE_SendToAll(0.0);
	SDKUnhook(client, SDKHookType:2, SDKCallBack_OnTakeDamge);
	SDKHook(client, SDKHookType:2, SDKCallBack_OnTakeDamge);
	return 0;
}

public Action:SDKCallBack_OnTakeDamge(client, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	PrintHintText(client, "<<<  [凡梦] 免除伤害  >>>");
	SDKUnhook(client, SDKHookType:2, SDKCallBack_OnTakeDamge);
	return Action:3;
}

BecomeIntoXiWu(entity, Float:dis)
{
	new var1;
	if (!IsValidEdict(entity) || !entity)
	{
		return 0;
	}
	XwDis[EntTypeCount] = dis;
	CreateTimer(0.2, TimerXiWu, entity, 1);
	nType[EntTypeCount] = 18;
	EntProp[EntTypeCount] = entity;
	EntTypeCount += 1;
	return 0;
}

public Action:TimerXiWu(Handle:timer, any:entity)
{
	new id = FindIdEntPropByEntity(entity);
	if (id == -1)
	{
		KillTimer(timer, false);
		return Action:0;
	}
	new tar = 1;
	while (GetMaxEntities() > tar)
	{
		if (IsValidEdict(tar))
		{
			new String:clsname[256];
			GetEdictClassname(tar, clsname, 256);
			if (StrEqual(clsname, "player", true))
			{
				new Float:vecOrigin[3] = 0.0;
				new Float:pos[3] = 0.0;
				new Float:vec[3] = 0.0;
				GetEntPropVector(tar, PropType:0, "m_vecOrigin", vecOrigin, 0);
				GetEntPropVector(entity, PropType:0, "m_vecOrigin", pos, 0);
				new Float:dis = GetVectorDistance(vecOrigin, pos, false);
				if (dis < XwDis[id])
				{
					if (dis > 100.0)
					{
						dis = 100.0;
					}
					SubtractVectors(pos, vecOrigin, vec);
					NormalizeVector(vec, vec);
					ScaleVector(vec, dis * 0.5);
					LogMessage("%f,%f,%f", vec, vec[1], vec[2]);
					TeleportEntity(tar, NULL_VECTOR, NULL_VECTOR, vec);
				}
			}
		}
		tar++;
	}
	return Action:0;
}

BecomeIntoTuiWu(entity, Float:dis)
{
	new var1;
	if (!IsValidEdict(entity) || !entity)
	{
		return 0;
	}
	TwDis[EntTypeCount] = dis;
	CreateTimer(0.1, TimerTuiWu, entity, 3);
	nType[EntTypeCount] = 19;
	EntProp[EntTypeCount] = entity;
	EntTypeCount += 1;
	return 0;
}

public Action:TimerTuiWu(Handle:timer, any:entity)
{
	new id = FindIdEntPropByEntity(entity);
	if (id == -1)
	{
		KillTimer(timer, false);
		return Action:0;
	}
	new tar = 1;
	while (GetMaxEntities() > tar)
	{
		if (IsValidEdict(tar))
		{
			new String:clsname[256];
			GetEdictClassname(tar, clsname, 256);
			new var1;
			if (StrEqual(clsname, "player", true) || StrEqual(clsname, "infected", true))
			{
				new Float:vecOrigin[3] = 0.0;
				new Float:pos[3] = 0.0;
				new Float:vec[3] = 0.0;
				GetEntPropVector(tar, PropType:0, "m_vecOrigin", vecOrigin, 0);
				GetEntPropVector(entity, PropType:0, "m_vecOrigin", pos, 0);
				new Float:dis = GetVectorDistance(vecOrigin, pos, false);
				if (dis < TwDis[id])
				{
					if (dis > 100.0)
					{
						dis = 100.0;
					}
					SubtractVectors(pos, vecOrigin, vec);
					NormalizeVector(vec, vec);
					ScaleVector(vec, dis * -0.5);
					LogMessage("%f,%f,%f", vec, vec[1], vec[2]);
					TeleportEntity(tar, NULL_VECTOR, NULL_VECTOR, vec);
				}
			}
		}
		tar++;
	}
	return Action:0;
}

BecomeIntoJiaXue(entity)
{
	new var1;
	if (entity <= 0 || !IsValidEdict(entity))
	{
		return 0;
	}
	SetEntityRenderColor(entity, 0, 255, 255, 0);
	nType[EntTypeCount] = 20;
	EntProp[EntTypeCount] = entity;
	EntTypeCount += 1;
	SDKUnhook(entity, SDKHookType:8, SDKCallBackJiaXue_Touched);
	SDKHook(entity, SDKHookType:8, SDKCallBackJiaXue_Touched);
	return 0;
}

HpPerson(person)
{
	if (!IsValidEdict(person))
	{
		return 0;
	}
	decl String:clsname[64];
	GetEdictClassname(person, clsname, 64);
	if (person > MaxClients)
	{
		if (StrEqual(clsname, "infected", true))
		{
			AcceptEntityInput(person, "health", -1, -1, 0);
		}
		return 0;
	}
	else
	{
		CheatCommand(person, "give", "health");
	}
	return 0;
}

public SDKCallBackJiaXue_Touched(entity, toucher)
{
	new id = FindIdEntPropByEntity(entity);
	if (id == -1)
	{
		return 0;
	}
	if (nType[id] != 20)
	{
		SDKUnhook(entity, SDKHookType:8, SDKCallBackJiaXue_Touched);
		return 0;
	}
	HpPerson(toucher);
	return 0;
}

BecomeIntoShuFu(entity)
{
	new var1;
	if (entity <= 0 || !IsValidEdict(entity))
	{
		return 0;
	}
	SetEntityRenderColor(entity, 0, 120, 240, 120);
	nType[EntTypeCount] = 21;
	EntProp[EntTypeCount] = entity;
	EntTypeCount += 1;
	SDKUnhook(entity, SDKHookType:8, BecomeIntoShuFu_Touched);
	SDKHook(entity, SDKHookType:8, BecomeIntoShuFu_Touched);
	return 0;
}

public BecomeIntoShuFu_Touched(entity, toucher)
{
	new id = FindIdEntPropByEntity(entity);
	if (id == -1)
	{
		return 0;
	}
	if (nType[id] != 21)
	{
		SDKUnhook(entity, SDKHookType:8, BecomeIntoShuFu_Touched);
		return 0;
	}
	SfPerson(toucher);
	return 0;
}

SfPerson(person)
{
	if (!IsValidEdict(person))
	{
		return 0;
	}
	decl String:clsname[64];
	GetEdictClassname(person, clsname, 64);
	if (person > MaxClients)
	{
		if (StrEqual(clsname, "infected", true))
		{
			BlockPlayer(person);
		}
		return 0;
	}
	else
	{
		BlockPlayer(person);
	}
	return 0;
}

BlockPlayer(client)
{
	SetEntityMoveType(client, MoveType:0);
	if (!IsSoundPrecached("level/timer_bell.wav"))
	{
		PrecacheSound("level/timer_bell.wav", false);
	}
	EmitSoundToClient(client, "level/timer_bell.wav", -2, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	PrintHintText(client, "<<<  [凡梦] 被锁定 5 秒  >>>");
	bShuFu[client] = 1;
	CreateTimer(5.0, TimerBlockPlayer, client, 2);
	return 0;
}

public Action:TimerBlockPlayer(Handle:hTimer, any:client)
{
	SetEntityMoveType(client, MoveType:2);
	if (!IsSoundPrecached("level/timer_bell.wav"))
	{
		PrecacheSound("level/timer_bell.wav", false);
	}
	EmitSoundToClient(client, "level/timer_bell.wav", -2, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	PrintHintText(client, "<<<  [凡梦] 解除锁定状态  >>>");
	bShuFu[client] = 0;
	return Action:0;
}

BecomeIntoColors(entity)
{
	new var1;
	if (entity <= 0 || !IsValidEdict(entity))
	{
		return 0;
	}
	nType[EntTypeCount] = 22;
	EntProp[EntTypeCount] = entity;
	EntTypeCount += 1;
	SDKUnhook(entity, SDKHookType:8, BecomeIntoColors_Touched);
	SDKHook(entity, SDKHookType:8, BecomeIntoColors_Touched);
	return 0;
}

public BecomeIntoColors_Touched(entity, toucher)
{
	new id = FindIdEntPropByEntity(entity);
	if (id == -1)
	{
		return 0;
	}
	if (nType[id] != 22)
	{
		SDKUnhook(entity, SDKHookType:8, BecomeIntoColors_Touched);
		return 0;
	}
	SetEntityRenderColor(entity, 0, GetRandomInt(0, 255), GetRandomInt(0, 255), GetRandomInt(0, 255));
	PerformGlow(entity, 3, 0, GetRandomInt(0, 255), GetRandomInt(0, 255), GetRandomInt(0, 255));
	return 0;
}

PerformGlow(Client, Type, Range, Red, Green, Blue)
{
	new Color = Blue * 65536 + Green * 256 + Red;
	SetEntProp(Client, PropType:0, "m_iGlowType", Type, 4, 0);
	SetEntProp(Client, PropType:0, "m_nGlowRange", Range, 4, 0);
	SetEntProp(Client, PropType:0, "m_glowColorOverride", Color, 4, 0);
	return 0;
}

BecomeIntoAlpha(entity)
{
	new var1;
	if (entity <= 0 || !IsValidEdict(entity))
	{
		return 0;
	}
	SetEntityRenderFx(entity, RenderFx:5);
	nType[EntTypeCount] = 23;
	EntProp[EntTypeCount] = entity;
	EntTypeCount += 1;
	return 0;
}

public BecomeIntoAlpha_Touched(entity, toucher)
{
	new id = FindIdEntPropByEntity(entity);
	if (id == -1)
	{
		return 0;
	}
	if (nType[id] != 23)
	{
		SDKUnhook(entity, SDKHookType:10, BecomeIntoAlpha_Touched);
		return 0;
	}
	SetEntityRenderMode(entity, RenderMode:10);
	SetEntityRenderColor(entity, 255, 255, 255, 255);
	return 0;
}

BecomeIntoBaoZha(entity)
{
	new var1;
	if (entity <= 0 || !IsValidEdict(entity))
	{
		return 0;
	}
	nType[EntTypeCount] = 24;
	EntProp[EntTypeCount] = entity;
	EntTypeCount += 1;
	SDKUnhook(entity, SDKHookType:8, BecomeIntoBaoZha_Touched);
	SDKHook(entity, SDKHookType:8, BecomeIntoBaoZha_Touched);
	SDKUnhook(entity, SDKHookType:0, BecomeIntoBaoZha_OnEndTouch);
	SDKHook(entity, SDKHookType:0, BecomeIntoBaoZha_OnEndTouch);
	return 0;
}

public BecomeIntoBaoZha_Touched(entity, toucher)
{
	new id = FindIdEntPropByEntity(entity);
	if (id == -1)
	{
		return 0;
	}
	if (nType[id] != 24)
	{
		SDKUnhook(entity, SDKHookType:10, BecomeIntoBaoZha_Touched);
		SDKUnhook(entity, SDKHookType:0, BecomeIntoBaoZha_OnEndTouch);
		return 0;
	}
	PrintHintText(toucher, "[凡梦] 离开物体后将会爆炸!");
	return 0;
}

public BecomeIntoBaoZha_OnEndTouch(entity, toucher)
{
	new id = FindIdEntPropByEntity(entity);
	if (id == -1)
	{
		return 0;
	}
	if (nType[id] != 24)
	{
		SDKUnhook(entity, SDKHookType:10, BecomeIntoBaoZha_Touched);
		SDKUnhook(entity, SDKHookType:0, BecomeIntoBaoZha_OnEndTouch);
		return 0;
	}
	SetUpExplosion(toucher);
	DoExplosionDamage(toucher);
	return 0;
}

SetUpExplosion(entity)
{
	new Float:pp[3] = 0.0;
	GetEntPropVector(entity, PropType:0, "m_vecOrigin", pp, 0);
	TE_SetupExplosion(pp, g_explotion, 100.0, 10, 0, 100, 10000, 1183064, 67);
	TE_SendToAll(0.0);
	switch (GetRandomInt(1, 2))
	{
		case 1:
		{
			EmitSoundToAll("weapons/grenade_launcher/grenadefire/grenade_launcher_explode_1.wav", entity, 0, 80, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}
		case 2:
		{
			EmitSoundToAll("weapons/grenade_launcher/grenadefire/grenade_launcher_explode_2.wav", entity, 0, 80, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}
		default:
		{
		}
	}
	return 0;
}

DoExplosionDamage(entity)
{
	new count;
	new client;
	new i;
	new attacker;
	decl Float:ddPos[3];
	decl Float:dgPos[3];
	decl String:tName[24];
	GetEntPropVector(entity, PropType:0, "m_vecOrigin", ddPos, 0);
	client = GetEntPropEnt(entity, PropType:1, "m_hOwnerEntity", 0);
	if (IsValidClient(client, 0, true, true))
	{
		attacker = client;
	}
	else
	{
		attacker = entity;
	}
	count = GetEntityCount();
	i = 1;
	while (i <= count)
	{
		if (IsValidEntity(i))
		{
			if (count <= MaxClients)
			{
				new var1;
				if (IsValidClient(i, 0, true, true) && GetClientTeam(i) >= 2)
				{
					GetEntPropVector(i, PropType:0, "m_vecOrigin", dgPos, 0);
					if (GetVectorDistance(ddPos, dgPos, false) <= 1140457472)
					{
						DealDamage(attacker, i, GetRandomInt(1000, 2000), 64, "grenade_launcher");
					}
				}
			}
			else
			{
				GetEntityClassname(i, tName, 24);
				if (StrContains(tName, "infected", false) != -1)
				{
					GetEntPropVector(i, PropType:0, "m_vecOrigin", dgPos, 0);
					if (GetVectorDistance(ddPos, dgPos, false) <= 1140457472)
					{
						DealDamage(attacker, i, GetRandomInt(1000, 2000), 64, "grenade_launcher");
					}
				}
				if (StrContains(tName, "witch", false) != -1)
				{
					GetEntPropVector(i, PropType:0, "m_vecOrigin", dgPos, 0);
					if (GetVectorDistance(ddPos, dgPos, false) <= 1140457472)
					{
						DealDamage(attacker, i, GetRandomInt(1000, 2000), 64, "grenade_launcher");
					}
				}
			}
		}
		i++;
	}
	return 0;
}

DealDamage(attacker, victim, damage, dmg_type, String:weapon[])
{
	new var1;
	if (IsValidEdict(victim) && damage > 0)
	{
		new String:victimid[64];
		new String:dmg_type_str[32];
		IntToString(dmg_type, dmg_type_str, 32);
		new ePointHurt = CreateEntityByName("point_hurt", -1);
		if (ePointHurt)
		{
			Format(victimid, 64, "victim%d", victim);
			DispatchKeyValue(victim, "targetname", victimid);
			DispatchKeyValue(ePointHurt, "DamageTarget", victimid);
			DispatchKeyValueFloat(ePointHurt, "Damage", float(damage));
			DispatchKeyValue(ePointHurt, "DamageType", dmg_type_str);
			if (!StrEqual(weapon, "", true))
			{
				DispatchKeyValue(ePointHurt, "classname", weapon);
			}
			DispatchSpawn(ePointHurt);
			if (IsValidPlayer(attacker, true, true))
			{
				AcceptEntityInput(ePointHurt, "Hurt", attacker, -1, 0);
			}
			else
			{
				AcceptEntityInput(ePointHurt, "Hurt", -1, -1, 0);
			}
			RemoveEdict(ePointHurt);
		}
	}
	return 0;
}

BecomeIntoJianyin(entity)
{
	new var1;
	if (entity <= 0 || !IsValidEdict(entity))
	{
		return 0;
	}
	nType[EntTypeCount] = 25;
	EntProp[EntTypeCount] = entity;
	EntTypeCount += 1;
	SDKUnhook(entity, SDKHookType:10, BecomeIntoJianyin_Touched);
	SDKHook(entity, SDKHookType:10, BecomeIntoJianyin_Touched);
	SDKUnhook(entity, SDKHookType:0, BecomeIntoJianyin_OnEndTouch);
	SDKHook(entity, SDKHookType:0, BecomeIntoJianyin_OnEndTouch);
	return 0;
}

public BecomeIntoJianyin_Touched(entity, toucher)
{
	new id = FindIdEntPropByEntity(entity);
	if (id == -1)
	{
		return 0;
	}
	if (nType[id] != 25)
	{
		SDKUnhook(entity, SDKHookType:10, BecomeIntoJianyin_Touched);
		SDKUnhook(entity, SDKHookType:0, BecomeIntoJianyin_OnEndTouch);
		return 0;
	}
	SetEntityRenderFx(entity, RenderFx:6);
	return 0;
}

public BecomeIntoJianyin_OnEndTouch(entity, toucher)
{
	new id = FindIdEntPropByEntity(entity);
	if (id == -1)
	{
		return 0;
	}
	if (nType[id] != 25)
	{
		SDKUnhook(entity, SDKHookType:10, BecomeIntoJianyin_Touched);
		SDKUnhook(entity, SDKHookType:0, BecomeIntoJianyin_OnEndTouch);
		return 0;
	}
	SetEntityRenderFx(entity, RenderFx:8);
	return 0;
}

BecomeIntoJianxian(entity)
{
	new var1;
	if (entity <= 0 || !IsValidEdict(entity))
	{
		return 0;
	}
	SetEntityRenderFx(entity, RenderFx:5);
	nType[EntTypeCount] = 26;
	EntProp[EntTypeCount] = entity;
	EntTypeCount += 1;
	SDKUnhook(entity, SDKHookType:10, BecomeIntoJianxian_Touched);
	SDKHook(entity, SDKHookType:10, BecomeIntoJianxian_Touched);
	SDKUnhook(entity, SDKHookType:0, BecomeIntoJianxian_OnEndTouch);
	SDKHook(entity, SDKHookType:0, BecomeIntoJianxian_OnEndTouch);
	return 0;
}

public BecomeIntoJianxian_Touched(entity, toucher)
{
	new id = FindIdEntPropByEntity(entity);
	if (id == -1)
	{
		return 0;
	}
	if (nType[id] != 26)
	{
		SDKUnhook(entity, SDKHookType:10, BecomeIntoJianxian_Touched);
		SDKUnhook(entity, SDKHookType:0, BecomeIntoJianxian_OnEndTouch);
		return 0;
	}
	SetEntityRenderFx(entity, RenderFx:8);
	return 0;
}

public BecomeIntoJianxian_OnEndTouch(entity, toucher)
{
	new id = FindIdEntPropByEntity(entity);
	if (id == -1)
	{
		return 0;
	}
	if (nType[id] != 26)
	{
		SDKUnhook(entity, SDKHookType:10, BecomeIntoJianxian_Touched);
		SDKUnhook(entity, SDKHookType:0, BecomeIntoJianxian_OnEndTouch);
		return 0;
	}
	SetEntityRenderFx(entity, RenderFx:5);
	return 0;
}

BecomeIntoFuHuo(entity)
{
	new var1;
	if (entity <= 0 || !IsValidEdict(entity))
	{
		return 0;
	}
	nType[EntTypeCount] = 27;
	EntProp[EntTypeCount] = entity;
	EntTypeCount += 1;
	SDKUnhook(entity, SDKHookType:8, BecomeIntoFuHuo_Touched);
	SDKHook(entity, SDKHookType:8, BecomeIntoFuHuo_Touched);
	return 0;
}

public BecomeIntoFuHuo_Touched(entity, toucher)
{
	new id = FindIdEntPropByEntity(entity);
	if (id == -1)
	{
		return 0;
	}
	if (nType[id] != 27)
	{
		SDKUnhook(entity, SDKHookType:8, BecomeIntoFuHuo_Touched);
		return 0;
	}
	FhPerson(toucher);
	return 0;
}

FhPerson(person)
{
	if (!IsValidEdict(person))
	{
		return 0;
	}
	decl String:clsname[64];
	GetEdictClassname(person, clsname, 64);
	if (person > MaxClients)
	{
		if (!(StrEqual(clsname, "infected", true)))
		{
			return 0;
		}
	}
	else
	{
		RespawnPlayer(person);
	}
	return 0;
}

public Action:TimerSoundPlayer(Handle:hTimer, any:client)
{
	if (!IsSoundPrecached("player/survivor/voice/coach/worldc2m2b06.wav"))
	{
		PrecacheSound("player/survivor/voice/coach/worldc2m2b06.wav", false);
	}
	EmitSoundToClient(client, "player/survivor/voice/coach/worldc2m2b06.wav", -2, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	return Action:0;
}

public Action:RespawnPlayerTime(Handle:timer, any:client)
{
	bFuHuo[client] = 0;
	return Action:0;
}

BecomeIntoLucky(entity)
{
	new var1;
	if (entity <= 0 || !IsValidEdict(entity))
	{
		return 0;
	}
	SetEntityRenderColor(entity, 0, 255, 255, 0);
	nType[EntTypeCount] = 28;
	EntProp[EntTypeCount] = entity;
	EntTypeCount += 1;
	SDKUnhook(entity, SDKHookType:8, BecomeIntoLucky_Touched);
	SDKHook(entity, SDKHookType:8, BecomeIntoLucky_Touched);
	return 0;
}

public BecomeIntoLucky_Touched(entity, toucher)
{
	new id = FindIdEntPropByEntity(entity);
	if (id == -1)
	{
		return 0;
	}
	if (nType[id] != 28)
	{
		SDKUnhook(entity, SDKHookType:8, BecomeIntoLucky_Touched);
		return 0;
	}
	LuckyPerson(toucher);
	return 0;
}

LuckyPerson(person)
{
	if (!IsValidEdict(person))
	{
		return 0;
	}
	decl String:clsname[64];
	GetEdictClassname(person, clsname, 64);
	if (person > MaxClients)
	{
		if (!(StrEqual(clsname, "infected", true)))
		{
			return 0;
		}
	}
	else
	{
		draw_function_off(person);
	}
	return 0;
}


public Action:draw_function_off(Client)
{
	PrintHintText(Client, "<<<  [凡梦] 抽奖功能停用!  >>>");
	return Action:0;
}

public Action:draw_function(Client)
{
	if (L[Client])
	{
		if (!IsFakeClient(Client))
		{
			switch (GetRandomInt(1, 42))
			{
				case 1:
				{
					new i = 1;
					while (i <= MaxClients)
					{
						if (IsClientInGame(i))
						{
							if (GetClientTeam(i) == 2)
							{
								new MaxHP = GetEntProp(i, PropType:1, "m_iMaxHealth", 4, 0);
								SetEntProp(i, PropType:1, "m_iHealth", MaxHP, 4, 0);
							}
						}
						i++;
					}
					L[Client] += -1;
					PrintToChatAll("\x04[抽奖]\x05 玩家：\x04%N \x05抽到了\x04 [所有幸存者血量恢复]", Client);
					PrintHintText(Client, "[抽奖] 你还有[%d]次抽奖机会!", L[Client]);
				}
				case 2:
				{
					new i = 1;
					while (i <= MaxClients)
					{
						if (IsClientInGame(i))
						{
							if (GetClientTeam(i) == 3)
							{
								ForcePlayerSuicide(i);
							}
						}
						i++;
					}
					L[Client] += -1;
					PrintToChatAll("\x04[抽奖]\x05 玩家：\x04%N \x05抽到了\x04 [清除所有的特感]", Client);
					PrintHintText(Client, "[抽奖] 你还有[%d]次抽奖机会!", L[Client]);
				}
				case 3:
				{
					CheatCommand(Client, "ent_remove_all", "infected");
					L[Client] += -1;
					PrintToChatAll("\x04[抽奖]\x05 玩家：\x04%N \x05抽到了\x04 [清除所有小僵尸]", Client);
					PrintHintText(Client, "[抽奖] 你还有[%d]次抽奖机会!", L[Client]);
				}
				case 4:
				{
					CheatCommand(Client, "give", "rifle");
					L[Client] += -1;
					PrintToChatAll("\x04[抽奖]\x05 玩家：\x04%N \x05抽到了\x04 [M16]", Client);
					PrintHintText(Client, "[抽奖] 你还有[%d]次抽奖机会!", L[Client]);
				}
				case 5:
				{
					CheatCommand(Client, "give", "rifle_ak47");
					L[Client] += -1;
					PrintToChatAll("\x04[抽奖]\x05 玩家：\x04%N \x05抽到了\x04 [AK47]", Client);
					PrintHintText(Client, "[抽奖] 你还有[%d]次抽奖机会!", L[Client]);
				}
				case 6:
				{
					CheatCommand(Client, "give", "sniper_military");
					L[Client] += -1;
					PrintToChatAll("\x04[抽奖]\x05 玩家：\x04%N \x05抽到了\x04 [大型连狙]", Client);
					PrintHintText(Client, "[抽奖] 你还有[%d]次抽奖机会!", L[Client]);
				}
				case 7:
				{
					CheatCommand(Client, "give", "hunting_rifle");
					L[Client] += -1;
					PrintToChatAll("\x04[抽奖]\x05 玩家：\x04%N \x05抽到了\x04 [小型连狙]", Client);
					PrintHintText(Client, "[抽奖] 你还有[%d]次抽奖机会!", L[Client]);
				}
				case 8:
				{
					CheatCommand(Client, "give", "autoshotgun");
					L[Client] += -1;
					PrintToChatAll("\x04[抽奖]\x05 玩家：\x04%N \x05抽到了\x04 [自动散弹枪]", Client);
					PrintHintText(Client, "[抽奖] 你还有[%d]次抽奖机会!", L[Client]);
				}
				case 9:
				{
					CheatCommand(Client, "give", "shotgun_spas");
					L[Client] += -1;
					PrintToChatAll("\x04[抽奖]\x05 玩家：\x04%N \x05抽到了\x04 [SPAS战斗散弹枪]", Client);
					PrintHintText(Client, "[抽奖] 你还有[%d]次抽奖机会!", L[Client]);
				}
				case 10:
				{
					CheatCommand(Client, "give", "shotgun_chrome");
					L[Client] += -1;
					PrintToChatAll("\x04[抽奖]\x05 玩家：\x04%N \x05抽到了\x04 [合金散弹枪]", Client);
					PrintHintText(Client, "[抽奖] 你还有[%d]次抽奖机会!", L[Client]);
				}
				case 11:
				{
					CheatCommand(Client, "give", "pumpshotgun");
					L[Client] += -1;
					PrintToChatAll("\x04[抽奖]\x05 玩家：\x04%N \x05抽到了\x04 [泵动式散弹枪]", Client);
					PrintHintText(Client, "[抽奖] 你还有[%d]次抽奖机会!", L[Client]);
				}
				case 12:
				{
					CheatCommand(Client, "give", "rifle_desert");
					L[Client] += -1;
					PrintToChatAll("\x04[抽奖]\x05 玩家：\x04%N \x05抽到了\x04 [突击步枪]", Client);
					PrintHintText(Client, "[抽奖] 你还有[%d]次抽奖机会!", L[Client]);
				}
				case 13:
				{
					CheatCommand(Client, "give", "grenade_launcher");
					L[Client] += -1;
					PrintToChatAll("\x04[抽奖]\x05 玩家：\x04%N \x05抽到了\x04 [榴弹炮]", Client);
					PrintHintText(Client, "[抽奖] 你还有[%d]次抽奖机会!", L[Client]);
				}
				case 14:
				{
					CheatCommand(Client, "give", "smg");
					L[Client] += -1;
					PrintToChatAll("\x04[抽奖]\x05 玩家：\x04%N \x05抽到了\x04 [乌兹小冲锋]", Client);
					PrintHintText(Client, "[抽奖] 你还有[%d]次抽奖机会!", L[Client]);
				}
				case 15:
				{
					CheatCommand(Client, "give", "smg_silenced");
					L[Client] += -1;
					PrintToChatAll("\x04[抽奖]\x05 玩家：\x04%N \x05抽到了\x04 [消音小冲锋]", Client);
					PrintHintText(Client, "[抽奖] 你还有[%d]次抽奖机会!", L[Client]);
				}
				case 16:
				{
					CheatCommand(Client, "give", "first_aid_kit");
					L[Client] += -1;
					PrintToChatAll("\x04[抽奖]\x05 玩家：\x04%N \x05抽到了\x04 [医药包]", Client);
					PrintHintText(Client, "[抽奖] 你还有[%d]次抽奖机会!", L[Client]);
				}
				case 17:
				{
					CheatCommand(Client, "give", "pain_pills");
					L[Client] += -1;
					PrintToChatAll("\x04[抽奖]\x05 玩家：\x04%N \x05抽到了\x04 [止痛药]", Client);
					PrintHintText(Client, "[抽奖] 你还有[%d]次抽奖机会!", L[Client]);
				}
				case 18:
				{
					CheatCommand(Client, "give", "adrenaline");
					L[Client] += -1;
					PrintToChatAll("\x04[抽奖]\x05 玩家：\x04%N \x05抽到了\x04 [肾上腺素]", Client);
					PrintHintText(Client, "[抽奖] 你还有[%d]次抽奖机会!", L[Client]);
				}
				case 19:
				{
					CheatCommand(Client, "give", "defibrillator");
					L[Client] += -1;
					PrintToChatAll("\x04[抽奖]\x05 玩家：\x04%N \x05抽到了\x04 [电击器]", Client);
					PrintHintText(Client, "[抽奖] 你还有[%d]次抽奖机会!", L[Client]);
				}
				case 20:
				{
					CheatCommand(Client, "give", "pistol_magnum");
					L[Client] += -1;
					PrintToChatAll("\x04[抽奖]\x05 玩家：\x04%N \x05抽到了\x04 [马格南手枪]", Client);
					PrintHintText(Client, "[抽奖] 你还有[%d]次抽奖机会!", L[Client]);
				}
				case 21:
				{
					CheatCommand(Client, "give", "baseball_bat");
					L[Client] += -1;
					PrintToChatAll("\x04[抽奖]\x05 玩家：\x04%N \x05抽到了\x04 [棒球棒]", Client);
					PrintHintText(Client, "[抽奖] 你还有[%d]次抽奖机会!", L[Client]);
				}
				case 22:
				{
					CheatCommand(Client, "give", "knife");
					L[Client] += -1;
					PrintToChatAll("\x04[抽奖]\x05 玩家：\x04%N \x05抽到了\x04 [小刀]", Client);
					PrintHintText(Client, "[抽奖] 你还有[%d]次抽奖机会!", L[Client]);
				}
				case 23:
				{
					CheatCommand(Client, "give", "pipe_bomb");
					L[Client] += -1;
					PrintToChatAll("\x04[抽奖]\x05 玩家：\x04%N \x05抽到了\x04 [土制炸弹]", Client);
					PrintHintText(Client, "[抽奖] 你还有[%d]次抽奖机会!", L[Client]);
				}
				case 24:
				{
					CheatCommand(Client, "give", "molotov");
					L[Client] += -1;
					PrintToChatAll("\x04[抽奖]\x05 玩家：\x04%N \x05抽到了\x04 [燃烧瓶]", Client);
					PrintHintText(Client, "[抽奖] 你还有[%d]次抽奖机会!", L[Client]);
				}
				case 25:
				{
					CheatCommand(Client, "give", "vomitjar");
					L[Client] += -1;
					PrintToChatAll("\x04[抽奖]\x05 玩家：\x04%N \x05抽到了\x04 [胆汁炸弹]", Client);
					PrintHintText(Client, "[抽奖] 你还有[%d]次抽奖机会!", L[Client]);
				}
				case 26:
				{
					CheatCommand(Client, "give", "chainsaw");
					L[Client] += -1;
					PrintToChatAll("\x04[抽奖]\x05 玩家：\x04%N \x05抽到了\x04 [电锯]", Client);
					PrintHintText(Client, "[抽奖] 你还有[%d]次抽奖机会!", L[Client]);
				}
				case 27:
				{
					CheatCommand(Client, "give", "upgradepack_incendiary");
					L[Client] += -1;
					PrintToChatAll("\x04[抽奖]\x05 玩家：\x04%N \x05抽到了\x04 [燃烧弹盒]", Client);
					PrintHintText(Client, "[抽奖] 你还有[%d]次抽奖机会!", L[Client]);
				}
				case 28:
				{
					CheatCommand(Client, "give", "upgradepack_explosive");
					L[Client] += -1;
					PrintToChatAll("\x04[抽奖]\x05 玩家：\x04%N \x05抽到了\x04 [高爆弹盒]", Client);
					PrintHintText(Client, "[抽奖] 你还有[%d]次抽奖机会!", L[Client]);
				}
				case 29:
				{
					CheatCommand(Client, "give", "propanetank");
					L[Client] += -1;
					PrintToChatAll("\x04[抽奖]\x05 玩家：\x04%N \x05抽到了\x04 [煤气罐]", Client);
					PrintHintText(Client, "[抽奖] 你还有[%d]次抽奖机会!", L[Client]);
				}
				case 30:
				{
					CheatCommand(Client, "give", "gascan");
					L[Client] += -1;
					PrintToChatAll("\x04[抽奖]\x05 玩家：\x04%N \x05抽到了\x04 [汽油桶]", Client);
					PrintHintText(Client, "[抽奖] 你还有[%d]次抽奖机会!", L[Client]);
				}
				case 31:
				{
					CheatCommand(Client, "give", "oxygentank");
					L[Client] += -1;
					PrintToChatAll("\x04[抽奖]\x05 玩家：\x04%N \x05抽到了\x04 [氧气罐]", Client);
					PrintHintText(Client, "[抽奖] 你还有[%d]次抽奖机会!", L[Client]);
				}
				case 32:
				{
					CheatCommand(Client, "z_spawn", "witch");
					CheatCommand(Client, "z_spawn", "witch");
					CheatCommand(Client, "z_spawn", "witch");
					CheatCommand(Client, "z_spawn", "witch");
					L[Client] += -1;
					PrintToChatAll("\x04[抽奖]\x05 玩家：\x04%N \x05抽到了\x04 [四只Witch]", Client);
					PrintHintText(Client, "[抽奖] 你还有[%d]次抽奖机会!", L[Client]);
				}
				case 33:
				{
					CheatCommand(Client, "z_spawn", "witch");
					CheatCommand(Client, "z_spawn", "witch");
					CheatCommand(Client, "z_spawn", "witch");
					L[Client] += -1;
					PrintToChatAll("\x04[抽奖]\x05 玩家：\x04%N \x05抽到了\x04 [三只Witch]", Client);
					PrintHintText(Client, "[抽奖] 你还有[%d]次抽奖机会!", L[Client]);
				}
				case 34:
				{
					CheatCommand(Client, "z_spawn", "witch");
					CheatCommand(Client, "z_spawn", "witch");
					L[Client] += -1;
					PrintToChatAll("\x04[抽奖]\x05 玩家：\x04%N \x05抽到了\x04 [两只Witch]", Client);
					PrintHintText(Client, "[抽奖] 你还有[%d]次抽奖机会!", L[Client]);
				}
				case 35:
				{
					CheatCommand(Client, "z_spawn", "tank");
					CheatCommand(Client, "z_spawn", "tank");
					CheatCommand(Client, "z_spawn", "tank");
					CheatCommand(Client, "z_spawn", "tank");
					L[Client] += -1;
					PrintToChatAll("\x04[抽奖]\x05 玩家：\x04%N \x05抽到了\x04 [四只Tank]", Client);
					PrintHintText(Client, "[抽奖] 你还有[%d]次抽奖机会!", L[Client]);
				}
				case 36:
				{
					CheatCommand(Client, "z_spawn", "tank");
					CheatCommand(Client, "z_spawn", "tank");
					CheatCommand(Client, "z_spawn", "tank");
					L[Client] += -1;
					PrintToChatAll("\x04[抽奖]\x05 玩家：\x04%N \x05抽到了\x04 [三只Tank]", Client);
					PrintHintText(Client, "[抽奖] 你还有[%d]次抽奖机会!", L[Client]);
				}
				case 37:
				{
					CheatCommand(Client, "z_spawn", "tank");
					CheatCommand(Client, "z_spawn", "tank");
					L[Client] += -1;
					PrintToChatAll("\x04[抽奖]\x05 玩家：\x04%N \x05抽到了\x04 [两只Tank]", Client);
					PrintHintText(Client, "[抽奖] 你还有[%d]次抽奖机会!", L[Client]);
				}
				case 38:
				{
					ServerCommand("sm_freeze \"%N\" \"%d\"", Client, 10);
					L[Client] += -1;
					PrintToChatAll("\x04[抽奖]\x05 玩家：\x04%N \x05抽到了\x04 [被冰冻10秒]", Client);
					PrintHintText(Client, "[抽奖] 你还有[%d]次抽奖机会!", L[Client]);
				}
				case 39:
				{
					ServerCommand("sm_freeze \"%N\" \"%d\"", Client, 30);
					L[Client] += -1;
					PrintToChatAll("\x04[抽奖]\x05 玩家：\x04%N \x05抽到了\x04 [被冰冻30秒]", Client);
					PrintHintText(Client, "[抽奖] 你还有[%d]次抽奖机会!", L[Client]);
				}
				case 40:
				{
					ServerCommand("sm_freeze \"%N\" \"%d\"", Client, 50);
					L[Client] += -1;
					PrintToChatAll("\x04[抽奖]\x05 玩家：\x04%N \x05抽到了\x04 [被冰冻50秒]", Client);
					PrintHintText(Client, "[抽奖] 你还有[%d]次抽奖机会!", L[Client]);
				}
				case 41:
				{
					ServerCommand("sm_freeze \"%N\" \"%d\"", Client, 70);
					L[Client] += -1;
					PrintToChatAll("\x04[抽奖]\x05 玩家：\x04%N \x05抽到了\x04 [被冰冻70秒]", Client);
					PrintHintText(Client, "[抽奖] 你还有[%d]次抽奖机会!", L[Client]);
				}
				case 42:
				{
					ServerCommand("sm_freeze \"%N\" \"%d\"", Client, 90);
					L[Client] += -1;
					PrintToChatAll("\x04[抽奖]\x05 玩家：\x04%N \x05抽到了\x04 [被冰冻90秒]", Client);
					PrintHintText(Client, "[抽奖] 你还有[%d]次抽奖机会!", L[Client]);
				}
				default:
				{
				}
			}
		}
	}
	else
	{
		PrintHintText(Client, "<<<  [凡梦] 你已经没有抽奖机会了!  >>>");
	}
	return Action:0;
}

BecomeIntoJumpEx(entity, Float:power)
{
	new var1;
	if (entity <= 0 || !IsValidEdict(entity))
	{
		return 0;
	}
	SetEntityRenderColor(entity, 255, 165, 0, 255);
	jumppowerex[EntTypeCount] = power;
	nType[EntTypeCount] = 29;
	EntProp[EntTypeCount] = entity;
	EntTypeCount += 1;
	SDKUnhook(entity, SDKHookType:3, SDKCallBackJump_TouchedEx);
	SDKHook(entity, SDKHookType:3, SDKCallBackJump_TouchedEx);
	return 0;
}

JumpPersonEx(person, Float:power)
{
	new var1;
	if (person > MaxClients && IsValidEdict(person))
	{
		return 0;
	}
	new Handle:pack = CreateDataPack();
	WritePackCell(pack, person);
	WritePackFloat(pack, power);
	CreateTimer(0.0, TimerJumpEx, pack, 0);
	return 0;
}

public Action:TimerJumpEx(Handle:timer, any:pack)
{
	ResetPack(pack, false);
	new person = ReadPackCell(pack);
	new Float:power = ReadPackFloat(pack);
	new Float:velo[3] = 0.0;
	velo[0] = GetEntPropFloat(person, PropType:0, "m_vecVelocity[0]", 0);
	velo[1] = GetEntPropFloat(person, PropType:0, "m_vecVelocity[1]", 0);
	velo[2] = GetEntPropFloat(person, PropType:0, "m_vecVelocity[2]", 0);
	if (velo[2] != 0.0)
	{
		return Action:0;
	}
	new Float:vec[3] = 0.0;
	vec[0] = velo[0];
	vec[1] = velo[1];
	vec[2] = velo[2] + power * 300.0;
	TeleportEntity(person, NULL_VECTOR, NULL_VECTOR, vec);
	EmitSoundFromPlayer(person, "buttons/blip1.wav");
	return Action:0;
}

ShowChooseJumpPowerMenuEx(client, entity)
{
	new Handle:menu = CreateMenu(MenuHandler_ChooseJumpPowerEx, MenuAction:28);
	SetMenuExitButton(menu, true);
	SetMenuTitle(menu, "请选择弹跳板的力度,编号:%d", entity);
	AddMenuItem(menu, "1.0", "小", 0);
	AddMenuItem(menu, "1.7", "较小", 0);
	AddMenuItem(menu, "3.4", "中", 0);
	AddMenuItem(menu, "4.0", "大", 0);
	AddMenuItem(menu, "5.0", "最大", 0);
	AddMenuItem(menu, "25.0", "最大x5", 0);
	AddMenuItem(menu, "50.0", "最大x10", 0);
	DisplayMenu(menu, client, 0);
	NowEntity = entity;
	return 0;
}

public MenuHandler_ChooseJumpPowerEx(Handle:menu, MenuAction:action, client, item)
{
	switch (action)
	{
		case 4:
		{
			new var1;
			if (NowEntity <= 0 || !IsValidEdict(NowEntity))
			{
				return 0;
			}
			decl String:sType[64];
			new Float:power = 0.0;
			GetMenuItem(menu, item, sType, 64, 0, "", 0);
			power = StringToFloat(sType);
			if (power < 0.0)
			{
				return 0;
			}
			BecomeIntoJumpEx(NowEntity, power);
		}
		case 8:
		{
		}
		default:
		{
		}
	}
	return 0;
}

public SDKCallBackJump_TouchedEx(entity, person)
{
	new id = FindIdEntPropByEntity(entity);
	if (id == -1)
	{
		return 0;
	}
	if (nType[id] != 29)
	{
		SDKUnhook(entity, SDKHookType:3, SDKCallBackJump_TouchedEx);
		return 0;
	}
	new var1;
	if (person < MaxClients && !IsPlayerAlive(person))
	{
		return 0;
	}
	JumpPersonEx(person, jumppowerex[id]);
	return 0;
}

BecomeIntoThrowex(entity, Float:power)
{
	new var1;
	if (entity <= 0 || !IsValidEdict(entity))
	{
		return 0;
	}
	SetEntityRenderColor(entity, 0, 255, 0, 255);
	throwpowerex[EntTypeCount] = power;
	nType[EntTypeCount] = 30;
	EntProp[EntTypeCount] = entity;
	EntTypeCount += 1;
	SDKUnhook(entity, SDKHookType:3, SDKCallBackThrow_Touchedex);
	SDKHook(entity, SDKHookType:3, SDKCallBackThrow_Touchedex);
	return 0;
}

ThrowPersonex(person, Float:power, Float:origin[3], Float:angles[3])
{
	new var1;
	if (person > MaxClients || bThrowex[person])
	{
		return 0;
	}
	new Handle:pack = CreateDataPack();
	WritePackCell(pack, person);
	WritePackFloat(pack, power);
	WritePackFloat(pack, origin[0]);
	WritePackFloat(pack, origin[1]);
	WritePackFloat(pack, origin[2]);
	WritePackFloat(pack, angles[0]);
	WritePackFloat(pack, angles[1]);
	WritePackFloat(pack, angles[2]);
	CreateTimer(0.0, TimerThrowex, pack, 0);
	bThrowex[person] = 1;
	return 0;
}

public Action:TimerThrowex(Handle:timer, any:pack)
{
	ResetPack(pack, false);
	decl Float:vAngles[3];
	decl Float:vOrigin[3];
	new person = ReadPackCell(pack);
	if (!bThrowex[person])
	{
		return Action:0;
	}
	new Float:power = ReadPackFloat(pack) * 3.0;
	vOrigin[0] = ReadPackFloat(pack);
	vOrigin[1] = ReadPackFloat(pack);
	vOrigin[2] = ReadPackFloat(pack);
	vAngles[0] = ReadPackFloat(pack);
	vAngles[1] = ReadPackFloat(pack);
	vAngles[2] = ReadPackFloat(pack);
	decl Float:VecOrigin[3];
	decl Float:pos[3];
	GetClientEyePosition(person, VecOrigin);
	TR_TraceRayFilter(VecOrigin, vAngles, 16513, RayType:1, TraceRayDontHitSelf, person);
	if (TR_DidHit(Handle:0))
	{
		TR_GetEndPosition(pos, Handle:0);
	}
	decl Float:volicity[3];
	SubtractVectors(pos, vOrigin, volicity);
	ScaleVector(volicity, power);
	volicity[2] = FloatAbs(volicity[2]);
	TeleportEntity(person, NULL_VECTOR, NULL_VECTOR, volicity);
	bThrowex[person] = 0;
	EmitSoundFromPlayer(person, "buttons/blip1.wav");
	return Action:0;
}

public SDKCallBackThrow_Touchedex(entity, toucher)
{
	new id = FindIdEntPropByEntity(entity);
	if (id == -1)
	{
		return 0;
	}
	if (nType[id] != 30)
	{
		SDKUnhook(entity, SDKHookType:10, SDKCallBackThrow_Touchedex);
		return 0;
	}
	new var1;
	if (toucher < MaxClients && !IsPlayerAlive(toucher))
	{
		return 0;
	}
	decl Float:ori[3];
	decl Float:ang[3];
	GetEntPropVector(entity, PropType:0, "m_vecOrigin", ori, 0);
	GetEntPropVector(entity, PropType:0, "m_angRotation", ang, 0);
	ThrowPersonex(toucher, throwpowerex[id], ori, ang);
	return 0;
}

ShowChooseThrowPowerMenuex(client, entity)
{
	new Handle:menu = CreateMenu(MenuHandler_ChooseThrowPowerex, MenuAction:28);
	SetMenuExitButton(menu, true);
	SetMenuTitle(menu, "请选择投掷板的力度,编号:%d", entity);
	AddMenuItem(menu, "1.0", "小", 0);
	AddMenuItem(menu, "1.3", "较小", 0);
	AddMenuItem(menu, "2.0", "中", 0);
	AddMenuItem(menu, "2.5", "大", 0);
	AddMenuItem(menu, "3.0", "最大", 0);
	AddMenuItem(menu, "25.0", "最大x5", 0);
	AddMenuItem(menu, "50.0", "最大x10", 0);
	DisplayMenu(menu, client, 0);
	NowEntity = entity;
	return 0;
}

public MenuHandler_ChooseThrowPowerex(Handle:menu, MenuAction:action, client, item)
{
	switch (action)
	{
		case 4:
		{
			new var1;
			if (NowEntity <= 0 || !IsValidEdict(NowEntity))
			{
				return 0;
			}
			decl String:sType[64];
			new Float:power = 0.0;
			GetMenuItem(menu, item, sType, 64, 0, "", 0);
			power = StringToFloat(sType);
			if (power < 0.0)
			{
				return 0;
			}
			BecomeIntoThrowex(NowEntity, power);
		}
		case 8:
		{
		}
		default:
		{
		}
	}
	return 0;
}

BecomeIntoTeleportex(entity, Float:posex[3])
{
	new var1;
	if (entity <= 0 || !IsValidEdict(entity))
	{
		return 0;
	}
	SetEntityRenderColor(entity, 0, 0, 150, 255);
	nType[EntTypeCount] = 31;
	EntProp[EntTypeCount] = entity;
	EntTypeCount += 1;
	SDKUnhook(entity, SDKHookType:3, SDKCallBackTele_Touchedex);
	SDKHook(entity, SDKHookType:3, SDKCallBackTele_Touchedex);
	return 0;
}

TeleportPlayerex(entity, Float:posex[3])
{
	TeleportEntity(entity, posex, NULL_VECTOR, NULL_VECTOR);
	if (entity < MaxClients)
	{
		EmitSoundFromPlayer(entity, "level/startwam.wav");
	}
	return 0;
}

public SDKCallBackTele_Touchedex(entity, toucher)
{
	new id = FindIdEntPropByEntity(entity);
	if (id == -1)
	{
		return 0;
	}
	if (nType[id] != 31)
	{
		SDKUnhook(entity, SDKHookType:3, SDKCallBackTele_Touchedex);
		return 0;
	}
	TeleportPlayerex(toucher, Posex[id]);
	return 0;
}

ShowChooseTelePosMenuex(client, entity)
{
	new Handle:menu = CreateMenu(MenuHandler_ChooseTelePosex, MenuAction:28);
	SetMenuExitButton(menu, true);
	SetMenuTitle(menu, "请移动到要传送的地方,然后选择。编号:%d", entity);
	AddMenuItem(menu, "item1", "把当前位置当作传送点", 0);
	AddMenuItem(menu, "item2", "把鼠标位置当作传送点", 0);
	DisplayMenu(menu, client, 0);
	NowEntity = entity;
	return 0;
}

public MenuHandler_ChooseTelePosex(Handle:menu, MenuAction:action, client, item)
{
	switch (action)
	{
		case 4:
		{
			new var1;
			if (NowEntity <= 0 || !IsValidEdict(NowEntity))
			{
				return 0;
			}
			decl Float:posex[3];
			switch (item)
			{
				case 0:
				{
					GetClientAbsOrigin(client, posex);
				}
				case 1:
				{
					GetClientCurPos(client, posex);
				}
				default:
				{
				}
			}
			BecomeIntoTeleportex(NowEntity, posex);
		}
		case 8:
		{
		}
		default:
		{
		}
	}
	return 0;
}

BecomeIntoDieShot(entity)
{
	new var1;
	if (entity <= 0 || !IsValidEdict(entity))
	{
		return 0;
	}
	nType[EntTypeCount] = 32;
	EntProp[EntTypeCount] = entity;
	EntTypeCount += 1;
	SDKUnhook(entity, SDKHookType:3, SDKCallBackDieShot_Touched);
	SDKHook(entity, SDKHookType:3, SDKCallBackDieShot_Touched);
	return 0;
}

public SDKCallBackDieShot_Touched(entity, toucher)
{
	new id = FindIdEntPropByEntity(entity);
	if (id == -1)
	{
		return 0;
	}
	if (nType[id] != 32)
	{
		SDKUnhook(entity, SDKHookType:3, SDKCallBackDieShot_Touched);
		return 0;
	}
	KillPerson(toucher);
	return 0;
}

BecomeIntoTeleportnocolors(entity, Float:posnocolors[3])
{
	new var1;
	if (entity <= 0 || !IsValidEdict(entity))
	{
		return 0;
	}
	nType[EntTypeCount] = 33;
	EntProp[EntTypeCount] = entity;
	EntTypeCount += 1;
	SDKUnhook(entity, SDKHookType:3, SDKCallBackTelenocolors_Touched);
	SDKHook(entity, SDKHookType:3, SDKCallBackTelenocolors_Touched);
	return 0;
}

TeleportPlayernocolors(entity, Float:posnocolors[3])
{
	TeleportEntity(entity, posnocolors, NULL_VECTOR, NULL_VECTOR);
	if (entity < MaxClients)
	{
		EmitSoundFromPlayer(entity, "level/startwam.wav");
	}
	return 0;
}

public SDKCallBackTelenocolors_Touched(entity, toucher)
{
	new id = FindIdEntPropByEntity(entity);
	if (id == -1)
	{
		return 0;
	}
	if (nType[id] != 33)
	{
		SDKUnhook(entity, SDKHookType:3, SDKCallBackTelenocolors_Touched);
		return 0;
	}
	TeleportPlayernocolors(toucher, Posnocolors[id]);
	return 0;
}

