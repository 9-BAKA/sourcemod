/************************************************************************
*	套装装备相关代码
************************************************************************/

/* 装备变量 */
new EpStr[MAXPLAYERS+1]; //力量
new EpAgi[MAXPLAYERS+1]; //敏捷
new EpHealth[MAXPLAYERS+1]; //生命
new EpEndurance[MAXPLAYERS+1]; //耐力
new EpIntelligence[MAXPLAYERS+1]; //智力

new Touke[MAXPLAYERS+1]; //头盔
new Jiake[MAXPLAYERS+1]; //护甲
new Xieke[MAXPLAYERS+1]; //鞋子
new Kuke[MAXPLAYERS+1]; //裤子
new Wuqi[MAXPLAYERS+1]; //武器
#define JBC[%1] JD[%1]	

//吸灵套装相关
new EpStrdan[MAXPLAYERS+1]; //弹药专家技能伤害
new Xizlv[MAXPLAYERS+1]; //吸灵套装等级

//装备属性增加and技能
public Zbtouke(Client)
{
	if (Touke[Client] == 1)
	{
		EpHealth[Client] += 10;	    
		EpEndurance[Client] += 10;
	}
}
public Zbjiake(Client)
{
	if (Jiake[Client] == 1)
	{   
		EpStr[Client] += 100;
		EpEndurance[Client] += 50;
	}
}
public Zbxieke(Client)
{
	if (Xieke[Client] == 1)
	{   
		EpStr[Client] += 15;
	}
}
public Zbkuke(Client)
{
	if (Kuke[Client] == 1)
	{   
		EpHealth[Client] += 50;
	}
}
public Zbwuqi(Client)
{
	if (Wuqi[Client] == 1)
	{   
		EpStr[Client] += 100;
	}
}
public Zbtaozb(Client)
{
	if (Touke[Client] == 1 && Jiake[Client] == 1 && Xieke[Client] == 1 && Kuke[Client] == 1 && Wuqi[Client] == 1)
	{   		
		if (Xizlv[Client] >= 1)    
		{		    
			EpStrdan[Client] += 10*Xizlv[Client];		    
			EpStr[Client] += 10*Xizlv[Client];	    		    
			EpAgi[Client] += 10*Xizlv[Client];	    		    
			EpHealth[Client] += 10*Xizlv[Client];	    		    
			EpEndurance[Client] += 10*Xizlv[Client];	    		    
			EpIntelligence[Client] += 10*Xizlv[Client];    
		} 		
		else		
		{		    
			EpStrdan[Client] += 10;		    
			EpStr[Client] += 10;	    	    
			EpAgi[Client] += 10;	    		    
			EpHealth[Client] += 10;	    	    
			EpEndurance[Client] += 10;	    		    
			EpIntelligence[Client] += 10;	
		}
	}
}
public Pandushu(Client)
{
	if (Touke[Client] == 1 && Jiake[Client] == 1 && Xieke[Client] == 1 && Kuke[Client] == 1 && Wuqi[Client] == 1)
	{   		
		StatusPoint[Client]++;
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
    
	decl String:ZBEET[1024];	   
	if(Touke[Client] == 0)			Format(ZBEET, sizeof(ZBEET), "无");   
	else if(Touke[Client] == 1)	    Format(ZBEET, sizeof(ZBEET), "吸灵头盔");
	   
	decl String:ZBXXT[1024];	   
	if(Jiake[Client] == 0)			Format(ZBXXT, sizeof(ZBXXT), "无");   
	else if(Jiake[Client] == 1)	    Format(ZBXXT, sizeof(ZBXXT), "吸灵护甲");
   
	decl String:ZBNNT[1024];	  
	if(Xieke[Client] == 0)			Format(ZBNNT, sizeof(ZBNNT), "无");  
	else if(Xieke[Client] == 1)	    Format(ZBNNT, sizeof(ZBNNT), "吸灵鞋子");
   
	decl String:ZBJJT[1024];	  
	if(Kuke[Client] == 0)			Format(ZBJJT, sizeof(ZBJJT), "无"); 
	else if(Kuke[Client] == 1)	    Format(ZBJJT, sizeof(ZBJJT), "吸灵裤子");
   
	decl String:ZBCCT[1024];	   
	if(Wuqi[Client] == 0)			Format(ZBCCT, sizeof(ZBCCT), "无");   
	else if(Wuqi[Client] == 1)	    Format(ZBCCT, sizeof(ZBCCT), "吸灵枪");
	  
	decl String:line[256];   
	Format(line, sizeof(line),    
	"═══我的特殊装备═══ \n 头盔:%s \n 护甲:%s \n 鞋子:%s \n 裤子:%s \n 武器:%s", ZBEET, ZBXXT, ZBNNT, ZBJJT, ZBCCT);    
	SetPanelTitle(menu, line);	
	if(JBC[Client] == 6)
	{    
		if(Touke[Client] == 1 && Jiake[Client] == 1 && Xieke[Client] == 1 && Kuke[Client] == 1 && Wuqi[Client] == 1)	    
		{        
			Format(line, sizeof(line),           
			"═══我的特殊装备[吸灵套装 LV.%d]═══ \n 头盔:%s \n 护甲:%s \n 鞋子:%s \n 裤子:%s \n 武器:%s", Xizlv[Client], ZBEET, ZBXXT, ZBNNT, ZBJJT, ZBCCT);           
			SetPanelTitle(menu, line);    
		}
	}
	   
	Format(line, sizeof(line), "查看装备");  
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "装备功能");  
	DrawPanelItem(menu, line);   
	Format(line, sizeof(line), "装备储存格子");  
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
            case 2: MenuFunc_Ghuang(Client);
			case 3: MenuFunc_RPG(Client);				
		}
	}
}

/* 装备显示菜单*/
public Action:MenuFunc_Ghuang(Client)
{ 
	new Handle:menu = CreatePanel();
    
	  
	decl String:line[256];   
	Format(line, sizeof(line), "═══我的特殊装备功能═══");    
	SetPanelTitle(menu, line);	
	   
	Format(line, sizeof(line), "丢弃装备");  
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "卸下装备");  
	DrawPanelItem(menu, line);   
	Format(line, sizeof(line), "出售装备");  
	DrawPanelItem(menu, line);
	DrawPanelItem(menu, "返回RPG选单");   
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
    
	SendPanelToClient(menu, Client, MenuHandler_Ghuang, MENU_TIME_FOREVER);     
	return Plugin_Handled;
}

public MenuHandler_Ghuang(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
            case 1: MenuFunc_Chadiuq(Client);
            case 2: MenuFunc_Xiadiuq(Client);
			case 3: MenuFunc_Xiadiuq(Client);
			case 4: MenuFunc_RPG(Client);				
		}
	}
}

/* 装备查看菜单*/
public Action:MenuFunc_Chakan(Client)
{ 
	new Handle:menu = CreatePanel();
    	
	decl String:ZBEET[1024];	   
	if(Touke[Client] == 0)			Format(ZBEET, sizeof(ZBEET), "无");   
	else if(Touke[Client] == 1)	    Format(ZBEET, sizeof(ZBEET), "吸灵头盔");
	   
	decl String:ZBXXT[1024];	   
	if(Jiake[Client] == 0)			Format(ZBXXT, sizeof(ZBXXT), "无");   
	else if(Jiake[Client] == 1)	    Format(ZBXXT, sizeof(ZBXXT), "吸灵护甲");
   
	decl String:ZBNNT[1024];	  
	if(Xieke[Client] == 0)			Format(ZBNNT, sizeof(ZBNNT), "无");  
	else if(Xieke[Client] == 1)	    Format(ZBNNT, sizeof(ZBNNT), "吸灵鞋子");
   
	decl String:ZBJJT[1024];	  
	if(Kuke[Client] == 0)			Format(ZBJJT, sizeof(ZBJJT), "无"); 
	else if(Kuke[Client] == 1)	    Format(ZBJJT, sizeof(ZBJJT), "吸灵裤子");
   
	decl String:ZBCCT[1024];	   
	if(Wuqi[Client] == 0)			Format(ZBCCT, sizeof(ZBCCT), "无");   
	else if(Wuqi[Client] == 1)	    Format(ZBCCT, sizeof(ZBCCT), "吸灵枪");
	
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

/* 装备丢弃菜单*/
public Action:MenuFunc_Chadiuq(Client)
{ 
	new Handle:menu = CreatePanel();
    	
	decl String:ZBEET[1024];	   
	if(Touke[Client] == 0)			Format(ZBEET, sizeof(ZBEET), "无");   
	else if(Touke[Client] == 1)	    Format(ZBEET, sizeof(ZBEET), "吸灵头盔");
	   
	decl String:ZBXXT[1024];	   
	if(Jiake[Client] == 0)			Format(ZBXXT, sizeof(ZBXXT), "无");   
	else if(Jiake[Client] == 1)	    Format(ZBXXT, sizeof(ZBXXT), "吸灵护甲");
   
	decl String:ZBNNT[1024];	  
	if(Xieke[Client] == 0)			Format(ZBNNT, sizeof(ZBNNT), "无");  
	else if(Xieke[Client] == 1)	    Format(ZBNNT, sizeof(ZBNNT), "吸灵鞋子");
   
	decl String:ZBJJT[1024];	  
	if(Kuke[Client] == 0)			Format(ZBJJT, sizeof(ZBJJT), "无"); 
	else if(Kuke[Client] == 1)	    Format(ZBJJT, sizeof(ZBJJT), "吸灵裤子");
   
	decl String:ZBCCT[1024];	   
	if(Wuqi[Client] == 0)			Format(ZBCCT, sizeof(ZBCCT), "无");   
	else if(Wuqi[Client] == 1)	    Format(ZBCCT, sizeof(ZBCCT), "吸灵枪");
	
	decl String:line[256];  
	Format(line, sizeof(line), "═══拥有的特殊装备═══");    
	SetPanelTitle(menu, line);   
	Format(line, sizeof(line), "丢弃我的头盔: %s", ZBEET);    
	DrawPanelItem(menu, line);   
	Format(line, sizeof(line), "丢弃我的护甲: %s", ZBXXT);   
	DrawPanelItem(menu, line);   
	Format(line, sizeof(line), "丢弃我的鞋子: %s", ZBNNT);  
	DrawPanelItem(menu, line);   
	Format(line, sizeof(line), "丢弃我的裤子: %s", ZBJJT);  
	DrawPanelItem(menu, line);   
	Format(line, sizeof(line), "丢弃我的武器: %s", ZBCCT);   
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
	if (Touke[Client] == 1)
	{
		Touke[Client] = 0;
		EpHealth[Client] -= 10;	    
		EpEndurance[Client] -= 10;
		CPrintToChat(Client, "{green}【装备】你丢弃了吸灵头盔!"); 
	}
}
public ZBDIUQ(Client)
{
	if (Jiake[Client] == 1)
	{   
		Jiake[Client] = 0;
		EpStr[Client] -= 100;
		EpEndurance[Client] -= 50;
		CPrintToChat(Client, "{green}【装备】你丢弃了吸灵护甲!"); 
	}
}
public ZBDIUA(Client)
{
	if (Xieke[Client] == 1)
	{   
		Xieke[Client] = 0;
		EpStr[Client] -= 15;
		CPrintToChat(Client, "{green}【装备】你丢弃了吸灵鞋子!"); 
	}
}
public ZBDIUR(Client)
{
	if (Kuke[Client] == 1)
	{   
		Kuke[Client] = 0;
		EpHealth[Client] -= 50;
		CPrintToChat(Client, "{green}【装备】你丢弃了吸灵裤子!"); 
	}
}
public ZBDIUY(Client)
{
	if (Wuqi[Client] == 1)
	{   
		Wuqi[Client] = 0;
		EpStr[Client] -= 100;
		CPrintToChat(Client, "{green}【装备】你丢弃了吸灵枪!"); 
	}
}

/* 头盔介绍说明 */
public Action:MenuFunc_Chash(Client)
{
	new Handle:menu = CreatePanel();
	   
	decl String:line[2024];   
	if(Touke[Client] == 1)
	{   
		Format(line, sizeof(line), "═══吸灵头盔[属性: 生命+10 耐力+10 特殊效果: 每秒自动恢复1点生命值]═══");      
		SetPanelTitle(menu, line);      
		Format(line, sizeof(line), "介绍: 传说在遥远的未来, 丧尸暴虐~科学家研究出了一种专门对抗僵尸的套装, 拥有强大的战力, 由于时空的干扰, 被传送到了现在");      
		DrawPanelText(menu, line);	
		Format(line, sizeof(line), "所属套装[吸灵套装] ☆未来战士专属☆");      
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
		Format(line, sizeof(line), "═══吸灵护甲[属性: 力量+100 耐力+50 特殊效果: 被敌人攻击是时时吸取80%的伤害转化成自身生命值]═══");       
		SetPanelTitle(menu, line);       
		Format(line, sizeof(line), "介绍: 传说在遥远的未来, 丧尸暴虐~科学家研究出了一种专门对抗僵尸的套装, 拥有强大的战力, 由于时空的干扰, 被传送到了现在");       
		DrawPanelText(menu, line);		
		Format(line, sizeof(line), "所属套装[吸灵套装] ☆未来战士专属☆");       
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
		Format(line, sizeof(line), "═══吸灵鞋子[属性: 力量+15 特殊效果: 移动速度增加10%]═══");       
		SetPanelTitle(menu, line);       
		Format(line, sizeof(line), "介绍: 传说在遥远的未来, 丧尸暴虐~科学家研究出了一种专门对抗僵尸的套装, 拥有强大的战力, 由于时空的干扰, 被传送到了现在");       
		DrawPanelText(menu, line);		
		Format(line, sizeof(line), "所属套装[吸灵套装] ☆未来战士专属☆");       
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
		Format(line, sizeof(line), "═══吸灵裤子[属性: 生命+50 特殊效果: 增加增加100生命上限]═══");       
		SetPanelTitle(menu, line);      
		Format(line, sizeof(line), "介绍: 传说在遥远的未来, 丧尸暴虐~科学家研究出了一种专门对抗僵尸的套装, 拥有强大的战力, 由于时空的干扰, 被传送到了现在");      
		DrawPanelText(menu, line);	
		Format(line, sizeof(line), "所属套装[吸灵套装] ☆未来战士专属☆");     
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
		Format(line, sizeof(line), "═══吸灵枪[属性: 力量+100  特殊效果: 攻击敌人时吸取10%的伤害转化成自身生命值]═══");       
		SetPanelTitle(menu, line);       
		Format(line, sizeof(line), "介绍: 传说在遥远的未来, 丧尸暴虐~科学家研究出了一种专门对抗僵尸的套装, 拥有强大的战力, 由于时空的干扰, 被传送到了现在");       
		DrawPanelText(menu, line);	
		Format(line, sizeof(line), "所属套装[吸灵套装] ☆未来战士专属☆");      
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