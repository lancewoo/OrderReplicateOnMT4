#import "FXBlueQuickChannel.dll"
   int QC_StartSenderW(string);
   int QC_ReleaseSender(int);
   int QC_SendMessageW(int, string&, int);
#import

int glbHandle = 0;

void OnInit()
{
   glbHandle = QC_StartSenderW("TestChannel");
}

void OnDeinit(const int reason)
{
   QC_ReleaseSender(glbHandle);
   glbHandle = 0;
}

void OnTick()
{
   string strMsg = "Hello @ " + TimeToStr(TimeCurrent());
   if (!QC_SendMessageW(glbHandle, strMsg , 3)) {
      Print("Message failed");
   }
}