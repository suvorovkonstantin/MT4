//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#property link "http://forexbig.ru"
//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
//+------------------------------------------------------------------+
//|                                               GannResistance.mq4 |
//|                                                Martingeil© 2011, |
//|                                                    fx.09@mail.ru |
//+------------------------------------------------------------------+
//2011 год 1 июля.
#property copyright "Martingeil© 2011,"
#property link      "fx.09@mail.ru"

#property indicator_chart_window
extern string a = "Таймфрейм ZZ_FF"; 
extern int    tf   = 6;    //0=текущий тф,1=М1,2=М5,3=М15,4=М30,5=Н1,6=Н4,7=D1,8=W1,9=MN.
extern string b = "Пункты между клетками"; 
extern string c = "4-x =5; для 5-знака = 50;";
extern double pip  = 50.0;    //пункты прибавления к цене для последующих цен в квадрате


int q;
int h,l;
datetime t0, time1, time2, ny_time;
double pips;
double R1,R2,R3,R4,R5,R6,R7,R8,R9,S1,S2,S3,S4,S5,S6,S7,S8,S9; 
int mper[10]={0,1,5,15,30,60,240,1440,10080,43200}; //массив таймфрейма
int init(){
pips = pip*Point;
return(0);}

int deinit(){
ObjectDelete("R1");ObjectDelete("R2");ObjectDelete("R3");
ObjectDelete("R4");ObjectDelete("R5");ObjectDelete("R6");
ObjectDelete("R7");ObjectDelete("R8");ObjectDelete("R9");
ObjectDelete("S1");ObjectDelete("S2");ObjectDelete("S3");
ObjectDelete("S4");ObjectDelete("S5");ObjectDelete("S6");
ObjectDelete("S7");ObjectDelete("S8");ObjectDelete("S9");
return(0);}

int start()
   {
   int  s,counted_bars=IndicatorCounted();
//----
   double LouZZ = ZZ_FF();    
   ny_time  = iTime(NULL,PERIOD_D1,0) + (0-Period()/60.0)*3600;
   time1 = t0; time2 = ny_time + 24*3600+Period()*60 ;
//----   
   if(h<l){s=1; Comment(" цена впадины ZZ = ",LouZZ);}else{s=-1;Comment(" цена вершины ZZ = ",LouZZ);}

   R1 = LouZZ+s*(5*pips);   R2 = LouZZ+s*(18*pips);   R3 = LouZZ+s*(39*pips);
   R4 = LouZZ+s*(68*pips);  R5 = LouZZ+s*(105*pips);  R6 = LouZZ+s*(150*pips);   
   R7 = LouZZ+s*(203*pips); R8 = LouZZ+s*(264*pips);  R9 = LouZZ+s*(333*pips);    
   
   S1 = LouZZ+s*(1*pips);   S2 = LouZZ+s*(10*pips);   S3 = LouZZ+s*(27*pips);
   S4 = LouZZ+s*(52*pips);  S5 = LouZZ+s*(85*pips);   S6 = LouZZ+s*(126*pips);   
   S7 = LouZZ+s*(175*pips); S8 = LouZZ+s*(232*pips);  S9 = LouZZ+s*(297*pips);           

//Выведим линии на график
   PlotLine("R1",R1,R1,Blue); PlotLine("R2",R2,R2,Blue); PlotLine("R3",R3,R3,Blue);
   PlotLine("R4",R4,R4,Blue); PlotLine("R5",R5,R5,Blue); PlotLine("R6",R6,R6,Blue);
   PlotLine("R7",R7,R7,Blue); PlotLine("R8",R8,R8,Blue); PlotLine("R9",R9,R9,Blue);      
   
   PlotLine("S1",S1,S1,Blue); PlotLine("S2",S2,S2,Blue); PlotLine("S3",S3,S3,Blue);
   PlotLine("S4",S4,S4,Blue); PlotLine("S5",S5,S5,Blue); PlotLine("S6",S6,S6,Blue);
   PlotLine("S7",S7,S7,Blue); PlotLine("S8",S8,S8,Blue); PlotLine("S9",S9,S9,Blue);       
   
return(0);}
//---------------------------------------------------------------------------------
double ZZ_FF()
{
   int      i;
   double   pric,lou,hai;
   datetime th,tl;
     
   for (i= 0; i < 100; i++){     
       double ZZb = iCustom(NULL,mper[tf], "ZZ_FF_v4", 10,10, 0, i); 
             if (ZZb!=0 && ZZb!=EMPTY_VALUE){ h=i ;hai=ZZb; break; }}       

   for (i= 0; i < 100; i++){     
       double ZZl = iCustom(NULL,mper[tf], "ZZ_FF_v4", 10,10, 1, i); 
             if (ZZl!=0 && ZZl!=EMPTY_VALUE){ l=i ;lou=ZZl; break; }}
                  
             th=iTime(NULL,mper[tf],h); 
             tl=iTime(NULL,mper[tf],l);                       
             hai=NormalizeDouble(hai, Digits);             
             lou=NormalizeDouble(lou, Digits);
             
             if(h>l){pric=hai;t0=th;}else{pric=lou;t0=tl;}
return(pric);}
//---------------------------------------------------------------------------------
void PlotLine(string name,double value,double value1,double line_color)
{
   double valueN=NormalizeDouble(value,Digits);
   double valueN1=NormalizeDouble(value1,Digits);
   bool res = ObjectCreate(name,OBJ_TREND,0,time1,valueN,time2,valueN1);
   ObjectSet(name, OBJPROP_WIDTH, 1);
   ObjectSet(name, OBJPROP_STYLE, 0);
   ObjectSet(name, OBJPROP_RAY, false);
   ObjectSet(name, OBJPROP_BACK, true);
   ObjectSet(name, OBJPROP_COLOR, line_color);
} 
//---------------------------------------------------------------------------------          