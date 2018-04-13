#include <sourcemod>

// -------- Forward----------
Handle g_hForwardClientOpenMainMenu,        // Открылось главное меню
       g_hForwardGameOnMenuCreate,          // Создание меню с играми
       g_hForwardGameOnMenuChoose,          // Выбрали какую-то игру
       g_hForwardClientOpenConvectorMenu,   // Игрок нажал "Управление балансом"
       g_hForwardClientChooseConvector,     // Игрок выбрал подходящий ему конвектор
       g_hForwardLoadSettings,              // В начале карты - загружаем настройки
       g_hForwardSaveSettings;              // В конце карты, сохраняем настройки игрока

void Casino_CreateForwards()
{
	g_hForwardClientOpenMainMenu =           CreateGlobalForward("Casino_ClientOpenMainMenu",ET_Hook,Param_Cell,Param_String, Param_Cell);
    g_hForwardGameOnMenuCreate =             CreateGlobalForward("Casino_GameOnMenuCreate",ET_Ignore, Param_Cell, Param_Cell,Param_Cell);
    g_hForwardGameOnMenuChoose  =            CreateGlobalForward("Casino_GameOnMenuChoose",ET_Ignore,Param_Cell,Param_String);
    g_hForwardClientOpenConvectorMenu  =     CreateGlobalForward("Casino_ClientOpenConvectorMenu",ET_Ignore, Param_Cell,Param_Cell);
    g_hForwardClientChooseConvector =        CreateGlobalForward("Casino_ClientChooseConvector",ET_Ignore,Param_Cell,Param_String);
    //g_hForwardLoadSettings              
}