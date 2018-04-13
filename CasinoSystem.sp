#include <sourcemod>
#include <shop>
#define MAX_GAME 50
#pragma tabsize 0

Database g_hDB;

int g_iId[MAXPLAYERS + 1]; // Уникальный id игрока
int g_iChips[MAXPLAYERS + 1]; // Кол-во Фишек у игрока (Основная валюта)



bool g_bUsedConverter; // Используется ли система конвертирования
bool g_bUsedAdminSystem; // Используется ли Админ-Система
bool g_bClientIsPlaying[MAXPLAYERS + 1]; // Играет ли игрок в данный момент

//Settings
bool g_bAllowedInvite[MAXPLAYERS + 1][MAX_GAME]; 


ConVar sm_casino_admin_flag;
int g_iAdminFlag;




public Plugin myinfo = 
{
	name = "[Casino System] Core",
	author = "Rostu",
	description = "",
	version = "1.0",
	url = "https://vk.com/rostu13"
};


// --------- Статистика -------
/*
int g_iTotal[MAXPLAYERS + 1];
int g_iWin[MAXPLAYERS +1];
int g_iLost[MAXPLAYERS + 1];
*/

#include "CasinoSystem/database.sp"
#include "CasinoSystem/forwards.sp"
#include "CasinoSystem/menu.sp"
#include "CasinoSystem/menu_hndlrs.sp"
#include "CasinoSystem/natives.sp"
public APLRes AskPluginLoad2(Handle myself, bool blate, char[] sError, int err_max)
{
	Casino_CreateNative();
	return APLRes_Success;
	
}

public void OnPluginStart()
{
    Casino_CreateForwards();
	
    Casino_DBConnect();

    sm_casino_admin_flag = CreateConVar("sm_casino_admin_flag", "z","Флаг для доступа к Админ меню");

    RegConsoleCmd("sm_casino",Cmd_Casino);
    RegConsoleCmd("sm_game",Cmd_Casino);
    RegConsoleCmd("sm_games",Cmd_Casino);
    RegConsoleCmd("sm_ruletka",Cmd_Casino);

    LoadTranslations("casino_system.phrases");
}
public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (convar == sm_casino_admin_flag)
    {
        g_iAdminFlag = sm_casino_admin_flag.IntValue;
		return;
    }
}
public void OnConfigsExecuted()
{
    g_bUsedConverter = false;
    g_bUsedAdminSystem = false;
    char sPath[200];

	BuildPath(Path_SM, sPath, sizeof sPath, "plugins/CasinoConverter");
	if(DirExists(sPath))    g_bUsedConverter = true;    

    BuildPath(Path_SM, sPath, sizeof sPath, "plugins/CasinoAdmin");
	if(DirExists(sPath))    g_bUsedAdminSystem = true;      


    g_iAdminFlag = GetConVarAdminFlag(sm_casino_admin_flag);

      
}
public void OnClientPostAdminCheck(int iClient)
{
    char sAuth[32];
    char sQuery[128];

    GetClientAuthId(iClient,AuthId_Steam2,sAuth,sizeof sAuth);

    FormatEx(sQuery,sizeof sQuery,"SELECT * FROM `casino_players` WHERE auth = '%s'",sAuth);
    DB_TQuery(ClientConnect_CallBack,sQuery,GetClientUserId(iClient));
}
public Action Cmd_Casino(int iClient, int args)
{
    OpenMainMenu(iClient);
}
void ListPlayer (Menu menu, bool bCheckGame)
{
    for(int x = 1; x<= MaxClients; x++)
    {
        if(IsClientInGame(x) && !IsFakeClient(x) )
        {
            char sName[46];
            char sUserId[16];
    
            GetClientName(x,sName,sizeof sName);
            Format(sName,sizeof sName,"%s [%d]",sName,g_iChips[x]);
            IntToString(GetClientUserId(x),sUserId,sizeof sUserId);

            menu.AddItem(sUserId,sName,!CheckIsGame ? ITEMDRAW_DEFAULT : g_bClientIsPlaying[x] ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);

        }
    }
}

char[] GetBalanse (int iClient)
{
    char sBuffer[128];
    FormatEx(sBuffer,sizeof sBuffer,"Ваш баланс:\nФишек: %d\nКредитов: %d \n ",g_iChips[iClient],Shop_GetClientCredits(iClient));
    return sBuffer;
}
// Vip by R1ko 
int GetConVarAdminFlag(ConVar &hCvar)
{
	char sBuffer[16];
	hCvar.GetString(sBuffer,sizeof sBuffer);
	return ReadFlagString(sBuffer);
}
bool CheckIsGame(int iClient)
{

}