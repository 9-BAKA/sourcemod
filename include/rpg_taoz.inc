/************************************************************************
*	套装装备相关代码
************************************************************************/
//装备属性增加and技能
public Zbtaozbx(Client)
{
	if (Lv[Client] > 20)
	{   			    
		if (Touke[Client] == 3)	    
		{   		
		    Touke[Client] = 0;    
		}
		if (Jiake[Client] == 3)	    
		{   		
			Jiake[Client] = 0;   
		}
		if (Xieke[Client] == 3)	    
		{   		
			Xieke[Client] = 0;   
		}
		if (Kuke[Client] == 3)	    
		{   		
			Kuke[Client] = 0;   
		}
		if (Wuqi[Client] == 3)	    
		{   		
			Wuqi[Client] = 0;	    
		}		
	}	
}
	

/* 装备显示菜单*/
public Action:Menu_Zhuang(Client,args)
{
	MenuFunc_Zhuang(Client);
	return Plugin_Handled;
}
public Action:MenuFunc_Zhuang(Client)
{ 
	new Handle:menu = CreatePanel();
    
	decl String:ZBEET[16];	   
	if(Touke[Client] == 0)			Format(ZBEET, sizeof(ZBEET), "无");   
	else if(Touke[Client] == 1)	    Format(ZBEET, sizeof(ZBEET), "铁头盔");
	else if(Touke[Client] == 2)	    Format(ZBEET, sizeof(ZBEET), "铜头盔");
	else if(Touke[Client] == 3)	    Format(ZBEET, sizeof(ZBEET), "新手头盔");
	   
	decl String:ZBXXT[16];	   
	if(Jiake[Client] == 0)			Format(ZBXXT, sizeof(ZBXXT), "无");   
	else if(Jiake[Client] == 1)	    Format(ZBXXT, sizeof(ZBXXT), "铁护甲");
	else if(Jiake[Client] == 2)	    Format(ZBXXT, sizeof(ZBXXT), "铜护甲");
	else if(Jiake[Client] == 3)	    Format(ZBXXT, sizeof(ZBXXT), "新手护甲");
   
	decl String:ZBNNT[16];	  
	if(Xieke[Client] == 0)			Format(ZBNNT, sizeof(ZBNNT), "无");  
	else if(Xieke[Client] == 1)	    Format(ZBNNT, sizeof(ZBNNT), "铁鞋子");
	else if(Xieke[Client] == 2)	    Format(ZBNNT, sizeof(ZBNNT), "铜鞋子");
	else if(Xieke[Client] == 3)	    Format(ZBNNT, sizeof(ZBNNT), "新手鞋子");
   
	decl String:ZBJJT[16];	  
	if(Kuke[Client] == 0)			Format(ZBJJT, sizeof(ZBJJT), "无"); 
	else if(Kuke[Client] == 1)	    Format(ZBJJT, sizeof(ZBJJT), "铁裤子");
	else if(Kuke[Client] == 2)	    Format(ZBJJT, sizeof(ZBJJT), "铜裤子");
	else if(Kuke[Client] == 3)	    Format(ZBJJT, sizeof(ZBJJT), "新手裤子");
   
	decl String:ZBCCT[16];	   
	if(Wuqi[Client] == 0)			Format(ZBCCT, sizeof(ZBCCT), "无");   
	else if(Wuqi[Client] == 1)	    Format(ZBCCT, sizeof(ZBCCT), "重铁刃");
	else if(Wuqi[Client] == 2)	    Format(ZBCCT, sizeof(ZBCCT), "青铜刃");
	else if(Wuqi[Client] == 3)	    Format(ZBCCT, sizeof(ZBCCT), "新手刃");
	
	decl String:ZBKKT[16];	   
	if(Zbming[Client] == 0)			Format(ZBKKT, sizeof(ZBKKT), "无");   
	else if(Zbming[Client] == 1)	    Format(ZBKKT, sizeof(ZBKKT), "钢铁套装");
	else if(Zbming[Client] == 2)	    Format(ZBKKT, sizeof(ZBKKT), "青铜套装");
	else if(Zbming[Client] == 3)	    Format(ZBKKT, sizeof(ZBKKT), "新手套装");
	  
	decl String:line[256];   
	Format(line, sizeof(line),    
	"═══[J键]我的特殊装备[套装: %s]═══ \n 头盔:%s \n 护甲:%s \n 鞋子:%s \n 裤子:%s \n 武器:%s", ZBKKT, ZBEET, ZBXXT, ZBNNT, ZBJJT, ZBCCT);    
	SetPanelTitle(menu, line);	
	   
	Format(line, sizeof(line), "查看装备");  
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "出售装备");  
	DrawPanelItem(menu, line);   
	Format(line, sizeof(line), "装备储存空间");  
	DrawPanelItem(menu, line);
	DrawPanelItem(menu, "返回RPG选单");   
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
    
	SendPanelToClient(menu, Client, MenuHandler_Zhuang, MENU_TIME_FOREVER);     
	return Plugin_Handled;
}

public MenuHandler_Zhuang(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
            case 1: MenuFunc_Chakan(Client);
            case 2: MenuFunc_Chadiuq(Client);
			case 3: MenuFunc_Chucu(Client);
			case 4: MenuFunc_RPG(Client);				
		}
	}
}

/* 装备储存空间*/
public Action:MenuFunc_Chucu(Client)
{ 
	new Handle:menu = CreatePanel();
    	
	decl String:ZBEET[16];	   
	if(Zbshu[Client] == 0)			Format(ZBEET, sizeof(ZBEET), "无");   
	else if(Zbshu[Client] == 1)	    Format(ZBEET, sizeof(ZBEET), "铁头盔");
	else if(Zbshu[Client] == 2)	    Format(ZBEET, sizeof(ZBEET), "铜头盔");
	else if(Zbshu[Client] == 3)	    Format(ZBEET, sizeof(ZBEET), "铁护甲");
	else if(Zbshu[Client] == 4)	    Format(ZBEET, sizeof(ZBEET), "铜护甲");
	else if(Zbshu[Client] == 5)	    Format(ZBEET, sizeof(ZBEET), "铁鞋子");
	else if(Zbshu[Client] == 6)	    Format(ZBEET, sizeof(ZBEET), "铜鞋子");
	else if(Zbshu[Client] == 7)	    Format(ZBEET, sizeof(ZBEET), "铁裤子");
	else if(Zbshu[Client] == 8)	    Format(ZBEET, sizeof(ZBEET), "铜裤子");
	else if(Zbshu[Client] == 9)	    Format(ZBEET, sizeof(ZBEET), "重铁刃");
	else if(Zbshu[Client] == 10)	    Format(ZBEET, sizeof(ZBEET), "青铜刃");
	
	decl String:ZBYYT[16];	   
	if(Zbshua[Client] == 0)			Format(ZBYYT, sizeof(ZBYYT), "无");   
	else if(Zbshua[Client] == 1)	    Format(ZBYYT, sizeof(ZBYYT), "铁头盔");
	else if(Zbshua[Client] == 2)	    Format(ZBYYT, sizeof(ZBYYT), "铜头盔");
	else if(Zbshua[Client] == 3)	    Format(ZBYYT, sizeof(ZBYYT), "铁护甲");
	else if(Zbshua[Client] == 4)	    Format(ZBYYT, sizeof(ZBYYT), "铜护甲");
	else if(Zbshua[Client] == 5)	    Format(ZBYYT, sizeof(ZBYYT), "铁鞋子");
	else if(Zbshua[Client] == 6)	    Format(ZBYYT, sizeof(ZBYYT), "铜鞋子");
	else if(Zbshua[Client] == 7)	    Format(ZBYYT, sizeof(ZBYYT), "铁裤子");
	else if(Zbshua[Client] == 8)	    Format(ZBYYT, sizeof(ZBYYT), "铜裤子");
	else if(Zbshua[Client] == 9)	    Format(ZBYYT, sizeof(ZBYYT), "重铁刃");
	else if(Zbshua[Client] == 10)	    Format(ZBYYT, sizeof(ZBYYT), "青铜刃");
	
	decl String:ZBXXT[16];	   
	if(Zbshub[Client] == 0)			Format(ZBXXT, sizeof(ZBXXT), "无");   
	else if(Zbshub[Client] == 1)	    Format(ZBXXT, sizeof(ZBXXT), "铁头盔");
	else if(Zbshub[Client] == 2)	    Format(ZBXXT, sizeof(ZBXXT), "铜头盔");
	else if(Zbshub[Client] == 3)	    Format(ZBXXT, sizeof(ZBXXT), "铁护甲");
	else if(Zbshub[Client] == 4)	    Format(ZBXXT, sizeof(ZBXXT), "铜护甲");
	else if(Zbshub[Client] == 5)	    Format(ZBXXT, sizeof(ZBXXT), "铁鞋子");
	else if(Zbshub[Client] == 6)	    Format(ZBXXT, sizeof(ZBXXT), "铜鞋子");
	else if(Zbshub[Client] == 7)	    Format(ZBXXT, sizeof(ZBXXT), "铁裤子");
	else if(Zbshub[Client] == 8)	    Format(ZBXXT, sizeof(ZBXXT), "铜裤子");
	else if(Zbshub[Client] == 9)	    Format(ZBXXT, sizeof(ZBXXT), "重铁刃");
	else if(Zbshub[Client] == 10)	    Format(ZBXXT, sizeof(ZBXXT), "青铜刃");
	
	decl String:ZBJJT[16];	   
	if(Zbshuc[Client] == 0)			Format(ZBJJT, sizeof(ZBJJT), "无");   
	else if(Zbshuc[Client] == 1)	    Format(ZBJJT, sizeof(ZBJJT), "铁头盔");
	else if(Zbshuc[Client] == 2)	    Format(ZBJJT, sizeof(ZBJJT), "铜头盔");
	else if(Zbshuc[Client] == 3)	    Format(ZBJJT, sizeof(ZBJJT), "铁护甲");
	else if(Zbshuc[Client] == 4)	    Format(ZBJJT, sizeof(ZBJJT), "铜护甲");
	else if(Zbshuc[Client] == 5)	    Format(ZBJJT, sizeof(ZBJJT), "铁鞋子");
	else if(Zbshuc[Client] == 6)	    Format(ZBJJT, sizeof(ZBJJT), "铜鞋子");
	else if(Zbshuc[Client] == 7)	    Format(ZBJJT, sizeof(ZBJJT), "铁裤子");
	else if(Zbshuc[Client] == 8)	    Format(ZBJJT, sizeof(ZBJJT), "铜裤子");
	else if(Zbshuc[Client] == 9)	    Format(ZBJJT, sizeof(ZBJJT), "重铁刃");
	else if(Zbshuc[Client] == 10)	    Format(ZBJJT, sizeof(ZBJJT), "青铜刃");
	
	decl String:ZBCCT[16];	   
	if(Zbshud[Client] == 0)			Format(ZBCCT, sizeof(ZBCCT), "无");   
	else if(Zbshud[Client] == 1)	    Format(ZBCCT, sizeof(ZBCCT), "铁头盔");
	else if(Zbshud[Client] == 2)	    Format(ZBCCT, sizeof(ZBCCT), "铜头盔");
	else if(Zbshud[Client] == 3)	    Format(ZBCCT, sizeof(ZBCCT), "铁护甲");
	else if(Zbshud[Client] == 4)	    Format(ZBCCT, sizeof(ZBCCT), "铜护甲");
	else if(Zbshud[Client] == 5)	    Format(ZBCCT, sizeof(ZBCCT), "铁鞋子");
	else if(Zbshud[Client] == 6)	    Format(ZBCCT, sizeof(ZBCCT), "铜鞋子");
	else if(Zbshud[Client] == 7)	    Format(ZBCCT, sizeof(ZBCCT), "铁裤子");
	else if(Zbshud[Client] == 8)	    Format(ZBCCT, sizeof(ZBCCT), "铜裤子");
	else if(Zbshud[Client] == 9)	    Format(ZBCCT, sizeof(ZBCCT), "重铁刃");
	else if(Zbshud[Client] == 10)	    Format(ZBCCT, sizeof(ZBCCT), "青铜刃");

	decl String:line[256];  
	Format(line, sizeof(line), "═══装备储存空间[穿戴装备]═══");    
	SetPanelTitle(menu, line);   
	Format(line, sizeof(line), "%s", ZBEET);    
	DrawPanelItem(menu, line);   
	Format(line, sizeof(line), "%s", ZBYYT);    
	DrawPanelItem(menu, line);	   	
	Format(line, sizeof(line), "%s", ZBXXT);    
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "%s", ZBJJT);    
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "%s", ZBCCT);    
	DrawPanelItem(menu, line);
	
	DrawPanelItem(menu, "返回装备选单");   
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);  
	
	SendPanelToClient(menu, Client, MenuHandler_Chucu, MENU_TIME_FOREVER);      	
	return Plugin_Handled;
}

public MenuHandler_Chucu(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
            case 1: OPZBCU(Client);
			case 2: OPZBCQ(Client);
			case 3: OPZBCA(Client);
			case 4: OPZBCZ(Client);
			case 5: OPZBCW(Client);
			case 6: MenuFunc_Zhuang(Client);				
		}
	}
}
public OPZBCU(Client)
{
	if (Zbshu[Client] > 0)
	{
		if (Zbshu[Client] == 1)    
		{		    
			Touke[Client] += 1;
			EpIntelligence[Client] += 10;			
		}		
		else if (Zbshu[Client] == 2)		
		{	    
			Touke[Client] += 2;
			EpIntelligence[Client] += 8;		
		}
		else if (Zbshu[Client] == 3)		
		{	    
			Jiake[Client] += 1;
			EpEndurance[Client] += 10;		
		}
		else if (Zbshu[Client] == 4)		
		{	    
			Jiake[Client] += 2;
			EpEndurance[Client] += 8;		
		}
		else if (Zbshu[Client] == 5)		
		{	    
			Xieke[Client] += 1;
			EpAgi[Client] += 10;		
		}
		else if (Zbshu[Client] == 6)		
		{	    
			Xieke[Client] += 2;
			EpAgi[Client] += 8;		
		}
		else if (Zbshu[Client] == 7)		
		{	    
			Kuke[Client] += 1;
			EpHealth[Client] += 10;		
		}
		else if (Zbshu[Client] == 8)		
		{	    
			Kuke[Client] += 2;
			EpHealth[Client] += 8;		
		}
		else if (Zbshu[Client] == 9)		
		{	    
			Wuqi[Client] += 1;
			EpStr[Client] += 10;		
		}
		else if (Zbshu[Client] == 10)		
		{	    
			Wuqi[Client] += 2;
			EpStr[Client] += 15;		
		}
		if (Touke[Client] == 1 && Jiake[Client] == 1 && Xieke[Client] == 1 && Kuke[Client] == 1 && Wuqi[Client] == 1)		
		{	    
			EpStr[Client] += 100;	    
			Zbming[Client] += 1;	
			CPrintToChatAll("【装备】玩家 %N 获得了钢铁套装!", Client);		
		}
		if (Touke[Client] == 2 && Jiake[Client] == 2 && Xieke[Client] == 2 && Kuke[Client] == 2 && Wuqi[Client] == 2)		
		{	    
			EpEndurance[Client] += 100;	    
			Zbming[Client] += 2;	
			CPrintToChatAll("【装备】玩家 %N 获得了青铜套装!", Client);		
		}
		Zbshu[Client] = 0;
		CPrintToChat(Client, "【提示】你穿戴了装备!");
	} else CPrintToChat(Client, "【提示】你没有任何的装备!");	
}
public OPZBCQ(Client)
{
	if (Zbshua[Client] > 0)
	{
		if (Zbshua[Client] == 1)    
		{		    
			Touke[Client] += 1;
			EpIntelligence[Client] += 10;			
		}		
		else if (Zbshua[Client] == 2)		
		{	    
			Touke[Client] += 2;
			EpIntelligence[Client] += 8;		
		}
		else if (Zbshua[Client] == 3)		
		{	    
			Jiake[Client] += 1;
			EpEndurance[Client] += 10;		
		}
		else if (Zbshua[Client] == 4)		
		{	    
			Jiake[Client] += 2;
			EpEndurance[Client] += 8;		
		}
		else if (Zbshua[Client] == 5)		
		{	    
			Xieke[Client] += 1;
			EpAgi[Client] += 10;		
		}
		else if (Zbshua[Client] == 6)		
		{	    
			Xieke[Client] += 2;
			EpAgi[Client] += 8;		
		}
		else if (Zbshua[Client] == 7)		
		{	    
			Kuke[Client] += 1;
			EpHealth[Client] += 10;		
		}
		else if (Zbshua[Client] == 8)		
		{	    
			Kuke[Client] += 2;
			EpHealth[Client] += 8;		
		}
		else if (Zbshua[Client] == 9)		
		{	    
			Wuqi[Client] += 1;
			EpStr[Client] += 10;		
		}
		else if (Zbshua[Client] == 10)		
		{	    
			Wuqi[Client] += 2;
			EpStr[Client] += 15;		
		}
		if (Touke[Client] == 1 && Jiake[Client] == 1 && Xieke[Client] == 1 && Kuke[Client] == 1 && Wuqi[Client] == 1)		
		{	    
			EpStr[Client] += 100;	    
			Zbming[Client] += 1;	
			CPrintToChatAll("【装备】玩家 %N 获得了钢铁套装!", Client);		
		}
		if (Touke[Client] == 2 && Jiake[Client] == 2 && Xieke[Client] == 2 && Kuke[Client] == 2 && Wuqi[Client] == 2)		
		{	    
			EpEndurance[Client] += 100;	    
			Zbming[Client] += 2;	
			CPrintToChatAll("【装备】玩家 %N 获得了青铜套装!", Client);		
		}
		Zbshua[Client] = 0;
		CPrintToChat(Client, "【提示】你穿戴了装备!");
	} else CPrintToChat(Client, "【提示】你没有任何的装备!");	
}
public OPZBCA(Client)
{
	if (Zbshub[Client] > 0)
	{
		if (Zbshub[Client] == 1)    
		{		    
			Touke[Client] += 1;
			EpIntelligence[Client] += 10;			
		}		
		else if (Zbshub[Client] == 2)		
		{	    
			Touke[Client] += 2;
			EpIntelligence[Client] += 8;		
		}
		else if (Zbshub[Client] == 3)		
		{	    
			Jiake[Client] += 1;
			EpEndurance[Client] += 10;		
		}
		else if (Zbshub[Client] == 4)		
		{	    
			Jiake[Client] += 2;
			EpEndurance[Client] += 8;		
		}
		else if (Zbshub[Client] == 5)		
		{	    
			Xieke[Client] += 1;
			EpAgi[Client] += 10;		
		}
		else if (Zbshub[Client] == 6)		
		{	    
			Xieke[Client] += 2;
			EpAgi[Client] += 8;		
		}
		else if (Zbshub[Client] == 7)		
		{	    
			Kuke[Client] += 1;
			EpHealth[Client] += 10;		
		}
		else if (Zbshub[Client] == 8)		
		{	    
			Kuke[Client] += 2;
			EpHealth[Client] += 8;		
		}
		else if (Zbshub[Client] == 9)		
		{	    
			Wuqi[Client] += 1;
			EpStr[Client] += 10;		
		}
		else if (Zbshub[Client] == 10)		
		{	    
			Wuqi[Client] += 2;
			EpStr[Client] += 15;		
		}
		if (Touke[Client] == 1 && Jiake[Client] == 1 && Xieke[Client] == 1 && Kuke[Client] == 1 && Wuqi[Client] == 1)		
		{	    
			EpStr[Client] += 100;	    
			Zbming[Client] += 1;	
			CPrintToChatAll("【装备】玩家 %N 获得了钢铁套装!", Client);		
		}
		if (Touke[Client] == 2 && Jiake[Client] == 2 && Xieke[Client] == 2 && Kuke[Client] == 2 && Wuqi[Client] == 2)		
		{	    
			EpEndurance[Client] += 100;	    
			Zbming[Client] += 2;	
			CPrintToChatAll("【装备】玩家 %N 获得了青铜套装!", Client);		
		}
		Zbshub[Client] = 0;
		CPrintToChat(Client, "【提示】你穿戴了装备!");
	} else CPrintToChat(Client, "【提示】你没有任何的装备!");	
}
public OPZBCZ(Client)
{
	if (Zbshuc[Client] > 0)
	{
		if (Zbshuc[Client] == 1)    
		{		    
			Touke[Client] += 1;
			EpIntelligence[Client] += 10;			
		}		
		else if (Zbshuc[Client] == 2)		
		{	    
			Touke[Client] += 2;
			EpIntelligence[Client] += 8;		
		}
		else if (Zbshuc[Client] == 3)		
		{	    
			Jiake[Client] += 1;
			EpEndurance[Client] += 10;		
		}
		else if (Zbshuc[Client] == 4)		
		{	    
			Jiake[Client] += 2;
			EpEndurance[Client] += 8;		
		}
		else if (Zbshuc[Client] == 5)		
		{	    
			Xieke[Client] += 1;
			EpAgi[Client] += 10;		
		}
		else if (Zbshuc[Client] == 6)		
		{	    
			Xieke[Client] += 2;
			EpAgi[Client] += 8;		
		}
		else if (Zbshuc[Client] == 7)		
		{	    
			Kuke[Client] += 1;
			EpHealth[Client] += 10;		
		}
		else if (Zbshuc[Client] == 8)		
		{	    
			Kuke[Client] += 2;
			EpHealth[Client] += 8;		
		}
		else if (Zbshuc[Client] == 9)		
		{	    
			Wuqi[Client] += 1;
			EpStr[Client] += 10;		
		}
		else if (Zbshuc[Client] == 10)		
		{	    
			Wuqi[Client] += 2;
			EpStr[Client] += 15;		
		}
		if (Touke[Client] == 1 && Jiake[Client] == 1 && Xieke[Client] == 1 && Kuke[Client] == 1 && Wuqi[Client] == 1)		
		{	    
			EpStr[Client] += 100;	    
			Zbming[Client] += 1;	
			CPrintToChatAll("【装备】玩家 %N 获得了钢铁套装!", Client);		
		}
		if (Touke[Client] == 2 && Jiake[Client] == 2 && Xieke[Client] == 2 && Kuke[Client] == 2 && Wuqi[Client] == 2)		
		{	    
			EpEndurance[Client] += 100;	    
			Zbming[Client] += 2;	
			CPrintToChatAll("【装备】玩家 %N 获得了青铜套装!", Client);		
		}
		Zbshuc[Client] = 0;
		CPrintToChat(Client, "【提示】你穿戴了装备!");
	} else CPrintToChat(Client, "【提示】你没有任何的装备!");	
}
public OPZBCW(Client)
{
	if (Zbshud[Client] > 0)
	{
		if (Zbshud[Client] == 1)    
		{		    
			Touke[Client] += 1;
			EpIntelligence[Client] += 10;			
		}		
		else if (Zbshud[Client] == 2)		
		{	    
			Touke[Client] += 2;
			EpIntelligence[Client] += 8;		
		}
		else if (Zbshud[Client] == 3)		
		{	    
			Jiake[Client] += 1;
			EpEndurance[Client] += 10;		
		}
		else if (Zbshud[Client] == 4)		
		{	    
			Jiake[Client] += 2;
			EpEndurance[Client] += 8;		
		}
		else if (Zbshud[Client] == 5)		
		{	    
			Xieke[Client] += 1;
			EpAgi[Client] += 10;		
		}
		else if (Zbshud[Client] == 6)		
		{	    
			Xieke[Client] += 2;
			EpAgi[Client] += 8;		
		}
		else if (Zbshud[Client] == 7)		
		{	    
			Kuke[Client] += 1;
			EpHealth[Client] += 10;		
		}
		else if (Zbshud[Client] == 8)		
		{	    
			Kuke[Client] += 2;
			EpHealth[Client] += 8;		
		}
		else if (Zbshud[Client] == 9)		
		{	    
			Wuqi[Client] += 1;
			EpStr[Client] += 10;		
		}
		else if (Zbshud[Client] == 10)		
		{	    
			Wuqi[Client] += 2;
			EpStr[Client] += 15;		
		}
		if (Touke[Client] == 1 && Jiake[Client] == 1 && Xieke[Client] == 1 && Kuke[Client] == 1 && Wuqi[Client] == 1)		
		{	    
			EpStr[Client] += 100;	    
			Zbming[Client] += 1;	
			CPrintToChatAll("【装备】玩家 %N 获得了钢铁套装!", Client);		
		}
		if (Touke[Client] == 2 && Jiake[Client] == 2 && Xieke[Client] == 2 && Kuke[Client] == 2 && Wuqi[Client] == 2)		
		{	    
			EpEndurance[Client] += 100;	    
			Zbming[Client] += 2;	
			CPrintToChatAll("【装备】玩家 %N 获得了青铜套装!", Client);		
		}
		Zbshud[Client] = 0;
		CPrintToChat(Client, "【提示】你穿戴了装备!");
	} else CPrintToChat(Client, "【提示】你没有任何的装备!");	
}

/* 装备查看菜单*/
public Action:MenuFunc_Chakan(Client)
{ 
	new Handle:menu = CreatePanel();
    	
	decl String:ZBEET[16];	   
	if(Touke[Client] == 0)			Format(ZBEET, sizeof(ZBEET), "无");   
	else if(Touke[Client] == 1)	    Format(ZBEET, sizeof(ZBEET), "铁头盔");
	else if(Touke[Client] == 2)	    Format(ZBEET, sizeof(ZBEET), "铜头盔");
	else if(Touke[Client] == 3)	    Format(ZBEET, sizeof(ZBEET), "新手头盔");
	   
	decl String:ZBXXT[16];	   
	if(Jiake[Client] == 0)			Format(ZBXXT, sizeof(ZBXXT), "无");   
	else if(Jiake[Client] == 1)	    Format(ZBXXT, sizeof(ZBXXT), "铁护甲");
	else if(Jiake[Client] == 2)	    Format(ZBXXT, sizeof(ZBXXT), "铜护甲");
	else if(Jiake[Client] == 3)	    Format(ZBXXT, sizeof(ZBXXT), "新手护甲");
   
	decl String:ZBNNT[16];	  
	if(Xieke[Client] == 0)			Format(ZBNNT, sizeof(ZBNNT), "无");  
	else if(Xieke[Client] == 1)	    Format(ZBNNT, sizeof(ZBNNT), "铁鞋子");
	else if(Xieke[Client] == 2)	    Format(ZBNNT, sizeof(ZBNNT), "铜鞋子");
	else if(Xieke[Client] == 3)	    Format(ZBNNT, sizeof(ZBNNT), "新手鞋子");
   
	decl String:ZBJJT[16];	  
	if(Kuke[Client] == 0)			Format(ZBJJT, sizeof(ZBJJT), "无"); 
	else if(Kuke[Client] == 1)	    Format(ZBJJT, sizeof(ZBJJT), "铁裤子");
	else if(Kuke[Client] == 2)	    Format(ZBJJT, sizeof(ZBJJT), "铜裤子");
	else if(Kuke[Client] == 3)	    Format(ZBJJT, sizeof(ZBJJT), "新手裤子");
   
	decl String:ZBCCT[16];	   
	if(Wuqi[Client] == 0)			Format(ZBCCT, sizeof(ZBCCT), "无");   
	else if(Wuqi[Client] == 1)	    Format(ZBCCT, sizeof(ZBCCT), "重铁刃");
	else if(Wuqi[Client] == 2)	    Format(ZBCCT, sizeof(ZBCCT), "青铜刃");
	else if(Wuqi[Client] == 3)	    Format(ZBCCT, sizeof(ZBCCT), "新手刃");
	
	decl String:line[256];  
	Format(line, sizeof(line), "═══拥有的特殊装备═══");    
	SetPanelTitle(menu, line);   
	Format(line, sizeof(line), "查看我的头盔: %s", ZBEET);    
	DrawPanelItem(menu, line);   
	Format(line, sizeof(line), "查看我的护甲: %s", ZBXXT);   
	DrawPanelItem(menu, line);   
	Format(line, sizeof(line), "查看我的鞋子: %s", ZBNNT);  
	DrawPanelItem(menu, line);   
	Format(line, sizeof(line), "查看我的裤子: %s", ZBJJT);  
	DrawPanelItem(menu, line);   
	Format(line, sizeof(line), "查看我的武器: %s", ZBCCT);   
	DrawPanelItem(menu, line);  
		   	
	DrawPanelItem(menu, "返回装备选单");   
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);  
	
	SendPanelToClient(menu, Client, MenuHandler_Chakan, MENU_TIME_FOREVER);      	
	return Plugin_Handled;
}

public MenuHandler_Chakan(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
            case 1: MenuFunc_Chash(Client);
			case 2: MenuFunc_Chasq(Client);
			case 3: MenuFunc_Chasa(Client);
			case 4: MenuFunc_Chasz(Client);
			case 5: MenuFunc_Chasw(Client);
			case 6: MenuFunc_Zhuang(Client);				
		}
	}
}

/* 装备出售菜单*/
public Action:MenuFunc_Chadiuq(Client)
{ 
	new Handle:menu = CreatePanel();
    	
	decl String:ZBEET[16];	   
	if(Touke[Client] == 0)			Format(ZBEET, sizeof(ZBEET), "无");   
	else if(Touke[Client] == 1)	    Format(ZBEET, sizeof(ZBEET), "铁头盔");
	else if(Touke[Client] == 2)	    Format(ZBEET, sizeof(ZBEET), "铜头盔");
	else if(Touke[Client] == 3)	    Format(ZBEET, sizeof(ZBEET), "新手头盔");
	   
	decl String:ZBXXT[16];	   
	if(Jiake[Client] == 0)			Format(ZBXXT, sizeof(ZBXXT), "无");   
	else if(Jiake[Client] == 1)	    Format(ZBXXT, sizeof(ZBXXT), "铁护甲");
	else if(Jiake[Client] == 2)	    Format(ZBXXT, sizeof(ZBXXT), "铜护甲");
	else if(Jiake[Client] == 3)	    Format(ZBXXT, sizeof(ZBXXT), "新手护甲");
   
	decl String:ZBNNT[16];	  
	if(Xieke[Client] == 0)			Format(ZBNNT, sizeof(ZBNNT), "无");  
	else if(Xieke[Client] == 1)	    Format(ZBNNT, sizeof(ZBNNT), "铁鞋子");
	else if(Xieke[Client] == 2)	    Format(ZBNNT, sizeof(ZBNNT), "铜鞋子");
	else if(Xieke[Client] == 3)	    Format(ZBNNT, sizeof(ZBNNT), "新手鞋子");
   
	decl String:ZBJJT[16];	  
	if(Kuke[Client] == 0)			Format(ZBJJT, sizeof(ZBJJT), "无"); 
	else if(Kuke[Client] == 1)	    Format(ZBJJT, sizeof(ZBJJT), "铁裤子");
	else if(Kuke[Client] == 2)	    Format(ZBJJT, sizeof(ZBJJT), "铜裤子");
	else if(Kuke[Client] == 3)	    Format(ZBJJT, sizeof(ZBJJT), "新手裤子");
   
	decl String:ZBCCT[16];	   
	if(Wuqi[Client] == 0)			Format(ZBCCT, sizeof(ZBCCT), "无");   
	else if(Wuqi[Client] == 1)	    Format(ZBCCT, sizeof(ZBCCT), "重铁刃");
	else if(Wuqi[Client] == 2)	    Format(ZBCCT, sizeof(ZBCCT), "青铜刃");
	else if(Wuqi[Client] == 3)	    Format(ZBCCT, sizeof(ZBCCT), "新手刃");
	
	decl String:line[256];  
	Format(line, sizeof(line), "═══拥有的特殊装备═══");    
	SetPanelTitle(menu, line);   
	Format(line, sizeof(line), "出售我的头盔: %s", ZBEET);    
	DrawPanelItem(menu, line);   
	Format(line, sizeof(line), "出售我的护甲: %s", ZBXXT);   
	DrawPanelItem(menu, line);   
	Format(line, sizeof(line), "出售我的鞋子: %s", ZBNNT);  
	DrawPanelItem(menu, line);   
	Format(line, sizeof(line), "出售我的裤子: %s", ZBJJT);  
	DrawPanelItem(menu, line);   
	Format(line, sizeof(line), "出售我的武器: %s", ZBCCT);   
	DrawPanelItem(menu, line);  
		   	
	DrawPanelItem(menu, "返回装备选单");   
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);  
	
	SendPanelToClient(menu, Client, MenuHandler_Chadiuq, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public MenuHandler_Chadiuq(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
            case 1: ZBDIUK(Client);
			case 2: ZBDIUQ(Client);
			case 3: ZBDIUA(Client);
			case 4: ZBDIUR(Client);
			case 5: ZBDIUY(Client);
			case 6: MenuFunc_Zhuang(Client);				
		}
	}
}
public ZBDIUK(Client)
{
	if (Touke[Client] > 0)
	{	    
		if (Touke[Client] == 1)	    
		{					    
			Touke[Client] = 0; 		    		    
			EpIntelligence[Client] -= 10;
			Cash[Client] += 5000; 		    
			CPrintToChat(Client, "{green}【装备】你出售了装备!获得5000$");       
		}
		else if (Touke[Client] == 2)	    
		{					    
			Touke[Client] = 0; 		    		    
			EpIntelligence[Client] -= 8;
			Cash[Client] += 5000; 		    
			CPrintToChat(Client, "{green}【装备】你出售了装备!获得5000$");       
		}
		else if (Touke[Client] == 3)	    
		{					    
			Touke[Client] = 0; 		    		    	    
			EpIntelligence[Client] -= 15;
			CPrintToChat(Client, "{green}【装备】你出售了新手装备!获得0$");       
		}
		if (Touke[Client] == 0 && Jiake[Client] == 1 && Xieke[Client] == 1 && Kuke[Client] == 1 && Wuqi[Client] == 1)		
		{	    
			EpStr[Client] -= 100;	    
			Zbming[Client] = 0;	
			CPrintToChatAll("【装备】玩家 %N 的钢铁套装属性消失了!", Client);		
		}
		if (Touke[Client] == 0 && Jiake[Client] == 2 && Xieke[Client] == 2 && Kuke[Client] == 2 && Wuqi[Client] == 2)		
		{	    
			EpEndurance[Client] -= 100;	    
			Zbming[Client] = 0;	
			CPrintToChatAll("【装备】玩家 %N 的青铜套装属性消失了!", Client);		
		}
		if (Touke[Client] == 0 && Jiake[Client] == 3 && Xieke[Client] == 3 && Kuke[Client] == 3 && Wuqi[Client] == 3)		
		{	    
			EpHealth[Client] -= 200;	    
			Zbming[Client] = 0;	
			CPrintToChatAll("【装备】玩家 %N 的新手套装属性消失了!", Client);		
		}
	} else CPrintToChat(Client, "{green}【提示】你没有可出售的装备");  	
}
public ZBDIUQ(Client)
{
	if (Jiake[Client] > 0)
	{	    
		if (Jiake[Client] == 1)	    
		{					    
			Jiake[Client] = 0; 		    		    
			EpEndurance[Client] -= 10;
			Cash[Client] += 5000; 		    
			CPrintToChat(Client, "{green}【装备】你出售了装备!获得5000$");       
		}
		else if (Jiake[Client] == 2)	    
		{					    
			Jiake[Client] = 0; 		    		    
			EpEndurance[Client] -= 8;
			Cash[Client] += 5000; 		    
			CPrintToChat(Client, "{green}【装备】你出售了装备!获得5000$");       
		}
		else if (Jiake[Client] == 3)	    
		{					    
			Jiake[Client] = 0; 		    		    	    
			EpEndurance[Client] -= 15;
			CPrintToChat(Client, "{green}【装备】你出售了新手装备!获得0$");       
		}
		if (Touke[Client] == 1 && Jiake[Client] == 0 && Xieke[Client] == 1 && Kuke[Client] == 1 && Wuqi[Client] == 1)		
		{	    
			EpStr[Client] -= 100;	    
			Zbming[Client] = 0;	
			CPrintToChatAll("【装备】玩家 %N 的钢铁套装属性消失了!", Client);		
		}
		if (Touke[Client] == 2 && Jiake[Client] == 0 && Xieke[Client] == 2 && Kuke[Client] == 2 && Wuqi[Client] == 2)		
		{	    
			EpEndurance[Client] -= 100;	    
			Zbming[Client] = 0;	
			CPrintToChatAll("【装备】玩家 %N 的青铜套装属性消失了!", Client);		
		}
		if (Touke[Client] == 3 && Jiake[Client] == 0 && Xieke[Client] == 3 && Kuke[Client] == 3 && Wuqi[Client] == 3)		
		{	    
			EpHealth[Client] -= 200;	    
			Zbming[Client] = 0;	
			CPrintToChatAll("【装备】玩家 %N 的新手套装属性消失了!", Client);		
		}
	} else CPrintToChat(Client, "{green}【提示】你没有可出售的装备");  	
}
public ZBDIUA(Client)
{
	if (Xieke[Client] > 0)
	{	    
		if (Xieke[Client] == 1)	    
		{					    
			Xieke[Client] = 0; 		    		    
			EpAgi[Client] -= 10;
			Cash[Client] += 5000; 		    
			CPrintToChat(Client, "{green}【装备】你出售了装备!获得5000$");       
		}
		else if (Xieke[Client] == 2)	    
		{					    
			Xieke[Client] = 0; 		    		    
			EpAgi[Client] -= 8;
			Cash[Client] += 5000; 		    
			CPrintToChat(Client, "{green}【装备】你出售了装备!获得5000$");       
		}
		else if (Xieke[Client] == 3)	    
		{					    
			Xieke[Client] = 0; 		    		    	    
			EpAgi[Client] -= 15;
			CPrintToChat(Client, "{green}【装备】你出售了新手装备!获得0$");       
		}
		if (Touke[Client] == 1 && Jiake[Client] == 1 && Xieke[Client] == 0 && Kuke[Client] == 1 && Wuqi[Client] == 1)		
		{	    
			EpStr[Client] -= 100;	    
			Zbming[Client] = 0;	
			CPrintToChatAll("【装备】玩家 %N 的钢铁套装属性消失了!", Client);		
		}
		if (Touke[Client] == 2 && Jiake[Client] == 2 && Xieke[Client] == 0 && Kuke[Client] == 2 && Wuqi[Client] == 2)		
		{	    
			EpEndurance[Client] -= 100;	    
			Zbming[Client] = 0;	
			CPrintToChatAll("【装备】玩家 %N 的青铜套装属性消失了!", Client);		
		}
		if (Touke[Client] == 3 && Jiake[Client] == 3 && Xieke[Client] == 0 && Kuke[Client] == 3 && Wuqi[Client] == 3)		
		{	    
			EpHealth[Client] -= 200;	    
			Zbming[Client] = 0;	
			CPrintToChatAll("【装备】玩家 %N 的新手套装属性消失了!", Client);		
		}
	} else CPrintToChat(Client, "{green}【提示】你没有可出售的装备");  	
}
public ZBDIUR(Client)
{
	if (Kuke[Client] > 0)
	{	    
		if (Kuke[Client] == 1)	    
		{					    
			Kuke[Client] = 0; 		    		    
			EpHealth[Client] -= 10;
			Cash[Client] += 5000; 		    
			CPrintToChat(Client, "{green}【装备】你出售了装备!获得5000$");       
		}
		else if (Kuke[Client] == 2)	    
		{					    
			Kuke[Client] = 0; 		    		    
			EpHealth[Client] -= 8;
			Cash[Client] += 5000; 		    
			CPrintToChat(Client, "{green}【装备】你出售了装备!获得5000$");       
		}
		else if (Kuke[Client] == 3)	    
		{					    
			Kuke[Client] = 0; 		    		    	    
			EpHealth[Client] -= 15;
			CPrintToChat(Client, "{green}【装备】你出售了新手装备!获得0$");       
		}
		if (Touke[Client] == 1 && Jiake[Client] == 1 && Xieke[Client] == 1 && Kuke[Client] == 0 && Wuqi[Client] == 1)		
		{	    
			EpStr[Client] -= 100;	    
			Zbming[Client] = 0;	
			CPrintToChatAll("【装备】玩家 %N 的钢铁套装属性消失了!", Client);		
		}
		if (Touke[Client] == 2 && Jiake[Client] == 2 && Xieke[Client] == 2 && Kuke[Client] == 0 && Wuqi[Client] == 2)		
		{	    
			EpEndurance[Client] -= 100;	    
			Zbming[Client] = 0;	
			CPrintToChatAll("【装备】玩家 %N 的青铜套装属性消失了!", Client);		
		}
		if (Touke[Client] == 3 && Jiake[Client] == 3 && Xieke[Client] == 3 && Kuke[Client] == 0 && Wuqi[Client] == 3)		
		{	    
			EpHealth[Client] -= 200;	    
			Zbming[Client] = 0;	
			CPrintToChatAll("【装备】玩家 %N 的新手套装属性消失了!", Client);		
		}
	} else CPrintToChat(Client, "{green}【提示】你没有可出售的装备");  	
}
public ZBDIUY(Client)
{
	if (Wuqi[Client] > 0)
	{	    
		if (Wuqi[Client] == 1)	    
		{				    
			Wuqi[Client] = 0; 		    		    
			EpStr[Client] -= 10;
			Cash[Client] += 5000; 		    
			CPrintToChat(Client, "{green}【装备】你出售了装备!获得5000$");       
		}
		else if (Wuqi[Client] == 2)	    
		{					    
			Wuqi[Client] = 0; 		    		    
			EpStr[Client] -= 15;
			Cash[Client] += 5000; 		    
			CPrintToChat(Client, "{green}【装备】你出售了装备!获得5000$");       
		}
		else if (Wuqi[Client] == 3)	    
		{					    
			Wuqi[Client] = 0; 		    		    	    
			EpStr[Client] -= 15;
			CPrintToChat(Client, "{green}【装备】你出售了新手装备!获得0$");       
		}
		if (Touke[Client] == 1 && Jiake[Client] == 1 && Xieke[Client] == 1 && Kuke[Client] == 1 && Wuqi[Client] == 0)		
		{	    
			EpStr[Client] -= 100;	    
			Zbming[Client] = 0;	
			CPrintToChatAll("【装备】玩家 %N 的钢铁套装属性消失了!", Client);		
		}
		if (Touke[Client] == 2 && Jiake[Client] == 2 && Xieke[Client] == 2 && Kuke[Client] == 2 && Wuqi[Client] == 0)		
		{	    
			EpEndurance[Client] -= 100;	    
			Zbming[Client] = 0;	
			CPrintToChatAll("【装备】玩家 %N 的青铜套装属性消失了!", Client);		
		}
		if (Touke[Client] == 3 && Jiake[Client] == 3 && Xieke[Client] == 3 && Kuke[Client] == 3 && Wuqi[Client] == 0)		
		{	    
			EpHealth[Client] -= 200;	    
			Zbming[Client] = 0;	
			CPrintToChatAll("【装备】玩家 %N 的新手套装属性消失了!", Client);		
		}
	} else CPrintToChat(Client, "{green}【提示】你没有可出售的装备");  	
}

/* 头盔介绍说明 */
public Action:MenuFunc_Chash(Client)
{
	new Handle:menu = CreatePanel();
	   
	decl String:line[2024];   
	if(Touke[Client] == 1)
	{   
		Format(line, sizeof(line), "═══铁头盔[属性: 智力+10]═══");      
		SetPanelTitle(menu, line);      
		Format(line, sizeof(line), "介绍: 钢铁所打造的装备");      
		DrawPanelText(menu, line);	
		Format(line, sizeof(line), "所属套装[钢铁套装]");      
		DrawPanelText(menu, line);   
	}
	else if(Touke[Client] == 2)
	{   
		Format(line, sizeof(line), "═══铜头盔[属性: 智力+8]═══");      
		SetPanelTitle(menu, line);      
		Format(line, sizeof(line), "介绍: 青铜所打造的装备");      
		DrawPanelText(menu, line);	
		Format(line, sizeof(line), "所属套装[青铜套装]");      
		DrawPanelText(menu, line);   
	}
	else if(Touke[Client] == 3)
	{   
		Format(line, sizeof(line), "═══新手头盔[属性: 智力+15]═══");      
		SetPanelTitle(menu, line);      
		Format(line, sizeof(line), "介绍: 新手专用的装备");      
		DrawPanelText(menu, line);	
		Format(line, sizeof(line), "所属套装[新手套装]");      
		DrawPanelText(menu, line);   
	}
    
	
	DrawPanelItem(menu, "返回特殊装备菜单");  
	DrawPanelItem(menu, "放弃", ITEMDRAW_DISABLED);    
	SendPanelToClient(menu, Client, MenuHandler_Chasq, MENU_TIME_FOREVER);  
	return Plugin_Handled;
}

public MenuHandler_Chash(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) 
	{
		switch (param)
		{
            case 1: MenuFunc_Zhuang(Client);			
		}
	}
}

/* 护甲介绍说明 */
public Action:MenuFunc_Chasq(Client)
{  
	new Handle:menu = CreatePanel();
	   
	decl String:line[2024];   
	if(Jiake[Client] == 1)
	{   
		Format(line, sizeof(line), "═══铁护甲[属性: 耐力+10]═══");      
		SetPanelTitle(menu, line);      
		Format(line, sizeof(line), "介绍: 钢铁所打造的装备");      
		DrawPanelText(menu, line);	
		Format(line, sizeof(line), "所属套装[钢铁套装]");      
		DrawPanelText(menu, line);   
	}
	else if(Jiake[Client] == 2)
	{	    
		Format(line, sizeof(line), "═══铜护甲[属性: 耐力+8]═══");      
		SetPanelTitle(menu, line);      
		Format(line, sizeof(line), "介绍: 青铜所打造的装备");      
		DrawPanelText(menu, line);	
		Format(line, sizeof(line), "所属套装[青铜套装]");      
		DrawPanelText(menu, line);    
	}
	else if(Jiake[Client] == 3)
	{	    
		Format(line, sizeof(line), "═══新手护甲[属性: 耐力+15]═══");      
		SetPanelTitle(menu, line);      
		Format(line, sizeof(line), "介绍: 新手专用的装备");      
		DrawPanelText(menu, line);	
		Format(line, sizeof(line), "所属套装[新手套装]");      
		DrawPanelText(menu, line);    
	}
    	
	DrawPanelItem(menu, "返回特殊装备菜单");   
	DrawPanelItem(menu, "放弃", ITEMDRAW_DISABLED);   
	SendPanelToClient(menu, Client, MenuHandler_Chasq, MENU_TIME_FOREVER);  
	return Plugin_Handled;
}

public MenuHandler_Chasq(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) 
	{
		switch (param)
		{
            case 1: MenuFunc_Zhuang(Client);			
		}
	}
}

/* 鞋子介绍说明 */
public Action:MenuFunc_Chasa(Client)
{   
	new Handle:menu = CreatePanel();
	   
	decl String:line[2024];   
	if(Xieke[Client] == 1)
	{   
		Format(line, sizeof(line), "═══铁鞋子[属性: 敏捷+10]═══");      
		SetPanelTitle(menu, line);      
		Format(line, sizeof(line), "介绍: 钢铁所打造的装备");      
		DrawPanelText(menu, line);	
		Format(line, sizeof(line), "所属套装[钢铁套装]");      
		DrawPanelText(menu, line);   
	}
	else if(Xieke[Client] == 2)
	{	    
		Format(line, sizeof(line), "═══铜鞋子[属性: 敏捷+8]═══");      
		SetPanelTitle(menu, line);      
		Format(line, sizeof(line), "介绍: 青铜所打造的装备");      
		DrawPanelText(menu, line);	
		Format(line, sizeof(line), "所属套装[青铜套装]");      
		DrawPanelText(menu, line);   
	}
	else if(Xieke[Client] == 3)
	{	    
		Format(line, sizeof(line), "═══新手鞋子[属性: 敏捷+15]═══");      
		SetPanelTitle(menu, line);      
		Format(line, sizeof(line), "介绍: 新手专用的装备");      
		DrawPanelText(menu, line);	
		Format(line, sizeof(line), "所属套装[新手套装]");      
		DrawPanelText(menu, line);   
	}
    	
	DrawPanelItem(menu, "返回特殊装备菜单");   
	DrawPanelItem(menu, "放弃", ITEMDRAW_DISABLED);  
	SendPanelToClient(menu, Client, MenuHandler_Chasa, MENU_TIME_FOREVER);  
	return Plugin_Handled;
}

public MenuHandler_Chasa(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) 
	{
		switch (param)
		{
            case 1: MenuFunc_Zhuang(Client);			
		}
	}
}

/* 裤子介绍说明 */
public Action:MenuFunc_Chasz(Client)
{   
	new Handle:menu = CreatePanel();
	   
	decl String:line[2024];   
	if(Kuke[Client] == 1)
	{   
		Format(line, sizeof(line), "═══铁裤子[属性: 生命+10]═══");      
		SetPanelTitle(menu, line);      
		Format(line, sizeof(line), "介绍: 钢铁所打造的装备");      
		DrawPanelText(menu, line);	
		Format(line, sizeof(line), "所属套装[钢铁套装]");      
		DrawPanelText(menu, line);   
	}
	else if(Kuke[Client] == 2)	
	{	    
		Format(line, sizeof(line), "═══铜裤子[属性: 生命+8]═══");      
		SetPanelTitle(menu, line);      
		Format(line, sizeof(line), "介绍: 青铜所打造的装备");      
		DrawPanelText(menu, line);	
		Format(line, sizeof(line), "所属套装[青铜套装]");      
		DrawPanelText(menu, line);    
	}
	else if(Kuke[Client] == 3)	
	{	    
		Format(line, sizeof(line), "═══新手裤子[属性: 生命+15]═══");      
		SetPanelTitle(menu, line);      
		Format(line, sizeof(line), "介绍: 新手专用的装备");      
		DrawPanelText(menu, line);	
		Format(line, sizeof(line), "所属套装[新手套装]");      
		DrawPanelText(menu, line);    
	}
    	
	DrawPanelItem(menu, "返回特殊装备菜单");   
	DrawPanelItem(menu, "放弃", ITEMDRAW_DISABLED);   
	SendPanelToClient(menu, Client, MenuHandler_Chasz, MENU_TIME_FOREVER);   
	return Plugin_Handled;
}

public MenuHandler_Chasz(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) 
	{
		switch (param)
		{
            case 1: MenuFunc_Zhuang(Client);			
		}
	}
}

/* 武器介绍说明 */
public Action:MenuFunc_Chasw(Client)
{    
	new Handle:menu = CreatePanel();
	    
	decl String:line[2024];    
	if(Wuqi[Client] == 1)
	{   
		Format(line, sizeof(line), "═══重铁刃[属性: 力量+10]═══");      
		SetPanelTitle(menu, line);      
		Format(line, sizeof(line), "介绍: 钢铁所打造的装备");      
		DrawPanelText(menu, line);	
		Format(line, sizeof(line), "所属套装[钢铁套装]");      
		DrawPanelText(menu, line);   
	}
	else if(Wuqi[Client] == 2)	
	{	    
		Format(line, sizeof(line), "═══青铜刃[属性: 力量+15]═══");      
		SetPanelTitle(menu, line);      
		Format(line, sizeof(line), "介绍: 青铜所打造的装备");      
		DrawPanelText(menu, line);	
		Format(line, sizeof(line), "所属套装[青铜套装]");      
		DrawPanelText(menu, line);   
	}
	else if(Wuqi[Client] == 3)	
	{	    
		Format(line, sizeof(line), "═══新手刃[属性: 力量+15]═══");      
		SetPanelTitle(menu, line);      
		Format(line, sizeof(line), "介绍: 新手专用的装备");      
		DrawPanelText(menu, line);	
		Format(line, sizeof(line), "所属套装[新手套装]");      
		DrawPanelText(menu, line);   
	}
    	
	DrawPanelItem(menu, "返回特殊装备菜单");   
	DrawPanelItem(menu, "放弃", ITEMDRAW_DISABLED); 
	SendPanelToClient(menu, Client, MenuHandler_Chasw, MENU_TIME_FOREVER);  
	return Plugin_Handled;
}

public MenuHandler_Chasw(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) 
	{
		switch (param)
		{
            case 1: MenuFunc_Zhuang(Client);			
		}
	}
}