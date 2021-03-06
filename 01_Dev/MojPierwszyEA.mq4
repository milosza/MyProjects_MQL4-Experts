//+------------------------------------------------------------------+
//|                                                MojPierwszyEA.mq4 |
//|                                                 Milosz Abramczyk |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Milosz Abramczyk"
#property link      ""
#property version   "1.00"
#property strict
//--- input parameters
input string   WitajSwiecie="Witaj Świecie! & Licznik Ticcków";
int Count = 1;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
   EventSetTimer(60);
   MessageBox(WitajSwiecie);  
   Alert ("Funkcja init() wywolana na poczatku"); 
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- destroy timer
   EventKillTimer();
   Alert("Wyjscie");
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   double aktualnaCena = Ask;
   licznikTickow(); 
   Alert("Nowy tick - zmiana ceny: ",Count," Cena Ask to: ",aktualnaCena); 
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Moje funkcje                                                  |
//+------------------------------------------------------------------+
void licznikTickow() 
   {
   Count++; // Inkrementacja zmiennej Count;
   }
//+------------------------------------------------------------------+