#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <shop>
#include <csgo_colors>
#pragma tabsize 0
#pragma semicolon 1
#pragma newdecls required

#define		KIT_COUNT		50

#define LOGS "addons/sourcemod/logs/Roulette.log"  
#define DEBUG_LOGS	"addons/sourcemod/logs/Roulette_debUg.log"
#define Version "2.2 DEBUG"
#define DEBUG

#define g_iRoundOff 15
public Plugin myinfo =
{
	name = 			"[Shop] Roulette",
	author = 		"Rostu",
	description = 	"Добавление системы рулетки на сервер.",
	version = 		Version,
	url = 			"hlmod.ru"
};
float g_fNeeded = 0.60,
	g_fCommission;

char g_sTag[16],
	g_sText[512],
	g_sCmd[32];

static const char g_sColor[][] =
{
	"FF0000", "FF4000", "FF8000", "FFBF00", "FFFF00", "BFFF00", "80FF00", "00BFFF", "0080FF", "0040FF", "0000FF", "4000FF", "8000FF", "BF00FF", "FF00FF",
	"FF00BF", "FF0080", "FF0040", "848484"
};


	
int 	g_iVotesNeeded = 4,
	g_iVotes = 0,
	g_iVoters = 0,
	g_iSecond,
	g_iBank = 0,
	g_iAmount[MAXPLAYERS + 1],
	g_iMinLimit,
	g_iRandomNumber[5],
	g_iGetClientNumbersMin[MAXPLAYERS + 1],
	g_iGetClientNumbersMax[MAXPLAYERS + 1],
	g_iLastNumber = 1,
	g_iMaxRate,
	g_iMoneySelected[MAXPLAYERS + 1],
	g_iMinJackPot,
	g_iTimeJackPot,
	g_iStavkamNetTime,
	g_iJackPotForAll,
	g_iMinPlayersJackPot,
	g_iWasJackpot,
	g_iModeValue,
	g_iMode,
	g_iLimitCredits,
	g_iValueOff,
	g_iAutoValue;
	
bool g_bVoted[MAXPLAYERS+1] = {false, ...},
	g_bRouletteStart = false,
	g_bFirts = true,
	g_bRouletteAllowed = false,
	g_bStavkamNet = false,
	g_bJackPotStart = false,
	g_bGetWinStart = false,
	g_bClose = false;

Handle	g_hRouletteTimer,
		g_hTimerToWin,
		g_hTimerToJackpot;
	   
	   
Database	g_hDatabase;

ConVar	sm_roulette_tag,
		sm_roulette_need_credits_min,
		sm_roulette_commission,
	    sm_roulette_min_credits_for_jackpot,
	    sm_roulette_time_jackpot,
	    sm_roulette_need_players_for_jackpot,
	    sm_roulette_cmd_vote,
	    sm_roulette_iMode,
	    sm_roulette_mode_value,
	    sm_roulette_off,
	    sm_roulette_auto_start;
	   
		
#include "Roulette/db.sp"
#include "Roulette/menu.sp"

public void OnPluginStart()
{
	sm_roulette_tag = CreateConVar(							"sm_roulette_tag", 		   				"Рулетка", 		"Тег в чате.");
	sm_roulette_need_credits_min = CreateConVar(			"sm_roulette_need_credits_min",     	"500", 			"Минимальное количество кредитов для участия");
	sm_roulette_commission = CreateConVar(					"sm_roulette_commission",   			"0.10", 		"Комиссия для JackPot", 0, true, 0.05, true, 0.45);
	sm_roulette_min_credits_for_jackpot = CreateConVar(	"sm_roulette_min_credits_for_jackpot",  "10000", 		"Минимальное количество кредитов для запуска JackPot");
	sm_roulette_time_jackpot = CreateConVar(				"sm_roulette_time_jackpot",   			"14", 			"В который час запустится JackPot ", 0, true, 1.0, true, 24.0);
	sm_roulette_need_players_for_jackpot = CreateConVar(	"sm_roulette_need_players_for_jackpot",  "2", 			"Минимальное количество игроков необходимое для запуска JackPot", 0, true, 0.0, true, 64.0);
	sm_roulette_cmd_vote =CreateConVar(						"sm_roulette_cmd_vote",			 		"!voteroulette", "Команда которая будет использоваться для голосования за рулетку.");
	sm_roulette_iMode = CreateConVar(						"sm_roulette_iMode",					"1",			"Включение рулетки.0 - сразу 1 - после N секунд после смены карты, 2 - на определенном раунде ", 0, true, 0.0,true, 2.0);
	sm_roulette_mode_value = CreateConVar(					"sm_roulette_mode_value",				"120",			"Через сколько секунд/На КАКОМ раунде после начала карты будет доступна рулетка");
	sm_roulette_off = CreateConVar(							"sm_roulette_off",						"300",			"Отключение рулетки. -1 Если у какой-то команды 15 победных раундов, 0 - не будет отключена, iMode 1/2 за сколько секунд до конца/на каком раунде");
	sm_roulette_auto_start = CreateConVar(					"sm_roulette_auto_start",				"0",			"Авто-Включение рулетки. 0 - Не включать. iMode 1/2 Через N секунд/Через N раундов рулетка автоматически запустится");
	RegConsoleCmd("sm_rouletteadd", Cmd_RouletteAdd, "Добавление кредитов");
	RegConsoleCmd("sm_roulette", 	Cmd_Menu, "Меню рулетки");
	
	
	
	RegAdminCmd("sm_roulette_mode", Cmd_Mode, ADMFLAG_ROOT, "Смена мода рулетки");
	RegAdminCmd("sm_roulette_start", Cmd_Start, ADMFLAG_ROOT, "Принудительное включение рулетки");
	RegAdminCmd("sm_roulette_adminadd", Cmd_add_admin, ADMFLAG_ROOT, "Добавить кредиты для рулетки");
	RegAdminCmd("sm_roulette_free", Cmd_Free,ADMFLAG_BAN, "Позволяет администратору  бесплатно присоединиться к рулетке");
	RegAdminCmd("sm_roulette_fast",Cmd_Fast,ADMFLAG_ROOT, "Позволяет администратору установить время аукциона = время закрытие ставок");
	
	Connect_DB();
	HookEvent("round_end", Event_RoundEnd);
	
	Handle kv = CreateKeyValues("Roulette"); 
	char config[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, config, PLATFORM_MAX_PATH, "configs/shop/Roulette.ini");  
    if (!FileToKeyValues(kv, config)) 
    SetFailState("Не удалось загрузить Roulette.ini"); 
	
    if (KvJumpToKey(kv, "Roulette_Default", false)) 
    { 
        g_iSecond = KvGetNum(kv, "Time", 600);  
        g_iStavkamNetTime= KvGetNum(kv, "StavkamNet", 60); 
		g_iMaxRate = KvGetNum(kv, "Limit", 20000);
		g_iLimitCredits = KvGetNum(kv,"LimitCredits",0);

    } 
    else 
    SetFailState("Не удалось найти: Roulette_Default\n Проверьте Roulette.ini!"); 
    CloseHandle(kv); 
	
	GuardLimit();
	g_bFirts = true;
	AutoExecConfig(true, "Shop_Roulette", "shop");
}


public void OnConfigsExecuted()
{
	sm_roulette_tag.GetString(g_sTag, sizeof(g_sTag));
	g_iMinLimit = sm_roulette_need_credits_min.IntValue;
	g_fCommission = sm_roulette_commission.FloatValue;
	g_iMinJackPot = sm_roulette_min_credits_for_jackpot.IntValue;
	g_iTimeJackPot = sm_roulette_time_jackpot.IntValue;	
	g_iMinPlayersJackPot = sm_roulette_need_players_for_jackpot.IntValue;	
	sm_roulette_cmd_vote.GetString(g_sCmd,sizeof(g_sCmd));
	g_iMode = sm_roulette_iMode.IntValue;
	g_iModeValue = sm_roulette_mode_value.IntValue;
	g_iValueOff = sm_roulette_off.IntValue;
	g_iAutoValue = sm_roulette_auto_start.IntValue;

	
	CheckValue();
	
	LateLoad();
}

public void OnClientSayCommand_Post(int iClient, const char[] sCommand, const char[] sMessage)
{
	if (strcmp(sMessage, g_sCmd) == 0)	Cmd_voteRoulette(iClient,0);
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (convar == sm_roulette_tag)
    {
        convar.GetString(g_sTag, sizeof(g_sTag));
		return;
    }
    if (convar == sm_roulette_need_credits_min)
    {
        g_iMinLimit = convar.IntValue;
		return;
    }
	if (convar == sm_roulette_commission)
	{
		g_fCommission = convar.FloatValue;
		return;
	}
    if (convar == sm_roulette_min_credits_for_jackpot)
    {
        g_iMinJackPot = convar.IntValue;
		return;
    }
    if (convar == sm_roulette_time_jackpot)
    {
        g_iTimeJackPot = convar.IntValue;
		return;
    }
    if (convar == sm_roulette_need_players_for_jackpot)
    {
        g_iMinPlayersJackPot = convar.IntValue;
		return;
    }
	if(convar == sm_roulette_cmd_vote)
	{
		convar.GetString(g_sCmd,sizeof(g_sCmd));
		return;
	}
	if(convar == sm_roulette_iMode)
	{
		g_iMode = convar.IntValue;
	}
	if(convar == sm_roulette_mode_value)
	{
		g_iModeValue = convar.IntValue;
		return;
	}
	if(convar == sm_roulette_off)
	{
		g_iValueOff = convar.IntValue;
		return;
	}
	if(convar == sm_roulette_auto_start)
	{
		g_iAutoValue = convar.IntValue;
		return;
	}
   
}																			  
public void OnMapStart()
{
	g_iLastNumber = 1;
	g_bClose = false;
	LateLoad();
	CreateTimer(91.0,Timer_Check_JackPot, _, TIMER_FLAG_NO_MAPCHANGE);
}

public void OnMapEnd()
{
	if (g_bRouletteStart)	StopRoulette();
}

public void OnClientConnected(int iClient)
{
	if(IsFakeClient(iClient))
		return;
	
	g_bVoted[iClient] = false;
	g_iGetClientNumbersMax[iClient] =
	g_iGetClientNumbersMin[iClient] = 0;
	g_iVoters++;
	g_iVotesNeeded = RoundToFloor(float(g_iVoters) * g_fNeeded);
}

public void OnClientDisconnect(int iClient)
{
	if(IsFakeClient(iClient))
		return;
	#if defined DEBUG
    LogToFile(DEBUG_LOGS, "[ВЫШЕЛ]Было: Всего g_iVoters = %d,g_iVotesNeeded = %d,g_bVoted? = %d,Учавствовали = %d игроков,g_ibank = %d, g_bRoulette start = %d",g_iVoters,g_iVotesNeeded,g_bVoted[iClient],g_iVotes,
    g_iBank,g_bRouletteStart);
    LogToFile(DEBUG_LOGS, "g_iAmount = %d,g_iLastNumber = %d,",g_iAmount[iClient],g_iLastNumber);
	#endif
	g_iVoters--;
	
	g_iVotesNeeded = RoundToFloor(float(g_iVoters) * g_fNeeded);
	if(g_bVoted[iClient])
	{
		g_bVoted[iClient] = false;
		g_iVotes--;
		if (g_bRouletteStart || g_bGetWinStart )
		{
			if(g_bStavkamNet && g_iVotes == 1)
			g_iBank-= g_iAmount[iClient];
			
			g_iLastNumber = 1;
			Stop_Bargaining();
			return;
			
			
		}
			
		if (!g_bRouletteStart && g_bRouletteAllowed)
		Shop_GiveClientCredits(iClient,g_iMinLimit,IGNORE_FORWARD_HOOK);
			
		if (g_bJackPotStart )
		{
			CalculateAmoutJackpot();
			g_iLastNumber = 1;
			Stop_Bargaining();
			return;
		}
	}
	#if defined DEBUG
		LogToFile(DEBUG_LOGS, "Стало:Всего g_iVoters = %d,g_iVotesNeeded = %d,g_bVoted? = %d,Учавствовали = %d игроков,g_ibank = %d, g_bRoulette start = %d",g_iVoters,g_iVotesNeeded,g_bVoted,g_iVotes,
	g_iBank,g_bRouletteStart);
	LogToFile(DEBUG_LOGS, "g_iAmount = %d,g_iLastNumber = %d,Игрок = %N",g_iAmount[iClient],g_iLastNumber,iClient);
	#endif
	if (g_iVotes && 
		g_iVoters && 
		g_iVotes >= g_iVotesNeeded &&
		g_bRouletteAllowed) 
	{
		StartRoulette();
	}
	
}

void GuardLimit()
{
	if(g_iMaxRate != 0 && g_iMaxRate < g_iMinLimit)				SetFailState("[Рулетка] Нельзя устанавливать максимальную ставку < минимальной");
	if(g_iMaxRate != 0 && g_iMaxRate < g_iMinLimit * 4)			SetFailState("[Рулетка] Нельзя устанавливать максимальную ставку < минимальной * минимальное количество игроков");	
	if(g_iSecond<g_iStavkamNetTime)								SetFailState("[Рулетка] Нельзя устанавливать время рулетки < время закрытия ставок");
	if(g_iLimitCredits < g_iMinLimit && g_iLimitCredits != 0)	SetFailState("[Рулетка] Нельзя устанавливать лимит игрокам < минимальная ставка");
}

public Action Cmd_Menu(int iClient, int args)
{
	MainMenu(iClient);
	return Plugin_Handled;
}

public Action Cmd_Free(int iClient, int args)
{
	if(!g_bRouletteStart)
	{
		CGOPrintToChat(iClient,"\x02[\x04%s\x02] \x01 Рулетка не запущена!",g_sTag);
		return Plugin_Handled;
	}
	
	if (CheckIf(iClient))
	{
		UpdateBankSum(g_iMinLimit);
		g_iAmount[iClient] = g_iMinLimit;
		g_bVoted[iClient] = true;
		g_iVotes++;
	}
	return Plugin_Handled;
}

public Action Cmd_Mode(int iClient, int args)
{
	Roulette_Mode(iClient);
	return Plugin_Handled;
}
public Action Cmd_Start(int iClient, int args)
{
	StartRoulette();
	return Plugin_Handled;
}


public Action Cmd_add_admin(int iClient, int args)
{
	if(args != 1)
	{
		CGOPrintToChat(iClient, "\x02[\x04%s\x02] \x01 Use sm_roulette_adminadd <amout> \n\x02[\x04%s\x02] \x01 Но так же: \n\x02[\x04%s\x02] \x01Вы можете еще внести %d кредитов ", g_sTag,g_sTag,g_sTag, g_iMaxRate - g_iBank);
		return Plugin_Handled;
	}
	if(g_iVotes == 0 )
	{
		CGOPrintToChat(iClient, "\x02[\x04%s\x02] \x01 Не найдено ни одного участника!",g_sTag);
		return Plugin_Handled;
	}
	char strAmount[16]; 
	GetCmdArg(1, strAmount, sizeof(strAmount));
	int Amount = StringToInt(strAmount);
	int addsum = g_iBank + Amount;
	if(!g_bRouletteStart)
	{
		CGOPrintToChat(iClient, "\x02[\x04%s\x02] \x01 Рулетка не запущена!",g_sTag);
		return Plugin_Handled;
	}
	if(addsum > g_iMaxRate && g_iMaxRate != 0 )
	{
		CGOPrintToChat(iClient, "\x02[\x04%s\x02] \x01 Если вы добавите то JackPot станет %d฿ что превышает лимит в %d кредитов",g_sTag,addsum, g_iMaxRate);
		return Plugin_Handled;
	}
	CalculateAddForPlayers(addsum);
	return Plugin_Handled;
	
}

public Action Cmd_Fast(int iClient, int agrs)
{
	if(!g_bRouletteStart)
	{
		CGOPrintToChat(iClient,"\x02[\x04%s\x02] \x01 Рулетка не запущена!",g_sTag);
		return Plugin_Handled;
	}
	if(g_iSecond <g_iStavkamNetTime)
	{
		CGOPrintToChat(iClient,"\x02[\x04%s\x02] \x01 Нельзя ускорить рулетку когда прием ставок был закрыт",g_sTag);
		return Plugin_Handled;
	}
	if(g_iVotes <2)
	{
		CGOPrintToChat(iClient,"\x02[\x04%s\x02] \x01 Нельзя ускорить рулетку когда в ней не участвует минимум 2 человека!",g_sTag);
		return Plugin_Handled;
	}
	CGOPrintToChatAll("\x02[\x04%s\x02] \x01 Администратор %N ускорил рулетку. Рулетка начнется через %d секунд!",g_sTag,iClient,g_iStavkamNetTime + 2);
	g_iSecond = g_iStavkamNetTime + 2;
	return Plugin_Handled;
}

public Action Cmd_RouletteAdd(int iClient, int args)
{
	if (!iClient || IsFakeClient(iClient))
	{
		return Plugin_Handled;
	}


	if(args != 1)
	{
		ReplyToCommand(iClient, " \x02[\x04%s\x02] \x01 Use sm_rouletteadd <amout> ", g_sTag);
		return Plugin_Handled;
	}
	
	if(!g_bVoted[iClient])
	{
		PrintToChat(iClient, "\x02[\x04%s\x02] \x01 Вы \x02не\x01 участвуете в рулетке!", g_sTag);
		return Plugin_Handled;
	}
	if (g_bStavkamNet)
	{
		CGOPrintToChat(iClient, "\x02[\x04%s\x02] \x01 Вы не можете прибавить ставку - \x02прием ставок закрыт.",g_sTag);
		return Plugin_Handled;
	}
	char strAmount[16]; 
	GetCmdArg(1, strAmount, sizeof(strAmount));
	int sum = StringToInt(strAmount);
	AddCredits(iClient,sum);
	return Plugin_Continue;

}
public Action AddCredits(int iClient, int sum)
{
	int Amount = sum;
	
	if ( Amount < 0 )
	{
		CGOPrintToChat(iClient, "\x02[\x04%s\x02] \x01 Нельзя добавить\x02 значение <= 0 ", g_sTag);
		return Plugin_Handled;
	}
	if (g_iLimitCredits < g_iAmount[iClient] + Amount && g_iLimitCredits != 0)
	{
		CGOPrintToChat(iClient, "\x02[\x04%s\x02] \x01 Вы превысите лимит в %d(У вас было бы %d)", g_sTag,g_iLimitCredits,g_iAmount[iClient] + sum);
		return Plugin_Handled;
	}
	
	int info = Shop_GetClientCredits(iClient);
	
	if(info < Amount )
	{
		CGOPrintToChat(iClient,"\x02[\x04%s\x02] \x01 У вас нет \x02%d\x01 кредитов", g_sTag, Amount);
		return Plugin_Handled;
	}
	if (g_iMaxRate != 0 && Amount + g_iBank > g_iMaxRate)
	{
		CGOPrintToChat(iClient, "\x02[\x04%s\x02] \x02 %d\x01 превышает лимит в \x02%d\x01. До лимита \x02%d\x01 кредитов", g_sTag, Amount + g_iBank, g_iMaxRate, g_iMaxRate - g_iBank);
		return Plugin_Handled;
	}
	#if defined DEBUG
		LogToFile(DEBUG_LOGS, "было : Банк = %d, g_iAmount[client] = %d, добавил = %d",g_iBank,g_iAmount[iClient],sum);
	#endif
	Shop_SetClientCredits(iClient, info - Amount);
	CGOPrintToChatAll("\x02[\x04%s\x02] \x01 Игрок %N добавил \x02%d\x01 кредитов ( шанс %.2f﹪ )", g_sTag, iClient, sum,CalculateChange(iClient));
	g_iAmount[iClient] += Amount;
	UpdateBankSum(Amount);
	#if defined DEBUG
		LogToFile(DEBUG_LOGS, "Стало : Банк = %d, g_iAmount[client] = %d, добавил = %d",g_iBank,g_iAmount[iClient],sum);
	#endif
	return Plugin_Continue;
}
public Action Cmd_voteRoulette(int iClient, int args)
{
	if (iClient == 0)
	return Plugin_Handled;
	if (IsFakeClient(iClient))
	return Plugin_Handled;
	if (CheckIf(iClient))
	{
		AttemptStartRoulette(iClient);
	}
	
	return Plugin_Continue;
}
bool CheckIf(int iClient)
{
	if (g_iVoters <1 && !g_bRouletteStart)
	{
		CGOPrintToChat(iClient,"\x02[\x04%s\x02] \x01 Недостаточно игроков чтобы голосовать! (Нужно 4)",g_sTag);
		return false;
	}	
	if(g_bRouletteStart && g_bVoted[iClient])
	{
		CGOPrintToChat(iClient,"\x02[\x04%s\x02] \x01 Вы уже участвуете",g_sTag);
		return false;
	}
	if(!g_bRouletteAllowed && !g_bRouletteStart)
	{
		CGOPrintToChat(iClient,"\x02[\x04%s\x02] \x01 Голосование за начало рулетки еще недоступно",g_sTag);
		return false;
	}
	if (g_bStavkamNet)
	{
		CGOPrintToChat(iClient, "\x02[\x04%s\x02] \x01 Вы не можете присоединиться - прием ставок закрыт.",g_sTag);
		return false;
	}
	if (g_bVoted[iClient])
	{
		CGOPrintToChat(iClient, " \x02[\x04%s\x02] \x01 Вы уже проголосовали. Всего голосов  %d/%d",g_sTag, g_iVotes, g_iVotesNeeded);
		return false;
	}
	if(g_iBank + g_iMinLimit > g_iMaxRate && g_iMaxRate != 0)
	{
		CGOPrintToChat(iClient,"\x02[\x04%s\x02] \x01 Вы не можете присоединиться так как вы будете превышать лимит %d/%d",g_sTag,g_iBank + g_iMinLimit, g_iMaxRate);
		return false;
	}
	return true;
}
void AttemptStartRoulette(int iClient)
{
	int info = Shop_GetClientCredits(iClient);
	if(info < g_iMinLimit)
	{
		CGOPrintToChat(iClient,"\x02[\x04%s\x02] \x01 Вы не можете начать голосовать - у вас нет \x02%d\x01 кредитов",g_sTag, g_iMinLimit);
		return;
	}
	g_iVotes++;
	if(!g_bRouletteStart)
	CGOPrintToChatAll("\x02[\x04%s\x02] \x01 Игрок %N проголосовал за начало рулетки, голосов нужно %d",g_sTag, iClient, g_iVotesNeeded-g_iVotes);
	else
	CGOPrintToChatAll("\x02[\x04%s\x02] \x01 Игрок %N успешно присоеденился к рулетке!",g_sTag,iClient );
	g_bVoted[iClient] = true;
	Shop_SetClientCredits(iClient, info - g_iMinLimit);
	UpdateBankSum(g_iMinLimit);
	g_iAmount[iClient] = g_iMinLimit;
	if (g_iVotes && 
		g_iVoters && 
		g_iVotes >= g_iVotesNeeded &&
		g_bRouletteAllowed &&
		!g_bRouletteStart
		) 
	{
		
		StartRoulette();
	}
	CheckMaxBank();
}

void StartRoulette()
{
	if(g_bRouletteStart)
	return;
	
	g_bRouletteAllowed = false;
	g_bRouletteStart = true;
	CGOPrintToChatAll("\x02[\x04%s\x02] \x01 Рулетка началась!\n\x02[\x04%s\x02] \x01 Параметры рулетки:\n\x02[\x04%s\x02] \x01 Время = %d\n\x02[\x04%s\x02] \x01 Ставки закрываются в %d секунд(ы)\n\x02[\x04%s\x02] \x01 Лимит банка = %s\n\x02[\x04%s\x02] \x01 Лимит ставки игрока = %s",
	g_sTag,g_sTag,g_sTag,g_iSecond,g_sTag,g_iStavkamNetTime,g_sTag, CheckMaxRate(),g_sTag,CheckLimitCredits());
	g_hRouletteTimer = CreateTimer(1.0, g_hRouletteTimer_CallBack, _, TIMER_REPEAT);
}

public Action g_hRouletteTimer_CallBack (Handle timer)
{
	return Roulette_Started();
	
}

public Action Roulette_Started()
{
	g_iSecond --;
	if (g_iSecond == g_iStavkamNetTime)
	{
		Stop_Bargaining();		
		g_bStavkamNet = true;
		CGOPrintToChatAll("\x02[\x04%s\x02] \x01 Прием ставок закрыт!",g_sTag);
		ListPlayers();
		return Plugin_Continue;
	}
	if(g_iSecond > 0)
	{
	
		Hint2();
		return Plugin_Continue;
	}
	
	else
	{
        if(g_hRouletteTimer) 
        {
            KillTimer(g_hRouletteTimer);  
            g_hRouletteTimer = null;     
        }
		for (int i = 0; i < 5; ++i)
		{
			g_iRandomNumber[i] = GetRandomInt(1, g_iLastNumber);
		}		
		if(g_iVotes < 2)
		{
			GuardVotes();
		}
		else
		g_hTimerToWin = CreateTimer(0.2, GettingWin, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		
    }
	g_hRouletteTimer = null;
	return Plugin_Stop;
}

public Action GettingWin(Handle timer)
{
	if(g_iVotes < 2)
	{
		KillTimer(g_hTimerToWin);  
		g_hTimerToWin = null; 
		GuardVotes();
		return Plugin_Stop;
	}
	g_bGetWinStart = true;
	static int Number;
	//NumberWin == iClient;
	int NumberWin =  RangeToNumber(g_iRandomNumber[2]);
	if(++Number < KIT_COUNT)
	{
		for (int i = 0; i < 4; ++i)
		{
			g_iRandomNumber[i] = g_iRandomNumber[i + 1];
		
		}
		Hint("\t<big><u><b><font color='#dd2f2f'><center>%s</center>\n</font>%d|%d| <font color=\"#%s\">%d</font> |%d|%d\nВыигрывает игрок - %N</font></b></u></big>",
		g_sTag,
		g_iRandomNumber[0], g_iRandomNumber[1], g_sColor[GetRandomInt(0, sizeof(g_sColor) - 1)], g_iRandomNumber[2], g_iRandomNumber[3],
		g_iRandomNumber[4] = GetRandomInt(1, g_iLastNumber), NumberWin);

		return Plugin_Continue;
	}
	int GiveCreditsPlayer = CalculateCommission();
	Hint("<big><u><b> %d Кредитов выиграл игрок:</b></u></big>\n\t\t<big><u><b>%N</b></u></big> \n\t  <big><u><b>С числом %d</b></u></big>",GiveCreditsPlayer,NumberWin, g_iRandomNumber[2]);
	Number = 0;
	for (int i; ++i <= MaxClients;) 	if (IsClientInGame(i) && !IsFakeClient(i))
	{
		ClientCommand(i, "playgamesound ui/csgo_ui_crate_display.wav");
	}
	CGOPrintToChatAll("\x02[\x04%s\x02] \x01 Выиграл игрок %N с шансом %.2f%%\n\x02[\x04%s\x02] \x01 Выпало число: %d\n\x02[\x04%s\x02] \x01 Поставил: %d฿ Выиграл: %d฿",g_sTag,NumberWin,CalculateChange(NumberWin),g_sTag,g_iRandomNumber[2],g_sTag,g_iAmount[NumberWin],GiveCreditsPlayer);
	UpdateJackPot(g_iBank, GiveCreditsPlayer);
	StopRoulette();
	
	
	LogToFile(LOGS, "Выиграл игрок : %N. Выпало число: %d, Выиграл кредитов: %d", NumberWin,g_iRandomNumber[2],GiveCreditsPlayer);
	if (NumberWin != 0 && !IsFakeClient(NumberWin))
		Shop_GiveClientCredits(NumberWin, GiveCreditsPlayer,IGNORE_FORWARD_HOOK);
	

	g_hTimerToWin = null;
	return Plugin_Stop;
}

int RangeToNumber(int Number)
{
	int z;
	for (int x = 1; x <=MaxClients; x++)	if (IsClientInGame(x) && !IsFakeClient(x) && g_bVoted[x] && g_iGetClientNumbersMin[x] <= Number <= g_iGetClientNumbersMax[x])
	{
		z = x;
		#if defined DEBUG
		LogToFile(DEBUG_LOGS, "Игрок %N, Голосовал? = %d, Числа с =%d по =%d, Номер = %d",x,g_bVoted[x],g_iGetClientNumbersMin[x],g_iGetClientNumbersMax[x]);
		#endif
	}		
	return z;
}

void StopRoulette()
{
	if(g_hTimerToWin)
	{
		KillTimer(g_hTimerToWin);  
		g_hTimerToWin = null; 
	}
	if(g_hRouletteTimer) 
    {
        KillTimer(g_hRouletteTimer);  
        g_hRouletteTimer = null;     
    }
	if(g_hTimerToJackpot)
	{
		KillTimer(g_hTimerToJackpot);
		g_hTimerToJackpot = null;
	}
	ResetRoulette();
}

void ResetRoulette()
{
	CreateTimer(90.0, DelayVote, _, TIMER_FLAG_NO_MAPCHANGE);
	g_iLastNumber = 1;
	g_iVotes =
	g_iBank = 0;
	g_bRouletteStart = 
	g_bStavkamNet = 
	g_bGetWinStart = false;
	for (int x = 1; x <=MaxClients; x++)
	{
		g_bVoted[x] = false;
		g_iGetClientNumbersMin[x] =
		g_iGetClientNumbersMax[x] = 0;
		g_iAmount[x] = 0;
	}
	LoadDefaultSettings();

}

int CalculateCommission()
{
	return g_iBank-RoundFloat(g_iBank * g_fCommission);
}


float CalculateChange(int iClient)
{
	return float(g_iAmount[iClient])/float(g_iBank) * 100.0;
}

int Stop_Bargaining()
{	
	
	static int DefaultNumber = 10000;
	g_bFirts = true;	
	for (int x = 1; x<=MaxClients; x++)	if(IsClientInGame(x) && !IsFakeClient(x) && g_bVoted[x])
	{
		float Change = CalculateChange(x);
		float z = Change / 100.00;
		float c = DefaultNumber * z;
		if (g_bFirts)
		{
			g_iGetClientNumbersMin[x] = 1;
			g_iGetClientNumbersMax[x] = RoundFloat(c);
			g_iLastNumber = g_iGetClientNumbersMax[x];
			g_bFirts = false;

		}
		else
		{
			g_iGetClientNumbersMin[x] = g_iLastNumber + 1;
			int y = RoundFloat(c) + g_iLastNumber;
			g_iGetClientNumbersMax[x] = y;
			g_iLastNumber = g_iGetClientNumbersMax[x];
		}
		CGOPrintToChat(x,"\x02[\x04%s\x02] \x01 Ваш диапозон чисел стал %d - %d",g_sTag, g_iGetClientNumbersMin[x], g_iGetClientNumbersMax[x]);
		#if defined DEBUG
		LogToFile(DEBUG_LOGS, "Игрок %N, голосовал? =%d,Change = %.2f,z = %.2f,c = %.2f, g_bFirst = %d", x, g_bVoted[x], CalculateChange(x), z, c, g_bFirts);
		LogToFile(DEBUG_LOGS, "g_iGetClientNumbersMin = %d, g_iGetClientNumbersMax = %d,g_iLastNumber = %d",g_iGetClientNumbersMin[x],g_iGetClientNumbersMax[x],g_iLastNumber);
		#endif
	}
}

void Hint(const char[] sFormat, any ...)
{
	char sBuffer[256];
	for (int i; ++i <= MaxClients;) if (IsClientInGame(i) && IsFakeClient(i))
	{
		SetGlobalTransTarget(i);
		VFormat(sBuffer, sizeof(sBuffer), sFormat, 3);
		PrintHintText(i, sBuffer);
		ClientCommand(i, "playgamesound ui/csgo_ui_crate_item_scroll.wav");
	}
}


void Hint2()
{
	for(int iClient = 1; iClient<=MaxClients;iClient++)
	{
		if (IsClientInGame(iClient) && !IsFakeClient(iClient))
		{
			if (g_bVoted[iClient])
			{
				Format(g_sText,sizeof(g_sText), "<font size='15'> ★★★★★★★ РУЛЕТКА ★★★★★★★\n\tДоступна еще: %02d:%02d\nБанк %d(%d)฿ \t Участников %d\n Вы поставили %d฿(Шанс %.2f﹪)</font>",
				g_iSecond / 60 % 60, 
				g_iSecond % 60,
				g_iBank,
				CalculateCommission(),
				g_iVotes,
				g_iAmount[iClient],
				CalculateChange(iClient));
			}
			else
			{
				Format(g_sText,sizeof(g_sText), "<font size='15'>★★★★★★★ РУЛЕТКА ★★★★★★★\n\tДоступна еще: %02d:%02d\nБанк %d(%d)฿ \t Участников %d\nУчаствовать - %s </font>",
				g_iSecond / 60 % 60, 
				g_iSecond % 60,
				g_iBank,
				CalculateCommission(),
				g_iVotes,
				g_sCmd);
			}
			PrintHintText(iClient, g_sText);
		}
	}
}

char CheckMaxRate()
{
	char MaxRate[32];
	char MaxRateValue[16];
	IntToString(g_iMaxRate,MaxRateValue,16);
	Format(MaxRate,sizeof(MaxRate),"%s", (g_iMaxRate != 0) ? MaxRateValue : " Неограниченно");
	return MaxRate;
}

char CheckLimitCredits()
{
	char LimitCredits[32];
	char LimitCreditsValue[16];
	IntToString(g_iLimitCredits,LimitCreditsValue,16);
	FormatEx(LimitCredits, 32 ,"%s",(g_iLimitCredits != 0) ? LimitCreditsValue : "Неограниченно");
	return LimitCredits;
}

void LateLoad()
{
	g_iVoters = 0;
	g_iVotes = 0;
	
	for (int i=1; i<=MaxClients; i++)
	{
		if (IsClientConnected(i))
		{
			OnClientConnected(i);	
		}	
	}
}
void LoadDefaultSettings()
{
	Handle kv = CreateKeyValues("Roulette");
	char config[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, config, PLATFORM_MAX_PATH, "configs/shop/Roulette.ini");  
	FileToKeyValues(kv, config);
	KvJumpToKey(kv, "Roulette_Default", false);
			
	g_iSecond = KvGetNum(kv, "Time", 600); 
	g_iStavkamNetTime= KvGetNum(kv, "StavkamNet", 60); 
	g_iMaxRate = KvGetNum(kv, "Limit", 20000); 
	CloseHandle(kv);
}
void UpdateBankSum (int add)
{
	g_iBank += add;
	CheckMaxBank();
}
void CalculateAddForPlayers(int add)
{
	int addevery = add / g_iVoters;
	for (int i = 1; ++i <= MaxClients;) 
	{
		if (!IsClientInGame(i) || IsFakeClient(i) && !g_bVoted[i])
        continue;
		g_iAmount[i] += addevery;
		
	}
	UpdateBankSum(add);
}
void CheckMaxBank()
{
	if (g_iBank == g_iMaxRate && g_iSecond > g_iStavkamNetTime )
	{
		CGOPrintToChatAll("\x02[\x04%s\x02] \x01 Уважаемые игроки!\n\x02[\x04%s\x02] \x01 Рулетка достигла лимита!\n\x02[\x04%s\x02] \x01 Розыгрыш произойдет через %d секунд!",g_sTag,g_sTag,g_sTag, g_iStavkamNetTime +2);
		g_iSecond = g_iStavkamNetTime + 2;
	}
}

public Action Timeleft(Handle hTimer)
{
	g_bRouletteAllowed = true;
	CGOPrintToChatAll("\x02[\x04%s\x02] \x01 Рулетка стала доступна!",g_sTag);
}

public Action Auto_Start(Handle hTimer)
{
	if(!g_bRouletteStart)
	{
		if(g_iAutoValue <60)
		CGOPrintToChatAll("\x02[\x04%s\x02] \x01 Прошло %d сек.! Рулетка автоматически запущена!",g_sTag,g_iAutoValue);
		else
		CGOPrintToChatAll("\x02[\x04%s\x02] \x01 Прошло %d мин.! Рулетка автоматически запущена!",g_sTag,g_iAutoValue / 60);
		StartRoulette();
	}
}

public void Event_RoundEnd(Event hEvent, const char[] name, bool dontBroadcast)
{
	switch(g_iValueOff)
	{
		case -1:	if(GetTeamScore(2) == g_iRoundOff || GetTeamScore(3) == g_iRoundOff)
		{
			CGOPrintToChatAll("\x02[\x04%s\x02] \x01 Одна из команд выиграла 15 раундов!", g_sTag);
			StartRoulette();
		}
		default:
		{
			switch(g_iMode)
			{
				case 1:
				{
					int timeleft;
					GetMapTimeLeft(timeleft);
					if (g_iValueOff > timeleft&& !g_bClose)
					{
						g_bClose = true;
						CGOPrintToChatAll("\x02[\x04%s\x02] \x01 До конца карты меньше %d минут! Рулетка закрыта!",g_sTag, g_iValueOff * 60);
						g_bRouletteAllowed = false;
						
					}
				}
				case 2:
				{
					int iScore = GetTeamScore(2) + GetTeamScore(3) + 1;
					if(g_iAutoValue == iScore && !g_bRouletteStart)
					{
						CGOPrintToChatAll("\x02[\x04%s\x02] \x01 Карта достигла %d раунда! Рулетка автоматически запустилась!", g_sTag, g_iAutoValue);
						StartRoulette();
					}
					if(g_iValueOff  == iScore)
					{
						CGOPrintToChatAll("\x02[\x04%s\x02] \x01 Карта достигла %d раунда! Рулетка закрыта!", g_sTag, g_iValueOff);
						g_bRouletteAllowed = false;
						g_bClose = true;
					}
					if(g_iModeValue == iScore)
					{
						g_bRouletteAllowed = true;
						CGOPrintToChatAll("\x02[\x04%s\x02] \x01 Рулетка стала доступна!", g_sTag);
					}
				}
			}
		}
	}
}

void CheckValue()
{
	if(g_iMode == 1)
	{
		CreateTimer(float(sm_roulette_mode_value.IntValue),Timeleft,_,TIMER_FLAG_NO_MAPCHANGE);
		if(g_iAutoValue != 0)
		CreateTimer(float(sm_roulette_auto_start.IntValue),Auto_Start,TIMER_FLAG_NO_MAPCHANGE);
		
	}
	else if (g_iMode == 0)
	g_bRouletteAllowed = true;
}
void GuardVotes()
{
	CGOPrintToChatAll("\x02[\x04%s\x02] \x01 Рулетка отменена!\n\x02[\x04%s\x02] \x01 В рулетке не участвует минимум 2 игрока", g_sTag, g_sTag);
	for (int x = 1; x<=MaxClients; x++)	if (g_bVoted[x] && !IsFakeClient(x))
	{
		Shop_GiveClientCredits(x, g_iAmount[x], IGNORE_FORWARD_HOOK);
	}
	StopRoulette();
}

void ListPlayers()
{
	CGOPrintToChatAll("\x02[\x04%s\x02] \x01 Список участников",g_sTag);
	for (int x = 1; x<=MaxClients; x++)
	{
		if (IsClientInGame(x) && !IsFakeClient(x))
		{
			if(g_bVoted[x])
			{
				CGOPrintToChatAll("\x02[\x04%s\x02] \x01 Игрок %N: Поставил %d кредитов ( Шанс %.2f%% )",g_sTag,x,g_iAmount[x],CalculateChange(x));
			}
			#if defined DEBUG
			LogToFile(DEBUG_LOGS, "Игрок %N, голосовал? =%d,g_iAmount = %d, Change = %.2f",x,g_bVoted[x],g_iAmount[x],CalculateChange(x));
			#endif
			
		}
	}
}
public Action DelayVote(Handle Timer)
{
	if(g_bClose)
	return;
	g_bRouletteAllowed = true;
}

// JackPot
public Action Timer_Check_JackPot(Handle Timer)
{
	char record_time[4];

	FormatTime(record_time, sizeof(record_time), "%H");
	int HoursServer =StringToInt(record_time);
	if (g_iTimeJackPot == HoursServer)
	{
		if(g_iWasJackpot == 1)
		return Plugin_Stop;
		
		if (g_iJackPotForAll < g_iMinJackPot)
		{
			CGOPrintToChatAll("\x02[\x04%s\x02] \x01 JackPot не был разыгран!\n\x02[\x04%s\x02] \x01 Причина: Не набрана минимальная сумма!\n\x02[\x04%s\x02] \x01 Минимальная сумма: %d\n\x02[\x04%s\x02] \x01 Собранно: %d",
			g_sTag,g_sTag,g_sTag,g_iMinJackPot, g_sTag,g_iJackPotForAll);
			return Plugin_Stop;
		}
		if (g_iMinPlayersJackPot > g_iVoters)
		{
			CGOPrintToChatAll("\x02[\x04%s\x02] \x01 JackPot не был разыгран!\n\x02[\x04%s\x02] \x01 Причина: Не набрано минимальное количество игроков!",
			g_sTag,g_sTag);

			return Plugin_Stop;
			
		}
		CGOPrintToChatAll("\x02[\x04%s\x02] \x01 Уважаемые игроки!\n\x02[\x04%s\x02] \x01 JackPot будет разыгран!\n\x02[\x04%s\x02] \x01 Главный приз: %d кредитов!\n\x02[\x04%s\x02] \x01 Розыгрыш произойдет через 30 секунд!",
		g_sTag,g_sTag,g_sTag,g_iJackPotForAll,g_sTag);
		g_bRouletteAllowed = false;
		g_bJackPotStart = true;
			
		CreateTimer(30.0,JackPot,_, TIMER_FLAG_NO_MAPCHANGE);
		
	}
	else if (g_iWasJackpot == 0)
	return Plugin_Stop; 
	else
	g_hDatabase.Query(SQL_Callback_ErrorCheck, "UPDATE `roulette_jackpot` SET `WasJackpot` = 0 ;");
	
	return Plugin_Stop;
 
}
void CalculateAmoutJackpot()
{
	int players = GetClientCount(true);
    for (int iClient = 1; iClient <= MaxClients; iClient++)
    {
        if(IsClientInGame(iClient) && !IsFakeClient(iClient))
        {
            g_bVoted[iClient] = true;
            g_iAmount[iClient] = g_iBank / players;
        }
    }
}

public Action JackPot (Handle Timer)
{
	CalculateAmoutJackpot();
	g_iBank = g_iJackPotForAll;
	g_hTimerToJackpot = CreateTimer(0.2, JackPot_Hint, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Stop; 
}
public Action JackPot_Hint(Handle hTimer)
{
	static int Number;
	//NumberWin == iClient;
	int NumberWin =  RangeToNumber(g_iRandomNumber[2]);
	if(++Number < KIT_COUNT)
	{
		for (int i = 0; i < 4; ++i)
		{
			g_iRandomNumber[i] = g_iRandomNumber[i + 1];
		
		}
		Hint("\t<big><u><b><font color='#dd2f2f'><center>JackPot</center>\n</font>%d|%d| <font color=\"#%s\">%d</font> |%d|%d\nВыигрывает игрок - %N</font></b></u></big>",
		
		g_iRandomNumber[0], g_iRandomNumber[1], g_sColor[GetRandomInt(0, sizeof(g_sColor) - 1)], g_iRandomNumber[2], g_iRandomNumber[3],
		g_iRandomNumber[4] = GetRandomInt(1, g_iLastNumber),
		NumberWin);

		return Plugin_Continue;
	}
	Hint("<big><u><b> %d Кредитов выиграл игрок:</b></u></big>\n\t\t<big><u><b>%N</b></u></big> \n\t  <big><u><b>С числом %d</b></u></big>",g_iBank,NumberWin, g_iRandomNumber[2]);
	g_bJackPotStart = false;
	Number =
	g_iJackPotForAll = 0;
	SuccessJackPot();
	StopRoulette();
	Shop_GiveClientCredits(NumberWin, g_iBank, IGNORE_FORWARD_HOOK);
	LogToFile(LOGS, "[JackPot] Выиграл игрок: %N. Выпало число: %d, Выиграл кредитов: %d", NumberWin,g_iRandomNumber[2],g_iBank);
	return Plugin_Handled;
}