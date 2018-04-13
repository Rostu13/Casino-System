#include <sourcemod>
#include <shop>
#include <morecolors>
#include <casino_system>
#pragma semicolon 1

int g_CheckChatMoney[MAXPLAYERS+1];
int g_MoneyClient[MAXPLAYERS+1];
char g_FlipCoin[MAXPLAYERS+1][1024];
int TargetSaveClient[MAXPLAYERS+1];
int TargetFlipSilver[MAXPLAYERS+1];
int g_FlipCoinTarget[MAXPLAYERS+1];
int g_MoneyItem[MAXPLAYERS+1];
char TargetFlip[65][65];
char TargetFlip1[65][65];
int g_TMoney[MAXPLAYERS+1];
int g_CheckMoneyGame[MAXPLAYERS+1];
int g_BlockClientGame[MAXPLAYERS+1];
int g_BlockTargetGame[MAXPLAYERS+1];
int FlipTime;
int FlipOffers;
float FlipBlockOffers;
int g_ChangeWrite;
int g_MaxFlipCredits;
int g_MinFlipCredits;
int g_Game;
float g_Percent;

public Plugin:myinfo = 
{
	name		= "[Shop] FlipGame",
	author		= "FLASHER",
	description	= "FlipGame For Shop Core",
	version		= "1.3",
	url			= "skype: flshr328"
};

public OnPluginStart ()
{
	RegConsoleCmd ("sm_flip", flipgame);
	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say, "say_team");
	//if (Shop_IsStarted()) Shop_Started();
	ConVar cvar;
	
	(cvar = CreateConVar("flip_time", "10",	"Время, через которое будет проведена игра между игроками", _, true, 1.0)).AddChangeHook(ChangeCvar_FlipTime);
	FlipTime = cvar.IntValue;
	(cvar = CreateConVar("flip_allowoffers", "1",	"Разрешить ли возможность отключать игрокам приглашения [1 - разрешено | 0 - запрещено]", _, true, 0.0, true, 1.0)).AddChangeHook(ChangeCvar_FlipOffers);
	FlipOffers = cvar.IntValue;
	(cvar = CreateConVar("flip_blocktime", "10.0",	"Сколько секунд запрещать повторное приглашение", _, true, 1.0)).AddChangeHook(ChangeCvar_FlipBlockOffers);
	FlipBlockOffers = cvar.FloatValue;
	(cvar = CreateConVar("flip_changewrite", "1",	"Тип вывода сообщения об игре [1 - HUD | 2 - Чат]", _, true, 1.0, true, 2.0)).AddChangeHook(ChangeCvar_g_ChangeWrite);
	g_ChangeWrite = cvar.IntValue;
	(cvar = CreateConVar("flip_maxcredits", "0",	"Максимум фишек для ставки [0 - без ограничений]", _, true, 0.0)).AddChangeHook(ChangeCvar_g_MaxFlipCredits);
	g_MaxFlipCredits = cvar.IntValue;
	(cvar = CreateConVar("flip_mincredits", "0",	"Минимум фишек для ставки", _, true, 0.0)).AddChangeHook(ChangeCvar_g_MinFlipCredits);
	g_MinFlipCredits = cvar.IntValue;
	(cvar = CreateConVar("flip_game", "0",	"Игра [CS:GO - 0 | CSS v89 - 1]", _, true, 0.0, true, 1.0)).AddChangeHook(ChangeCvar_g_Game);
	g_Game = cvar.IntValue;
	(cvar = CreateConVar("flip_percent", "0.0",	"Комиссия, которая будет взиматься с выигрыша (В процентах) [0 - нет комиссии]", _, true, 0.0, true, 49.0)).AddChangeHook(ChangeCvar_g_Percent);
	g_Percent = cvar.FloatValue;
	AutoExecConfig(true, "shop_flipgame", "shop");
}
public void Casino_GameOnMenuCreate (Menu menu, int iType, int iClient)
{
	if( iType == Game_Multiplayer )	
	{
		menu.AddItem("flip","Монетка");
	}
}
public void Casino_GameOnMenuChoose (int iClient, char[] sName)
{
	if( strcmp (sName,"flip") == 0)	MoneyGameMenu(iClient);
}
public void ChangeCvar_FlipTime(ConVar convar, const char[] oldValue, const char[] newValue)
{
	FlipTime = convar.IntValue;
}
public void ChangeCvar_FlipOffers(ConVar convar, const char[] oldValue, const char[] newValue)
{
	FlipOffers = convar.IntValue;
}
public void ChangeCvar_FlipBlockOffers(ConVar convar, const char[] oldValue, const char[] newValue)
{
	FlipBlockOffers = convar.FloatValue;
}
public void ChangeCvar_g_ChangeWrite(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_ChangeWrite = convar.IntValue;
}
public void ChangeCvar_g_MaxFlipCredits(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_MaxFlipCredits = convar.IntValue;
}
public void ChangeCvar_g_MinFlipCredits(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_MinFlipCredits = convar.IntValue;
}
public void ChangeCvar_g_Game(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_Game = convar.IntValue;
}
public void ChangeCvar_g_Percent(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_Percent = convar.FloatValue;
}


public Action:flipgame(client, args)
{
	MoneyGameMenu(client);
	return Plugin_Handled;
}

MoneyGameMenu(client)
{
	Menu menu = new Menu(FlipGameMenu);
	menu.SetTitle("Монетка\n \n");
	menu.AddItem("StartGame", "Начать игру");
	if(FlipOffers == 1)
	{
		if(g_BlockClientGame[client] == 0)	menu.AddItem("block", "Отключить предложения");
		else	menu.AddItem("unblock", "Включить предложения");
	}
	menu.AddItem("info", "Информация\n \n");
	menu.ExitButton = true;
	menu.Display(client, 0);
}

MoneyGameStartMenu(client)
{
	if(g_MoneyClient[client] < g_MinFlipCredits)
	{
		g_MoneyClient[client] = 0;
	}
	if(g_MaxFlipCredits != 0)
	{
		if(g_MoneyClient[client] > g_MaxFlipCredits)
		{
			g_MoneyClient[client] = 0;
		}
	}
	if(g_CheckMoneyGame[client] == 0)
	{
		if(g_MoneyItem[client] == 0)	g_FlipCoin[client] = "Решка";
		else	g_FlipCoin[client] = "Орёл";
		Menu menu = new Menu(FlipGameStartMenu);
		if(g_Percent != 0)
		{
			menu.SetTitle("Старт игры\n \nВаша ставка [%i фишек]\nВаша сторона монетки [%s]\nКомиссия выигрыша [%.1f%%]\n \n", g_MoneyClient[client], g_FlipCoin[client], g_Percent);
		}
		else
		{
			menu.SetTitle("Старт игры\n \nВаша ставка [%i фишек]\nВаша сторона монетки [%s]\n \n", g_MoneyClient[client], g_FlipCoin[client]);
		}
		menu.AddItem("credits", "Изменить ставку");
		menu.AddItem("money", "Изменить сторону монетки\n \n");
		menu.AddItem("start", "Найти игрока");
		menu.ExitButton = true;
		menu.Display(client, 0);
	}
	else
	{
		if(g_Game != 0)
		{
			CPrintToChat(client, "\x07FFFFFFУ вас уже начата игра!");
		}
		else CGOPrintToChat(client, "У вас уже начата игра!");
		MoneyGameMenu(client);
	}
}

CreditsRateMenu(client)
{
	Menu menu = new Menu(MenuCreditsRateMenu); 
	menu.SetTitle("Фишек для ставки [%i]\n \n", g_MoneyClient[client]);
	if(g_MinFlipCredits > 0 && g_MinFlipCredits != 10)
	{
		char Credits[128];
		Format(Credits, sizeof(Credits), "%i", g_MinFlipCredits);
		menu.AddItem(Credits, Credits);
	}
	menu.AddItem("10", "+10");
	menu.AddItem("500", "+500");
	menu.AddItem("5000", "+5000");
	menu.AddItem("50000", "+50000\n \n");
	menu.AddItem("done", "Готово");
	menu.ExitButton = false;
	menu.Display(client, 0);
}

public int FlipGameMenu(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	if (action == MenuAction_Select)
	{
		new String:info[64];
		menu.GetItem(param, info, sizeof(info));
		if(strcmp(info, "StartGame") == 0)
		{
			MoneyGameStartMenu(client);
		}
		else if(strcmp(info, "info") == 0)
		{
			Menu hMenu = new Menu(InfoMoneyMenu);
			hMenu.SetTitle("Информация\n \n* Игра 1 на 1\n-Играйте с другими игроками\nна свои Фишки!-\n \n");
			hMenu.AddItem("exit", "Назад");
			hMenu.ExitButton = false;
			hMenu.Display(client, 0);
		}
		else if(strcmp(info, "block") == 0)
		{
			g_BlockClientGame[client] = 1;
			if(client && IsClientInGame(client) && client <= MaxClients)
			{
				if(g_Game != 0)
				{
					CPrintToChat(client, "\x07FFFFFF[\x07FF0000Монетка\x07FFFFFF] Предложения отключены! Теперь только вы сможете их отправлять!");
				}
				else CGOPrintToChat(client, "[{RED}Монетка{DEFAULT}] Предложения отключены! Теперь только вы сможете их отправлять!");		
			}			
			MoneyGameMenu(client);
		}
		else if(strcmp(info, "unblock") == 0)
		{
			g_BlockClientGame[client] = 0;
			if(client && IsClientInGame(client) && client <= MaxClients)
			{
				if(g_Game != 0)
				{
					CPrintToChat(client, "\x07FFFFFF[\x07FF0000Монетка\x07FFFFFF] Предложения включены! Теперь каждый игрок сможет вас пригласить в игру!");
				}
				else CGOPrintToChat(client, "[{RED}Монетка{DEFAULT}] Предложения включены! Теперь каждый игрок сможет вас пригласить в игру!");
			}
			MoneyGameMenu(client);
		}
	}
}

public int InfoMoneyMenu(Menu hMenu, MenuAction action, int client, int param)
{
	if (action == MenuAction_End)
	{
		delete hMenu;
	}
	else if (action == MenuAction_Select)
	{
		MoneyGameMenu(client);
	}
}

public int FlipGameStartMenu(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_End)
	{
		delete menu; 
	}
	if (action == MenuAction_Select)
	{
		if(param == 0)
		{
			g_CheckChatMoney[client] = 0;
			Menu hMenu = new Menu(ImputSelectionMenu);
			if(g_MaxFlipCredits != 0)	hMenu.SetTitle("Выберите тип ввода\n \nМинимальная ставка: %i фишек\nМаксимальная ставка: %i фишек\n \n", g_MinFlipCredits, g_MaxFlipCredits);
			else	hMenu.SetTitle("Выберите тип ввода\n \nМинимальная ставка: %i фишек\n \n", g_MinFlipCredits, g_MaxFlipCredits);
			hMenu.AddItem("one", "В чат");
			hMenu.AddItem("two", "Через меню\n \n");
			hMenu.AddItem("exit", "Назад");
			hMenu.ExitButton = true;
			hMenu.Display(client, 0);
		}
		else if(param == 1)
		{
			if(g_MoneyItem[client] == 0)
			{
				g_MoneyItem[client] = 1;
			}
			else g_MoneyItem[client] = 0;
			MoneyGameStartMenu(client);
		}
		else if(param == 2)
		{
			if(g_MoneyClient[client] != 0 && Shop_GetClientCredits(client) >= g_MoneyClient[client])
			{
				int player;
				Menu hMenu = new Menu(ChoicePlayerMenu);
				hMenu.SetTitle("Выберите игрока [%i фишек]:\n \n", g_MoneyClient[client]); 
				decl String:userid[15], String:name[32]; 
				for (int i = 1; i <= MaxClients; i++) 
				{
					if(IsClientInGame(i))
					{
						if (!IsFakeClient(i) && Shop_GetClientCredits(i) >= g_MoneyClient[client] && i != client && g_BlockClientGame[i] != 1 && g_BlockTargetGame[client] != i && g_CheckMoneyGame[i] != 1) 
						{ 
							IntToString(GetClientUserId(i), userid, 15); 
							GetClientName(i, name, 32); 
							hMenu.AddItem(userid, name); 
							player++;
						}
					}
				} 
				if (player == 0)
				{
					hMenu.AddItem("nonplayer", "Нет подходящих игроков");
				}
				hMenu.Display(client, 0); 
			}
			else
			{
				if(client && IsClientInGame(client) && client <= MaxClients)
				{
					if(g_Game != 0)
					{
						CPrintToChat(client, "\x07FFFFFF[\x07FF0000Монетка\x07FFFFFF] У вас не достаточно фишек, либо ставка не может ранятся 0!");
					}
					else CGOPrintToChat(client, "[{RED}Монетка{DEFAULT}] У вас не достаточно фишек, либо ставка не может ранятся 0!");
				}
				MoneyGameStartMenu(client);
			}
		}
	}
}

public int ImputSelectionMenu(Menu hMenu, MenuAction action, int client, int param)
{
	if (action == MenuAction_End)
	{
		delete hMenu;
	}
	if (action == MenuAction_Select)
	{
		if(param == 0)
		{
			g_CheckChatMoney[client] = 1;
			if(g_Game != 0)
			{
				CPrintToChat(client, "\x07FFFFFF[\x07FF0000Монетка\x07FFFFFF] Введите сумму в чат:");
			}
			else CGOPrintToChat(client, "[{RED}Монетка{DEFAULT}] Введите сумму в чат:");
			MoneyGameStartMenu(client);
		}
		else if(param == 1)
		{
			g_MoneyClient[client] = 0;
			CreditsRateMenu(client);
		}
		else if(param == 2)
		{
			MoneyGameStartMenu(client);
		}
	}
}

public int MenuCreditsRateMenu(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	if (action == MenuAction_Select)
	{
		new String:info[64];
		menu.GetItem(param, info, sizeof(info));
		if(strcmp(info, "done") == 0)
		{
			if(g_MoneyClient[client] >= g_MinFlipCredits)
			{
				if(g_MaxFlipCredits != 0)
				{
					if(g_MoneyClient[client] <= g_MaxFlipCredits)
					{
						if(Shop_GetClientCredits(client) < g_MoneyClient[client])
						{
							if(client && IsClientInGame(client) && client <= MaxClients)
							{
								if(g_Game != 0)
								{
									CPrintToChat(client, "\x07FFFFFF[\x07FF0000Монетка\x07FFFFFF] У вас  уже не достаточно фишек! Ставка равна 0");
								}
								else CGOPrintToChat(client, "[{RED}Монетка{DEFAULT}] У вас  уже не достаточно фишек! Ставка равна 0");
							}
							g_MoneyClient[client] = 0;
							MoneyGameStartMenu(client);
						}
						else
						{
							MoneyGameStartMenu(client);
						}
					}
					else
					{
						if(client && IsClientInGame(client) && client <= MaxClients)
						{
							if(g_Game != 0)
							{
								CPrintToChat(client, "\x07FFFFFF[\x07FF0000Монетка\x07FFFFFF] Ошибка! Максимальная ставка: \x07FF0000%i \x07FFFFFFфишек", g_MaxFlipCredits);
							}
							else CGOPrintToChat(client,"[{RED}Монетка{DEFAULT}] Ошибка! Максимальная ставка: {RED}%i {DEFAULT}фишек", g_MaxFlipCredits);
						}
						g_MoneyClient[client] = 0;
						MoneyGameStartMenu(client);
					}
				}
			}
			else
			{
				if(client && IsClientInGame(client) && client <= MaxClients)
				{
					if(g_Game != 0)
					{
						CPrintToChat(client, "\x07FFFFFF[\x07FF0000Монетка\x07FFFFFF] Ошибка! Минимальная ставка: \x07FF0000%i \x07FFFFFFфишек", g_MinFlipCredits);
					}
					else CGOPrintToChat(client,"[{RED}Монетка{DEFAULT}] Ошибка! Минимальная ставка: {RED}%i {DEFAULT}фишек", g_MinFlipCredits);
				}
				g_MoneyClient[client] = 0;
				MoneyGameStartMenu(client);
			}
			MoneyGameStartMenu(client);
			return;
		}
		int Credits = StringToInt(info);
		if((Shop_GetClientCredits(client) - g_MoneyClient[client] - Credits) >= 0)
		{
			if(g_MoneyClient[client] + Credits >= g_MinFlipCredits)
			{
				if(g_MaxFlipCredits != 0)
				{
					if(g_MoneyClient[client] + Credits <= g_MaxFlipCredits)
					{
						g_MoneyClient[client] = g_MoneyClient[client] + Credits;
					}
					else
					{
						if(client && IsClientInGame(client) && client <= MaxClients)
						{
							if(g_Game != 0)
							{
								CPrintToChat(client, "\x07FFFFFF[\x07FF0000Монетка\x07FFFFFF] Ошибка! Максимальная ставка \x07FF0000%i \x07FFFFFFфишек", g_MaxFlipCredits);
							}
							else CGOPrintToChat(client, "[{RED}Монетка{DEFAULT}] Ошибка! Максимальная ставка {RED}%i {DEFAULT}фишек", g_MaxFlipCredits);
						}
					}
				}
				else
				{
					g_MoneyClient[client] = g_MoneyClient[client] + Credits;
				}
			}
			else 
			{
				if(client && IsClientInGame(client) && client <= MaxClients)
				{
					if(g_Game != 0)
					{
						CPrintToChat(client, "\x07FFFFFF[\x07FF0000Монетка\x07FFFFFF] Ошибка! Минимальная ставка \x07FF0000%i \x07FFFFFFфишек", g_MinFlipCredits);
					}
					else CGOPrintToChat(client, "[{RED}Монетка{DEFAULT}] Ошибка! Минимальная ставка {RED}%i {DEFAULT}фишек", g_MinFlipCredits);
				}
			}
		}
		else 
		{
			if(client && IsClientInGame(client) && client <= MaxClients)
			{
				if(g_Game != 0)
				{
					CPrintToChat(client, "\x07FFFFFF[\x07FF0000Монетка\x07FFFFFF] Не достаточно фишек!");
				}
				else CGOPrintToChat(client, "[{RED}Монетка{DEFAULT}] Не достаточно фишек!");
			}
		}
		CreditsRateMenu(client);
	}
}


public int ChoicePlayerMenu(Menu hMenu, MenuAction action, int client, int param)
{
	if (action == MenuAction_End) 
	{ 
		delete hMenu;
	} 
	if (action != MenuAction_Select) 
	{
		return; 
	}
	decl String:userid[15]; 
	hMenu.GetItem(param, userid, 15); 
	int target = GetClientOfUserId(StringToInt(userid));
	if(g_CheckMoneyGame[target] == 0)
	{
		if (Shop_GetClientCredits(client) >= g_MoneyClient[client])
		{
			if (target && IsClientInGame(target)) 
			{
				if(client && IsClientInGame(client) && client <= MaxClients)
				{
					if(g_Game != 0)
					{
						CPrintToChat(client, "\x07FFFFFF[\x07FF0000Монетка\x07FFFFFF] Предложение отправлено");
					}
					else CGOPrintToChat(client, "[{RED}Монетка{DEFAULT}] Предложение отправлено");
				}
				if(Shop_GetClientCredits(target) >= g_MoneyClient[client])
				{
					g_CheckMoneyGame[client] = 1;
					TargetSaveClient[target] = client;
					TargetFlipSilver[target] = g_MoneyClient[client];
					g_FlipCoinTarget[target] = g_MoneyItem[client];
					Menu pMenu = new Menu(TargetFliChoicePlayerHandle);
					pMenu.SetTitle("-Монетка-\n \nПредложение сыграть с игроком %N\nСтавка [%i фишек]\nСторона монетки %N [%s]\n \n", client, TargetFlipSilver[target], client, g_FlipCoin[client]); 
					pMenu.AddItem("yes", "Принять предложение");
					pMenu.AddItem("no", "Отказаться от предложения");
					pMenu.ExitButton = false;
					pMenu.Display(target, 15);
				}
				else
				{
					if(client && IsClientInGame(client) && client <= MaxClients)
					{
						if(g_Game != 0)
						{
							CPrintToChat(client, "\x07FFFFFF[\x07FF0000Монетка\x07FFFFFF] У игрока уже нет достаточного количества фишек!");
						}
						else CGOPrintToChat(client, "[{RED}Монетка{DEFAULT}] У игрока уже нет достаточного количества фишек!");
					}
					MoneyGameStartMenu(client); 
				}
			} 
			else
			{		
				if(client && IsClientInGame(client) && client <= MaxClients)
				{
					if(g_Game != 0)
					{
						CPrintToChat(client, "\x07FFFFFF[\x07FF0000Монетка\x07FFFFFF] Игрок не найден (вышел с сервера)");
					}
					else CGOPrintToChat(client, "[{RED}Монетка{DEFAULT}] Игрок не найден (вышел с сервера)"); 
				}
				MoneyGameStartMenu(client); 
			}
		}
		else
		{
			if(client && IsClientInGame(client) && client <= MaxClients)
			{
				if(g_Game != 0)
				{
					CPrintToChat(client, "\x07FFFFFF[\x07FF0000Монетка\x07FFFFFF] У вас не достаточно фишек");
				}
				else CGOPrintToChat(client, "[{RED}Монетка{DEFAULT}] У вас не достаточно фишек!");
			}
			MoneyGameStartMenu(client);
		}
	}
	else
	{
		if(client && IsClientInGame(client) && client <= MaxClients)
		{
			if(g_Game != 0)
			{
				CPrintToChat(client, "\x07FFFFFF[\x07FF0000Монетка\x07FFFFFF] Игрок уже в игре");
			}
			else CGOPrintToChat(client, "[{RED}Монетка{DEFAULT}] Игрок уже в игре");
		}
		g_CheckMoneyGame[client] = 0;
		g_CheckMoneyGame[target] = 0;
	}
}

public int TargetFliChoicePlayerHandle(Menu pMenu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Cancel)
	{
		if(TargetSaveClient[client] && IsClientInGame(TargetSaveClient[client]) && TargetSaveClient[client] <= MaxClients)
		{
			if(g_Game != 0)
			{
				CPrintToChat(TargetSaveClient[client], "\x07FFFFFF[\x07FF0000Монетка\x07FFFFFF] \x070000FF%N \x07FFFFFFотказался", client);
			}
			else CGOPrintToChat(TargetSaveClient[client], "[{RED}Монетка{DEFAULT}] {BLUE}%N {DEFAULT}отказался", client);
		}
		g_CheckMoneyGame[client] = 0;
		g_CheckMoneyGame[TargetSaveClient[client]] = 0;
	}
	else if(action == MenuAction_End)
	{
		delete pMenu;
	}
	else if (action == MenuAction_Select)
	{
		new String:info[64];
		pMenu.GetItem(param, info, sizeof(info));
		if(strcmp(info, "yes") == 0)
		{
			if(client && IsClientInGame(client) && TargetSaveClient[client] && IsClientInGame(TargetSaveClient[client]) && TargetSaveClient[client] <= MaxClients && client <= MaxClients)
			{
				if(Shop_GetClientCredits(client) >= TargetFlipSilver[client] && Shop_GetClientCredits(TargetSaveClient[client]) >= TargetFlipSilver[client])
				{
					g_CheckMoneyGame[client] = 1;
					if(g_FlipCoinTarget[client] == 0)
					{
						TargetFlip[client] = "Орёл";
						TargetFlip1[client] = "Решка";
					}
					else
					{
						TargetFlip[client] = "Решка";
						TargetFlip1[client] = "Орёл";
					}
					if(g_Game != 0)
					{
						CPrintToChat(TargetSaveClient[client], "\x07FFFFFF[\x07FF0000Монетка\x07FFFFFF] \x070000FF%N \x07FFFFFFпринял предложение", client);
					}
					else CGOPrintToChat(TargetSaveClient[client], "[{RED}Монетка{DEFAULT}] {BLUE}%N {DEFAULT}принял предложение", client);
					Shop_SetClientCredits(client, Shop_GetClientCredits(client) - TargetFlipSilver[client]);
					Shop_SetClientCredits(TargetSaveClient[client], Shop_GetClientCredits(TargetSaveClient[client]) - TargetFlipSilver[client]);
				
					g_TMoney[client] = FlipTime;
					CreateTimer(1.0, MoneyTime, GetClientUserId(client), TIMER_REPEAT);
				}
				else
				{
					if(client && IsClientInGame(client) && client <= MaxClients)
					{
						if(g_Game != 0)
						{
							CPrintToChat(client, "\x07FFFFFF[\x07FF0000Монетка\x07FFFFFF] Ошибка!!!");
						}
						else CGOPrintToChat(client, "[{RED}Монетка{DEFAULT}] Ошибка!!!");
					}
					if(TargetSaveClient[client] && IsClientInGame(TargetSaveClient[client]) && TargetSaveClient[client] <= MaxClients)
					{
						if(g_Game != 0)
						{
							CPrintToChat(TargetSaveClient[client], "\x07FFFFFF[\x07FF0000Монетка\x07FFFFFF] Ошибка!!!");
						}
						else CGOPrintToChat(TargetSaveClient[client], "[{RED}Монетка{DEFAULT}] Ошибка!!!");
					}
					g_CheckMoneyGame[client] = 0;
					g_CheckMoneyGame[TargetSaveClient[client]] = 0;
				}
			}
			else
			{
				if(client && IsClientInGame(client) && client <= MaxClients)
				{
					if(g_Game != 0)
					{
						CPrintToChat(client, "\x07FFFFFF[\x07FF0000Монетка\x07FFFFFF] Ошибка!!!");
					}
					else CGOPrintToChat(client, "[{RED}Монетка{DEFAULT}] Ошибка!!!");
					g_CheckMoneyGame[client] = 0;
				}
				if(TargetSaveClient[client] && IsClientInGame(TargetSaveClient[client]) && TargetSaveClient[client] <= MaxClients)
				{
					if(g_Game != 0)
					{
						CPrintToChat(TargetSaveClient[client], "\x07FFFFFF[\x07FF0000Монетка\x07FFFFFF] Ошибка!!!");
					}
					else CGOPrintToChat(TargetSaveClient[client], "[{RED}Монетка{DEFAULT}] Ошибка!!!");
					g_CheckMoneyGame[TargetSaveClient[client]] = 0;
				}
				
			}
		}
		else if(strcmp(info, "no") == 0)
		{
			if(TargetSaveClient[client] && IsClientInGame(TargetSaveClient[client]) && TargetSaveClient[client] <= MaxClients)
			{
				if(g_Game != 0)
				{
					CPrintToChat(TargetSaveClient[client], "\x07FFFFFF[\x07FF0000Монетка\x07FFFFFF] \x070000FF%N \x07FFFFFFотказался", client);
				}
				CGOPrintToChat(TargetSaveClient[client], "[{RED}Монетка{DEFAULT}] {BLUE}%N {DEFAULT}отказался", client);
				g_CheckMoneyGame[TargetSaveClient[client]] = 0;
				g_BlockTargetGame[TargetSaveClient[client]] = client;
				CreateTimer(FlipBlockOffers, MoneyTimeUnblock, GetClientUserId(TargetSaveClient[client]), TIMER_REPEAT);
			}
		}
	}
}

public Action MoneyTime(Handle timer, any UserId)
{
	int iClient = GetClientOfUserId(UserId);
	char g_mText[512];
	int credits;
	if(g_Percent != 0)
	{
		float c = (TargetFlipSilver[iClient]*2) - (((TargetFlipSilver[iClient]*2)/100)*g_Percent);
		credits = RoundFloat(c);
	}
	else credits = (TargetFlipSilver[iClient] * 2);
	if (iClient == 0 || !IsClientInGame(iClient)) 
	{
		if(TargetSaveClient[iClient] && IsClientInGame(TargetSaveClient[iClient]))
		{
			Shop_SetClientCredits(TargetSaveClient[iClient], Shop_GetClientCredits(TargetSaveClient[iClient]) + credits/2);
			PrintToChat(TargetSaveClient[iClient], "Вам вернули %i фишек", credits/2);
			g_CheckMoneyGame[TargetSaveClient[iClient]] = 0;
		}
		return Plugin_Stop;
	}
	if(TargetSaveClient[iClient] == 0 || !IsClientInGame(TargetSaveClient[iClient]))
	{
		if(iClient && IsClientInGame(iClient))
		{
			Shop_SetClientCredits(iClient, Shop_GetClientCredits(iClient) + credits/2);
			PrintToChat(iClient, "Вам вернули %i фишек", credits/2);
			g_CheckMoneyGame[iClient] = 0;
		}
		return Plugin_Stop;
	}
	
	if(g_TMoney[iClient] != 0)
	{
		if(g_ChangeWrite == 1)
		{
			if(g_Game != 0)
			{
				if(iClient && IsClientInGame(iClient) && iClient <= MaxClients)
				{
					Format(g_mText,sizeof(g_mText), "★★★★★★★Монетка★★★★★★★\nВы [%s] Vs Противник [%s]\nНа кону %i фишек\nДо спина %i сек.",TargetFlip[iClient], TargetFlip1[iClient], credits, g_TMoney[iClient]);
					PrintHintText(iClient, g_mText);
				}
				if(TargetSaveClient[iClient] && IsClientInGame(TargetSaveClient[iClient]) && TargetSaveClient[iClient] <= MaxClients)
				{
					Format(g_mText,sizeof(g_mText), "★★★★★★★Монетка★★★★★★★\nПротивник [%s] Vs Вы [%s]\nНа кону %i фишек\nДо спина %i сек.",TargetFlip[iClient], TargetFlip1[iClient], credits, g_TMoney[iClient]);
					PrintHintText(TargetSaveClient[iClient], g_mText);
				}
			}
			else
			{
				if(iClient && IsClientInGame(iClient) && iClient <= MaxClients)
				{
					Format(g_mText,sizeof(g_mText), "<font size='16'> <center>★★★★★★★Монетка★★★★★★★</center>\nВы [%s] Vs Противник [%s]\nНа кону %i фишек\nДо спина %i сек.</font>",TargetFlip[iClient], TargetFlip1[iClient], credits, g_TMoney[iClient]);
					PrintHintText(iClient, g_mText);
				}
				if(TargetSaveClient[iClient] && IsClientInGame(TargetSaveClient[iClient]) && TargetSaveClient[iClient] <= MaxClients)
				{
					Format(g_mText,sizeof(g_mText), "<font size='16'> <center>★★★★★★★Монетка★★★★★★★</center>\nПротивник [%s] Vs Вы [%s]\nНа кону %i фишек\nДо спина %i сек.</font>",TargetFlip[iClient], TargetFlip1[iClient], credits, g_TMoney[iClient]);
					PrintHintText(TargetSaveClient[iClient], g_mText);
				}
			}
		}
		else
		{
			if(iClient && IsClientInGame(iClient) && iClient <= MaxClients)
			{
				if(g_TMoney[iClient] == FlipTime)
				{
					if(g_Game != 0)
					{
						Format(g_mText,sizeof(g_mText), "\x07FFFFFF[\x07FF0000Монетка\x07FFFFFF] Вы [\x07FF0000%s\x07FFFFFF] Vs Противник [\x07FF0000%s\x07FFFFFF] || На кону \x07FF0000%i \x07FFFFFFфишек",TargetFlip[iClient], TargetFlip1[iClient], credits);
						CPrintToChat(iClient, g_mText);
						Format(g_mText,sizeof(g_mText), "\x07FFFFFF[\x07FF0000Монетка\x07FFFFFF] До спина \x070000FF%i \x07FFFFFFсек.", g_TMoney[iClient]);
						CPrintToChat(iClient, g_mText);
					}
					else
					{
						Format(g_mText,sizeof(g_mText), "{DEFAULT}[{RED}Монетка{DEFAULT}] Вы [{RED}%s{DEFAULT}] Vs Противник [{RED}%s{DEFAULT}] || На кону {RED}%i {DEFAULT}фишек",TargetFlip[iClient], TargetFlip1[iClient], credits);
						CGOPrintToChat(iClient, g_mText);
						Format(g_mText,sizeof(g_mText), "{DEFAULT}[{RED}Монетка{DEFAULT}] До спина {BLUE}%i {DEFAULT}сек.", g_TMoney[iClient]);
						CGOPrintToChat(iClient, g_mText);
					}
				}
			}
			if(TargetSaveClient[iClient] && IsClientInGame(TargetSaveClient[iClient]) && TargetSaveClient[iClient] <= MaxClients)
			{
				if(g_TMoney[iClient] == FlipTime)
				{
					if(g_Game != 0)
					{
						Format(g_mText,sizeof(g_mText), "\x07FFFFFF[\x07FF0000Монетка\x07FFFFFF] Противник [\x07FF0000%s\x07FFFFFF] Vs Вы [\x07FF0000%s\x07FFFFFF] || На кону \x07FF0000%i фишек",TargetFlip[iClient], TargetFlip1[iClient], credits);
						CPrintToChat(TargetSaveClient[iClient], g_mText);
						Format(g_mText,sizeof(g_mText), "\x07FFFFFF[\x07FF0000Монетка\x07FFFFFF] До спина \x070000FF%i \x07FFFFFFсек.", g_TMoney[iClient]);
						CPrintToChat(TargetSaveClient[iClient], g_mText);
					}
					else
					{
						Format(g_mText,sizeof(g_mText), "{DEFAULT}[{RED}Монетка{DEFAULT}] Противник [{RED}%s{DEFAULT}] Vs Вы [{RED}%s{DEFAULT}] || На кону {RED}%i фишек",TargetFlip[iClient], TargetFlip1[iClient], credits);
						CGOPrintToChat(TargetSaveClient[iClient], g_mText);
						Format(g_mText,sizeof(g_mText), "{DEFAULT}[{RED}Монетка{DEFAULT}] До спина {BLUE}%i {DEFAULT}сек.", g_TMoney[iClient]);
						CGOPrintToChat(TargetSaveClient[iClient], g_mText);
					}
				}
			}
		}
		g_TMoney[iClient]--;
		return Plugin_Continue;
	}
	else
	{
		int i = GetRandomInt(0, 1);
		char MoneyWin[64];
		if (i == 0)
		{
			MoneyWin = "Решку";
		}
		else
		{
			MoneyWin = "Орла";
		}
		if(g_ChangeWrite == 1)
		{
			if(g_Game != 0)
			{
				if(iClient && IsClientInGame(iClient) && iClient <= MaxClients)
				{
					Format(g_mText,sizeof(g_mText), "★★★★★★★Монетка★★★★★★★\nВы [%s] Vs Противник [%s]\nНа кону %i фишек\nМонетка повернулась на %s",TargetFlip[iClient], TargetFlip1[iClient], credits, MoneyWin);
					PrintHintText(iClient, g_mText);
				}
				if(TargetSaveClient[iClient] && IsClientInGame(TargetSaveClient[iClient]) && TargetSaveClient[iClient] <= MaxClients)
				{
					Format(g_mText,sizeof(g_mText), "★★★★★★★Монетка★★★★★★★\nПротивник [%s] Vs Вы [%s]\nНа кону %i фишек\nМонетка повернулась на %s",TargetFlip[iClient], TargetFlip1[iClient], credits, MoneyWin);
					PrintHintText(TargetSaveClient[iClient], g_mText);
				}
			}
			else
			{
				if(iClient && IsClientInGame(iClient) && iClient <= MaxClients)
				{
					Format(g_mText,sizeof(g_mText), "<font size='16'> <center>★★★★★★★Монетка★★★★★★★</center>\nВы [%s] Vs Противник [%s]\nНа кону %i фишек\nМонетка повернулась на %s</font>",TargetFlip[iClient], TargetFlip1[iClient], credits, MoneyWin);
					PrintHintText(iClient, g_mText);
				}
				if(TargetSaveClient[iClient] && IsClientInGame(TargetSaveClient[iClient]) && TargetSaveClient[iClient] <= MaxClients)
				{
					Format(g_mText,sizeof(g_mText), "<font size='16'> <center>★★★★★★★Монетка★★★★★★★</center>\nПротивник [%s] Vs Вы [%s]\nНа кону %i фишек\nМонетка повернулась на %s</font>",TargetFlip[iClient], TargetFlip1[iClient], credits, MoneyWin);
					PrintHintText(TargetSaveClient[iClient], g_mText);
				}
			}
		}
		else
		{
			if(g_Game != 0)
			{
				if(iClient && IsClientInGame(iClient) && iClient <= MaxClients)
				{
					Format(g_mText,sizeof(g_mText), "\x07FFFFFF[\x07FF0000Монетка\x07FFFFFF] Монетка повернулась на \x07FF0000%s", MoneyWin);
					CGOPrintToChat(iClient, g_mText);
				}
				if(TargetSaveClient[iClient] && IsClientInGame(TargetSaveClient[iClient]) && TargetSaveClient[iClient] <= MaxClients)
				{
					Format(g_mText,sizeof(g_mText), "\x07FFFFFF[\x07FF0000Монетка\x07FFFFFF] Монетка повернулась на \x07FF0000%s", MoneyWin);
					CGOPrintToChat(TargetSaveClient[iClient], g_mText);
				}
			}
			else
			{
				if(iClient && IsClientInGame(iClient) && iClient <= MaxClients)
				{
					Format(g_mText,sizeof(g_mText), "{DEFAULT}[{RED}Монетка{DEFAULT}] Монетка повернулась на {RED}%s", MoneyWin);
					CGOPrintToChat(iClient, g_mText);
				}
				if(TargetSaveClient[iClient] && IsClientInGame(TargetSaveClient[iClient]))
				{
					Format(g_mText,sizeof(g_mText), "{DEFAULT}[{RED}Монетка{DEFAULT}] Монетка повернулась на {RED}%s", MoneyWin);
					CGOPrintToChat(TargetSaveClient[iClient], g_mText);
				}
			}
		}
		if (i == 0)
		{
			if(g_FlipCoinTarget[iClient] == 0)
			{
				if(TargetSaveClient[iClient] && IsClientInGame(TargetSaveClient[iClient]) && TargetSaveClient[iClient] <= MaxClients)
				{
					Shop_SetClientCredits(TargetSaveClient[iClient], Shop_GetClientCredits(TargetSaveClient[iClient]) + credits);
					if(g_Game != 0)
					{
						CPrintToChat(TargetSaveClient[iClient], "\x07FFFFFF[\x07FF0000Монетка\x07FFFFFF] Вы выиграли \x07FF0000}%i \x07FFFFFFфишек", credits);
						CPrintToChatAll("\x07FFFFFF[\x07FF0000Монетка\x07FFFFFF] \x070000FF%N \x07FFFFFFвыиграл \x07FF0000%i \x07FFFFFFфишек у \x070000FF%N",TargetSaveClient[iClient], credits, iClient);
					}
					else
					{
						CGOPrintToChat(TargetSaveClient[iClient], "[{RED}Монетка{DEFAULT}] Вы выиграли {RED}%i {DEFAULT}фишек", credits);
						CGOPrintToChatAll("[{RED}Монетка{DEFAULT}] {BLUE}%N {DEFAULT}выиграл {RED}%i {DEFAULT}фишек у {BLUE}%N",TargetSaveClient[iClient], credits, iClient);
					}
				}
				if(iClient && IsClientInGame(iClient) && iClient <= MaxClients)
				{
					if(g_Game != 0)
					{
						CPrintToChat(iClient, "\x07FFFFFF[\x07FF0000Монетка\x07FFFFFF] Вы проиграли в битве. Выпала \x07FF0000Решка");
					}
					else CGOPrintToChat(iClient, "[{RED}Монетка{DEFAULT}] Вы проиграли в битве. Выпала {RED}Решка");
				}
			}
			else
			{
				if(iClient && IsClientInGame(iClient) && iClient <= MaxClients)
				{
					Shop_SetClientCredits(iClient, Shop_GetClientCredits(iClient) + credits);
					if(g_Game != 0)
					{
						CPrintToChat(iClient, "\x07FFFFFF[\x07FF0000Монетка\x07FFFFFF] Вы выиграли \x07FF0000%i \x07FFFFFFфишек", credits);
						CPrintToChatAll("\x07FFFFFF[\x07FF0000Монетка\x07FFFFFF] \x070000FF%N \x07FFFFFFвыиграл \x07FF0000%i \x07FFFFFFфишек у \x070000FF%N",iClient, credits, TargetSaveClient[iClient]);
					}
					else
					{
						CGOPrintToChat(iClient, "[{RED}Монетка{DEFAULT}] Вы выиграли {RED}%i {DEFAULT}фишек", credits);
						CGOPrintToChatAll("[{RED}Монетка{DEFAULT}] {BLUE}%N {DEFAULT}выиграл {RED}%i {DEFAULT}фишек у {BLUE}%N",iClient, credits, TargetSaveClient[iClient]);
					}
				}
				if(TargetSaveClient[iClient] && IsClientInGame(TargetSaveClient[iClient]) && TargetSaveClient[iClient] <= MaxClients)
				{
					if(g_Game != 0)
					{
						CPrintToChat(TargetSaveClient[iClient], "\x07FFFFFF[\x07FF0000Монетка\x07FFFFFF] Вы проиграли в битве. Выпала \x07FF0000Решка");
					}
					else CGOPrintToChat(TargetSaveClient[iClient], "[{RED}Монетка{DEFAULT}] Вы проиграли в битве. Выпала {RED}Решка");
				}
			}
		}
		if (i == 1)
		{
			if(g_FlipCoinTarget[iClient] == 1)
			{
				if(TargetSaveClient[iClient] && IsClientInGame(TargetSaveClient[iClient]) && TargetSaveClient[iClient] <= MaxClients)
				{
					Shop_SetClientCredits(TargetSaveClient[iClient], Shop_GetClientCredits(TargetSaveClient[iClient]) + credits);
					if(g_Game != 0)
					{
						CPrintToChat(TargetSaveClient[iClient], "\x07FFFFFF[\x07FF0000Монетка\x07FFFFFF] Вы выиграли \x07FF0000%i \x07FFFFFFфишек", credits);
						CPrintToChatAll("\x07FFFFFF[\x07FF0000Монетка\x07FFFFFF] \x070000FF%N \x07FFFFFFвыиграл \x07FF0000%i \x07FFFFFFфишек у \x070000FF%N",TargetSaveClient[iClient], credits, iClient);
					}
					else
					{
						CGOPrintToChat(TargetSaveClient[iClient], "[{RED}Монетка{DEFAULT}] Вы выиграли {RED}%i {DEFAULT}фишек", credits);
						CGOPrintToChatAll("[{RED}Монетка{DEFAULT}] {BLUE}%N {DEFAULT}выиграл {RED}%i {DEFAULT}фишек у {BLUE}%N",TargetSaveClient[iClient], credits, iClient);
					}
				}
				if(iClient && IsClientInGame(iClient) && iClient <= MaxClients)
				{
					if(g_Game != 0)
					{
						CPrintToChat(iClient, "\x07FFFFFF[\x07FF0000Монетка\x07FFFFFF] Вы проиграли в битве. Выпал \x07FF0000Орёл");
					}
					else CGOPrintToChat(iClient, "[{RED}Монетка{DEFAULT}] Вы проиграли в битве. Выпал {RED}Орёл");
				}
			}
			else
			{
				if(iClient && IsClientInGame(iClient) && iClient <= MaxClients)
				{
					Shop_SetClientCredits(iClient, Shop_GetClientCredits(iClient) + credits);
					if(g_Game != 0)
					{
						CPrintToChat(iClient, "\x07FFFFFF[\x07FF0000Монетка\x07FFFFFF] Вы выиграли \x07FF0000%i \x07FFFFFFфишек", credits);
						CPrintToChatAll("\x07FFFFFF[\x07FF0000Монетка\x07FFFFFF] \x070000FF%N \x07FFFFFFвыиграл \x07FF0000%i \x07FFFFFFфишек у \x070000FF%N",iClient, credits, TargetSaveClient[iClient]);
					}
					else
					{
						CGOPrintToChat(iClient, "[{RED}Монетка{DEFAULT}] Вы выиграли {RED}%i {DEFAULT}фишек", credits);
						CGOPrintToChatAll("[{RED}Монетка{DEFAULT}] {BLUE}%N {DEFAULT}выиграл {RED}%i {DEFAULT}фишек у {BLUE}%N",iClient, credits, TargetSaveClient[iClient]);
					}
				}
				if(TargetSaveClient[iClient] && IsClientInGame(TargetSaveClient[iClient]) && TargetSaveClient[iClient] <= MaxClients)
				{
					if(g_Game != 0)
					{
						CGOPrintToChat(TargetSaveClient[iClient], "\x07FFFFFF[\x07FF0000Монетка\x07FFFFFF] Вы проиграли в битве. Выпал \x07FF0000Орёл");
					}
					else CGOPrintToChat(TargetSaveClient[iClient], "[{RED}Монетка{DEFAULT}] Вы проиграли в битве. Выпал {RED}Орёл");
				}
			}
		}
		g_BlockTargetGame[TargetSaveClient[iClient]] = iClient;
		CreateTimer(FlipBlockOffers, MoneyTimeUnblock, GetClientUserId(TargetSaveClient[iClient]), TIMER_REPEAT);
		g_CheckMoneyGame[iClient] = 0;
		g_CheckMoneyGame[TargetSaveClient[iClient]] = 0;
		TargetSaveClient[iClient] = 0;
		return Plugin_Stop;
	}
}

public Action MoneyTimeUnblock(Handle timer, any UserId)
{
	int iClient = GetClientOfUserId(UserId);
	g_BlockTargetGame[iClient] = 0;
	return Plugin_Stop;
}

public Action Command_Say(int client, const char[] command, int argc)
{
	if(client > 0 && client <= MaxClients)
	{
		char text[64];
		if (!GetCmdArgString(text, sizeof(text)) || !text[0])
		{
			return Plugin_Continue;
		}
		if(g_CheckChatMoney[client] == 1)
		{
			StripQuotes(text);
			TrimString(text);
			g_MoneyClient[client] = StringToInt(text);
			if(g_MoneyClient[client] > 0)
			{
				if(g_MoneyClient[client] >= g_MinFlipCredits)
				{
					if(g_MaxFlipCredits != 0)
					{
						if(g_MoneyClient[client] <= g_MaxFlipCredits)
						{
							if(Shop_GetClientCredits(client) < g_MoneyClient[client])
							{
								if(g_Game != 0)
								{
									CPrintToChat(client,"\x07FFFFFF[\x07FF0000Монетка\x07FFFFFF] У вас не достаточно фишек");
								}
								else CGOPrintToChat(client,"[{RED}Монетка{DEFAULT}] У вас не достаточно фишек");
								g_MoneyClient[client] = 0;
							}
						}
						else
						{
							if(g_Game != 0)
							{
								CPrintToChat(client,"\x07FFFFFF[\x07FF0000Монетка\x07FFFFFF] Ошибка! Максимальная ставка: \x07FF0000%i \x07FFFFFFфишек", g_MaxFlipCredits);
							}
							else CGOPrintToChat(client,"[{RED}Монетка{DEFAULT}] Ошибка! Максимальная ставка: {RED}%i {DEFAULT}фишек", g_MaxFlipCredits);
							g_MoneyClient[client] = 0;
						}
					}
				}
				else
				{
					if(g_Game != 0)
					{
						CPrintToChat(client,"\x07FFFFFF[\x07FF0000Монетка\x07FFFFFF] Ошибка! Минимальная ставка: \x07FF0000%i \x07FFFFFFфишек", g_MinFlipCredits);
					}
					else CGOPrintToChat(client,"[{RED}Монетка{DEFAULT}] Ошибка! Минимальная ставка: {RED}%i {DEFAULT}фишек", g_MinFlipCredits);
					g_MoneyClient[client] = 0;
				}
			}
			else
			{
				if(g_Game != 0)
				{
					CPrintToChat(client,"\x07FFFFFF[\x07FF0000Монетка\x07FFFFFF] Не правильное число");
				}
				else CGOPrintToChat(client,"[{RED}Монетка{DEFAULT}] Неправильное число");
				g_MoneyClient[client] = 0;
			}
			g_CheckChatMoney[client] = 0;
			MoneyGameStartMenu(client);
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public OnClientPostAdminCheck(iClient)
{
	g_CheckMoneyGame[iClient] = 0;
	g_CheckChatMoney[iClient] = 0;
	g_MoneyClient[iClient] = 0;
	TargetSaveClient[iClient] = 0;
}

public OnClientDisconnect(iClient) // Ловим выход игрока
{
	if(TargetSaveClient[iClient] > 0)
	{
		if (TargetSaveClient[iClient] && IsClientInGame(TargetSaveClient[iClient]))
		{
			if(g_Game != 0)
			{
				CPrintToChat(TargetSaveClient[iClient],"\x07FFFFFF[\x07FF0000Монетка\x07FFFFFF] \x070000FF%N \x07FFFFFFвышел с сервера", iClient);
			}
			else CGOPrintToChat(TargetSaveClient[iClient], "[{RED}Монетка{DEFAULT}] {BLUE}%N {DEFAULT}вышел с сервера", iClient);
		}
		g_CheckMoneyGame[TargetSaveClient[iClient]] = 0;
		TargetSaveClient[iClient] = 0;
	}
	
}