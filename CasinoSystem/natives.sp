#include <sourcemod>

void Casino_CreateNative()
{
    CreateNative("Casino_OpenClientMainMenu", Native_OpenClientMainMenu);
    CreateNative("Casino_ClientIsPlaying",Native_ClientIsPlaying);
    CreateNative("Casino_GetClientChips",Native_GetClientChips);
    CreateNative("Casino_StartGame",Native_StartGame);
    CreateNative("Casino_ListPlayers",Native_ListPlayers);
}
public int Native_OpenClientMainMenu(Handle hPlugin, int iParams)
{
    int iClient = GetNativeCell(1);
    if(!g_bClientIsPlaying[iClient])    OpenMainMenu(iClient);
}
public int Native_ClientIsPlaying(Handle hPlugin, int iParams)
{
    int iClient = GetNativeCell(1);
    return g_bClientIsPlaying[iClient];
}
public int Native_GetClientChips(Handle hPlugin, int iParams)
{
    int iClient = GetNativeCell(1);
    return g_iChips[iClient];
}
public int Native_StartGame(Handle hPlugin, int iParams)
{
    int iClient = GetNativeCell(1);
    return g_iChips[iClient];
}
public int Native_ListPlayers (Handle hPlugin, int iParams)
{
    Menu menu = view_as<Menu>(GetNativeCell(1));
    bool CheckIsGame = GetNativeCell(2) ? true : false;
    
    ListPlayer(menu,CheckIsGame);
}