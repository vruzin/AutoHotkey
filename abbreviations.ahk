
; ----------------------------------------------------------
; ����������
::ltd::
Send2("dev")
return
::���::
Send2("dev")
return
::crom::
Send2("cron")
return
:o:GA::
Send2("Google Analitics")
return
:o:����::
Send2("������ ����. �� �� �����?")
return
:o:���::
Send2("������ ����")
return
:o:��::
Send2("������ ����")
return
:o:��::
Send2("������ �����")
return
:o:���::
Send2("����������")
return
:o:���::
Send2("����������")
return
:*:@@::
Send2("vruzin@ya.ru")
return
#!u::
Send2("?utm_source=yandex&utm_medium=cpc&utm_campaign={campaign_id}&utm_content={ad_id}&utm_term={keyword}")
return
::���::
Send2("������ ����. ��� ����� ������� �� ������ �������: ")
return
:*:���1::
Send2("��� ��������: WhatsApp, �������: +79046464626; Skype: vruzin; Telegram: @vruzin (����� � ���������)")
return
:*:���2::
Send2("��� ��������: WhatsApp, ������� - � �������; Skype: vruzin; Telegram: @vruzin (����� � ���������)")
return
:*:���3::
Send2("� ��� �� ����� �������, ��� ��� �� ��������� ��� ����, ������� ���� ���, ������ � �����������. ��� ��������: WhatsApp, �������: +79046464626; Skype: vruzin; Telegram: @vruzin (����� � ���������)")
return
:*:��1::
Send2("�� ������� ����: PHP, Go, MySQL, PgSQL, Vue (+Quasar), JS, CSS, SCSS, Less, Stylus.")
return
:*:qua1::
Send2("Quasar (VueJS) ������������� � PWA ����������, �������� ���������� Windows, MacOS, iOS, Android, Linux.")
return

:*:��1::
Send2("��������� �������� �� Vue:`r1. ��������: https://bit.ly/42IrTkR - Vue, Quasar`r2. ���� ��� ����������: https://bit.ly/3DJ5ngE - Vue`r3. ������� - http://inqoob-main.vruzin.ru - vue`r4. ������� - http://levelcrowd.vruzin.ru - vue`r5. http://inqoob-main.vruzin.ru/adm.pdf � ������� � Vue+Golang+Materio`r6. http://inqoob-main.vruzin.ru/app.pdf � ������� � Vue+Golang+Firebase+SCSS`r7. http://inqoob-main.vruzin.ru/lp3.pdf � ������� ���������� � Vue`r8. http://sms.artgroup.ru/prs/ - ����������")
return



:*:��1::
Send2("������ ����.`r`r������������ ���� ������ 20 ���. `r`r�����������. ������ ��������� �����, ����� ����� �����.`r`r�� ������ ���������� � ����� ��� ������� � ���� - �� � ������ ����. ��������� ������������, ������� ���� ��� ������� �������� �������� ���������, ��� ���� ��������. ���� ���� �������, ���� ������� ����������� �������� (������ ������ ������� 20 ����������� � �������� ��, ��� ������ �����). ��� ������ ������� ������ �� Vue/Vite. �� ������ ��������� ������ CSS � JS. �� ����� ���� ��� ������� �� ������. � ��������� ����. ����� ���� �������� ������� ��� JS, ������ �� HTML c CSS... ��� ��� ��� ��� ��� ���������, ��� � ������.`r`r��� ��������: WhatsApp, �������: +79046464626`; Skype: vruzin`; Telegram: @vruzin (����� � ���������)")
return

:*:���1::������������� �������, ���������� �����, �. ����� �������, ���. ������, �. 4, ��. 147
:*:���1::������������� �������, ���������� �����, �. ����� �������, ���. ������, �. 4, ��. 147
:*:����::HTML
:*:���::CSS
:*:������::Golang
:*:������::Vruzin
:*:������::Python
:*:���::PHP
:*:������::Bitrix
:*:�����::fl.ru
:*:������::yandex
:*:������::google
:*:���::mvk
:*:���::spb
:*:���::.ru
:*:����::.com
:*:����::.doc
::����::http
:*:�����::https
:*:�����::https:
:*:���::ssh
:*:���::ahk
:*:�����::VueJS
::���::Vue
::������::Github
::���::git
::���::API
::���::API
:*:���::CDN
:*:��::IP
:*:������::Direct
::DO::Digital Ocean
::��::Digital Ocean
::����::UUID
::��::id
::�����::nginx
:*:�����::MySQL
:*:�����::PgSQL




; ----------------------------------------------------------
; � ����������� �� ������� ����� ����� �����������
::��::
Hello()
return
::LL::
Hello()
return

Hello(){
    if(A_Hour < 5)
      state = ������ ����
    else if(A_Hour < 10)
      state = ������ ����
    else if(A_Hour < 17)
      state = ������ ����
    else
      state = ������ �����
    state=%state%.
    Send2(state)
}


#Persistent  ; ��������� ������, ���� �� ������� ������������.

; ----------------------------------------------------------

CapsLock & h:: ; ������� ������� Win+H
; �������� ������� ���������� �����. ������ "ControlGet Selected" ������������
; ����� ������, ��� ��� �� ���� � ����������� ����������
; (�.�. ��������� �����������).  ��������� ������� ���������� ������ ������,
; ����� ������������ ��� �������. ���� �������������� ������ ������� �����,
; ��� ��� �� �����, ��� ������:
SetNumLockState, Off
SetCapsLockState, Off

AutoTrim Off ; ��������� ����� ����������� �������� � ������ � ����� ��������� ������ � ������ ������.
ClipboardOld = %ClipboardAll%
Clipboard = ; ����� ����������� ����������, ����� ������ � ������� ��������.
Send ^c
ClipWait 1
if ErrorLevel ; ����� �������� ClipWait �����.
  return
; �������� CRLF �/��� LF �� `n, ����� ������������ � ������ ���������� ����� "send-raw" (R):
; ���� ����� ������ � ������ ������� ���������, �����
; ����� ���������� �������� � "�����" ������:
; ������ ��� ������ �������, ����� �������� ����� �� ������� ���, ������� ���� �����.
StringReplace, Hotstring, Clipboard, ``, ````, All
StringReplace, Hotstring, Hotstring, `r`n, ``r, All ; � MS Word...`r �������� �����, ��� `n.
StringReplace, Hotstring, Hotstring, `n, ``r, All
StringReplace, Hotstring, Hotstring, %A_Tab%, ``t, All
StringReplace, Hotstring, Hotstring, `;, ```;, All
Clipboard = %ClipboardOld% ; ��������������� ���������� ���������� ������ ������.
; ������� ���� ����� (InputBox) ��������������� � ����� ������� �������:
SetTimer, MoveCaret, 10
; ���������� ���� ����� (InputBox), ����������� ������ ���������� �� ���������:
Text1 := "����������� ���� ������������ � ��������� �����. "
Text2 := "`n"
Text3 =
(
  ������: :R:btw`::by the way

  ���:
  R � �����,
  btw � ���������� (������������);

  �����:
  * (���������): � ����� (������, ����� ��� ������� ������) �� ���������.
  ? (���� �������): ������ ���������� ����������, ���� ���� ��������� ������ ������� �����.
  B0 (�� ������ B ���� ����� 0): �������� (�������������� �����) ������������ ���� ������������ �� ������������.
  C: ���������������� � ��������. ������� ������������ ������ ����� ��������� � ���������
  C1: �� ����������� ��������, ������������� ��� ������ ������.
  Kn: �������� ������� �������. 0 �������������; -1 ��� ��������
  o (�����): �������� �������� ������ (��� ������� � �����)
  R: ����� �����
  ��������: https://ahk-wiki.ru/hotstrings
)
SetNumLockState, Off
SetCapsLockState, Off
Gui, Font, s48, Arial
InputBox, Hotstring, ����� ����������, %Text1%%Text2%%Text3%,,757,413,,,,, :R:`::Send2("%Hotstring%")
if ErrorLevel <> 0 ; ������������ ����� Cancel.
  return
IfInString, Hotstring, :R`:::
{
  MsgBox �� �� ���������� ������������. ������ ���������� �� ���������.
  return
}
; �����, ��������� ������ ���������� � ������������� ������.
; �������� `n � ������, � ������, ���� � ����� ����� ��� ������ ������.
FileAppend, `n%Hotstring%, %A_Scriptdir%\abbreviations.ahk
; FileAppend, `n%Hotstring%, %A_ScriptFullPath%
Reload
; � ������ ��������� ���������� ������������ ������� ���� ��������� ������� � ������ ��������,
; ������� ������ ���� ������� �� ����� ���������.
Sleep 200
Text1 := "������ ��� ����������� ������ ������� ���������������. "
Text2 := "������� ���� ��� ��������������? "
Text3 := "�������� ��������, ��� ����������� ������ ���������� ��������� ����� �������."
MsgBox, 4,, %Text1%%Text2%%Text3%
IfMsgBox, Yes, Edit
return

MoveCaret:
IfWinNotActive, ����� ����������
  return
; �����, ����������� ������ � ���� ����� ����, ��� ������������ ���������� ������������.
Send {Home}{Right 3}
SetTimer, MoveCaret, Off
return



tt(text){
    ToolTip, %text%
    SetTimer, ttRemove, -2000
    return
}
ttRemove:
ToolTip
return


