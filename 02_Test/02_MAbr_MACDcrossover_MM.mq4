//+------------------------------------------------------------------+
//|   This MQL created by Milosz Abramczyk                           |
//|                                                                  |
//|   ENTRY RULES:                                                   |
//|                                                                  |
//|   EXIT RULES:                                                    |
//|                                                                  |
//|   POSITION SIZING RULE:                                          |                                                               
//|                                                                  |
//+------------------- DO NOT REMOVE THIS HEADER --------------------+
   
#define SIGNAL_NONE 0
#define SIGNAL_BUY   1
#define SIGNAL_SELL  2
#define SIGNAL_CLOSEBUY 3
#define SIGNAL_CLOSESELL 4

// EA values
// Stop Loss, Take Profit and Position Sizing

extern bool UseEquityRisk = True;
extern double EquityRisk = 0.01;
extern double MarginToEquity = 0.3;
extern double Lots = 0.1;
extern int MaxPips = 331;
extern int MaxSpread = 20;
extern int Slippage = 3;
extern bool UseStopLoss = True;
extern double StopLoss = 11.5; // min 0.1 (1 point)
extern bool UseTakeProfit = True;
extern double TakeProfit = 5.6; // min 0
extern bool UseTrailingStop = True;
extern double TrailingStop = 3.9;
extern int MagicNumber = 1;
extern bool SignalMail = False;
extern int StopLossBarDistance = 10;
extern int SlowMA_period = 200;
extern bool BuyOnly = True;
extern bool SellOnly = True;
extern bool UseTradeHours = True;
extern int StartHour = 8;
extern int StopHour = 17;
extern bool CloseOrdersOutsideTradingHours = False;


// Declare Variables and functions
int P = 1;
int Order = SIGNAL_NONE;
int Total, Ticket, Ticket2, Ticket3, LotStep;
double price, ma_faster, ma_slower, macd_main_prev, macd_main_actual, macd_signal_prev, macd_signal_actual;
double StopLossLevel, TakeProfitLevel, StopLevel, LotsBuy, MinLots, MaxLots, LotsSell, Spread, Equity, LastSL, LotSize, TrailingStep;
double SL_sell, SL_buy;


//int LastOrderClosedMinAgo() {
//   if (OrdersHistoryTotal() > 0){
//      Ticket3 = OrdersHistoryTotal()-1; 
//      if (OrderSelect(Ticket3, SELECT_BY_POS, MODE_HISTORY)){ 
//         return((TimeCurrent() - OrderCloseTime())/60);
//         }
//      else{ 
//         Print("LastOrderClosedMinAgo(): OrderSelect error code = ",GetLastError(),", Ticket 3 = ",Ticket3);
//         return 0;
//         }
//   }
//   else   
//      return Period();
//}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int init() {  
   if(Digits == 5 || Digits == 3 || Digits == 1) P = 10; // P = 10
   else P = 1; // To account for 5 digit brokers
   
   if(MarketInfo(Symbol(), MODE_LOTSTEP) == 1) LotStep = 0;
   else if (MarketInfo(Symbol(), MODE_LOTSTEP) == 0.1) LotStep = 1;
   else LotStep = 2;
   
   
   Print("--- TOBOR v2 started ---");
   Print("Market info -"
         " Current symbol: ", Symbol(),
         " Current tf: ", Period(),
         " digits: ", Digits,
         " Trade allowed: ",MarketInfo(Symbol(),MODE_TRADEALLOWED),
         " 1 Lot size: ",MarketInfo(Symbol(),MODE_LOTSIZE),
         " Margin req for 1 Lot: ", MarketInfo(Symbol(),MODE_MARGINREQUIRED),            
         "");
   Print("Account info -"
         " Broker: ", AccountCompany(),
         " Leverage: ", AccountLeverage(),
         " Balance: ", AccountBalance(),
         " Equity: ", AccountEquity(),
         " Free margin: ", AccountFreeMargin(),
         " Margin call: ", AccountInfoDouble(ACCOUNT_MARGIN_SO_CALL),
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
  
   Print("--- TOBOR v2 stopped ---");
   return(0);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function - END                           |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Expert start function                                            |
//+------------------------------------------------------------------+
int start() {
   static datetime PrevBarTime = Time[1];
   if (PrevBarTime == Time[0]) return 0;
   PrevBarTime = Time[0];
   
   Total = OrdersTotal();
   Order = SIGNAL_NONE;
   
   //+------------------------------------------------------------------+
   //| Variable Setup                                                   |
   //+------------------------------------------------------------------+
 
   // Assign Values to variables
   //ma_faster = iMA(NULL, 0, FastMA_period, 0, MODE_EMA, PRICE_CLOSE, 1);
   ma_slower = iMA(NULL, 0, SlowMA_period, 0, MODE_EMA, PRICE_CLOSE, 1);
   macd_main_prev = iMACD(NULL, 0, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 2);
   macd_main_actual = iMACD(NULL, 0, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 1);
   macd_signal_prev = iMACD(NULL, 0, 12, 26, 9, PRICE_CLOSE, MODE_SIGNAL, 2);
   macd_signal_actual = iMACD(NULL, 0, 12, 26, 9, PRICE_CLOSE, MODE_SIGNAL, 1);

   Spread = MarketInfo(Symbol(), MODE_SPREAD); 
   StopLevel = (MarketInfo(Symbol(), MODE_STOPLEVEL) + MarketInfo(Symbol(), MODE_SPREAD)); //  /P; // Checking broker min SL
   MinLots = MarketInfo(Symbol(),MODE_MINLOT);
   MaxLots = NormalizeDouble((MarginToEquity*(AccountFreeMargin() / MarketInfo(Symbol(),MODE_MARGINREQUIRED))),2);
   //SL_sell = High[1];
   SL_sell = High[iHighest(NULL, 0, MODE_HIGH, StopLossBarDistance, 1)];   
   //SL_buy = Low[1]; 
   SL_buy = Low[iLowest(NULL, 0, MODE_LOW, StopLossBarDistance, 1)];  
   Equity = AccountEquity();
   LotSize = MarketInfo(Symbol(),MODE_LOTSIZE);
      
   //LotsBuy = MarginRisk*AccountEquity()*AccountLeverage()/Ask/100000;
   //LotsSell = MarginRisk*AccountEquity()*AccountLeverage()/Bid/100000;     
   //if (StopLoss < StopLevel) StopLoss = StopLevel; // Defining minimum SL and TP of current asset to prevent OrderSend error 130 
   //if (TakeProfit < StopLevel) TakeProfit = StopLevel;
   
   //+------------------------------------------------------------------+
   //| Variable Setup - END                                             |
   //+------------------------------------------------------------------+
             
   //Check position
   bool IsTrade = False;

   for (int i = 0; i < Total; i ++) {
      Ticket2 = OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
      if(OrderType() <= OP_SELL &&  OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber) {
         IsTrade = True;
         if(OrderType() == OP_BUY) {
            //Close
            //+------------------------------------------------------------------+
            //| Signal Begin(Exit Buy)                                           |
            //+------------------------------------------------------------------+          
            
            // Code Exit Rules  
            
            // Rule to EXIT a Long trade      
            if (CloseOrdersOutsideTradingHours){               
               if (Hour()<StartHour){
               Print("###BUY - Closing order, outside trading hours = ", StartHour," - ", StopHour);
               Order = SIGNAL_CLOSEBUY;
               }
               if (Hour()>=StopHour && Minute()>=0){
               Print("###BUY - Closing order, outside trading hours = ", StartHour," - ", StopHour);
               Order = SIGNAL_CLOSEBUY;
               } 
            }
            //+------------------------------------------------------------------+
            //| Signal End(Exit Buy)                                             |
            //+------------------------------------------------------------------+

            if (Order == SIGNAL_CLOSEBUY) {           
               Ticket2 = OrderClose(OrderTicket(), OrderLots(), Bid, Slippage, MediumSeaGreen);
               Print("Buy signal - Trade buy closed"); 

               if (SignalMail) SendMail("[Signal Alert]", "[" + Symbol() + "] " + DoubleToStr(Bid, Digits) + " Close Buy");
               IsTrade = False;
               continue;
            }
            
            //Trailing stop for buy
            if(UseTrailingStop && TrailingStop > 0) {
               if(Bid - OrderOpenPrice() >= TrailingStep * TrailingStop) {
                  if(StopLossLevel == 0) {
                     Print("### ERRROR BUY - can't set trailing stop. StopLossLevel is set to 0");
                     continue;
                  }   
                  if (OrderStopLoss() < OrderOpenPrice()) {
                     Ticket2 = OrderModify(OrderTicket(), OrderOpenPrice(), NormalizeDouble(OrderOpenPrice(), Digits), OrderTakeProfit(), 0, MediumSeaGreen);
                     if(Ticket2 > 0) {
                        if (OrderSelect(Ticket, SELECT_BY_TICKET, MODE_TRADES)) {
                           Print("Buy signal - trailing stop placed for break even, next SL = ",DoubleToString(OrderStopLoss() + (TrailingStep * TrailingStop), Digits), " when price hits ", DoubleToString(OrderStopLoss() + 2*(TrailingStep * TrailingStop), Digits));
                           continue;
                           if (SignalMail) SendMail("[Signal Alert]", "[" + Symbol() + "] " + DoubleToStr(Ask, Digits) + " TarilingStop Buy");
			               } 
			               else {
				               Print("###ERROR BUY - error modifing order : ", GetLastError());
			               }
                     }
                  }
                  if((OrderStopLoss() >= OrderOpenPrice()) && (Bid - OrderStopLoss() >= 2*(TrailingStep * TrailingStop))) {
                     //LastSL = OrderStopLoss();
                     Ticket2 = OrderModify(OrderTicket(), OrderOpenPrice(), NormalizeDouble((OrderStopLoss() + (TrailingStep * TrailingStop)), Digits), 0, 0, MediumSeaGreen);
                     if(Ticket2 > 0) {
                        if (OrderSelect(Ticket, SELECT_BY_TICKET, MODE_TRADES)) {
                           Print("Buy signal - trailing stop placed: next SL = ",DoubleToString(OrderStopLoss() + (TrailingStep * TrailingStop), Digits), " when price hits ", DoubleToString(OrderStopLoss() + 2*(TrailingStep * TrailingStop), Digits));
                           continue;
                           if (SignalMail) SendMail("[Signal Alert]", "[" + Symbol() + "] " + DoubleToStr(Ask, Digits) + " TarilingStop Buy");
			               } 
			               else {
				               Print("###ERROR BUY - error modifing order : ", GetLastError());
			               }
                     }
                  }
               }
               
               // poprzednia wersja              
               //if (Bid > OrderOpenPrice()) {
               //   if ((NormalizeDouble((Low[1] - (Spread + TrailingStop * P)*Point),Digits) > NormalizeDouble(OrderStopLoss(), Digits)) || (OrderStopLoss() == 0)) { 
               //      LastSL = OrderStopLoss();
               //      Ticket2 = OrderModify(OrderTicket(), OrderOpenPrice(), NormalizeDouble((Low[1] - (TrailingStop * P) * Point), Digits), OrderTakeProfit(), 0, MediumSeaGreen);
               //      Print("Buy signal - trailing stop placed: prev SL = ",DoubleToString(LastSL, Digits),", new SL = ",DoubleToString((Low[1] - (TrailingStop * P) * Point), Digits));
               //      continue;
               //   } 
               //}
               
               // najstarsza wersja       
               //if(buy != NULL) {
               //   if(
               //      (NormalizeDouble((Low[1] - (Spread + TrailingStop * P)*Point),Digits) > NormalizeDouble(OrderStopLoss(), Digits)) 
               //      && (NormalizeDouble((Low[1] - (Spread + TrailingStop * P)*Point),Digits) > OrderOpenPrice()) // <= NormalizeDouble((Ask-StopLevel*Point),Digits)) 
               //   ) 
               //   {
               //      LastSL = OrderStopLoss();
               //      Ticket2 = OrderModify(OrderTicket(), OrderOpenPrice(), NormalizeDouble((Low[1] - (TrailingStop * P) * Point), Digits), OrderTakeProfit(), 0, MediumSeaGreen);
               //      Print("Buy signal - trailing stop placed: prev SL: ",DoubleToString(LastSL, Digits),", new SL: ",DoubleToString((Low[1] - (TrailingStop * P) * Point), Digits));
               //      continue;
               //   } else return 0;
               ////}
               
            }
//            if(UseTrailingStop && TrailingStop > 0) {                 
//              if(Bid - OrderOpenPrice() > P * Point * TrailingStop) {
//                  if(OrderStopLoss() < Bid - P * Point * TrailingStop) {
//                     Ticket2 = OrderModify(OrderTicket(), OrderOpenPrice(), Bid - P * Point * TrailingStop, OrderTakeProfit(), 0, MediumSeaGreen);
//                     continue;
//                  }
//               }
//            }            
         } 
         else {
            //Close
            //+------------------------------------------------------------------+
            //| Signal Begin(Exit Sell)                                          |
            //+------------------------------------------------------------------+
            
            // Rule to EXIT a Short trade
            if (CloseOrdersOutsideTradingHours){               
               if (Hour()<StartHour){
               Print("###SELL - Closing order, outside trading hours = ", StartHour," - ", StopHour);
               Order = SIGNAL_CLOSESELL;
               }
               if (Hour()>=StopHour && Minute()>=0){
               Print("###SELL - Closing order, outside trading hours = ", StartHour," - ", StopHour);
               Order = SIGNAL_CLOSESELL;
               }
            }
            //+------------------------------------------------------------------+
            //| Signal End(Exit Sell)                                            |
            //+------------------------------------------------------------------+

            if (Order == SIGNAL_CLOSESELL) {
               Ticket2 = OrderClose(OrderTicket(), OrderLots(), Ask, Slippage, DarkOrange);
               //Ticket3 = Ticket;
               Print("Sell signal - Trade sell closed");
                
               if (SignalMail) SendMail("[Signal Alert]", "[" + Symbol() + "] " + DoubleToStr(Ask, Digits) + " Close Sell");
               IsTrade = False;
               continue;
            }
            
            //Trailing stop for sell
            if(UseTrailingStop && TrailingStop > 0) {
               if(OrderOpenPrice() - Ask >= TrailingStep * TrailingStop) {
                  if(StopLossLevel == 0) {
                     Print("### ERRROR SELL - can't set trailing stop. StopLossLevel is set to 0");
                     continue;
                  }   
                  if (OrderStopLoss() > OrderOpenPrice()) {
                     Ticket2 = OrderModify(OrderTicket(), OrderOpenPrice(), NormalizeDouble(OrderOpenPrice(), Digits), OrderTakeProfit(), 0, MediumSeaGreen);
                     if(Ticket2 > 0) {
                        if (OrderSelect(Ticket, SELECT_BY_TICKET, MODE_TRADES)) {
                           Print("Sell signal - trailing stop placed for break even, next SL = ",DoubleToString(OrderStopLoss() - (TrailingStep * TrailingStop), Digits), " when price hits ", DoubleToString(OrderStopLoss() - 2*(TrailingStep * TrailingStop), Digits));
                           continue;
                           if (SignalMail) SendMail("[Signal Alert]", "[" + Symbol() + "] " + DoubleToStr(Ask, Digits) + " TarilingStop Sell");
			               } 
			               else {
				               Print("###ERROR SELL - error modifing order : ", GetLastError());
			               }
                     }
                  }
                  if((OrderStopLoss() <= OrderOpenPrice()) && (OrderStopLoss() - Ask >= 2*(TrailingStep * TrailingStop))) {
                     //LastSL = OrderStopLoss();
                     Ticket2 = OrderModify(OrderTicket(), OrderOpenPrice(), NormalizeDouble((OrderStopLoss() - (TrailingStep * TrailingStop)), Digits), 0, 0, MediumSeaGreen);
                     if(Ticket2 > 0) {
                        if (OrderSelect(Ticket, SELECT_BY_TICKET, MODE_TRADES)) {
                           Print("Buy signal - trailing stop placed: next SL = ",DoubleToString(OrderStopLoss() - (TrailingStep * TrailingStop), Digits), " when price hits ", DoubleToString(OrderStopLoss() - 2*(TrailingStep * TrailingStop), Digits));
                           continue;
                           if (SignalMail) SendMail("[Signal Alert]", "[" + Symbol() + "] " + DoubleToStr(Ask, Digits) + " TarilingStop Sell");
			               } 
			               else {
				               Print("###ERROR SELL - error modifing order : ", GetLastError());
			               }
                     }
                  }
               }               
               
               
               // poprzednia wersja - dla buy zapomanilem skomentowac
               //if((OrderOpenPrice() - Ask) >= (TrailingStep * TrailingStop)) {
               //   if(StopLossLevel == 0) Print("### ERRROR SELL - no stop loss for trailing stop");
               //   if((OrderStopLoss() - Ask) >= (TrailingStep * TrailingStop)+TrailingStep) {
               //      LastSL = OrderStopLoss();
               //      Ticket2 = OrderModify(OrderTicket(), OrderOpenPrice(), NormalizeDouble((LastSL - (TrailingStep * TrailingStop)), Digits), 0, 0, DarkOrange);
               //      Print("Sell signal - trailing stop placed: prev SL: ",DoubleToString(LastSL, Digits),", new SL: ",DoubleToString((LastSL - (TrailingStep * TrailingStop)), Digits));
               //      continue;
               //   }
               //}
                  
               // poprzednia wersja
               //if (Ask < OrderOpenPrice()) {
               //   if ((NormalizeDouble((High[1] + (Spread + TrailingStop * P) * Point), Digits) < NormalizeDouble(OrderStopLoss(), Digits)) || (OrderStopLoss() == 0)) {  // >= NormalizeDouble((Bid+StopLevel*Point), Digits))  
               //      LastSL = OrderStopLoss();
               //      Ticket2 = OrderModify(OrderTicket(), OrderOpenPrice(), NormalizeDouble((High[1] + (Spread + TrailingStop * P) * Point), Digits), OrderTakeProfit(), 0, DarkOrange);
               //      Print("Sell signal - trailing stop placed: prev SL: ",DoubleToString(LastSL, Digits),", new SL: ",DoubleToString((High[1] + (Spread + StopLoss * P) * Point), Digits));
               //      continue;
               //   }
               //}
               
               // najstarsza wersja                 
               ////if(sell != NULL) {
               //   if(
               //   (NormalizeDouble((High[1] + (Spread + TrailingStop * P) * Point), Digits) < NormalizeDouble(OrderStopLoss(), Digits)) 
               //   && (NormalizeDouble((High[1] + (Spread + TrailingStop * P) * Point), Digits) < OrderOpenPrice()) // >= NormalizeDouble((Bid+StopLevel*Point), Digits))  
               //   ) {
               //      LastSL = OrderStopLoss();
               //      Ticket2 = OrderModify(OrderTicket(), OrderOpenPrice(), NormalizeDouble((High[1] + (Spread + TrailingStop * P) * Point), Digits), OrderTakeProfit(), 0, DarkOrange);
               //      Print("Sell signal - trailing stop placed: prev SL: ",DoubleToString(LastSL, Digits),", new SL: ",DoubleToString((High[1] + (Spread + StopLoss * P) * Point), Digits));
               //      continue;
               //   } else return 0;
               ////}
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
   //| Signal Begin (Entries)                                           |
   //+------------------------------------------------------------------+
   
   // Code Entry Rules 
   
   // Rule to ENTER a Long trade
   if (
      macd_main_prev < macd_signal_prev
      && macd_main_actual >= macd_signal_actual
      && macd_main_prev < 0
      && macd_main_actual < 0
      && macd_signal_prev < 0
      && macd_signal_actual < 0
      && Low[1] > ma_slower 
      //&& LastOrderClosedMinAgo() >= Period()
      && BuyOnly == True
      ) Order = SIGNAL_BUY; // Rule to ENTER a Long trade
   
   // Rule to ENTER a Short trade
   if (
      macd_main_prev > macd_signal_prev
      && macd_main_actual <= macd_signal_actual
      && macd_main_prev > 0
      && macd_main_actual > 0
      && macd_signal_prev > 0
      && macd_signal_actual > 0
      && High[1] < ma_slower  
      //&& LastOrderClosedMinAgo() >= Period()
      && SellOnly == True
      ) Order = SIGNAL_SELL;  
   //+------------------------------------------------------------------+
   //| Signal End                                                       |
   //+------------------------------------------------------------------+

   //Buy
   if (Order == SIGNAL_BUY) {
      Print("Buy signal - checking entry params");
      if(!IsTrade) {                       
         //Adjust order stop loss
         if (UseStopLoss) 
            StopLossLevel = SL_buy - (StopLoss * P) * Point;
         else StopLossLevel = 0.0;
         
         //Adjust order take profit         
         if (UseTakeProfit)
            if (StopLossLevel == 0.0)
               TakeProfitLevel = Ask + TakeProfit * Point * P;
            else TakeProfitLevel = Ask + ((Close[1] - StopLossLevel) * TakeProfit) + (Spread * Point);//* P * Point; //Close[1]
         else TakeProfitLevel = 0.0;
         
         //Adjust order lot size
         if (UseEquityRisk)
            if ((Ask - StopLossLevel)>0 && StopLossLevel != 0.0) 
               LotsBuy = EquityRisk*Equity/LotSize/(Ask-StopLossLevel);                         
            else LotsBuy = Lots;
         else LotsBuy = Lots;

         //Adjust maximum order lot size
         if (LotsBuy > MaxLots) LotsBuy = MaxLots; 
         
      //   Print("###CHECK BUY-"
      //        " BuyOnly: ", BuyOnly,
      //        " Current tf: ", Period(),
      //        " LastOrderClosedMinAgo: ",LastOrderClosedMinAgo(), 
      //        " Ask: ", DoubleToString(Ask, Digits),
      //        " sl: ", DoubleToString(StopLossLevel, Digits),     
		//        " min sl: ", DoubleToString((Ask-StopLevel*Point), Digits),
		//        " tp: ", DoubleToString(TakeProfitLevel, Digits),
		//        " lots: ", LotsBuy, 
		//        " min lots: ", MinLots,
		//        " lot step: ", MarketInfo(Symbol(), MODE_LOTSTEP),
		//        " lot digits: ", LotStep,
		//        " max lots: ", MarketInfo(Symbol(), MODE_MAXLOT), 
		//        " margin req: ", MarketInfo(Symbol(),MODE_MARGINREQUIRED)*LotsBuy,             
      //        " digits : ", Digits,
      //        " last error : ", GetLastError(),
      //        "");
       
         //Check trading hours
         if (UseTradeHours){ 
            if (Hour()<StartHour){
               Print("###ERROR BUY - Outside trading hours = ", StartHour," - ", StopHour);
               return(0);
            }
            if (Hour()>=StopHour && Minute()>=0){
               Print("###ERROR BUY - Outside trading hours = ", StartHour," - ", StopHour);
               return(0);
            }
         }
                        
         //Check free margin
         if (AccountFreeMargin() < (MarketInfo(Symbol(),MODE_MARGINREQUIRED) * LotsBuy)) {
            Print("###ERROR BUY - Can't trade. We have no money. Free Margin = ", AccountFreeMargin()," and Required Margin = ",MarketInfo(Symbol(),MODE_MARGINREQUIRED));
            return(0);
         }

         //Check minimum order lot size
         if (LotsBuy < MinLots) {
            Print("###ERROR BUY - Can't trade buy. Lot size to small. Order Lots ",LotsBuy," < minimum lot size ",MinLots,". Increase EquityRisk or MarginToEquity and restart EA to trade.");
            return(0);
         }
         
         //Check minimum distance of stop loss
         if (StopLossLevel != 0.0 && (StopLossLevel > (Ask-StopLevel*Point))) {
            Print("###ERROR BUY - Can't trade buy. SL to close. Order SL ",DoubleToString(StopLossLevel, Digits)," > maximum SL ",DoubleToString((Ask-StopLevel*Point), Digits));
            return(0);
         }        
         //Check max candle size to secure equity risk, when trading on fixed lots, e.g. EURUSD for 0.1 lot and maxpips 331 equity at risk is 33,1 USD (0,1 lot * 100000$ * 0,00001 pip value * 331 maxpips)
         if (!UseEquityRisk && StopLossLevel != 0.0){
            if (Ask - StopLossLevel > MaxPips*Point) {
               Print("###ERROR BUY - Can't trade buy. Equity risk to high. Ask ",DoubleToString(Ask, Digits)," - SL ",DoubleToString(StopLossLevel, Digits)," > MaxPips ",MaxPips," pips");
               return(0);
            }
         }
         
         Ticket = OrderSend(Symbol(), OP_BUY, NormalizeDouble(LotsBuy,LotStep), Ask, Slippage, NormalizeDouble(StopLossLevel, Digits), NormalizeDouble(TakeProfitLevel, Digits), "Buy (EA#"+MagicNumber+")", MagicNumber, 0, DodgerBlue);
         if(Ticket > 0) {
            if (OrderSelect(Ticket, SELECT_BY_TICKET, MODE_TRADES)) {
				    TrailingStep = OrderOpenPrice() - OrderStopLoss();
				    Print("###BUY"
				      " order price: ", DoubleToString(OrderOpenPrice(),Digits),
				      " SL: ", DoubleToString(StopLossLevel, Digits),//" = ", DoubleToString(Low[1], Digits)," - ", StopLoss," * ", DoubleToString(Point,Digits),
				      " TP: ", DoubleToString(TakeProfitLevel, Digits),//" = ", DoubleToString(Close[1], Digits)," + ((", DoubleToString(Close[1], Digits)," - ", DoubleToString(Low[1], Digits),") * ", TakeProfit,")",
				      " Lots: ", LotsBuy,
				      " Last iLowest", StopLossBarDistance,": ", DoubleToString(SL_buy, Digits),
				      "");
				    Print("---"  
				    	" Risk (Ask - SL): ", DoubleToString((OrderOpenPrice() - OrderStopLoss()), Digits),
				      " Profit (TP - Close): ", DoubleToString((OrderTakeProfit() - OrderOpenPrice()), Digits),
				      " Risk to Profit: ", (OrderTakeProfit() - OrderOpenPrice())/(OrderOpenPrice() - OrderStopLoss()),
				    	" Money at risk: ", MarketInfo(Symbol(), MODE_TICKVALUE)*((OrderOpenPrice() - OrderStopLoss())*LotSize*LotsBuy),
                  " Money to gain: ", MarketInfo(Symbol(), MODE_TICKVALUE)*((OrderTakeProfit() - OrderOpenPrice())*LotSize*LotsBuy)
				      );
				   Print("---"
                  " Ask: ", DoubleToString(Ask, Digits),
                  " Slippage: ", DoubleToString(Slippage, Digits),  
                  " OrderSelect: ", OrderSelect(OrderTicket(), SELECT_BY_TICKET, MODE_HISTORY),
                  //" LastOrderClosedMinAgo() >= Tf: ", (LastOrderClosedMinAgo()>=Period()),
                  " ticket: ", Ticket,
                  " ticket in history: ", Ticket3,
                  " digits: ", Digits,
                  " last error: ", GetLastError(),
                  "");
               Print("---"
				      " Account equity: ",AccountEquity(),
				      " Account free margin: ",AccountFreeMargin(),
				      " Account margin: ", AccountMargin(),
				      " Ryzyko: ", (AccountMargin()/AccountEquity()),
				      " Min lot: ", MinLots,
                  "");
               if(UseTrailingStop) {
                  Print("---"
				      " TrailingStop ratio: ",TrailingStop,
				      " Trailing step in pips: ",DoubleToString(TrailingStep*TrailingStop, Digits),
				      " Next SL value: ", DoubleToString(OrderOpenPrice(), Digits),
				      " when price hits: ", DoubleToString(OrderOpenPrice() + (TrailingStep * TrailingStop), Digits),
                  "");
                }
               if (SignalMail) SendMail("[Signal Alert]", "[" + Symbol() + "] " + DoubleToStr(Ask, Digits) + " Open Buy");
			   } 
			   else {
				Print("###ERROR BUY - error opening order : ", GetLastError());
			   }
         }
         return(0);
      }
      Print("###ERROR BUY - only one open order allowed");
   }

   //Sell
   if (Order == SIGNAL_SELL) {
      Print("Sell signal - checking entry params");
      if(!IsTrade) {
         //Adjust order stop loss
         if (UseStopLoss) 
            StopLossLevel = SL_sell + (StopLoss * P) * Point;
         else StopLossLevel = 0.0;
         
         //Adjust order take profit       
         if (UseTakeProfit)
            if (StopLossLevel == 0.0)
               TakeProfitLevel = Bid - TakeProfit * Point * P;
            else TakeProfitLevel = Bid - ((StopLossLevel - Close[1]) * TakeProfit) - (Spread * Point);//* P * Point; //Close[1]
         else TakeProfitLevel = 0.0;
         
         //Adjust order lot size
         if (UseEquityRisk)
            if ((StopLossLevel-Bid)>0 && StopLossLevel != 0.0)
               LotsSell = EquityRisk*Equity/LotSize/(StopLossLevel-Bid);
            else LotsSell = Lots;
         else LotsSell = Lots;
         
         //Adjust maximum order lot size
         if (LotsSell > MaxLots) LotsSell = MaxLots; 
         
      //   Print("###CHECK SELL -"
      //        " SellOnly: ", SellOnly,
      //        " Current tf: ", Period(),
      //        " LastOrderClosedMinAgo: ",LastOrderClosedMinAgo(), 
      //        " Bid: ", DoubleToString(Bid, Digits),
	   //        " sl: ", DoubleToString(StopLossLevel, Digits),          
		//        " min sl: ", DoubleToString((Bid+StopLevel*Point), Digits),
		//        " tp: ", DoubleToString(TakeProfitLevel, Digits),
		//        " lots: ", LotsSell,
		//        " min lots: ", MinLots,
		//        " lot step: ", MarketInfo(Symbol(), MODE_LOTSTEP),
		//        " lot digits: ", LotStep,
		//        " max lots: ", MarketInfo(Symbol(), MODE_MAXLOT),    
      //        " margin req: ", MarketInfo(Symbol(),MODE_MARGINREQUIRED)*LotsSell,             
      //        " digits: ", Digits,
      //        " last error: ", GetLastError(),
      //        "");

         //Check trading hours
         if (UseTradeHours){ 
            if (Hour()<StartHour){
               Print("###ERROR SELL - Outside trading hours = ", StartHour," - ", StopHour);
               return(0);
            }
            if (Hour()>=StopHour && Minute()>=0){
               Print("###ERROR SELL - Outside trading hours = ", StartHour," - ", StopHour);
               return(0);
            }
         }
                                   
         //Check free margin
         if (AccountFreeMargin() < (MarketInfo(Symbol(),MODE_MARGINREQUIRED) * LotsSell)) {
            Print("###ERROR SELL - Can't trade. We have no money. Free Margin = ", AccountFreeMargin()," and Required Margin = ",MarketInfo(Symbol(),MODE_MARGINREQUIRED));
            return(0);
         }
         
         //Check minimum order lot size
         if (LotsSell < MinLots) {
            Print("###ERROR SELL - Can't trade sell. Lot size to small. Order Lots ",LotsSell," < minimum lot size ",MinLots,". Increase EquityRisk or MarginToEquity and restart EA to trade.");
            return(0);
         }
         
         //Check minimum distance of stop loss
         if (StopLossLevel != 0.0 && (StopLossLevel < (Bid+StopLevel*Point))) {
            Print("###ERROR SELL - Can't trade sell. SL to close. Order SL ",DoubleToString(StopLossLevel, Digits)," < minimum SL ", DoubleToString((Bid+StopLevel*Point), Digits));
            return(0);
         }
         
         //Check max candle size to secure equity risk, when trading on fixed lots, e.g. EURUSD for 0.1 lot and maxpips 331 equity at risk is 33,1 USD (0,1 lot * 100000$ * 0,00001 pip value * 331 maxpips)
         if (!UseEquityRisk && StopLossLevel != 0.0){
            if (StopLossLevel - Bid > MaxPips*Point) {
               Print("###ERROR SELL - Can't trade sell. Equity risk to high. SL ",DoubleToString(StopLossLevel, Digits)," - Bid ",DoubleToString(Bid, Digits)," > MaxPips ",MaxPips," pips");
               return(0);
            }
         }
         
         Ticket = OrderSend(Symbol(), OP_SELL, NormalizeDouble(LotsSell, LotStep), Bid, Slippage, NormalizeDouble(StopLossLevel, Digits), NormalizeDouble(TakeProfitLevel, Digits), "Sell (EA#"+MagicNumber+")", MagicNumber, 0, DeepPink);
         if(Ticket > 0) {
            if (OrderSelect(Ticket, SELECT_BY_TICKET, MODE_TRADES)) {
				   TrailingStep = OrderStopLoss() - OrderOpenPrice();
				   Print("###SELL"
				      " order price: ", DoubleToString(OrderOpenPrice(),Digits),
				      " SL: ", DoubleToString(StopLossLevel, Digits),//" = ", DoubleToString(High[1], Digits)," + ", StopLoss," * ", DoubleToString(Point,Digits),
				      " TP: ", DoubleToString(TakeProfitLevel, Digits),//" = ", DoubleToString(Close[1], Digits)," - ((", DoubleToString(High[1], Digits)," - ", DoubleToString(Close[1], Digits),") * ", TakeProfit,")",
				      " Lots: ", LotsSell,
				      " Last iHighest", StopLossBarDistance,": ", DoubleToString(SL_sell, Digits),
				      " Money at risk: ", MarketInfo(Symbol(), MODE_TICKVALUE)*((OrderOpenPrice() - StopLossLevel)*LotSize*LotsBuy)
				      );
				   Print("---"   
				      " Ryzyko (SL - Close): ", DoubleToString((StopLossLevel - OrderOpenPrice()), Digits),
				      " Zysk (Bid - TP): ", DoubleToString((OrderOpenPrice() - TakeProfitLevel), Digits),
				      " Z/R : ", ((OrderOpenPrice() - TakeProfitLevel))/(StopLossLevel - OrderOpenPrice()),
				      " Last O: ", DoubleToString(Open[1], Digits),
				      " C: ", DoubleToString(Close[1], Digits),
				      " H: ", DoubleToString(High[1], Digits),
				      " L: ", DoubleToString(Low[1], Digits)
				      );
				   Print("---"
                  " Bid: ", DoubleToString(Bid, Digits),
                  " Slippage: ", DoubleToString(Slippage, Digits),  
                  " OrderSelect: ", OrderSelect(OrderTicket(), SELECT_BY_TICKET, MODE_HISTORY), 
                  //" LastOrderClosedMinAgo() >= Timeframe: ", (LastOrderClosedMinAgo()>=Period()),
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
               if(UseTrailingStop) {
                  Print("---"
				      " TrailingStop ratio: ",TrailingStop,
				      " Trailing step in pips: ",DoubleToString(TrailingStep*TrailingStop, Digits),
				      " Next SL value: ", DoubleToString(OrderOpenPrice(), Digits),
				      " when price hits: ", DoubleToString(OrderOpenPrice() - (TrailingStep * TrailingStop), Digits)
                  );
               }
               if (SignalMail) SendMail("[Signal Alert]", "[" + Symbol() + "] " + DoubleToStr(Bid, Digits) + " Open Sell");
			} else {
				Print("###ERROR SELL - Error opening order : ", GetLastError());
			}
         }
         return(0);
      }
      Print("###ERROR SELL - only one open order allowed");
   }

   return(0);
}
//+------------------------------------------------------------------+
