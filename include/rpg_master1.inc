
#define MaxPupil	5
#define STSKILLCOUNT	5

/* 拜师面板 */
public MenuFunc_Baishi(Client)
{
	if(!IsValidPlayer(Client)){
		return;
	}
	if(!IsPasswordConfirm[Client]){
		CPrintToChat(Client, "{olive}你还没有注册或登录,请先注册/登录游戏才能拜师收徒~~~");
		return;
	}
	ResetMaster(Client);
	ResetPupil(Client);
	decl String:line[128], String:name[64], i, has;
	//new Handle:menu = CreateMenu(MenuHandler_Baishi);
	if(IsMaster[Client]){
		//师父菜单
		new PupilNum=0;
		new Handle:menu = CreateMenu(MenuHandler_Baishi_master);
		SetMenuTitle(menu, "我的徒弟:");
		for(i = 0;i < MaxPupil;i++){
			if(!StrEqual(PupilArray[Client][i], "", true))
			{
				PupilNum++;
				Format(name, sizeof(name), PupilArray[Client][i]);
				new pupil = GetClientForName(name);
				if(IsValidPlayer(pupil))
				{
					if(IsClientInGame(pupil))
					{
						Format(line, sizeof(line), "%s(在线)", PupilArray[Client][i]);
					}
				}
				else
					Format(line, sizeof(line), "%s(离线)", PupilArray[Client][i]);
				AddMenuItem(menu, name, line);
				//AddMenuItem(menu, option, line, ITEMDRAW_DISABLED);

			}
		
		}
		if(!IsMasterFull(Client))
		{
			Format(line, sizeof(line), "招收徒弟(可招%d个)", (MaxPupil-PupilNum));
			AddMenuItem(menu, "->招收徒弟<-", line);
		}
		if(MasterReward[Client] > 0)
		{
			Format(line, sizeof(line), "师父礼包(%d个)", MasterReward[Client]);
			AddMenuItem(menu, "->师父礼包<-", line);
		}else{
			AddMenuItem(menu, "->师父礼包<-", "师父礼包(0个)", ITEMDRAW_DISABLED);
		}
		
		
		
		SetMenuExitBackButton(menu, true);
		DisplayMenu(menu, Client, MENU_TIME_FOREVER);
		
	}else if(IsPupil[Client]){
		//徒弟菜单
		new Handle:menu = CreateMenu(MenuHandler_Baishi_Pupil);
		SetMenuTitle(menu, "我的师父:");
		if(!StrEqual(PMaster[Client], "", true)){
			//strcopy(MasterSelectedName[Client], 64, PMaster[Client]);
			new master=GetClientForName(PMaster[Client]);
			if(IsValidPlayer(master))
			{
				if(IsClientInGame(master))
				{
					Format(line, sizeof(line), "%s(在线)", PMaster[Client]);
				}
			}else{
				Format(line, sizeof(line), "%s(离线)", PMaster[Client]);
			}
			AddMenuItem(menu, "item0", line);
		}else{
			IsPupil[Client] = false;
			AddMenuItem(menu, "item0", "你还没有师父", ITEMDRAW_DISABLED);
		}
		SetMenuExitBackButton(menu, true);
		DisplayMenu(menu, Client, MENU_TIME_FOREVER);
	}else{
		if(NewLifeCount[Client] > 0){
			//转生过的玩家可以收徒弟
			new Handle:menu = CreateMenu(MenuHandler_GetPupil);
			SetMenuTitle(menu, "招收徒弟:");
			has = 0;
			for (i = 1; i <= MaxClients; i++)
			{
				if (IsValidPlayer(i, false) && i != Client)
				{
					ResetMaster(i);
					ResetPupil(i);
					GetClientName(i, name, sizeof(name));
					if(NewLifeCount[i] == 0 && !IsPupil[i]){
						Format(line, sizeof(line), "%N (Lv.%d)", i, Lv[i]);
						AddMenuItem(menu, name, line);
						has++;
					}
					
				}
			}
			if (has <= 0){
				AddMenuItem(menu, "item0", "没有发现可以招收的徒弟!", ITEMDRAW_DISABLED)
			}
			SetMenuExitBackButton(menu, true);
			DisplayMenu(menu, Client, MENU_TIME_FOREVER);
		}else{
			//拜师傅
			new Handle:menu = CreateMenu(MenuHandler_GetMaster);
			SetMenuTitle(menu, "拜师:\n未转生的玩家可以在游戏中找已转生的玩家作自己的师父!\n转生后玩家自动出师并可以招收徒弟!\n师徒在线可获得额外的奖励!");
			has = 0;
			for (i = 1; i <= MaxClients; i++)
			{
				if (IsValidPlayer(i, false) && i != Client)
				{
					GetClientName(i, name, sizeof(name));
					if(NewLifeCount[i] > 0 && !IsMasterFull(i)){
						Format(line, sizeof(line), "%N (NL.%d,Lv.%d)", i, NewLifeCount[i], Lv[i]);
						AddMenuItem(menu, name, line);
						has++;
					}
					
				}
			}
			if (has <= 0){
				AddMenuItem(menu, "item0", "没有发现符合条件的师父!", ITEMDRAW_DISABLED)
			}			
			SetMenuExitBackButton(menu, true);
			DisplayMenu(menu, Client, MENU_TIME_FOREVER);
		}
	}
	
}
/*拜师-子面板*/
public MenuHandler_GetMaster(Handle:menu, MenuAction:action, Client, param)
{
	decl String:name[64], target;
	if (action == MenuAction_End)	
		CloseHandle(menu);
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_ExitBack)
			MenuFunc_RPG_Learn(Client);
	}
	if (action == MenuAction_Select) {
		
		GetMenuItem(menu, param, name, sizeof(name));
		target = GetClientForName(name);
		if(IsValidPlayer(target) && IsClientInGame(target) && !IsMasterFull(target)){
			MenuFunc_Master_Confirm(target, Client);
			CPrintToChat(Client, "你向%N发起了拜师的信息,等待对方的确认!", target);
		}else{
			CPrintToChat(Client, "拜师失败,可能对方已经招够了徒弟!");
		}
	}
}
/*拜师-师父确认信息*/
public MenuFunc_Master_Confirm(Client, target)
{
	if(!IsPupil[Client] && IsValidPlayer(Client) && NewLifeCount[Client] > 0 && IsValidPlayer(target) && NewLifeCount[target] <= 0 && !IsMasterFull(Client) && !IsPupil[target])
	{
		new Handle:menu = CreateMenu(MenuHandler_Master_Confirm);
		BPupil[Client] = target;
		SetMenuTitle(menu, "玩家想拜你为师,你是否愿意? \n玩家: %N \n等级: %d", target, Lv[target]);
		AddMenuItem(menu, "item0", "好吧，晚上寂寞时找徒弟爆菊");
		AddMenuItem(menu, "item1", "不行！我不是这样的淫！");
		SetMenuExitBackButton(menu, true);
		DisplayMenu(menu, Client, MENU_TIME_FOREVER);		
	}
}
/*拜师-师父确认信息2*/
public MenuHandler_Master_Confirm(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_End)	
		CloseHandle(menu);
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_ExitBack)
			MenuFunc_RPG_Learn(Client);
	}
	if (action == MenuAction_Select) {
		new target = BPupil[Client];
		switch(param)
		{
			case 0:
			{
				
				if(!IsPupil[Client] && IsValidPlayer(Client) && NewLifeCount[Client] > 0 && IsValidPlayer(target) && NewLifeCount[target] <= 0 && !IsMasterFull(Client) && !IsPupil[target])
				{
					GetClientName(Client, PMaster[target], 64);	//PMaster[target]=师父名字
					SetMasterPupil(Client, target);	
				}
				
			}
			case 1: CloseHandle(menu);
		}
	}
}
/*招收徒弟-子面板*/
public MenuHandler_GetPupil(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_End)	
		CloseHandle(menu);
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_ExitBack)
			MenuFunc_RPG_Learn(Client);
	}
	if (action == MenuAction_Select) {
		decl String:name[64], target;
		GetMenuItem(menu, param, name, sizeof(name));
		target = GetClientForName(name);
		if(IsValidPlayer(target) && !IsPupil[target]){
			MenuFunc_Pupil_Confirm(target, Client);
			CPrintToChat(Client, "你向[%N]发起了招收徒弟的信息,等待对方的确认!", target);
		}else{
			CPrintToChat(Client, "招收徒弟失效,可能对方已经拜过师了!");
		}
	}
}
/*招收徒弟-徒弟确认信息*/
public MenuFunc_Pupil_Confirm(Client, target)
{
	if(!IsPupil[Client] && IsValidPlayer(Client) && !IsMaster[Client] && NewLifeCount[Client] <= 0 && IsValidPlayer(target) && NewLifeCount[target] > 0 && !IsMasterFull(target))
	{
		new Handle:menu = CreateMenu(MenuHandler_Pupil_Confirm);
		BMaster[Client] = target;
		SetMenuTitle(menu, "玩家想收你为徒,你是否愿意? \n玩家: %N \n转生次数:%d \n等级: %d", target, NewLifeCount[target], Lv[target]);
		AddMenuItem(menu, "item0", "我愿意拜他为师");
		AddMenuItem(menu, "item1", "我考虑考虑");
		SetMenuExitBackButton(menu, true);
		DisplayMenu(menu, Client, MENU_TIME_FOREVER);		
	}
}
/*招收徒弟-徒弟确认信息2*/
public MenuHandler_Pupil_Confirm(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_End)	
		CloseHandle(menu);
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_ExitBack)
			MenuFunc_RPG_Learn(Client);
	}
	if (action == MenuAction_Select) {
		new target = BMaster[Client];
		switch(param)
		{
			case 0:
			{
				if(!IsPupil[Client] && IsValidPlayer(Client) && !IsMaster[Client] && NewLifeCount[Client] <= 0 && IsValidPlayer(target) && NewLifeCount[target] > 0 && !IsMasterFull(target))
				{
					GetClientName(target, PMaster[Client], 64);		//徒弟的师父
					SetMasterPupil(target, Client);
				}
			}
			case 1: CloseHandle(menu);
		}
	}
}
/* 师父收徒 */
//SetMasterPupil(师父,徒弟)
public SetMasterPupil(target, Client)
{
	if(!IsValidPlayer(target) || !IsValidPlayer(Client)){
		return;
	}
	if(NewLifeCount[target] <= 0){
		return;
	}
	if(IsMasterFull(target)){
		return;
	}
	if(IsPupil[Client]){
		return;
	}
	new String:pupilname[64];	//徒弟的名字
	GetClientName(Client, pupilname, sizeof(pupilname));
	for(new i = 0;i < MaxPupil; i++)
	{
		if(StrEqual(PupilArray[target][i], "", true))
		{
			if(i == 0){
				GetClientName(Client, Pupil_1[target], 64);
			}else if(i == 1){
				GetClientName(Client, Pupil_2[target], 64);
			}else if(i == 2){
				GetClientName(Client, Pupil_3[target], 64);
			}else if(i == 3){
				GetClientName(Client, Pupil_4[target], 64);
			}else if(i == 4){
				GetClientName(Client, Pupil_5[target], 64);
			}
			break;
		}
	}
	//徒弟是否是师父的徒弟
	if(IsMasterPupil(target, pupilname)){
		//PrintHintTextToAll("======【祝贺】======= \n %N 成功拜 %N 为师!", Client, target);
		PrintHintTextToAll(" \n %N 成为了 %N 的师父[爷俩晚上不再寂寞了！] \n ", target, Client);
		ResetMaster(target);
		ResetPupil(Client);
	}
}
/* 判断徒弟师父满员 */
public bool:IsMasterFull(Client)
{
	if(!IsValidPlayer(Client)){
		return true;
	}
	if(NewLifeCount[Client] <= 0){
		return true;
	}
	new has = 0;
	for(new i = 0; i < MaxPupil; i++)
	{
		if(!StrEqual(PupilArray[Client][i], "", true))
		{
			has++;
		}
	
	}
	if(has < MaxPupil){
		return false;
	}else{
		return true;
	}
}

/* 徒弟子面板 */
public MenuHandler_Baishi_Pupil(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_End)	
		CloseHandle(menu);
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_ExitBack)
			MenuFunc_Baishi(Client);
	}
	if (action == MenuAction_Select) {
		if(IsPupil[Client]){
			switch(param)
			{
				case 0: MenuFunc_Baishi_pupil_master(Client);
			}
		}
	}
}


/* 徒弟子面板-师父操作 */
public MenuFunc_Baishi_pupil_master(Client)
{
	if(IsPupil[Client])
	{
		new master, String:masterjob[256];
		master = GetClientForName(PMaster[Client]);
		new String:option[32];//, String:line[128];
		new Handle:menu = CreateMenu(MenuHandler_Baishi_pupil_master);
		if(IsValidPlayer(master) && IsClientInGame(master))
		{
			if(JD[master] == 0)
			{
				Format(masterjob, sizeof(masterjob), "未转职");
			}else if(JD[master] == 1){
				Format(masterjob, sizeof(masterjob), "工程师");
			}else if(JD[master] == 2){
				Format(masterjob, sizeof(masterjob), "士兵");
			}else if(JD[master] == 3){
				Format(masterjob, sizeof(masterjob), "生物");
			}else if(JD[master] == 4){
				Format(masterjob, sizeof(masterjob), "医生");
			}else if(JD[master] == 5){
				Format(masterjob, sizeof(masterjob), "魔法师");
			}else if(JD[master] == 6){
				Format(masterjob, sizeof(masterjob), "弹药师");
			}
			SetMenuTitle(menu, "师父[%N] \n转生:%d次 \n等级:Lv.%d \n职业:%s", master, NewLifeCount[master], Lv[master], masterjob);
		}else{
			SetMenuTitle(menu, "师父[%s]: \n状态:离线", PMaster[Client]);
		}
		if(IsValidPlayer(master) && IsPlayerAlive(master) && IsClientInGame(master) && IsPlayerAlive(Client))
		{
			AddMenuItem(menu, "item0", "传送到师父位置");
		}else{
			AddMenuItem(menu, "item0", "传送到师父位置", ITEMDRAW_DISABLED);
		}
		Format(option, sizeof(option), "item%d", STSKILLCOUNT+1);
		AddMenuItem(menu, option, "取消师徒关系");
		
		SetMenuExitBackButton(menu, true);
		DisplayMenu(menu, Client, MENU_TIME_FOREVER);
	}
}
/* 徒弟子面板-师父操作2 */
public MenuHandler_Baishi_pupil_master(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_End)	
		CloseHandle(menu);
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_ExitBack)
			MenuFunc_RPG_Learn(Client);
	}
	if (action == MenuAction_Select) {
		new master = GetClientForName(PMaster[Client]);
		switch(param){
			case 0:
			{
				//传送到师父跟前
				if(IsPupil[Client])
				{
					if(IsValidPlayer(master) && IsClientInGame(master) && IsPlayerAlive(master))
					{
						League_Teleport(Client, master, 0);
					}
				}
			}
			case 1:
			{
				if(IsPupil[Client]){
					//取消师徒关系确认
					MenuFunc_Baishi_Release_Master(Client);
				}
			}
		}
	}
}
/*徒弟子面板-取消师徒关系确认*/
public MenuFunc_Baishi_Release_Master(Client)
{
	if(IsPupil[Client])
	{
		new Handle:menu = CreateMenu(MenuHandler_Release_Master);
		SetMenuTitle(menu, "决定不再作[%s]的徒弟了吗?\n费用:500000$", PMaster[Client]);
		AddMenuItem(menu, "item0", "我决定了");
		AddMenuItem(menu, "item1", "我点错了");
		SetMenuExitBackButton(menu, true);
		DisplayMenu(menu, Client, MENU_TIME_FOREVER);
	}
}
/*徒弟子面板-取消师徒关系确认2*/
public MenuHandler_Release_Master(Handle:menu, MenuAction:action, Client, param)
{
	decl String:MyMaster[64], String:MyName[64];
	if (action == MenuAction_End)	
		CloseHandle(menu);
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_ExitBack)
			MenuFunc_RPG_Learn(Client);
	}
	if (action == MenuAction_Select) {
		switch(param){
			case 0:
			{
				//离开师父
				if(IsPupil[Client] && Cash[Client] >= 500000){
					strcopy(MyMaster, 64, PMaster[Client]);
					strcopy(PMaster[Client], 64, "");
					IsPupil[Client] = false;
					//师父是否在线
					new target = GetClientForName(MyMaster);
					GetClientName(Client, MyName, sizeof(MyName));
					if(IsValidPlayer(target) && IsClientInGame(target) && IsMaster[target])
					{
						if(IsMasterPupil(target, MyName))
						{
							for(new i = 0; i < MaxPupil; i++){
								if(StrEqual(PupilArray[target][i], MyName, true)){
									strcopy(PupilArray[target][i], sizeof(MyName), "");
									if(i == 0){
										strcopy(Pupil_1[target], 64, "");
									}else if(i == 1){
										strcopy(Pupil_2[target], 64, "");
									}else if(i == 2){
										strcopy(Pupil_3[target], 64, "");
									}else if(i == 3){
										strcopy(Pupil_4[target], 64, "");
									}else if(i == 4){
										strcopy(Pupil_5[target], 64, "");
									}
									break;
								}
							}
							ResetMaster(target);
						}
					}
					Cash[Client] -= 500000;
					PrintHintTextToAll(" \n 徒弟 %N 背弃了师父 %s，背弃师门十分可耻！[可能师父爆菊太大力了] \n ", Client, MyMaster);
					//PrintHintText(Client,"你解除了与%s的师徒关系!", MyMaster);
				}else{
					CPrintToChat(Client, "【师徒】解除师徒关系失败!");
				}
			}
			case 1: CloseHandle(menu);
		}
	}

}

/* 师父子面板 */
public MenuHandler_Baishi_master(Handle:menu, MenuAction:action, Client, param)
{
	
	if (action == MenuAction_End)	
		CloseHandle(menu);
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_ExitBack)
			MenuFunc_RPG_Learn(Client);
	}
	if (action == MenuAction_Select) {
		//通过菜单获取玩家名字
		decl String:name[64];
		GetMenuItem(menu, param, name, sizeof(name));
		if(StrEqual(name, "->招收徒弟<-", true))
		{
			MenuFunc_GetPupil(Client);
		}else if(StrEqual(name, "->师父礼包<-", true)){
			MenuFunc_MasterLibao(Client);
		}else{
			MenuFunc_Baishi_master_pupil(Client, name);
		}
	}
}


/* 师父礼包 */
public MenuFunc_MasterLibao(Client)
{
	if(!IsValidPlayer(Client)) return;
	if(!IsMaster[Client]) return;
	if(MasterReward[Client] <= 0) return;
	//decl String:line[128];
	new Handle:menu = CreateMenu(MenuHandler_MasterLibao);
	SetMenuTitle(menu, "师父礼包:%d个\n师父礼包是师父带徒弟升级而获得的礼包\n获得条件:徒弟每升10级且师徒同时在线奖励1个师徒礼包", MasterReward[Client]);
	
	AddMenuItem(menu, "item0", "开启师父礼包");
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, Client, MENU_TIME_FOREVER);
}
/* 师父礼包2 */
public MenuHandler_MasterLibao(Handle:menu, MenuAction:action, Client, param)
{
	
	if (action == MenuAction_End)	
		CloseHandle(menu);
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_ExitBack)
			MenuFunc_RPG_Learn(Client);
	}
	if (action == MenuAction_Select) {
		switch(param)
		{
			case 0:
			{
				if(IsValidPlayer(Client) && IsClientInGame(Client))
				{
					if(MasterReward[Client] > 0)
					{
						new Float:Mrandom = GetRandomFloat(0.0, 100.0);

						if(Mrandom < 1.0)
						{
							new Crandom = GetRandomInt(1, 8);
							if(PlayerZBItemSize[Client] - GetHasZBItemCount(Client) > 0)
							{
								MasterReward[Client]--;
								switch(Crandom)
								{
									case 1:
									{
										SetZBItemTime(Client, ITZB_TYZSEM, 3, true, true);
										CPrintToChatAll("\x05【师徒奖励】玩家 %N 成功开启了师父礼包,奖励【三相之力】3日!", Client);
									}
									case 2:
									{
										SetZBItemTime(Client, ITZB_ZRZYJZ, 3, true, true);
										CPrintToChatAll("\x05【师徒奖励】玩家 %N 成功开启了师父礼包,奖励【自然之力】3日!", Client);
									}
									case 3:
									{
										SetZBItemTime(Client, ITZB_JRSMZD, 3, true, true);
										CPrintToChatAll("\x05【师徒奖励】玩家 %N 成功开启了师父礼包,奖励【巨人腰带】3日!", Client);
									}
									case 4:
									{
										SetZBItemTime(Client, ITZB_YXGLDY, 3, true, true);
										CPrintToChatAll("\x05【师徒奖励】玩家 %N 成功开启了师父礼包,奖励【饮血剑】3日!", Client);
									}
									case 5:
									{
										SetZBItemTime(Client, ITZB_JPMLJL, 3, true, true);
										CPrintToChatAll("\x05【师徒奖励】玩家 %N 成功开启了师父礼包,奖励【仲亚之戒】3日!", Client);
									}
									case 6:
									{
										SetZBItemTime(Client, ITZB_SQ_AH, 3, true, true);
										CPrintToChatAll("\x05【师徒奖励】玩家 %N 成功开启了师父礼包,奖励【冥火之拥】3日!", Client);
									}
									case 7:
									{
										SetZBItemTime(Client, ITZB_TYZSTZ, 3, true, true);
										CPrintToChatAll("\x05【师徒奖励】玩家 %N 成功开启了师父礼包,奖励【霸王血铠】3日!", Client);
									}
									case 8:
									{
										SetZBItemTime(Client, ITZB_TYZSQT, 3, true, true);
										CPrintToChatAll("\x05【师徒奖励】玩家 %N 成功开启了师父礼包,奖励【兰顿之兆】3日!", Client);
									}
								}
							}else{
								CPrintToChat(Client, "【师徒奖励】师父礼包开启失败,你的装备物品栏已满!");
							}
						}
						else if(Mrandom < 5.0)
						{
							new Hrandom = GetRandomInt(1, 9);
							if(PlayerZBItemSize[Client] - GetHasZBItemCount(Client) > 0)
							{
								MasterReward[Client]--;
								switch(Hrandom)
								{
									case 1:
									{
										SetZBItemTime(Client, ITZB_DJZYJZ, 3, true, true);
										CPrintToChatAll("\x05【师徒奖励】玩家 %N 成功开启了师父礼包,奖励【活力宝珠】3日!", Client);
									}
									case 2:
									{
										SetZBItemTime(Client, ITZB_DJSMZD, 3, true, true);
										CPrintToChatAll("\x05【师徒奖励】玩家 %N 成功开启了师父礼包,奖励【多兰之盾】3日!", Client);
									}
									case 3:
									{
										SetZBItemTime(Client, ITZB_DJGLDY, 3, true, true);
										CPrintToChatAll("\x05【师徒奖励】玩家 %N 成功开启了师父礼包,奖励【长剑】3日!", Client);
									}
									case 4:
									{
										SetZBItemTime(Client, ITZB_DJMLJL, 3, true, true);
										CPrintToChatAll("\x05【师徒奖励】玩家 %N 成功开启了师父礼包,奖励【贤者之戒】3日!", Client);
									}
									case 5:
									{
										SetZBItemTime(Client, ITZB_TYZSQT, 3, true, true);
										CPrintToChatAll("\x05【师徒奖励】玩家 %N 成功开启了师父礼包,奖励【兰顿之兆】3日!", Client);
									}
									case 6:
									{
										SetZBItemTime(Client, ITZB_TYZSWTZ, 3, true, true);
										CPrintToChatAll("\x05【师徒奖励】玩家 %N 成功开启了师父礼包,奖励【狂徒铠甲】3日!", Client);
									}
									case 7:
									{
										SetZBItemTime(Client, ITZB_TYZSEM, 3, true, true);
										CPrintToChatAll("\x05【师徒奖励】玩家 %N 成功开启了师父礼包,奖励【三相之力】3日!", Client);
									}
									case 8:
									{
										SetZBItemTime(Client, ITZB_KXTZ, 3, true, true);
										CPrintToChatAll("\x05【师徒奖励】玩家 %N 成功开启了师父礼包,奖励【春哥套装】3日!", Client);
									}
								}
							}
							else
							{
								CPrintToChat(Client, "【师徒奖励】师父礼包开启失败,你的装备物品栏已满!");
							}
						}
						else if(Mrandom < 30)
						{
							new Jrandom = GetRandomInt(1, 9);
							if(PlayerZBItemSize[Client] - GetHasZBItemCount(Client) > 0)
							{
								MasterReward[Client]--;
								switch(Jrandom)
								{
									case 1:
									{
										SetZBItemTime(Client, ITZB_GJZYJZ, 3, true, true);
										CPrintToChatAll("\x05【师徒奖励】玩家 %N 成功开启了师父礼包,奖励【再生坠饰】3日!", Client);
									}
									case 2:
									{
										SetZBItemTime(Client, ITZB_GJSMZD, 3, true, true);
										CPrintToChatAll("\x05【师徒奖励】玩家 %N 成功开启了师父礼包,奖励【红宝石水晶】3日!", Client);
									}
									case 3:
									{
										SetZBItemTime(Client, ITZB_GJGLDY, 3, true, true);
										CPrintToChatAll("\x05【师徒奖励】玩家 %N 成功开启了师父礼包,奖励【麦瑞得的拳刃】3日!", Client);
									}
									case 4:
									{
										SetZBItemTime(Client, ITZB_ZJMLJL, 3, true, true);
										CPrintToChatAll("\x05【师徒奖励】玩家 %N 成功开启了师父礼包,奖励【女神之泪】3日!", Client);
									}
									case 5:
									{
										PlayerItem[Client][ITEM_XH][0] += 10;
										CPrintToChatAll("\x05【师徒奖励】玩家 %N 成功开启了师父礼包,奖励【全体传召令】10个!", Client);
									}
									case 6:
									{
										PlayerItem[Client][ITEM_XH][1] += 10;
										CPrintToChatAll("\x05【师徒奖励】玩家 %N 成功开启了师父礼包,奖励【全体狂暴卷】10个!", Client);
									}
									case 7:
									{
										PlayerItem[Client][ITEM_XH][2] += 10;
										CPrintToChatAll("\x05【师徒奖励】玩家 %N 成功开启了师父礼包,奖励【全体嗜血卷】10个!", Client);
									}
									case 8:
									{
										PlayerItem[Client][ITEM_XH][3] += 10;
										CPrintToChatAll("\x05【师徒奖励】玩家 %N 成功开启了师父礼包,奖励【全体换弹卷】10个!", Client);
									}
									case 9:
									{
										PlayerItem[Client][ITEM_XH][4] += 10;
										CPrintToChatAll("\x05【师徒奖励】玩家 %N 成功开启了师父礼包,奖励【生命恢复卷】10个!", Client);
									}
								}
							}
							else
							{
								CPrintToChat(Client, "【师徒奖励】师父礼包开启失败,你的装备物品栏已满!");
							}
						}else{
							MasterReward[Client]--;
							new Qrandom = GetRandomInt(1, 10);
							Qcash[Client] += Qrandom;
							CPrintToChatAll("\x05【师徒奖励】玩家 %N 成功开启了师父礼包,奖励 %d 点卷!", Client, Qrandom);
						}
					}
				}
			}
		}
	}
}
/* 师父招收徒弟菜单 */
public MenuFunc_GetPupil(Client)
{
	if(!IsMaster[Client]) return;
	if(IsMasterFull(Client)) return;
	decl String:line[128], String:name[64], i, has;
	new Handle:menu = CreateMenu(MenuHandler_GetPupil);
	SetMenuTitle(menu, "招收徒弟:");
	
	for (i = 1; i <= MaxClients; i++)
	{
		if (IsValidPlayer(i, false) && i != Client)
		{
			if(!IsPasswordConfirm[i])
				continue;
			ResetMaster(i);
			ResetPupil(i);
			GetClientName(i, name, sizeof(name));
			if(NewLifeCount[i] == 0 && !IsPupil[i]){
				Format(line, sizeof(line), "%N (Lv.%d)", i, Lv[i]);
				AddMenuItem(menu, name, line);
				has++;
			}
			
		}
	}
	if (has <= 0){
		AddMenuItem(menu, "item0", "没有发现可以招收的徒弟!", ITEMDRAW_DISABLED)
	}
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, Client, MENU_TIME_FOREVER);
}
/*师父子面板-徒弟操作*/
public MenuFunc_Baishi_master_pupil(Client, String:pupilname[64])
{
	new pupil, String:pupiljob[128];
	pupil = GetClientForName(pupilname);
	new Handle:menu = CreateMenu(MenuHandler_Baishi_master_pupil);
	if(IsValidPlayer(pupil))
	{
		if(IsClientInGame(pupil) && GetClientTeam(pupil) != 3)
		{
			if(JD[pupil] == 0)
			{
				Format(pupiljob, sizeof(pupiljob), "未转职");
			}else if(JD[pupil] == 1){
				Format(pupiljob, sizeof(pupiljob), "工程师");
			}else if(JD[pupil] == 2){
				Format(pupiljob, sizeof(pupiljob), "士兵");
			}else if(JD[pupil] == 3){
				Format(pupiljob, sizeof(pupiljob), "生物");
			}else if(JD[pupil] == 4){
				Format(pupiljob, sizeof(pupiljob), "医生");
			}else if(JD[pupil] == 5){
				Format(pupiljob, sizeof(pupiljob), "魔法师");
			}else if(JD[pupil] == 6){
				Format(pupiljob, sizeof(pupiljob), "弹药师");
			}
			SetMenuTitle(menu, "徒弟[%N] \n等级:Lv.%d \n职业:%s", pupil, Lv[pupil], pupiljob);
		}else{
			SetMenuTitle(menu, "徒弟[%s]: \n状态:不在线", pupilname);
		}
	}else{
		SetMenuTitle(menu, "徒弟[%s]: \n状态:不在线", pupilname);
	}
	strcopy(PupilSelectedName[Client], sizeof(pupilname), pupilname);
	if(IsValidPlayer(pupil))
	{
		if(IsClientInGame(pupil) && IsPlayerAlive(pupil) && IsPlayerAlive(Client))
		{
			AddMenuItem(menu, "item0", "传送自己到徒弟身边");
			AddMenuItem(menu, "item1", "召唤徒弟到自己身边");
		}else{
			AddMenuItem(menu, "item0", "传送自己到徒弟身边", ITEMDRAW_DISABLED);
			AddMenuItem(menu, "item1", "召唤徒弟到自己身边", ITEMDRAW_DISABLED);
		}
	}else{
		AddMenuItem(menu, "item0", "传送自己到徒弟身边", ITEMDRAW_DISABLED);
		AddMenuItem(menu, "item1", "召唤徒弟到自己身边", ITEMDRAW_DISABLED);
	}
	
	AddMenuItem(menu, "item2", "取消师徒关系");
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, Client, MENU_TIME_FOREVER);
}
/*师父子面板-徒弟操作2*/
public MenuHandler_Baishi_master_pupil(Handle:menu, MenuAction:action, Client, param)
{
	if(!IsValidPlayer(Client)) return;
	new pupil = GetClientForName(PupilSelectedName[Client]);
	//if(!IsValidPlayer(pupil)) return;
	if (action == MenuAction_End)	
		CloseHandle(menu);
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_ExitBack)
			MenuFunc_Baishi(Client);
	}
	if (action == MenuAction_Select) {
		switch(param){
			case 0:
			{
				//传送到徒弟跟前
				if(IsMaster[Client] && IsPlayerAlive(Client))
				{
					if(IsValidPlayer(pupil) && IsClientInGame(pupil) && IsPlayerAlive(pupil))
					{
						League_Teleport(Client, pupil, 0);
					}
				}
			}
			case 1:
			{
				//传送徒弟到自己的身边
				if(IsMaster[Client] && IsPlayerAlive(Client))
				{
					if(IsValidPlayer(pupil) && IsClientInGame(pupil) && IsPlayerAlive(pupil))
					{
						League_Teleport(Client, pupil, 1);
					}
				}
			}
			case 2:
			{
				if(!StrEqual(PupilSelectedName[Client], "", true)){
					//取消师徒关系确认
					MenuFunc_Baishi_Release_Pupil(Client, PupilSelectedName[Client]);
				}
			}
		}
	}
}
/*师父子面板-取消师徒关系确认*/
public MenuFunc_Baishi_Release_Pupil(Client, String:pupilname[64])
{
	new Handle:menu = CreateMenu(MenuHandler_Release_Pupil);
	SetMenuTitle(menu, "确定要将徒弟[%s]赶出师门吗? \n如果他洗心革面后,还可以收他为徒!\n费用:500000$!", pupilname);
	AddMenuItem(menu, "item0", "另寻他欢[确定]");
	AddMenuItem(menu, "item1", "舍不得[否定]");
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, Client, MENU_TIME_FOREVER);
}
/*师父子面板-取消师徒关系确认2*/
public MenuHandler_Release_Pupil(Handle:menu, MenuAction:action, Client, param)
{
	//new i;
	if (action == MenuAction_End)	
		CloseHandle(menu);
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_ExitBack)
			MenuFunc_RPG_Learn(Client);
	}
	if (action == MenuAction_Select) {
		switch(param){
			case 0:
			{
				//赶出师门
				//判断是否是师父的徒弟
				if(IsMasterPupil(Client, PupilSelectedName[Client]) && Cash[Client] >= 500000){
					for(new i = 0; i < MaxPupil; i++){
						if(StrEqual(PupilArray[Client][i], PupilSelectedName[Client], true)){
							strcopy(PupilArray[Client][i], 64, "");
							if(i == 0){
								strcopy(Pupil_1[Client], 64, "");
								//GetClientName(Client, Pupil_1[i], 64);
							}else if(i == 1){
								strcopy(Pupil_2[Client], 64, "");
								//GetClientName(Client, Pupil_2[i], 64);
							}else if(i == 2){
								strcopy(Pupil_3[Client], 64, "");
								//GetClientName(Client, Pupil_3[i], 64);
							}else if(i == 3){
								strcopy(Pupil_4[Client], 64, "");
								//GetClientName(Client, Pupil_4[i], 64);
							}else if(i == 4){
								strcopy(Pupil_5[Client], 64, "");
								//GetClientName(Client, Pupil_5[i], 64);
							}
							new target = GetClientForName(PupilSelectedName[Client]);
							if(IsValidPlayer(target) && IsClientInGame(target)){
								strcopy(PMaster[target], 64, "");
								IsPupil[target] = false;
							}
							ResetMaster(Client);
							Cash[Client] -= 500000;
							PrintHintTextToAll(" \n 师父 %N 将徒弟 %s 逐出了师门! \n ", Client, PupilSelectedName[Client]);
							//PrintHintText(Client,"你解除了与 %s 的师徒关系!", PupilSelectedName[Client]);
							break;
						}
					}
					
					//CPrintToChatAll("master:debug");
				}else{
					CPrintToChat(Client, "【师徒】解除师徒关系失败!");
				}
			}
			case 1: CloseHandle(menu);
		}
	}

}
/*通过徒弟的名字判断徒弟是否是师父的徒弟*/
public bool:IsMasterPupil(Client, String:pupilname[64])
{	
	/*
	for(new i = 0; i < 2; i++){
		if(StrEqual(PupilArray[Client][i], pupilname, true)){
			return true;
		}
	}
	*/
	if(StrEqual(Pupil_1[Client], pupilname, true) || StrEqual(Pupil_2[Client], pupilname, true) || StrEqual(Pupil_3[Client], pupilname, true) || StrEqual(Pupil_4[Client], pupilname, true) || StrEqual(Pupil_5[Client], pupilname, true)){
		return true;
	}
	return false;
}
//更新师父状态
public ResetMaster(Client){
	if(IsValidPlayer(Client) && IsClientInGame(Client) && NewLifeCount[Client] > 0){
		strcopy(PupilArray[Client][0], 64, Pupil_1[Client]);
		strcopy(PupilArray[Client][1], 64, Pupil_2[Client]);
		strcopy(PupilArray[Client][2], 64, Pupil_3[Client]);
		strcopy(PupilArray[Client][3], 64, Pupil_4[Client]);
		strcopy(PupilArray[Client][4], 64, Pupil_5[Client]);
		//判断徒弟是否背叛了师父
		//判断徒弟是否在线
		//String:pupil1[64], String:pupil2[64];
		new String:master[64], pupil;
		GetClientName(Client, master, sizeof(master));
		for(new i = 0;i < MaxPupil;i++)
		{
			pupil = GetClientForName(PupilArray[Client][i]);
			if(IsValidPlayer(pupil) && IsClientInGame(pupil))
			{
				//if(StrEqual(PMaster[pupil], master, true){
				//	continue;
				//}
				if(!StrEqual(PMaster[pupil], master, true)){
					//徒弟的师父不是本人
					//更新徒弟
					if(i == 0)
					{
						strcopy(Pupil_1[Client], 64, "");
					}else if(i == 1){
						strcopy(Pupil_2[Client], 64, "");
					}else if(i == 2){
						strcopy(Pupil_3[Client], 64, "");
					}else if(i == 3){
						strcopy(Pupil_4[Client], 64, "");
					}else if(i == 4){
						strcopy(Pupil_5[Client], 64, "");
					}
				}
			}
		
		}
		strcopy(PupilArray[Client][0], 64, Pupil_1[Client]);
		strcopy(PupilArray[Client][1], 64, Pupil_2[Client]);
		strcopy(PupilArray[Client][2], 64, Pupil_3[Client]);
		strcopy(PupilArray[Client][3], 64, Pupil_4[Client]);
		strcopy(PupilArray[Client][4], 64, Pupil_5[Client]);
		if(StrEqual(Pupil_1[Client], "", true) && StrEqual(Pupil_2[Client], "",true) && StrEqual(Pupil_3[Client], "", true) && StrEqual(Pupil_4[Client], "", true) && StrEqual(Pupil_5[Client], "", true))
		{
			IsMaster[Client] = false;
			
		}else if(!StrEqual(Pupil_1[Client], "", true) || !StrEqual(Pupil_2[Client], "",true) || !StrEqual(Pupil_3[Client], "", true) || !StrEqual(Pupil_4[Client], "", true) || !StrEqual(Pupil_5[Client], "", true))
		{
			IsMaster[Client] = true;
		}
		IsPupil[Client] = false;
		strcopy(PMaster[Client], 64, "");
		//更新师父同名的徒弟bug
		if(IsMaster[Client])
		{
			if(StrEqual(Pupil_1[Client], Pupil_2[Client], true))
			{
				strcopy(Pupil_2[Client], 64, "");
			}
			if(StrEqual(Pupil_1[Client], Pupil_3[Client], true))
			{
				strcopy(Pupil_3[Client], 64, "");
			}
			if(StrEqual(Pupil_1[Client], Pupil_4[Client], true))
			{
				strcopy(Pupil_4[Client], 64, "");
			}
			if(StrEqual(Pupil_1[Client], Pupil_5[Client], true))
			{
				strcopy(Pupil_5[Client], 64, "");
			}
			if(StrEqual(Pupil_2[Client], Pupil_3[Client], true))
			{
				strcopy(Pupil_3[Client], 64, "");
			}
			if(StrEqual(Pupil_2[Client], Pupil_4[Client], true))
			{
				strcopy(Pupil_4[Client], 64, "");
			}
			if(StrEqual(Pupil_2[Client], Pupil_5[Client], true))
			{
				strcopy(Pupil_5[Client], 64, "");
			}
			if(StrEqual(Pupil_3[Client], Pupil_4[Client], true))
			{
				strcopy(Pupil_4[Client], 64, "");
			}
			if(StrEqual(Pupil_3[Client], Pupil_5[Client], true))
			{
				strcopy(Pupil_5[Client], 64, "");
			}
			if(StrEqual(Pupil_4[Client], Pupil_5[Client], true))
			{
				strcopy(Pupil_5[Client], 64, "");
			}
			strcopy(PupilArray[Client][0], 64, Pupil_1[Client]);
			strcopy(PupilArray[Client][1], 64, Pupil_2[Client]);
			strcopy(PupilArray[Client][2], 64, Pupil_3[Client]);
			strcopy(PupilArray[Client][3], 64, Pupil_4[Client]);
			strcopy(PupilArray[Client][4], 64, Pupil_5[Client]);
		}
	}
}
//更新徒弟状态
public ResetPupil(Client)
{
	if(IsValidPlayer(Client) && IsClientInGame(Client) && NewLifeCount[Client] <= 0){
		for(new i = 0;i < MaxPupil;i++)
		{
			strcopy(PupilArray[Client][i], 64, "");
		}
		if(StrEqual(PMaster[Client], "", true))
		{
			IsPupil[Client] = false;
		}else{
			//判断师父是否在线
			new master = GetClientForName(PMaster[Client]);
			new String:name[64];
			GetClientName(Client, name, sizeof(name));
			if(IsValidPlayer(master) && IsClientInGame(master)){
				//CPrintToChat(Client, "我的师父 %N 在线!", master);
				//如果师父在线 判断是否徒弟是否是师父的徒弟
				if(IsMasterPupil(master, name))
				{
					IsPupil[Client] = true;
				}else{
					strcopy(PMaster[Client], 64, "");
					IsPupil[Client] = false;
				}
			}else{
				IsPupil[Client] = true;
			}
		}
	}
}

//转生后自动出师
public NewLifePupil(Client)
{
	if(IsValidPlayer(Client) && IsClientInGame(Client)){
		if(NewLifeCount[Client] == 1 && IsPupil[Client])
		{
			
			//判断师父是否在线
			new master = GetClientForName(PMaster[Client]);
			strcopy(PMaster[Client], 64,"");
			IsPupil[Client] = false;
			if(IsValidPlayer(master) && IsClientInGame(master))
			{
				ResetMaster(master);
				//师徒奖励
				EXP[Client] += 10000;
				EXP[master] += 50000;
				Qcash[Client] += 300;
				Qcash[master] += 500;
				/*
				if(PlayerZBItemSize[Client] - GetHasZBItemCount(Client) > 0){
					SetZBItemTime(Client, ITZB_STR_TSZL, 3, true);
				}
				
				if(PlayerZBItemSize[master] - GetHasZBItemCount(master) > 0){
					SetZBItemTime(master, ITZB_SQ_AH, 3, true);
				}
				*/
				MasterReward[master]+=5;
				CPrintToChat(Client, "恭喜你成功出师,奖励10000EXP,300点卷,送[暗黑]3天");
				CPrintToChat(master, "恭喜你的徒弟[%N]成功出师,作为师父奖励你50000EXP,500点卷,师父礼包5个", Client);
			}
			
			
		}
	}

}
/*判断对方是否是自己的师父*/
public IsPupilMaster(Client, target)
{
	if(!IsValidPlayer(Client) || !IsValidPlayer(target))
	{
		return false;
	}
	if(!IsPupil[Client])
	{
		return false;
	}
	if(!IsMaster[target])
	{
		return false;
	}
	new String:master[64];
	GetClientName(target, master, sizeof(master));
	if(StrEqual(PMaster[Client], master, true))
	{
		return true;
	}
	return false;
}
/*同门师兄*/
public IsMyBother(Client, target)
{
	if(!IsValidPlayer(Client) || !IsValidPlayer(target))
	{
		return false;
	}
	if(!IsPupil[Client] || !IsPupil[target])
	{
		return false;
	}
	if(StrEqual(PMaster[Client], PMaster[target], true))
	{
		return true;
	}
	return false;
}
/*传送*/
public League_Teleport(Client, target, type)
{
	new Float:pos[3];
	new Float:t_pos[3];
	//new Float:m_pos[3];
	new String:name[32];
	
	if (IsValidPlayer(Client) && IsValidPlayer(target))
	{
		if(!IsPlayerAlive(Client) || !IsPlayerAlive(target))
			return;
		GetEntPropVector(Client, Prop_Send, "m_vecOrigin", pos);
		GetEntPropVector(target, Prop_Send, "m_vecOrigin", t_pos);
		if (type == 0)
		{
			if(IsPupil[Client])
			{
				strcopy(name, sizeof(name), "师父");
			}else{
				strcopy(name, sizeof(name), "徒弟");
			}
			TeleportEntity(Client, t_pos, NULL_VECTOR, NULL_VECTOR);
			//MenuFunc_Teleport(Client);
			CPrintToChatAll("\x03{olive}【师徒技能】\x03{olive} %N \x03使用{olive}万水千山总是情\x03,传送到了%s {olive}%N \x03的身边.", Client, name, target);
		}
		else if (type == 1)
		{
			TeleportEntity(target, pos, NULL_VECTOR, NULL_VECTOR)
			//MenuFunc_Teleport(Client);
			CPrintToChatAll("\x03{olive}【师徒技能】\x03{olive} %N \x03使用{olive}万水千山总是情\x03,将徒弟{olive} %N \x03传送到了自己的身边.", Client, target);
		}
		/*
		else if (type == 2)
		{
			GetTracePosition(Client, m_pos);
			TeleportEntity(Client, m_pos, NULL_VECTOR, NULL_VECTOR);
			MenuFunc_Teleport(Client);
			CPrintToChatAll("{olive}[VIP]{lightgreen}%N{olive}使用传送补给,传送到了他准心的位置.", Client, target);
		}
		*/
	}
}
//师父是否在线
public bool:IsMasterOnline(Client)
{
	if(!IsPupil[Client]) return false;
	//判断师父是否在线
	new master = GetClientForName(PMaster[Client]);
	new String:name[64];
	GetClientName(Client, name, sizeof(name));
	if(IsValidPlayer(master) && IsClientInGame(master)){
		//CPrintToChat(Client, "我的师父 %N 在线!", master);
		//如果师父在线 判断是否徒弟是否是师父的徒弟
		if(IsMasterPupil(master, name))
		{
			return true;
		}else{
			strcopy(PMaster[Client], 64, "");
			IsPupil[Client] = false;
			return false;
		}
	}else{
		return false;
	}
}
//徒弟是否在线
public bool:IsPupilOnline(Client)
{
	if(!IsMaster[Client]) return false;
	new String:master[64], pupil;
	GetClientName(Client, master, sizeof(master));
	for(new i = 0;i < MaxPupil;i++)
	{
		pupil = GetClientForName(PupilArray[Client][i]);
		if(IsValidPlayer(pupil) && IsClientInGame(pupil))
		{
			//if(StrEqual(PMaster[pupil], master, true){
			//	continue;
			//}
			if(!StrEqual(PMaster[pupil], master, true)){
				//徒弟的师父不是本人
				//更新徒弟
				if(i == 0)
				{
					strcopy(Pupil_1[Client], 64, "");
				}else if(i == 1){
					strcopy(Pupil_2[Client], 64, "");
				}else if(i == 2){
					strcopy(Pupil_3[Client], 64, "");
				}else if(i == 3){
					strcopy(Pupil_4[Client], 64, "");
				}else if(i == 4){
					strcopy(Pupil_5[Client], 64, "");
				}
			}else{
				return true;
			}
		}
	
	}
	return false;
}

//拜师快捷键
public Action:Command_Baishi(client, args)
{
	MenuFunc_Baishi(client);
	return Plugin_Handled;
}