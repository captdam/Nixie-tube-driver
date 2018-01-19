# Nixie-tube-driver

Nixie tube driver code for 51 MCU


This code is designed for 51 MCU with core frequency of 11.0592MHz. The output is on I/O P1, P2, and P3. P1: Hour; P2: Minute; P3: Second. Each port is devided into two parts, high value and low value; for example, P1(7:4) is designed for the tens of hour value. The output signal is coded in BCD code, you will need 74/54LS138 to decode this signal into one-hot signal.


For example, if the time is 15:22:08, the output will be:

P1: 00010101; P2: 00100010; P3: 00001000.

After 3-8 decodedr (74LS138):

Hour_H: 1; Hour_L: 5; Min_H: 2; Min_L: 2; Sec_H: 0; Sec_L: 8.


Every hour, all six tube will do a cycle as cathodic production.



# 辉光管驱动

51单片机辉光管驱动


这个代码是为使用11.0592Mhz晶振的51单片机设定的。P1，P2，P3将作为时钟时，分，秒信号输出。 每一个Port将会被分为高四位与第四位，比如说，P1的7654脚将作为时针的十位输出。输出编码格式为BCD，你将需要74LS138解码器来将这个信号转化为One-hot信号。


比如说，在15：22：08，输出为：

P1: 00010101; P2: 00100010; P3: 00001000.

通过3-8解码器后（74LS138）:

Hour_H: 1; Hour_L: 5; Min_H: 2; Min_L: 2; Sec_H: 0; Sec_L: 8.


每个小时，所有数字都将进行一圈循环以防止阴极中毒。
