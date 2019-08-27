//天赋系统
public Action:MenuFunc_TFXT(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	decl String:wq[1024], String:ss[1024], String:xs[1024], String:xz[1024], String:shixue[1024], String:NH[1024], String:KB[1024], String:JDS[1024], String:ZHS[1024];	    
	if(MSTF[Client] <= 0)			Format(wq, sizeof(wq), "");
	else Format(wq, sizeof(wq), "【妙手医师】");
	if(DJYX[Client] <= 0)			Format(ss, sizeof(ss), "");
	else Format(ss, sizeof(ss), "【电击游侠】");
	if(tgyj[Client] <= 0)			Format(xs, sizeof(xs), "");
	else Format(xs, sizeof(xs), "【愤怒反击】");
	if(xstf[Client] <= 0)			Format(xz, sizeof(xz), "");
	else Format(xz, sizeof(xz), "【绝不牺牲】");
	if(NHYS[Client] <= 0)			Format(NH, sizeof(NH), "");
	else Format(NH, sizeof(NH), "【怒火医师】");
	if(KBYS[Client] <= 0)			Format(KB, sizeof(KB), "");
	else Format(KB, sizeof(KB), "【狂暴医师】");
	if(sxtf[Client] <= 0)			Format(shixue, sizeof(shixue), "");
	else Format(shixue, sizeof(shixue), "【疯狂嗜血】");
	if(ZHONGHUO[Client] <= 0)			Format(ZHS, sizeof(ZHS), "");
	else Format(ZHS, sizeof(ZHS), "【纵火术】");
	if(JIDONG[Client] <= 0)			Format(JDS, sizeof(JDS), "");
	else Format(JDS, sizeof(JDS), "【极冻术】");

	Format(line, sizeof(line), "==========天赋技能系统=========");
	SetPanelTitle(menu, line);
	Format(line, sizeof(line),"说明:天赋需要10个BOSS的心愿和50W游戏币\n材料：【BOSS的心愿】目前拥有：%d个", BSXY[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line),"===========拥有天赋==========");
	DrawPanelText(menu, line);
	Format(line, sizeof(line),"%s%s%s\n%s%s%s\n%s%s%s", wq, ss, shixue, xs, xz, NH, KB, JDS, ZHS);
	DrawPanelText(menu, line);
	Format(line, sizeof(line),"===========================");
	DrawPanelText(menu, line);
   
	Format(line, sizeof(line), "疯狂嗜血【被动】");
	DrawPanelItem(menu, line);
	
	Format(line, sizeof(line), "电击游侠【被动】");
	DrawPanelItem(menu, line);
	
	Format(line, sizeof(line), "愤怒反击【被动】");
	DrawPanelItem(menu, line);
	
	Format(line, sizeof(line), "绝不牺牲【被动】");
	DrawPanelItem(menu, line);
	
	Format(line, sizeof(line), "下一页");
	DrawPanelItem(menu, line);
	
	Format(line, sizeof(line), "返回主菜单");
	DrawPanelItem(menu, line);
	SendPanelToClient(menu, Client, MenuHandler_TFXT, MENU_TIME_FOREVER);
}

public MenuHandler_TFXT(Handle:menu, MenuAction:action, Client, param)//基础菜单	
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1:
                if (BSXY[Client] > 9 && Cash[Client] > 500000)
			    {
			        MenuFunc_fksx(Client);
				}else CPrintToChat(Client, "你没有【BOSS的心愿】材料或者金钱不够");
			case 2:
                if (BSXY[Client] > 9 && Cash[Client] > 500000)
			    {
			        MenuFunc_djyx(Client);
				}else CPrintToChat(Client, "你没有【BOSS的心愿】材料或者金钱不够");
			case 3:
                if (BSXY[Client] > 9 && Cash[Client] > 500000)
			    {
			        MenuFunc_fnfj(Client);
				}else CPrintToChat(Client, "你没有【BOSS的心愿】材料或者金钱不够");
			case 4:
                if (BSXY[Client] > 9 && Cash[Client] > 500000)
			    {
			        MenuFunc_jbxs(Client);
				}else CPrintToChat(Client, "你没有【BOSS的心愿】材料或者金钱不够");
			case 5: MenuFunc_xiayi(Client);
			case 6: MenuFunc_RPG(Client);	
		}
	}
}

public Action:MenuFunc_xiayi(Client)
{
	decl String:line[128];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "====天赋技能====");
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "极冻术【被动】");
	DrawPanelItem(menu, line);
	
	Format(line, sizeof(line), "纵火术【被动】");
	DrawPanelItem(menu, line);
	
	Format(line, sizeof(line), "妙手医师【被动】");
	DrawPanelItem(menu, line);
	
	Format(line, sizeof(line), "怒火医师【被动】");
	DrawPanelItem(menu, line);
	
	Format(line, sizeof(line), "狂暴医师【被动】");
	DrawPanelItem(menu, line);
	
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_xiayi, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}

public MenuHandler_xiayi(Handle:menu, MenuAction:action, Client, param)//基础菜单	
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: 
                if (BSXY[Client] > 9 && Cash[Client] > 500000)
			    {
			        MenuFunc_JIDONGS(Client);
				}else CPrintToChat(Client, "你没有【BOSS的心愿】材料或者金钱不够");
			case 2: 
                if (BSXY[Client] > 9 && Cash[Client] > 500000)
			    {
			        MenuFunc_ZHONGHUOS(Client);
				}else CPrintToChat(Client, "你没有【BOSS的心愿】材料或者金钱不够");
			case 3: 
                if (BSXY[Client] > 9 && Cash[Client] > 500000)
			    {
			        MenuFunc_mstf(Client);
				}else CPrintToChat(Client, "你没有【BOSS的心愿】材料或者金钱不够");	
			case 4:
                if (BSXY[Client] > 9 && Cash[Client] > 500000)
			    {
			        MenuFunc_nhys(Client);
				}else CPrintToChat(Client, "你没有【BOSS的心愿】材料或者金钱不够");
			case 5:
                if (BSXY[Client] > 9 && Cash[Client] > 500000)
			    {
			        MenuFunc_kbys(Client);
				}else CPrintToChat(Client, "你没有【BOSS的心愿】材料或者金钱不够");	
		}
	}
}

public Action:MenuFunc_ZHONGHUOS(Client)
{
	decl String:line[128];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "═════纵火术═════");
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "说明：学习此技能以后倒地 \n即可发动300码的火海");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "═════════════");
	DrawPanelText(menu, line);
	DrawPanelItem(menu, "学习");
	DrawPanelItem(menu, "返回");
	
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_ZHONGHUOS, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}

public MenuHandler_ZHONGHUOS(Handle:menu, MenuAction:action, Client, param)//基础菜单	
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: mstft(Client);
			case 2: MenuFunc_TFXT(Client);
		}
	}
}

public mstft(Client)
{
    if(ZHONGHUO[Client] < 1)   
	{
		ZHONGHUO[Client] ++;
		BSXY[Client] -= 10;
		Cash[Client] -= 500000;
		PrintHintTextToAll("【天赋】:玩家 %N 习得【纵火术】技能，恭喜他", Client);
    }else CPrintToChat(Client, "你已经拥有此技能，无法学习");     
}

public Action:MenuFunc_JIDONGS(Client)
{
	decl String:line[128];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "═════极冻术═════");
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "说明：学习此技能以后倒地 \n可以冰冻所有感染者30秒");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "═════════════");
	DrawPanelText(menu, line);
	DrawPanelItem(menu, "学习");
	DrawPanelItem(menu, "返回");
	
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_MenuFunc_JIDONGS, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}

public MenuHandler_MenuFunc_JIDONGS(Handle:menu, MenuAction:action, Client, param)//基础菜单	
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: mstff(Client);
			case 2: MenuFunc_TFXT(Client);
		}
	}
}

public mstff(Client)
{
    if(JIDONG[Client] < 1)   
	{
		JIDONG[Client] ++;
		BSXY[Client] -= 10;
		Cash[Client] -= 500000;
		PrintHintTextToAll("【天赋】:玩家 %N 习得【极冻术】技能，恭喜他", Client);
    }else CPrintToChat(Client, "你已经拥有此技能，无法学习");     
}

public Action:MenuFunc_mstf(Client)
{
	decl String:line[128];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "═════妙手医师═════");
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "说明：学习此技能以后拉人 \n可以获得天赋随即奖励");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "═════════════");
	DrawPanelText(menu, line);
	DrawPanelItem(menu, "学习");
	DrawPanelItem(menu, "返回");
	
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_mstf, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}

public MenuHandler_mstf(Handle:menu, MenuAction:action, Client, param)//基础菜单	
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: mstf(Client);
			case 2: MenuFunc_TFXT(Client);
		}
	}
}

public mstf(Client)
{
    if(MSTF[Client] < 1 && NHYS[Client] < 1 && KBYS[Client] < 1)   
	{
		MSTF[Client] ++;
		BSXY[Client] -= 10;
		Cash[Client] -= 500000;
		PrintHintTextToAll("【天赋】:玩家 %N 习得【妙手医师】技能，恭喜他", Client);
    }else CPrintToChat(Client, "你已经拥有此类技能，无法学习");     
}

public Action:MenuFunc_djyx(Client)
{
	decl String:line[128];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "═════电击游侠═════");
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "说明：学习此技能以后 \n电人可以获得天赋随即奖励");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "═════════════");
	DrawPanelText(menu, line);
	DrawPanelItem(menu, "学习");
	DrawPanelItem(menu, "返回");
	
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_djyx, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}

public MenuHandler_djyx(Handle:menu, MenuAction:action, Client, param)//基础菜单	
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: djyx(Client);
			case 2: MenuFunc_TFXT(Client);
		}
	}
}

public djyx(Client)
{
    if(DJYX[Client] < 1)   
	{
		DJYX[Client] ++;
		BSXY[Client] -= 10;
		Cash[Client] -= 500000;
		PrintHintTextToAll("【天赋】:玩家 %N 习得【电击游侠】天赋技能，恭喜他", Client);
    }else CPrintToChat(Client, "你已经拥有此技能，无需再次学习");    
}

public Action:MenuFunc_fnfj(Client)
{
	decl String:line[128];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "═════愤怒反击═════");
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "说明：学习此技能以后 \n被TANK打到会反伤5000伤害");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "═════════════");
	DrawPanelText(menu, line);
	DrawPanelItem(menu, "学习");
	DrawPanelItem(menu, "返回");
	
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_fnfj, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}

public MenuHandler_fnfj(Handle:menu, MenuAction:action, Client, param)//基础菜单	
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: fnfjj(Client);
			case 2: MenuFunc_TFXT(Client);
		}
	}
}

public fnfjj(Client)
{
    if(tgyj[Client] < 1)   
	{
		tgyj[Client] ++;
		BSXY[Client] -= 10;
		Cash[Client] -= 500000;
		PrintHintTextToAll("【天赋】:玩家 %N 习得【愤怒反击】天赋技能，恭喜他", Client);
    }else CPrintToChat(Client, "你已经拥有此技能，无需再次学习");    
}

public Action:MenuFunc_jbxs(Client)
{
	decl String:line[128];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "═════绝不牺牲═════");
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "说明：自身死亡时有1/3 \n的几率与攻击者同归于尽");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "═════════════");
	DrawPanelText(menu, line);
	DrawPanelItem(menu, "学习");
	DrawPanelItem(menu, "返回");
	
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_jbxs, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}

public MenuHandler_jbxs(Handle:menu, MenuAction:action, Client, param)//基础菜单	
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: jbxs(Client);
			case 2: MenuFunc_TFXT(Client);
		}
	}
}

public jbxs(Client)
{
    if(xstf[Client] < 1)   
	{
		xstf[Client] ++;
		BSXY[Client] -= 10;
		Cash[Client] -= 500000;
		PrintHintTextToAll("【天赋】:玩家 %N 习得【绝不牺牲】天赋技能，恭喜他", Client);
    }else CPrintToChat(Client, "你已经拥有此技能，无需再次学习");    
}

public Action:MenuFunc_fksx(Client)
{
	decl String:line[128];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "═════疯狂嗜血═════");
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "说明：击杀特感随机增加血量5到15");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "═════════════");
	DrawPanelText(menu, line);
	DrawPanelItem(menu, "学习");
	DrawPanelItem(menu, "返回");
	
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_fksx, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}

public MenuHandler_fksx(Handle:menu, MenuAction:action, Client, param)//基础菜单	
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: fkss(Client);
			case 2: MenuFunc_TFXT(Client);
		}
	}
}

public fkss(Client)
{
    if(sxtf[Client] < 1)   
	{
		sxtf[Client] ++;
		BSXY[Client] -= 10;
		Cash[Client] -= 500000;
		PrintHintTextToAll("【天赋】:玩家 %N 习得【疯狂嗜血】天赋技能，恭喜他", Client);
    }else CPrintToChat(Client, "你已经拥有此技能，无需再次学习");    
}

public Action:MenuFunc_nhys(Client)
{
	decl String:line[128];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "═════怒火医师═════");
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "说明：拉人1/3获得爆炎弹");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "═════════════");
	DrawPanelText(menu, line);
	DrawPanelItem(menu, "学习");
	DrawPanelItem(menu, "返回");
	
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_nhys, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}

public MenuHandler_nhys(Handle:menu, MenuAction:action, Client, param)//基础菜单	
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: nhys(Client);
			case 2: MenuFunc_TFXT(Client);
		}
	}
}

public nhys(Client)
{
    if(NHYS[Client] < 1 && MSTF[Client] < 1 && KBYS[Client] < 1)   
	{
		NHYS[Client] ++;
		BSXY[Client] -= 10;
		Cash[Client] -= 500000;
		PrintHintTextToAll("【天赋】:玩家 %N 习得【怒火医师】天赋技能，恭喜他", Client);
    }else CPrintToChat(Client, "你已经拥有此类技能，无法学习");    
}

public Action:MenuFunc_kbys(Client)
{
	decl String:line[128];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "═════狂暴医师═════");
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "说明：拉人1/3获得爆裂弹");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "═════════════");
	DrawPanelText(menu, line);
	DrawPanelItem(menu, "学习");
	DrawPanelItem(menu, "返回");
	
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_kbys, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}

public MenuHandler_kbys(Handle:menu, MenuAction:action, Client, param)//基础菜单	
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: kbys(Client);
			case 2: MenuFunc_TFXT(Client);
		}
	}
}

public kbys(Client)
{
    if(KBYS[Client] < 1 && NHYS[Client] < 1 && MSTF[Client] < 1)   
	{
		KBYS[Client] ++;
		BSXY[Client] -= 10;
		Cash[Client] -= 500000;
		PrintHintTextToAll("【天赋】:玩家 %N 习得【狂暴医师】天赋技能，恭喜他", Client);
    }else CPrintToChat(Client, "你已经拥有此类技能，无法学习");    
}

/*public Action:EventFrancis(Handle:Timer, any:client)
{
	if(g_creattimer5[client] == true)
	{
		if(IsClientInGame(client) && IsClientConnected(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2) 
		{
			if((GetEntProp(client,Prop_Send,"m_iHealth") < GetEntProp(client,Prop_Send,"m_iMaxHealth")) || GetEntProp(client, Prop_Send, "m_isIncapacitated"))
			{
				CheatCommand(client, "give", "health");
				if(!IsFakeClient(client)) PrintToChat(client, "\x03[\x05提示\x03]\x04你使用\x03永康\x04天赋恢复了自我血气!");
			}
		}
		TimerTelant_2[client] = CreateTimer(200.0, EventFrancis, client);
	}
	else TimerTelant_2[client] = INVALID_HANDLE;
}

public Action:EventCoach(Handle:Timer, any:client)
{
	if(g_creattimer6[client] == true)
	{
		if(IsClientInGame(client) && IsClientConnected(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2) 
		{
			CheatCommand(client, "give", "defibrillator");
			if(!IsFakeClient(client)) PrintToChat(client, "\x03[\x05提示\x03]\x04你使用\x03电疗\x04天赋获得电击器!");
		}
		TimerTelant_3[client] = CreateTimer(200.0, EventCoach, client);
	}
	else TimerTelant_3[client] = INVALID_HANDLE;
}

public Action:EventNick(Handle:Timer, any:client)
{
	if(g_creattimer8[client] == true)
	{
		if(IsClientInGame(client) && IsClientConnected(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2) 
		{
			CheatCommand(client, "give", "pipe_bomb");
			if(!IsFakeClient(client)) PrintToChat(client, "\x03[\x05提示\x03]\x04你使用\x03爆破\x04天赋获得土制炸弹!");
		}
		TimerTelant_4[client] = CreateTimer(100.0, EventNick, client);
	}
	else TimerTelant_4[client] = INVALID_HANDLE;
}


public Action:Event_Heal_Success(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new target = GetClientOfUserId(GetEventInt(event, "subject"));
	new ClientHP;
	new MaxHP = GetEntProp(target,Prop_Send,"m_iMaxHealth");
	if(g_creattimer7[client] == true) MaxHP += 50;
	if(MaxHP > GetEntProp(target,Prop_Send,"m_iHealth")) ClientHP = MaxHP;
	else ClientHP = GetEntProp(target,Prop_Send,"m_iHealth");
	SetEntProp(target,Prop_Send,"m_iHealth",ClientHP);
}


public Action:EventSuperCoach(Handle:event, String:event_name[], bool:dontBroadcast) 
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new client = GetClientOfUserId(GetEventInt(event, "userid")); 

	if (!client || !IsClientInGame(client) || !IsClientConnected(client) || GetClientTeam(client) != 2) return;
	
	if (g_creattimer9[client] == true)
	{
		new chance = GetRandomInt(1,4);
		if(chance == 1)
		{
			CreateTimer(3.0, EventRevive, client);
			if(!IsFakeClient(client)) PrintToChat(client, "\x03[\x05提示\x03]\x04你成功使用\x03顽强\x04天赋,3秒后倒地自救!");
		}
	}
	
	if (!attacker || !IsClientInGame(attacker)) return;
	
	if(GetClientTeam(attacker) == TEAM_ZOMBIES) 
	{
		if(si[client] == true)
		{
			ServerCommand("sm_freeze \"%N\" \"12\"",attacker); 
			new String:name[32];
			GetClientName(attacker, name, 32);
			PrintToChatAll("\x03[\x05提示\x03] %N\x04使用\x03释冰\x04天赋冻结了\x03%s\x0412秒!",client,name);
		}
		new extradmg = 0;
		new bool:ExtraAdd = false;
		for(new i = 0;i < 4;i ++)
		{
			if(CurrentEqm[client][i] != -1)
			{
				if(clienteqmextalent[client][CurrentEqm[client][i]] == 5) 
				{
					ExtraAdd = true;
					break;
				}
			}
		}
		if(ExtraAdd == true) extradmg += 100;
		if(qi[client] == true)
		{
			extradmg += 150;
		}
		if(extradmg)
		{
			IgniteEntity(attacker, 60.0, true);
			DealDamage(client, attacker, extradmg, 0);
			new String:name[32];
			GetClientName(attacker, name, 32);
			PrintToChatAll("\x03[\x05提示\x03] %N\x04使用\x03纵火\x04天赋给予\x03%s %d\x04点伤害并燃烧60秒!",client,name,extradmg);
		}
	}
}

if(respawn)
		{
			new chance = GetRandomInt(1, 3);
			if(chance <= respawn)
			{
				CreateTimer(5.0, Event_Respawn, client);
				PrintToChatAll("\x03[\x05提示\x03] %N\x04成功\x03转生\x04,5秒后复活到队友身边!",client);
			}
			else PrintToChatAll("\x03[\x05提示\x03]\x04很遗憾!\x03%N\x04转生失败!",client);
		}
public Action:Event_Respawn(Handle:timer, any:client)
{
	if (client && IsClientInGame(client) && IsClientConnected(client) && GetClientTeam(client) == 2)
	{
		decl String:playername[64];
		GetClientName(client, playername, sizeof(playername));
		new teletarget = 0;
		for(new i = 1; i <= MaxClients; i++)
		{
			if(!IsClientInGame(i)) continue;
			if(!IsPlayerAlive(i)) continue;
			if(GetClientTeam(i) != 2) continue;
			if(i == client) continue;
			teletarget = i;
			break;
		}
		if(IsPlayerAlive(client))
		{
			PrintToChatAll("\x03[\x05提示\x03]\x04由于玩家\x03%s\x04已经是活着的状态,玩家\x03%s\x04复活失败.", playername);
		}
		if(teletarget == 0)
		{
			PrintToChatAll("\x03[\x05提示\x03]\x04由于没有可传送的队友,玩家\x03%s\x04复活失败.", playername);
		}
		else
		{
			SDKCall(hRoundRespawn, client);
			PrintToChatAll("\x03[\x05提示\x03]\x04玩家\x03%s\x04顺利复活.", playername);
			new Float:position[3];
			new Float:anglestarget[3];
			GetClientAbsOrigin(teletarget, position);
			position[2] + 0.2;
			GetClientAbsAngles(teletarget, anglestarget);
			TeleportEntity(client, position, anglestarget, NULL_VECTOR);
		}
	}
}*/		