# OrderReplicateOnMT4
An order replicate/dupliate EA(Expert Advisors) on MT4 using FXBlueQuickChannelSetup.

To use it, first install the FXBlueQuickChannelSetup library.
Then drop OrderMonitor.ex4 into the Experts folder of the trader account which is going
to be monitored and copied; drop OrderReplicate.ex4 into the Experts folder of the trader account
which is going to copy/duplicate/replicate orders from the other account.

You have to allow DLL imports on both MT4 terminals. Automatic trading should be allowed on the
receiver termial.

Folders should be like this:
D:\Trader-1\
<Trader-1>
��terminal.exe
��<MQL4>
��  ��<Experts>
��  ��  ��MACD Sample.ex4
��  ��  ��MACD Sample.mq4
��  ��  ��Moving Average.ex4
��  ��  ��Moving Average.mq4
��  ��  ��mqlcache.dat
��  ��  ��OrderMonitor.ex4
��  ��<Libraries>
��  ��  ��FXBlueQuickChannel.dll
��  ��  ��FXBlueQuickChannel64.dll
��  ��  ��mqlcache.dat
��  ��  ��stdlib.ex4
��  ��  ��stdlib.mq4


D:\Trader-2\
<Trader-2>
��terminal.exe
��<MQL4>
��  ��<Experts>
��  ��  ��MACD Sample.ex4
��  ��  ��MACD Sample.mq4
��  ��  ��Moving Average.ex4
��  ��  ��Moving Average.mq4
��  ��  ��mqlcache.dat
��  ��  ��OrderMonitor.ex4
��  ��<Libraries>
��  ��  ��FXBlueQuickChannel.dll
��  ��  ��FXBlueQuickChannel64.dll
��  ��  ��mqlcache.dat
��  ��  ��stdlib.ex4
��  ��  ��stdlib.mq4

......

D:\Trader-Receiver\
<Trader-Receiver>
��terminal.exe
��<MQL4>
��  ��<Experts>
��  ��  ��MACD Sample.ex4
��  ��  ��MACD Sample.mq4
��  ��  ��Moving Average.ex4
��  ��  ��Moving Average.mq4
��  ��  ��mqlcache.dat
��  ��  ��OrderReplicate.ex4
��  ��<Libraries>
��  ��  ��FXBlueQuickChannel.dll
��  ��  ��FXBlueQuickChannel64.dll
��  ��  ��mqlcache.dat
��  ��  ��stdlib.ex4
��  ��  ��stdlib.mq4



