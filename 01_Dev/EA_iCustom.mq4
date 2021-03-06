//+------------------------------------------------------------------+
//|                                                   EA_iCustom.mq4 |
//|                                                 Milosz Abramczyk |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Milosz Abramczyk"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   double cpi=iCustom(NULL,0,"Candle Patterns Indicator",1,0);
   double cs=iCustom(NULL,0,"Candle Sizes",1,0);
   double cma=iCustom(NULL,0,"Custom Moving Averages",1,0);
   
   Alert("Wartość Candle Patterns Indicator: ",cpi,
         " Wartość Candle Sizes: ",cs,
         " Wartość Custom Moving Averages: ",cma
        );
  }
//+------------------------------------------------------------------+
