# class ToolTip
Представляю класс ToolTip, который можно использовать для создания ToolTip'ов и TrayTip'ов с возможностью выбора шрифта (и его размера и стиля), а также цвета фона и текста.  
  
### Пример использования:  
Код:  
```ahk
#Persistent
myToolTip := new ToolTip({ title: "Title"
                         , text: "I'm the colored TrayTip!"
                         , icon: 1  ; icon Info
                         , TrayTip: true
                         , FontName: "Comic Sans MS"
                         , FontSize: 20
                         , TextColor: "Navy"
                         , BackColor: 0xFFA500 })
```
Результат:  
![TrayTip](http://i.imgur.com/SMhcrkd.jpg)
  
Также примеры использования приводятся в файлах example1.ahk и example2.ahk. Для их запуска необходимо файл ToolTip.ahk положить в папку скрипта, либо удалить из примеров строку
```ahk
#Include %A_ScriptDir%\ToolTip.ahk
```
и дописать класс непосредственно в код примера.
### Описание
При создании экземпляра объекта в конструктор передаётся ассоциативный массив с опциями.
Возможные ключи и их псевдонимы:
```
title
text
icon (1 — Info, 2 — Warning; 3 — Error; n > 3 — предполагается hIcon)
CloseButton (или close) — true или false
transparent (или trans) — true или false, указывает, будет ли ToolTip прозрачен для кликов мыши
ShowNow (или now) — true или false, показывать или не показывать ToolTip при создании экземпляра объекта
   Если параметр не указан, ToolTip будет показан сразу же.
x, y — координаты, если не указаны, ToolTip появится вблизи курсора
BalloonTip (или balloon, или ball) — true или false, BalloonTip — это ToolTip с хвостиком
TrayTip (или tray) — будет показан BalloonTip у иконки скрипта в трее,
   параметры x, y, и BalloonTip игнорируются.
   Если указан ключ TrayTip, удалить экземпляр объекта можно либо методом Destroy(),
      либо указав TimeOut с отрицателным значением.
   Если нет, тогда можно просто прировнять ссылку на объект пустому значению.
FontName (или font)
FontSize (или size)
FontStyle (или style) — bold, italic, underline, strikeout в любом сочетании через пробел
TimeOut (или time) — время в милисекундах, через которое ToolTip будет скрыт, если число положительное,
   либо уничтожен, если отрицательное
BackColor (или back) — цвет фона
TextColor (или color) — цвет текста
```
