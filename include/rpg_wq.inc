
public Action:MenuFunc_WUQI(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	decl String:wq[1024], String:sx[1024], String:QH[1024];	    
	
	new ak47 = 5 * AK47[Client] + DMG_AK47;
	new m60 =  5 * M60[Client] + DMG_M60;
	new m16 =  5 * M16[Client] + DMG_M16;
	new spas = 3 * PZ[Client] + DMG_SPAS;
	new awp = 12 * AWP[Client] + DMG_AWP;
	
	if (WQXT[Client] == 0)
		Format(wq, sizeof(wq), "无");
	else if (WQXT[Client] == 1)
		Format(wq, sizeof(wq), "【水晶M16】");
	else if (WQXT[Client] == 2)
		Format(wq, sizeof(wq), "【黄金AK47】");
	else if (WQXT[Client] == 3)
		Format(wq, sizeof(wq), "【雷神之怒】");
	else if (WQXT[Client] == 4)
		Format(wq, sizeof(wq), "【欲蛇之贪】");
	else if (WQXT[Client] == 5)
		Format(wq, sizeof(wq), "【麒麟之枪】");
	
	if (WQXT[Client] == 0)
		Format(sx, sizeof(sx), "无");
	else if (WQXT[Client] == 1)
		Format(sx, sizeof(sx), "M16伤害：%d", m16);
	else if (WQXT[Client] == 2)
		Format(sx, sizeof(sx), "AK47伤害：%d", ak47);
	else if (WQXT[Client] == 3)
		Format(sx, sizeof(sx), "AWP伤害：%d", awp);
	else if (WQXT[Client] == 4)
		Format(sx, sizeof(sx), "喷子伤害：%d", spas);
	else if (WQXT[Client] == 5)
		Format(sx, sizeof(sx), "M60伤害：%d", m60);
		
	if (WQXT[Client] == 0)
		Format(QH, sizeof(QH), "无");
	else if (WQXT[Client] == 1)
		Format(QH, sizeof(QH), "强化LV%d M16", M16[Client]);
	else if (WQXT[Client] == 2)
		Format(QH, sizeof(QH), "强化LV%d AK47", AK47[Client]);
	else if (WQXT[Client] == 3)
		Format(QH, sizeof(QH), "强化LV%d AWP", AWP[Client]);
	else if (WQXT[Client] == 4)
		Format(QH, sizeof(QH), "强化LV%d 喷子", PZ[Client]);
	else if (WQXT[Client] == 5)
		Format(QH, sizeof(QH), "强化LV%d M60", M60[Client]);

	Format(line, sizeof(line),"==================");
	SetPanelTitle(menu, line);
	Format(line, sizeof(line),"主武器名称: %s ", wq);
	DrawPanelText(menu, line);
	Format(line, sizeof(line),"强化等级: %s ", QH);
	DrawPanelText(menu, line);
	Format(line, sizeof(line),"主武器属性: %s ", sx);
	DrawPanelText(menu, line);
	Format(line, sizeof(line),"【材料】:拥有强化石【%d个】\n【改装】:拥有机械之心【%d个】", Qhs[Client], JXZX[Client]);
	DrawPanelText(menu, line);
	/*if(GZ[Client] == 1)
	{	    
		Format(line, sizeof(line),"【改造】:%s", gz);
		DrawPanelText(menu, line);
	}*/
	Format(line, sizeof(line),"===================");
	DrawPanelText(menu, line);
   
	Format(line, sizeof(line), "武器强化");
	DrawPanelItem(menu, line);
	
	Format(line, sizeof(line), "机械改造");
	DrawPanelItem(menu, line);
	
	Format(line, sizeof(line), "选择主武器");
	DrawPanelItem(menu, line);
	
	Format(line, sizeof(line), "返回");
	DrawPanelItem(menu, line);
	
	SendPanelToClient(menu, Client, MenuHandler_WUQI, MENU_TIME_FOREVER);
}

public MenuHandler_WUQI(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select) {
		switch(param) {
			case 1:
			    if (Qhs[Client] > 0)
			    {  
				if(WQXT[Client] == 1)	qhm161(Client);
			        else if(WQXT[Client] == 2)	qhak471(Client);
			        else if(WQXT[Client] == 3)	qhawp1(Client);
			        else if(WQXT[Client] == 4)	qhpz1(Client);
			        else if(WQXT[Client] == 5)	qhm601(Client);
				else if(WQXT[Client] == 0)	CPrintToChat(Client, "请选择需要强化的武器！");
			    }else CPrintToChat(Client, "你没有强化石，击杀特感有机会获得");
			case 2:
                if (JXZX[Client] > 0)
			    {
			        jxgz(Client);
				}else CPrintToChat(Client, "你没有【机械之心】材料，击杀妹子会随机获得");
			case 3: MenuFunc_zwq(Client);	
			case 4: MenuFunc_RPG(Client);
		}
	}
}

public Action:MenuFunc_zwq(Client)
{
	new Handle:menu = CreatePanel();
	
	decl String:line[1024];
	Format(line, sizeof(line), "===选定主武器===");
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "[水晶M16]");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "[黄金AK47]");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "[雷神之怒][AWP]");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "[欲蛇之贪][喷子]");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "[麒麟之枪][M60]");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "重铸武器[10万]");
	DrawPanelItem(menu, line);
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

	SendPanelToClient(menu, Client, MenuHandler_zwq, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public MenuHandler_zwq(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: zwq1(Client);
			case 2: zwq2(Client);
			case 3: zwq3(Client);
			case 4: zwq4(Client);
			case 5: zwq5(Client);
			case 6: zwq6(Client);
		}
	}
}
public zwq1(Client)
{   
	if (WQXT[Client] == 0)
	{  
        WQXT[Client] += 1;
        CPrintToChat(Client, "选择[水晶M16]成功");
        ClientSaveToFileSave(Client);
	} else CPrintToChat(Client, "已经选择过了，无法选择");
}
public zwq2(Client)
{   
	if (WQXT[Client] == 0)
	{  
        WQXT[Client] += 2;
        CPrintToChat(Client, "选择[黄金AK47]成功");
        ClientSaveToFileSave(Client);
	} else CPrintToChat(Client, "已经选择过了，无法选择");
}
public zwq3(Client)
{   
	if (WQXT[Client] == 0)
	{  
        WQXT[Client] += 3;
        CPrintToChat(Client, "选择[雷神之怒]成功");
        ClientSaveToFileSave(Client);
	} else CPrintToChat(Client, "已经选择过了，无法选择");
}
public zwq4(Client)
{   
	if (WQXT[Client] == 0)
	{  
        WQXT[Client] += 4;
        CPrintToChat(Client, "选择[欲蛇之贪]成功");
        ClientSaveToFileSave(Client);
	} else CPrintToChat(Client, "已经选择过了，无法选择");
}
public zwq5(Client)
{   
	if (WQXT[Client] == 0)
	{  
        WQXT[Client] += 5;
        CPrintToChat(Client, "选择[麒麟之枪]成功");
        ClientSaveToFileSave(Client);
	} else CPrintToChat(Client, "已经选择过了，无法选择");
}
public zwq6(Client)
{   
	if(Cash[Client] > 100000)   
	{
	    if (WQXT[Client] != 0)
	    {  
            WQXT[Client] = 0;
            Cash[Client] -= 100000;
            ClientSaveToFileSave(Client);
            CPrintToChat(Client, "武器重铸成功，-100000$");
            CPrintToChatAll("\x01[\x03武器\x01]\x05玩家\x04 %N \x03花费\x05 10万$ \x03把武器重铸\x05 成功", Client);
	    } else CPrintToChat(Client, "武器已经初始化了，不需要再重铸");
	} else CPrintToChat(Client, "小伙子，钱不够100000，好好赚钱去吧");
}

public jxgz(Client)
{
    if(GZ[Client] < 1)   
	{
	    if(Cash[Client] > 100000)   
		{
		    Cash[Client] -= 100000;
		    JXZX[Client] -= 1;
		    new Qhjl = GetRandomInt(1, 10);
		
		    switch (Qhjl)       
		    {    
			    case 1:           
				{               
	   	  	       GZ[Client] = 1;
	   	  	       PrintHintTextToAll("【恭喜】：玩家 %N 改造武器成功", Client);           
				}
				case 2:           
				{   
					Sxcs[Client] ++			
					CPrintToChat(Client, "\x01[\x04改造\x01]\x03：\x05失败");           
				}
				case 3:           
				{   
					Sxcs[Client] ++			
					CPrintToChat(Client, "\x01[\x04改造\x01]\x03：\x05失败");           
				}
				case 4:           
				{     
					Sxcs[Client] ++			
					CPrintToChat(Client, "\x01[\x04改造\x01]\x03：\x05失败");           
				}
	    	}
   		}else CPrintToChat(Client, "\x01[\x04改造\x01]\x03：\x05金币不足");
    }else CPrintToChat(Client, "\x01[\x04改造\x01]\x03：\x05你的武器已经改造过了！不需要改造");    
}
