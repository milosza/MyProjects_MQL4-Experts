//+------------------------------------------------------------------+
//|   This MQL created by Milosz Abramczyk                           |
//|                                                                  |
//|   ENTRY RULES:                                                   |
//|   Based on NowaZielonaStrzalka indicator                         |
//|   Enter a long trade: when buy candle pattern recognised         |
//|   Enter a short trade: when buy candle pattern recognised        |
//|                                                                  |
//|   EXIT RULES:                                                    |
//|   Exit the long trade: take profit when 3x cande size            |
//|                        or short trade signal                     |
//|   Exit the short trade: take profit when 3x cande size           |
//|                         or long trade signal                     |
//|   Stop loss: 1 pip (or user input) from candle low/high          |
//|   Trailing stop: above take profit + 1 candle size               |
//|                                                                  |
//|   POSITION SIZING RULE:                                          |
//|   3% of equity or 0.1 Lot (user input)                           |                                                                 
//|                                                                  |
//+------------------- DO NOT REMOVE THIS HEADER --------------------+
   
#define SIGNAL_NONE 0
#define SIGNAL_BUY   1
#define SIGNAL_SELL  2
#define SIGNAL_CLOSEBUY 3
#define SIGNAL_CLOSESELL 4

// EA values
// Stop Loss, Take Profit and Position Sizing
extern int MagicNumber = 1;
extern bool SignalMail = False;
extern bool UseEquityRisk = True;
extern double EquityRisk = 0.05;
extern double MarginToEquity = 0.3;
extern double Lots = 0.1;
extern int MaxPips = 331;
extern int MaxSpread = 20;
extern int Slippage = 3;
extern bool UseStopLoss = True;
extern int StopLoss = 1;
extern bool UseTakeProfit = True;
extern double TakeProfit = 3;
extern bool UseTrailingStop = False;
extern int TrailingStop = 1;

// indicator values
//adjust visuals
extern int Vertical_Shift = 10;       // Vertical shift of drawing in points 
extern int History  = 40320;            // Amount of bars in calculation history
extern int Bar_Index = 1;             // Bar index calculated 0 = actual incompleted, 1 = last completed, 2 = second completed... 
//show patterns
extern bool Show_Mlot = True; // Show Hammer pattern
extern bool Show_SpadajacaGwiazda = True;
extern bool Show_Przenikanie = True;
extern bool Show_ZaslonaCiemnejChmury = True;
extern bool Show_ObjecieHossy = True;
extern bool Show_ObjecieBessy = True;
extern bool Show_GwiazdaPolarna = True;
extern bool Show_GwiazdaWieczorna = True;
//adjust importance of signal
extern int CSI_number = 11;
//trade with/agaainst patterns' trend, e.g. trade hammer on bearish trend
extern bool Trade_All = True;
extern bool Trade_WithTrend_Only = False;
extern bool Trade_AgainstTrend_Only = False;
//adjust aux parameters for trade with/against trend
extern int RSI_top_level = 65;
extern int RSI_bottom_level = 45;
extern int FastSMA_period = 10;
extern int SlowSMA_period = 40;
extern int Distance = 1;

// Declare Variables and functions
int P = 1;
int Order = SIGNAL_NONE;
int OTotal, Ticket, Ticket2, Ticket3;
double StopLossLevel, TakeProfitLevel, StopLevel, LotsBuy, MinLots, MaxLots, LotsSell, Spread, Equity, LastSL;
double buy, sell;

int LastOrderClosedMinAgo() {
   if (OrdersHistoryTotal() > 0){
      Ticket3 = OrdersHistoryTotal()-1; 
      if (OrderSelect(Ticket3, SELECT_BY_POS, MODE_HISTORY)){ 
         return((TimeCurrent() - OrderCloseTime())/60);
         }
      else{ 
         Print("LastOrderClosedMinAgo(): OrderSelect error code = ",GetLastError(),", Ticket 3 = ",Ticket3);
         return 0;
         }
   }
   else   
      return Period();
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int init() {
   Equity = AccountEquity();
   
   if(Digits == 5 || Digits == 3 || Digits == 1) P = 10; // P = 10
   else P = 1; // To account for 5 digit brokers
   
   Print("--- TOBOR v1 started ---");
   Print("Market info -"
         " Current symbol: ", Symbol(),
         " Current tf: ", Period(),
         " digits: ", Digits,
         " Trade allowed: ",MarketInfo(Symbol(),MODE_TRADEALLOWED),
         " Margin req for 1 Lot: ", MarketInfo(Symbol(),MODE_MARGINREQUIRED),            
         "");
   Print("Account info -"
         " Broker: ", AccountCompany(),
         " Leverage: ", AccountLeverage(),
         " Balance: ", AccountBalance(),
         " Equity: ", AccountEquity(),
         " Free margin: ", AccountFreeMargin(),
         " Stopout: ", AccountStopoutLevel(), 
         "");
   return(0);
}
//+------------------------------------------------------------------+
//| Expert initialization function - END                             |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit() {    
   Print("--- TOBOR v1 stopped ---");
   return(0);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function - END                           |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Expert start function                                            |
//+------------------------------------------------------------------+
int start() {
   OTotal = OrdersTotal();
   Order = SIGNAL_NONE;
   
   //+------------------------------------------------------------------+
   //| Variable Setup                                                   |
   //+------------------------------------------------------------------+
 
   // Assign Values to variables
 
   buy = iCustom(NULL,0,"MyIndicators\\MAbr_5CandlePatterns",
                  Vertical_Shift, 
                  History, 
                  Bar_Index, 
                  Show_Mlot, 
                  Show_SpadajacaGwiazda, 
                  Show_Przenikanie, 
                  Show_ZaslonaCiemnejChmury, 
                  Show_ObjecieHossy, 
                  Show_ObjecieBessy, 
                  Show_GwiazdaPolarna,
                  Show_GwiazdaWieczorna,
                  CSI_number,
                  Trade_All,
                  Trade_WithTrend_Only,
                  Trade_AgainstTrend_Only,
                  RSI_top_level,
                  RSI_bottom_level,
                  FastSMA_period,
                  SlowSMA_period,
                  Distance,
                  0,1);
   sell = iCustom(NULL,0,"MyIndicators\\MAbr_5CandlePatterns",                  
                  Vertical_Shift, 
                  History, 
                  Bar_Index, 
                  Show_Mlot, 
                  Show_SpadajacaGwiazda, 
                  Show_Przenikanie, 
                  Show_ZaslonaCiemnejChmury, 
                  Show_ObjecieHossy, 
                  Show_ObjecieBessy, 
                  Show_GwiazdaPolarna,
                  Show_GwiazdaWieczorna,
                  CSI_number,
                  Trade_All,
                  Trade_WithTrend_Only,
                  Trade_AgainstTrend_Only,
                  RSI_top_level,
                  RSI_bottom_level,
                  FastSMA_period,
                  SlowSMA_period,
                  Distance,
                  1,1);
 
   Spread = MarketInfo(Symbol(), MODE_SPREAD); 
   StopLevel = (MarketInfo(Symbol(), MODE_STOPLEVEL) + MarketInfo(Symbol(), MODE_SPREAD)); //  /P; // Checking broker min SL
   MinLots = MarketInfo(Symbol(),MODE_MINLOT);
   MaxLots = NormalizeDouble((MarginToEquity*(AccountFreeMargin() / MarketInfo(Symbol(),MODE_MARGINREQUIRED))),2);
   //LotsBuy = MarginRisk*AccountEquity()*AccountLeverage()/Ask/100000;
   //LotsSell = MarginRisk*AccountEquity()*AccountLeverage()/Bid/100000;     
   //if (StopLoss < StopLevel) StopLoss = StopLevel; // Defining minimum SL and TP of current asset to prevent OrderSend error 130 
   //if (TakeProfit < StopLevel) TakeProfit = StopLevel;

   //+------------------------------------------------------------------+
   //| Variable Setup - END                                             |
   //+------------------------------------------------------------------+
                 
   //Check position
   bool IsTrade = False;

   for (int i = 0; i < OTotal; i ++) {
      Ticket2 = OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
      if(OrderType() <= OP_SELL &&  OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber) {
         IsTrade = True;
         if(OrderType() == OP_BUY) {
            //Close

            //+------------------------------------------------------------------+
            //| Signal Begin(Exit Buy)                                           |
            //+------------------------------------------------------------------+
            
            // Code Exit Rules        
            if (sell != NULL) Order = SIGNAL_CLOSEBUY;
            
            //if(sma10_2 > sma40_2 && sma40_1 >= sma10_1) Order = SIGNAL_CLOSEBUY; // Rule to EXIT a Long trade

            //+------------------------------------------------------------------+
            //| Signal End(Exit Buy)                                             |
            //+------------------------------------------------------------------+

            if (Order == SIGNAL_CLOSEBUY) {           
               Ticket2 = OrderClose(OrderTicket(), OrderLots(), Bid, Slippage, MediumSeaGreen);
               Print("Sell signal - Trade buy closed"); 

               if (SignalMail) SendMail("[Signal Alert]", "[" + Symbol() + "] " + DoubleToStr(Bid, Digits) + " Close Buy");
               IsTrade = False;
               continue;
            }
            //Trailing stop for buy
            if(UseTrailingStop && TrailingStop > 0) {                 
               if(buy != NULL) {
                  if(
                     (NormalizeDouble((Low[1] - (TrailingStop * P)*Point),Digits) > NormalizeDouble(OrderStopLoss(), Digits)) 
                     && (NormalizeDouble((Low[1] - (TrailingStop * P)*Point),Digits) <= NormalizeDouble((Ask-StopLevel*Point),Digits)) 
                  ) 
                  {
                     LastSL = OrderStopLoss();
                     Ticket2 = OrderModify(OrderTicket(), OrderOpenPrice(), NormalizeDouble((Low[1] - (TrailingStop * P) * Point), Digits), OrderTakeProfit(), 0, MediumSeaGreen);
                     Print("Buy signal - trailing stop placed: prev SL: ",DoubleToString(LastSL, Digits),", new SL: ",DoubleToString((Low[1] - (TrailingStop * P) * Point), Digits));
                     continue;
                  } else return 0;
               }
            }
//            if(UseTrailingStop && TrailingStop > 0) {                 
//              if(Bid - OrderOpenPrice() > P * Point * TrailingStop) {
//                  if(OrderStopLoss() < Bid - P * Point * TrailingStop) {
//                     Ticket2 = OrderModify(OrderTicket(), OrderOpenPrice(), Bid - P * Point * TrailingStop, OrderTakeProfit(), 0, MediumSeaGreen);
//                     continue;
//                  }
//               }
//            }            
         } else {
            //Close

            //+------------------------------------------------------------------+
            //| Signal Begin(Exit Sell)                                          |
            //+------------------------------------------------------------------+
            if (buy != NULL) Order = SIGNAL_CLOSESELL;
            
            //if (sma40_2 > sma10_2 && sma10_1 >= sma40_1) Order = SIGNAL_CLOSESELL; // Rule to EXIT a Short trade

            //+------------------------------------------------------------------+
            //| Signal End(Exit Sell)                                            |
            //+------------------------------------------------------------------+

            if (Order == SIGNAL_CLOSESELL) {
               Ticket2 = OrderClose(OrderTicket(), OrderLots(), Ask, Slippage, DarkOrange);
               //Ticket3 = Ticket;
               Print("Buy signal - Trade sell closed");
                
               if (SignalMail) SendMail("[Signal Alert]", "[" + Symbol() + "] " + DoubleToStr(Ask, Digits) + " Close Sell");
               IsTrade = False;
               continue;
            }
            //Trailing stop for sell
            if(UseTrailingStop && TrailingStop > 0) {                 
               if(sell != NULL) {
                  if(
                  (NormalizeDouble((High[1] + (Spread + StopLoss * P) * Point), Digits) < NormalizeDouble(OrderStopLoss(), Digits)) 
                  && (NormalizeDouble((High[1] + (Spread + StopLoss * P) * Point), Digits) >= NormalizeDouble((Bid+StopLevel*Point), Digits))  
                  ) {
                     LastSL = OrderStopLoss();
                     Ticket2 = OrderModify(OrderTicket(), OrderOpenPrice(), NormalizeDouble((High[1] + (Spread + StopLoss * P) * Point), Digits), OrderTakeProfit(), 0, DarkOrange);
                     Print("Sell signal - trailing stop placed: prev SL: ",DoubleToString(LastSL, Digits),", new SL: ",DoubleToString((High[1] + (Spread + StopLoss * P) * Point), Digits));
                     continue;
                  } else return 0;
               }
            }
//            if(UseTrailingStop && TrailingStop > 0) {                 
//               if((OrderOpenPrice() - Ask) > (P * Point * TrailingStop)) {
//                  if((OrderStopLoss() > (Ask + P * Point * TrailingStop)) || (OrderStopLoss() == 0)) {
//                     Ticket2 = OrderModify(OrderTicket(), OrderOpenPrice(), Ask + P * Point * TrailingStop, OrderTakeProfit(), 0, DarkOrange);
//                     continue;
//                  }
//               }
//            }
         }
      }
   }

   //+------------------------------------------------------------------+
   //| Signal Begin(Entries)                                            |
   //+------------------------------------------------------------------+

   // Code Entry Rules 
   //if (buy != NULL) Order = SIGNAL_BUY; 
   if (buy != NULL && LastOrderClosedMinAgo() >= Period()) Order = SIGNAL_BUY; // Rule to ENTER a Long trade
   
   //if (sell != NULL) Order = SIGNAL_SELL; 
   if (sell != NULL && LastOrderClosedMinAgo() >= Period()) Order = SIGNAL_SELL; // Rule to ENTER a Short trade
   
   //+------------------------------------------------------------------+
   //| Signal End                                                       |
   //+------------------------------------------------------------------+

   //Buy
   if (Order == SIGNAL_BUY) {
      if(!IsTrade) {        
         if (UseStopLoss) 
            StopLossLevel = Low[1] - (StopLoss * P) * Point;
         else StopLossLevel = 0.0;
                  
         if (UseTakeProfit) 
            TakeProfitLevel = Ask + ((Close[1] - StopLossLevel) * TakeProfit);//* P * Point; //Close[1]
         else TakeProfitLevel = 0.0;

         if (UseEquityRisk)
            if ((Ask - StopLossLevel)>0) LotsBuy = NormalizeDouble((EquityRisk*Equity/100000/(Ask-StopLossLevel)),2);                          
            else return 0;
         else LotsBuy = Lots;

         //Adjust maximum order lot size
         if (LotsBuy > MaxLots) LotsBuy = MaxLots; 
         
         Print("###CHECK BUY-"
              " Current tf: ", Period(),
              " LastOrderClosedMinAgo: ",LastOrderClosedMinAgo(), 
              " Ask: ", DoubleToString(Ask, Digits),
              " sl: ", DoubleToString(StopLossLevel, Digits),     
				  " min sl: ", DoubleToString((Ask-StopLevel*Point), Digits),
				  " tp: ", DoubleToString(TakeProfitLevel, Digits),
				  " lots: ", LotsBuy, 
				  " min lots: ", MinLots,
				  " lot step: ", MarketInfo(Symbol(), MODE_LOTSTEP),
				  " max lots: ", MarketInfo(Symbol(), MODE_MAXLOT), 
				  " margin req: ", MarketInfo(Symbol(),MODE_MARGINREQUIRED)*LotsBuy,             
              " digits : ", Digits,
              " last error : ", GetLastError(),
              "");
                       
         //Check free margin
         if (AccountFreeMargin() < (MarketInfo(Symbol(),MODE_MARGINREQUIRED) * LotsBuy)) {
            Print("###ERROR BUY - Can't trade. We have no money. Free Margin = ", AccountFreeMargin()," and Required Margin = ",MarketInfo(Symbol(),MODE_MARGINREQUIRED));
            return(0);
         }

         //Check minimum order lot size
         if (LotsBuy < MinLots) {
            Print("###ERROR BUY - Can't trade buy. Order Lots ",LotsBuy," < minimum lot size ",MinLots,". Increase EquityRisk or MarginToEquity and restart EA to trade.");
            return(0);
         }
         
         //Check minimum distance of stop loss
         if (StopLossLevel != 0.0 && (StopLossLevel > (Ask-StopLevel*Point))) {
            Print("###ERROR BUY - Can't trade buy. Order SL ",DoubleToString(StopLossLevel, Digits)," > maximum SL ",DoubleToString((Ask-StopLevel*Point), Digits));
            return(0);
         }        
         //Check max candle size to secure equity risk, when trading on fixed lots, e.g. EURUSD for 0.1 lot and maxpips 331 equity at risk is 33,1 USD (0,1 lot * 100000$ * 0,00001 pip value * 331 maxpips)
         if (!UseEquityRisk && StopLossLevel != 0.0){
            if (Ask - StopLossLevel > MaxPips*Point) {
               Print("###ERROR BUY - Can't trade buy. Ask ",DoubleToString(Ask, Digits)," - SL ",DoubleToString(StopLossLevel, Digits)," > ",MaxPips," pips");
               return(0);
            }
         }
         
         Ticket = OrderSend(Symbol(), OP_BUY, LotsBuy, Ask, Slippage, StopLossLevel, TakeProfitLevel, "Buy (EA#" + MagicNumber + ", Risk " + ((Ask - StopLossLevel)*100000*LotsBuy) + ", ToProfit "+ ((TakeProfitLevel - Ask)*100000*LotsBuy) + ")", MagicNumber, 0, DodgerBlue);
         if(Ticket > 0) {
            if (OrderSelect(Ticket, SELECT_BY_TICKET, MODE_TRADES)) {
				    Print("###BUY"
				      " order opened at: ", DoubleToString(OrderOpenPrice(),Digits),
 
				      " Lots: ", LotsBuy,
				      " sl: ", DoubleToString(StopLossLevel, Digits),//" = ", DoubleToString(Low[1], Digits)," - ", StopLoss," * ", DoubleToString(Point,Digits),
				      " tp: ", DoubleToString(TakeProfitLevel, Digits),//" = ", DoubleToString(Close[1], Digits)," + ((", DoubleToString(Close[1], Digits)," - ", DoubleToString(Low[1], Digits),") * ", TakeProfit,")",
				      " Ryzyko (Ask - SL): ", DoubleToString((OrderOpenPrice() - StopLossLevel), Digits),
				      " Zysk (TP - Close): ", DoubleToString((TakeProfitLevel - OrderOpenPrice()), Digits),
				      " Z/R: ", (TakeProfitLevel - OrderOpenPrice())/((OrderOpenPrice() - StopLossLevel)),
				      " O: ", DoubleToString(Open[1], Digits),
				      " C: ", DoubleToString(Close[1], Digits),
				      " H: ", DoubleToString(High[1], Digits),
				      " L: ", DoubleToString(Low[1], Digits)
				      );
				   Print("---"
                  " Buy: ", DoubleToString(buy, Digits),
                  " Sell: ", DoubleToString(sell, Digits),
                  " Ask: ", DoubleToString(Ask, Digits),
                  " Slippage: ", DoubleToString(Slippage, Digits),  
                  " OrderSelect: ", OrderSelect(OrderTicket(), SELECT_BY_TICKET, MODE_HISTORY),
                  " buy != NULL: ", (buy != NULL),
                  " sell != NULL: ", (sell != NULL),  
                  " LastOrderClosedMinAgo() >= Tf: ", (LastOrderClosedMinAgo()>=Period()),
                  " ticket: ", Ticket,
                  " ticket in history: ", Ticket3,
                  " digits: ", Digits,
                  " last error: ", GetLastError(),
                  "");
               Print("---"
				      " Account equity: ",AccountEquity(),
				      " Account free margin: ",AccountFreeMargin(),
				      " Account margin: ", AccountMargin(),
				      " StopOut level [%]: ", AccountStopoutLevel(),
				      " Lewar: ", AccountLeverage(),
				      " Ryzyko: ", (AccountMargin()/AccountEquity()),
				      " Ile lotów buy: ", LotsBuy,
				      " Ile lotów sell: ", LotsSell,
				      " Min lot: ", MinLots
                  );
               if (SignalMail) SendMail("[Signal Alert]", "[" + Symbol() + "] " + DoubleToStr(Ask, Digits) + " Open Buy");
			   } 
			   else {
				Print("###ERROR BUY - error opening order : ", GetLastError());
			   }
         }
         return(0);
      }
   }

   //Sell
   if (Order == SIGNAL_SELL) {
      if(!IsTrade) {
         if (UseStopLoss) 
            StopLossLevel = High[1] + (Spread + StopLoss * P) * Point;
         else StopLossLevel = 0.0;
                
         if (UseTakeProfit) 
            TakeProfitLevel = Bid - ((StopLossLevel - Close[1]) * TakeProfit);//* P * Point; //Close[1]
         else TakeProfitLevel = 0.0;

         if (UseEquityRisk)
            if ((StopLossLevel-Bid)>0)
               LotsSell = NormalizeDouble((EquityRisk*Equity/100000/(StopLossLevel-Bid)),2);
            else return 0;
         else LotsSell = Lots;
         
         //Adjust maximum order lot size
         if (LotsSell > MaxLots) LotsSell = MaxLots; 
         
         Print("###CHECK SELL -"
              " Current tf: ", Period(),
              " LastOrderClosedMinAgo: ",LastOrderClosedMinAgo(), 
              " Bid: ", DoubleToString(Bid, Digits),
				  " sl: ", DoubleToString(StopLossLevel, Digits),          
				  " min sl: ", DoubleToString((Bid+StopLevel*Point), Digits),
				  " tp: ", DoubleToString(TakeProfitLevel, Digits),
				  " lots: ", LotsSell,
				  " min lots: ", MinLots,
				  " lot step: ", MarketInfo(Symbol(), MODE_LOTSTEP),
				  " max lots: ", MarketInfo(Symbol(), MODE_MAXLOT),    
              " margin req: ", MarketInfo(Symbol(),MODE_MARGINREQUIRED)*LotsSell,             
              " digits: ", Digits,
              " last error: ", GetLastError(),
              "");
                                   
         //Check free margin
         if (AccountFreeMargin() < (MarketInfo(Symbol(),MODE_MARGINREQUIRED) * LotsBuy)) {
            Print("###ERROR SELL - Can't trade. We have no money. Free Margin = ", AccountFreeMargin()," and Required Margin = ",MarketInfo(Symbol(),MODE_MARGINREQUIRED));
            return(0);
         }
         
         //Check minimum order lot size
         if (LotsSell < MinLots) {
            Print("###ERROR SELL - Can't trade sell. Order Lots ",LotsSell," < minimum lot size ",MinLots,". Increase EquityRisk or MarginToEquity and restart EA to trade.");
            return(0);
         }
         
         //Check minimum distance of stop loss
         if (StopLossLevel != 0.0 && (StopLossLevel < (Bid+StopLevel*Point))) {
            Print("###ERROR SELL - Can't trade sell. Order SL ",DoubleToString(StopLossLevel, Digits)," < minimum SL ", DoubleToString((Bid+StopLevel*Point), Digits));
            return(0);
         }
         
         //Check max candle size to secure equity risk, when trading on fixed lots, e.g. EURUSD for 0.1 lot and maxpips 331 equity at risk is 33,1 USD (0,1 lot * 100000$ * 0,00001 pip value * 331 maxpips)
         if (!UseEquityRisk && StopLossLevel != 0.0){
            if (StopLossLevel - Bid > MaxPips*Point) {
               Print("###ERROR SELL - Can't trade sell. SL ",DoubleToString(StopLossLevel, Digits)," - Bid ",DoubleToString(Bid, Digits)," > ",MaxPips," pips");
               return(0);
            }
         }
         
         Ticket = OrderSend(Symbol(), OP_SELL, LotsSell, Bid, Slippage, StopLossLevel, TakeProfitLevel, "Sell (EA#" + MagicNumber + "), Risk " + ((StopLossLevel - Bid)*100000*LotsBuy) + ", ToProfit "+ ((Bid - TakeProfitLevel)*100000*LotsBuy), MagicNumber, 0, DeepPink);
         if(Ticket > 0) {
            if (OrderSelect(Ticket, SELECT_BY_TICKET, MODE_TRADES)) {
				   Print("###SELL"
				      " order opened at: ", DoubleToString(OrderOpenPrice(),Digits),
				      " Lots: ", LotsSell,
				      " sl: ", DoubleToString(StopLossLevel, Digits),//" = ", DoubleToString(High[1], Digits)," + ", StopLoss," * ", DoubleToString(Point,Digits),
				      " tp: ", DoubleToString(TakeProfitLevel, Digits),//" = ", DoubleToString(Close[1], Digits)," - ((", DoubleToString(High[1], Digits)," - ", DoubleToString(Close[1], Digits),") * ", TakeProfit,")",
				      " Ryzyko (SL - Close): ", DoubleToString((StopLossLevel - OrderOpenPrice()), Digits),
				      " Zysk (Bid - TP): ", DoubleToString((OrderOpenPrice() - TakeProfitLevel), Digits),
				      " Z/R : ", ((OrderOpenPrice() - TakeProfitLevel))/(StopLossLevel - OrderOpenPrice()),
				      " O: ", DoubleToString(Open[1], Digits),
				      " C: ", DoubleToString(Close[1], Digits),
				      " H: ", DoubleToString(High[1], Digits),
				      " L: ", DoubleToString(Low[1], Digits)
				      );
				   Print("---"
                  " Sell: ", DoubleToString(sell, Digits),
                  " Buy: ", DoubleToString(buy, Digits),
                  " Bid: ", DoubleToString(Bid, Digits),
                  " Slippage: ", DoubleToString(Slippage, Digits),  
                  " OrderSelect: ", OrderSelect(OrderTicket(), SELECT_BY_TICKET, MODE_HISTORY),
                  " buy != NULL: ", (buy != NULL),
                  " sell != NULL: ", (sell != NULL),  
                  " LastOrderClosedMinAgo() >= Timeframe: ", (LastOrderClosedMinAgo()>=Period()),
                  " ticket: ", Ticket,
                  " ticket in history: ", Ticket3,
                  " digits: ", Digits,
                  " last error: ", GetLastError(),
                  "");
               Print("---"
				      " Account equity: ",AccountEquity(),
				      " Account free margin: ",AccountFreeMargin(),
				      " Account margin: ", AccountMargin(),
				      " StopOut level [%]: ", AccountStopoutLevel(),
				      " Lewar: ", AccountLeverage(),
				      " Ryzyko: ", (AccountMargin()/AccountEquity()),
				      " Ile lotów buy: ", LotsBuy,
				      " Ile lotów sell: ", LotsSell,
				      " Min lot: ", MinLots
                  );

               if (SignalMail) SendMail("[Signal Alert]", "[" + Symbol() + "] " + DoubleToStr(Bid, Digits) + " Open Sell");
			} else {
				Print("###ERROR - Error opening order : ", GetLastError());
			}
         }
         return(0);
      }
   }

   return(0);
}
//+------------------------------------------------------------------+
