CaplsLock::
  сBaseKey              := "CapseLock"
  cAloneKey             := "1"  ;одиночное нежатие клавиши
  cDoubleKey            := "2"  ;двойное нажатие клавиши
  cHoldingKey           := "3"  ;удержание клавиши
 ;Активация констант для скорости реакции нажатий  для остального
  сPause_PressKey       := 400   
  cWaitHoldingBaseKey   := 1     
  cCountHoldingBaseKey  := 80   
  cWaitVirtualKey       := 5    
  cWaitBaselKey         := 10
  fAutoRepeat           := False       ; Автоповтор основной клавиши         = деактивирован
  fAloneHoldKey         := False       ; Модификатор для одиночного нажатия  = деактивирован
  fDoubleHoldKey        := False       ; Модификатор для двойного нажатия    = деактивирован
  fHoldingHoldKey       := False       ; Модификатор для удержания           = деактивирован
  gosub sbTrioProcessingKeys
Return

/*
==============Подпрограмма - Три действия/клавиши в одной======================
сBaseKey          :=  Автозадание через "A_ThisHotkey", возможно переназначение, но не рекомендуются, возможны коллизии
cAloneKey         :=  ;1-я Виртуальная клавиша, по умолчанию задаётся переменной "сBaseKey"
cAloneHoldKey     :=  ;Клавиша-модификатор для одиночного нажатия, основная и клавиша-модификатор
cDoubleKey        :=  ;2-я Виртуальная клавиша, по умолчанию задаётся переменной "сBaseKey"
cDoubleHoldKey    :=  ;Клавиша-модификатор для двойного нажатия, основная и клавиша-модификатор
cHoldingKey       :=  ;3-я Виртуальная клавиша, по умолчанию задаётся переменной "сBaseKey". Клавишиа удерживается(автоповтор)
cHoldingHoldKey   :=  ;Модификатор удержания, основная и клавиша-модификатор
Gosub sbIniTrioParams - вызов подпрограммы для задания констант для скорости реакции по обработке нажатий

ВАЖНО!!! - Задание клавиш-модификаторов не обязательно, при условии, если их флаги в состоянии FALSE

--------------------------------------------------------------
Описание констант для скорости реакции по обработке нажатий
-------------------------------------------------------------
сPause_PressKey  
          Если пауза меньше этого количества миллисекунд, то нажатие двойное. Если больше, то оно расценивается как 2 одиночных
cWaitHoldingBaseKey    
          Время ожидания в цикле определения удержания за каждый шаг, при больших значениях блокирует одиночное/двойное нажатие.
cCountHoldingBaseKey  
          Число шагов цикла для определения удержание клавиши/кнопки, при больших значениях блокирует одиночное/двойное нажатие.
cWaitVirtualKey
          Время задержки между эмуляцией нажатия на клавиши/кнопки подмены реально нажатой клавишей/кнопкой.
cWaitBaselKey 
          Время для Без/С автоповтором основной клавиши/кнопки
fAutoRepeat
          Автоповтор реально нажатой клавиши/кнопки - включён/выключен True/False
fAloneHoldKey
          Флаг(On/Off) для работы модификатора одиночного нажатия
fDoubleHoldKey
          Флаг(On/Off) для работы модификатора двойного нажатия
fHoldingHoldKey
          Флаг(On/Off) для работы модификатора удержания 
          
;-------Оптимальное значение, рекомендуемые, на основе игр - "The Witcher 2: Assassins of Kings" и "The Witcher 3: Wild Hunt"
Значения 
  сPause_PressKey       := 325  
  cWaitHoldingBaseKey   := 1     
  cCountHoldingBaseKey  := 40   
  cWaitVirtualKey       := 5    
  cWaitBaselKey         := 10
  fAutoRepeat           := False   Автоповтор основной клавиши         = деактивирован (при активации требуется описать, см выше)
  fAloneHoldKey         := False   Модификатор для одиночного нажатия  = деактивирован (при активации требуется описать, см выше)
  fDoubleHoldKey        := False   Модификатор для двойного нажатия    = деактивирован (при активации требуется описать, см выше)  
  fHoldingHoldKey       := False   Модификатор для удержания           = деактивирован (при активации требуется описать, см выше)  
*/

;------------Начало работы      
#UseHook, On
sbTrioProcessingKeys:
  vCountHoldingBaseKey:=cCountHoldingBaseKey
  ;Проверка на удержание нажатия/клика клавиши/кнопки
  while ((GetKeyState(сBaseKey, "P")) && vCountHoldingBaseKey && (!сSecond_PressKey)) 
      {
        Sleep  %cWaitHoldingBaseKey%   
        vCountHoldingBaseKey--
      }
  if (!vCountHoldingBaseKey)
      { 
       If (fHoldingHoldKey)
           Send, {%cHoldingHoldKey% Down}
       Send, {%cHoldingKey% Down}  ;Удержание нажатия/клика клавиши/кнопки
        while (GetKeyState(сBaseKey, "P"))
                 {
                   Sleep %cWaitVirtualKey%    
                 }
         Send, {%cHoldingKey% Up}
       If (fHoldingHoldKey)
           Send, {%cHoldingHoldKey% Up}         
        Gosub sbAutoRepeat
        return
      } 
     else 
        Gosub, sbPressCountKeys
return            ; Конец обработки подпрограммы sbStartProcessingKeys


;Одиночное нажатие/клик клавиши/кнопки
sbAloneKey:
  If (fAloneHoldKey)
        {
            Send, {%cAloneKey% Down}
            Send, {%cAloneHoldKey% Down}
            Sleep %cWaitVirtualKey%
            Send, {%cAloneHoldKey% Up}
            Send, {%cAloneKey% Up}  
        }
      Else 
      {
            Send, {%cAloneKey% Down}
            Sleep %cWaitVirtualKey%    
            Send, {%cAloneKey% Up}      
      }
  Gosub sbAutoRepeat
Return

;Двойное нажатие/клик клавиши/кнопки
sbDoubleKey:
  If (fDoubleHoldKey)
        {
            Send, {%cDoubleKey% Down}
            Send, {%cDoubleHoldKey% Down}
            Sleep %cWaitVirtualKey%
            Send, {%cDoubleHoldKey% Up}
            Send, {%cDoubleKey% Up}
        }
      Else  
      {
            Send, {%cDoubleKey% Down}
            Sleep %cWaitVirtualKey%    
            Send, {%cDoubleKey% Up}        
      }
  Gosub sbAutoRepeat
Return

;Без/С автоповтором основной клавиши/кнопки
sbAutoRepeat:
  if (fAutoRepeat) ; Автоповтор основной клавиши
      {
        Send, {%сBaseKey% Down}
        Sleep %cWaitVirtualKey%
        Send, {%сBaseKey% Up}      
      }
Return

sbPressCountKeys:
  If not сSecond_PressKey
      {
        сSecond_PressKey := 1
        SetTimer, sbDoublePressKey, -%сPause_PressKey%
      }
    Else
      {
        сSecond_PressKey := 0
        SetTimer, sbDoubleKey, -1
      }
Return

sbDoublePressKey:
  If not сSecond_PressKey
        Return
  сSecond_PressKey := 0
  SetTimer, sbAloneKey, -1
Return
;-----------------------------------------------------------------
#UseHook, Off