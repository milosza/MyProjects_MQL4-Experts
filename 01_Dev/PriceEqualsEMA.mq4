//+------------------------------------------------------------------+
//|                                                   EA_iCustom.mq4 |
//|                                                 Milosz Abramczyk |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Milosz Abramczyk"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

extern int ema_period = 21;
extern int bar_number = 1;
extern int bar_prev = 1;

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
   int bar_number_prev = bar_number + bar_prev;
   double ema = iMA(NULL, 0, ema_period, 0, MODE_EMA, PRICE_CLOSE, bar_number);
   double price = Close[bar_number];
   double price_prev = Close[bar_number_prev];
   static datetime TimeStamp;
   
   if (TimeStamp != Time[0])
      {  
      if(price_prev <= ema && price >= ema) {
         Print("BUY Alert ", Symbol(), ": Price ", price, " = EMA", ema_period, " ", DoubleToString(ema, Digits), " for bar number ", bar_number);
         Alert("BUY Alert ", Symbol(), ": Price ", price, " = EMA", ema_period, " ", DoubleToString(ema, Digits), " for bar number ", bar_number);
         }
      
      if(price_prev >= ema && price <= ema) {
         Print("SELL Alert ", Symbol(), ": Price ", price, " = EMA", ema_period, " ", DoubleToString(ema, Digits), " for bar number ", bar_number);
         Alert("SELL Alert ", Symbol(), ": Price ", price, " = EMA", ema_period, " ", DoubleToString(ema, Digits), " for bar number ", bar_number);
         } 
      TimeStamp = Time[0];
      } 
  }
//+------------------------------------------------------------------+
