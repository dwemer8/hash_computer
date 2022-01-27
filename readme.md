--Устройство ретранслирует сообщения по интерфейсу UART (максимальная длина
--сообщения 10Кбайт) и вычисляет хеш-сумму ретранслированных данных по алгоритмам
--CRC32, SHA-1, SHA-2 (SHA256). Значение хеш-функции выводится на LCD16x2,
--переключение осуществляется с помощью кнопок.

--Сначало устройство, находясь в состоянии ретрансляции, считывает через UART_rx сообщение, запоминая его в FIFO_8x10240_mod и ретранcлируя через UART_tx. 
--По кнопке start_comp_i устройство переходит в состояние вычисления хеша, какой хеш вычисляется, зависит от режима вычисления. 
--В модуль crc32 данные обрабатываемого сообщения из FIFO загружаются топ-модулем, для остальных вычислителей написаны загрузчики-препроцессоры.
--После вычисления устройство переходит в состояние отображения, топ-модуль загружает вычисленное значения хеша в lcd_loader. 
--В этом состоянии могут быть осуществлены либо переключение режима кнопкой switch_mode_i, тогда устройство вернется в состояние вычисления, 
--где будет считать новый хеш, а после его отобразит, либо в переход состояние ретрансляции, если начать передавать по UART новые данные.

--На кнопках start_comp_i и switch_mode_i висят устранители дребезга.