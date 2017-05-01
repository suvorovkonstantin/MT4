//+------------------------------------------------------------------+
//|                                                 ZZ_FF_v4.mq4   |
//|                                                 George Tischenko |
//|                    Zig-Zag & Fractal Filter                      |
//+------------------------------------------------------------------+
/*
Расчет ценовых экстремумов производится с помощью функций iHighest / iLowest
Фильтрация полученных значений производится с помощью фрактального фильтра
добавлена визуализация фракталов, определенных по алгоритму данного индикатора
*/
#property copyright "George Tischenko"

#property indicator_chart_window
#property indicator_buffers 2
#property indicator_color1 DodgerBlue
#property indicator_color2 DodgerBlue

extern int ExtPeriod=10;  //количество баров для расчета экстремумов
extern int MinAmp=10;     //минимальное расстояние цены между соседними пиком и впадиной (иначе не регистрируется)

int TimeFirstExtBar,lastUPbar,lastDNbar,TimeOpen; //время открытия текущего бара;
double MP,lastUP,lastDN;
double UP[],DN[];
bool downloadhistory=false;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
  TimeFirstExtBar=0;
  TimeOpen=0;
  MP=MinAmp*Point;
  lastUP=0; lastDN=0;
//---- indicators
  IndicatorDigits(Digits);
  IndicatorBuffers(6); 
  
  SetIndexBuffer(0,UP);
  SetIndexStyle(0,DRAW_ZIGZAG,STYLE_SOLID,3);
  
  SetIndexBuffer(1,DN);
  SetIndexStyle(1,DRAW_ZIGZAG);
//----
  SetIndexLabel(0,"UP");
  SetIndexLabel(1,"DN");
  return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
  {
//----
//----
  return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()
  {
  int BarsForRecalculation,i;
  int counted_bars=IndicatorCounted();
  if(Bars-counted_bars>2) 
    {
    BarsForRecalculation=Bars-ExtPeriod-1;
    if(downloadhistory) //история загружена
      {
      ArrayInitialize(UP,EMPTY_VALUE);
      ArrayInitialize(DN,EMPTY_VALUE);
      }
    else downloadhistory=true;
    }
  else BarsForRecalculation=Bars-counted_bars;
  if(BarsForRecalculation>0) TimeOpen=Time[Bars-counted_bars]; //проверим эту строку при открытии МТ-4 с перерывом
/*
в связи с тем, что фракталом по определению является ценовой экстремум относительно 2 баров вправо
(остальное см. функцию Fractal) - соответственно фрактал на 3 баре может считаться сформированным 
только при открытии нулевого текущего бара: [3]-2-1-0 Поэтому расчет цикла выполняется только при 
открытии нового бара. Внутри бара при поступлении новых тиков расчет не производится.
*/
  if(TimeOpen<Time[0]) 
    {  
//======== основной цикл
    while(BarsForRecalculation>1)
     {
     i=BarsForRecalculation+1; lastUP=0; lastDN=0; lastUPbar=i; lastDNbar=i;
     int LET=LastEType(); //поиск последнего экстремума
     
//---- рассмотрим ценовые экстремумы за расчетный период:       
     double H=High[iHighest(NULL,0,MODE_HIGH,ExtPeriod,i)];
     double L=Low[iLowest(NULL,0,MODE_LOW,ExtPeriod,i)];
            
//---- рассмотрим, имеются ли на баре [i] фракталы минимальной или максимальной цен: 
     double Fup=Fractal(1,i); //MODE_UPPER 
     double Fdn=Fractal(2,i); //MODE_LOWER
     
//---- проанализируем ситуацию и рассмотрим возможность регистрации новых экстремумов: 

     switch(Comb(i,H,L,Fup,Fdn))
       {
//---- на расчетном баре потенциальный пик (Comb)      
       case 1 :
         {
         switch(LET)
           {
           case 1 : //предыдущий экстремум тоже пик
             {//выбираем больший:
             if(NormalizeDouble(Fup-lastUP,Digits)>0) {UP[lastUPbar]=EMPTY_VALUE; UP[i]=Fup;}
             break;
             }
           case -1 : if(NormalizeDouble(Fup-lastDN-MP,Digits)>0) UP[i]=Fup; break; //предыдущий экстремум - впадина
           default : UP[i]=Fup; TimeFirstExtBar=iTime(NULL,0,i); //0 - значит это начало расчета 
           }
         break;
         }
          
//---- на расчетном баре потенциальная впадина  (Comb)          
       case -1 :
         {
         switch(LET)
          {
          case 1 : if(NormalizeDouble(lastUP-Fdn-MP,Digits)>0) DN[i]=Fdn; break; //предыдущий экстремум - пик
          case -1 : //предыдущий экстремум тоже впадина
            {
            if(NormalizeDouble(lastDN-Fdn,Digits)>0) {DN[lastDNbar]=EMPTY_VALUE; DN[i]=Fdn;}
            break;
            }
          default : DN[i]=Fdn; TimeFirstExtBar=iTime(NULL,0,i); //0 - значит это начало расчета 
          }
        break;
        }
       
//---- на расчетном баре потенциальный пик и потенциальная впадина (Comb)        
      case 2 : //предположительно сначала сформировался LOW потом HIGH (бычий бар)
        {
        switch(LET)
          {
          case 1 : //предыдущий экстремум - пик
            {
            if(NormalizeDouble(Fup-Fdn-MP,Digits)>0)
              {
              if(NormalizeDouble(lastUP-Fdn-MP,Digits)>0) {UP[i]=Fup; DN[i]=Fdn;}
              else 
                {
                if(NormalizeDouble(Fup-lastUP,Digits)>0) {UP[lastUPbar]=EMPTY_VALUE; UP[i]=Fup;}
                }
              }
            else
              {
              if(NormalizeDouble(lastUP-Fdn-MP,Digits)>0) DN[i]=Fdn;
              else
                {
                if(NormalizeDouble(Fup-lastUP,Digits)>0) {UP[lastUPbar]=EMPTY_VALUE; UP[i]=Fup;}
                }
              }
            break;
            }
          case -1 : //предыдущий экстремум - впадина
            {
            if(NormalizeDouble(Fup-Fdn-MP,Digits)>0)
              {
              UP[i]=Fup;
              if(NormalizeDouble(lastDN-Fdn,Digits)>0 && iTime(NULL,0,lastDNbar)>TimeFirstExtBar) 
                {DN[lastDNbar]=EMPTY_VALUE; DN[i]=Fdn;}
              }
            else
              {
              if(NormalizeDouble(Fup-lastDN-MP,Digits)>0) UP[i]=Fup;
              else
                {
                if(NormalizeDouble(lastDN-Fdn,Digits)>0) {DN[lastDNbar]=EMPTY_VALUE; DN[i]=Fdn;}
                }
              }
            }
          } //switch LET
        break;
        }// case 2
      
      case -2 : //предположительно сначала сформировался HIGH потом LOW (медвежий бар)
        {
        switch(LET)
          {
          case 1 : //предыдущий экстремум - пик
            {
            if(NormalizeDouble(Fup-Fdn-MP,Digits)>0)
              {
              DN[i]=Fdn;
              if(NormalizeDouble(Fup-lastUP,Digits)>0 && iTime(NULL,0,lastUPbar)>TimeFirstExtBar) 
                {UP[lastUPbar]=EMPTY_VALUE; UP[i]=Fup;}
              }
            else
              {
              if(NormalizeDouble(lastUP-Fdn-MP,Digits)>0) DN[i]=Fdn;
              else
                {
                if(NormalizeDouble(Fup-lastUP,Digits)>0) {UP[lastUPbar]=EMPTY_VALUE; UP[i]=Fup;}
                }
              }
            break;
            }
          case -1 : //предыдущий экстремум - впадина
            {
            if(NormalizeDouble(Fup-Fdn-MP,Digits)>0)
              {
              if(NormalizeDouble(Fup-lastDN-MP,Digits)>0) {UP[i]=Fup; DN[i]=Fdn;}
              else
                {
                if(NormalizeDouble(lastDN-Fdn,Digits)>0) {DN[lastDNbar]=EMPTY_VALUE; DN[i]=Fdn;}
                }
              }
            else
              {
              if(NormalizeDouble(Fup-lastDN-MP,Digits)>0) UP[i]=Fup;
              else
                {
                if(NormalizeDouble(Fdn-lastDN,Digits)>0) {DN[lastDNbar]=EMPTY_VALUE; DN[i]=Fdn;}
                }
              }
            }
          } //switch LET
        }// case -2 
      }
//----  
     BarsForRecalculation--;    
     } 
//========
    TimeOpen=Time[0];
    }
//----
  return(0);
  }
//+------------------------------------------------------------------+
//| функция определения фракталов                                    |
//+------------------------------------------------------------------+  
double Fractal(int mode, int i) 
  {
//----
  bool fr=true;
  int a,b,count;
  double res;
  
  switch(mode)
    {
    
    case 1 : //поиск верхних фракталов
//справа от фрактала должно быть 2 бара с более низкими максимумами
//слева от фрактала пожет быть группа баров, которую завершат 2 бара с более низкими максимумами 
//максимум любого бара из группы не должен превысить максимум фрактального бара    
      {
      for(b=i-1;b>i-3;b--) 
        {
        if(High[i]<=High[b]) {fr=false; break;}
        }
      a=i+1; 
      while(count<2)
        {
        if(High[i]<High[a]) {fr=false; break;}
        else
          {
          if(High[i]>High[a]) count++;
          else count=0;
          }
        a++;
        }
      if(fr==true) res=High[i];
      break;
      }
      
    case 2 : //поиск нижних фракталов
//справа от фрактала должно быть 2 бара с более высокими минимумами
//слева от фрактала может быть группа баров, которую завершат 2 бара с более высокими минимумами 
//минимум любого бара из группы не должен быть ниже минимума фрактального бара 
      {
      for(b=i-1;b>i-3;b--) 
        {
        if(Low[i]>=Low[b]) {fr=false; break;}
        }
      a=i+1; 
      while(count<2)
        {
        if(Low[i]>Low[a]) {fr=false; break;}
        else
          {
          if(Low[i]<Low[a]) count++;
          else count=0;
          }
        a++;
        }
      if(fr==true) res=Low[i];
      }
    }
//----
  return(res);  
  } 
//+------------------------------------------------------------------+
//| функция определения последнего экстремума                        |
//+------------------------------------------------------------------+  
int LastEType()
  {
//----
  int m,n,res;
  m=0; n=0;
  while(UP[lastUPbar]==EMPTY_VALUE) {if(lastUPbar>Bars-ExtPeriod) break; lastUPbar++;} 
  lastUP=UP[lastUPbar]; //возможно нашли последний пик
  while(DN[lastDNbar]==EMPTY_VALUE) {if(lastDNbar>Bars-ExtPeriod) break; lastDNbar++;} 
  lastDN=DN[lastDNbar]; //возможно нашли последнюю впадину
  if(lastUPbar<lastDNbar) res=1;
  else
    {
    if(lastUPbar>lastDNbar) res=-1;
    else //lastUPbar==lastDNbar надо узнать, какой одиночный экстремум был последним:
      {
      m=lastUPbar; n=m;
      while(m==n)
        {
        m++; n++;
        while(UP[m]==EMPTY_VALUE) {if(m>Bars-ExtPeriod) break; m++;} //возможно нашли последний пик
        while(DN[n]==EMPTY_VALUE) {if(n>Bars-ExtPeriod) break; n++;} //возможно нашли последнюю впадину
        if(MathMax(m,n)>Bars-ExtPeriod) break;
        }
      if(m<n) res=1;       //базовый отсчет - пик
      else if(m>n) res=-1; //базовый отсчет - впадина
      }
    }
//----    
  return(res); //если res==0 - значит это начало отсчета или в самом начале зафиксирован внешний бар с 2 экстремумами
  }
//+------------------------------------------------------------------+
//| функция анализа текущей ситуации                                 |
//+------------------------------------------------------------------+ 
int Comb(int i, double H, double L, double Fup, double Fdn)
  {
//----
  if(Fup==H && (Fdn==0 || (Fdn>0 && Fdn>L))) return(1);  //на расчетном баре потенциальный пик
  if(Fdn==L && (Fup==0 || (Fup>0 && Fup<H))) return(-1); //на расчетном баре потенциальная впадина
  if(Fdn==L && Fup==H)                                   //на расчетном баре потенциальный пик и потенциальная впадина 
    {
    switch(GetOrderFormationBarHighLow(i))
      {//предположительно сначала сформировался LOW потом HIGH (бычий бар)
      case -1 : return(2); break;
      //предположительно сначала сформировался HIGH потом LOW (медвежий бар)
      case 1 : return(-2); 
      }
    }
//----  
  return(0);                                             //на расчетном баре пусто...
  }
//+------------------------------------------------------------------+
//| функция возвращает порядок формирования High Low для бара        |
//|  1: сначала High, затем Low                                      |
//| -1: сначала Low, затем High                                      |
//|  0: High = Low                                                   |
//+------------------------------------------------------------------+ 
int GetOrderFormationBarHighLow(int Bar)
  {
//---- Для начала встроим простейшую логику по Open / Close
  int res = 0;
  if(High[Bar]==Low[Bar]) return(res);
  if(Close[Bar]>Open[Bar]) res=-1;
  if(Close[Bar]<Open[Bar]) res=1;
   
  if(res==0) // Когда Close = Open
    {
    double a1=High[Bar]-Close[Bar];
    double a2=Close[Bar]-Low[Bar];
    if(a1>a2) res=-1;
    if(a1<a2) res=1;
    if(res==0) res=1; // Когда и это равно  - будем так считать! и баста! - натяжка!
    }
//----
  return(res);
  } 
//+------------------------------------------------------------------+