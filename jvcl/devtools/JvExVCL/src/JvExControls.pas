{-----------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/MPL-1.1.html

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either expressed or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: JvExControls.pas, released on 2004-01-04

The Initial Developer of the Original Code is Andreas Hausladen [Andreas.Hausladen@gmx.de]
Portions created by Andreas Hausladen are Copyright (C) 2004 Andreas Hausladen.
All Rights Reserved.

Contributor(s): -

Last Modified: 2004-01-04

You may retrieve the latest version of this file at the Project JEDI's JVCL home page,
located at http://jvcl.sourceforge.net

Known Issues:
-----------------------------------------------------------------------------}
{$I jvcl.inc}

unit JvExControls;
interface
uses
  {$IFDEF VCL}
  Windows, Messages, Controls, Forms, JclSysUtils,
  {$ENDIF VCL}
  {$IFDEF VisualCLX}
  QWindows, QControls, QForms,
  {$ENDIF VisualCLX}
  Classes, SysUtils;

type
  IJvControlEvents = interface
    ['{61FC57FF-D4DA-4840-B871-63DE804E9921}']
    procedure VisibleChanged;
    procedure EnabledChanged;
    procedure TextChanged;
    procedure FontChanged;
    procedure ColorChanged;
    procedure ParentFontChanged;
    procedure ParentColorChanged;
    procedure ParentShowHintChanged;
    function WantKey(Key: Integer; Shift: TShiftState;
      const KeyText: WideString): Boolean;
    function HintShow(var HintInfo : THintInfo): Boolean;
    function HitTest(X, Y: Integer): Boolean;
    procedure MouseEnter(AControl: TControl);
    procedure MouseLeave(AControl: TControl);
  end;

  IJvWinControlEvents = interface(IJvControlEvents)
    ['{B5F7FB62-78F0-481D-AFF4-7A24ED6776A0}']
    procedure CursorChanged;
    procedure ShowingChanged;
    procedure ShowHintChanged;
    procedure ControlsListChanging(Control: TControl; Inserting: Boolean);
    procedure ControlsListChanged(Control: TControl; Inserting: Boolean);
  end;

type
  JV_CONTROL_EVENTS(Control)
  JV_WINCONTROL_EVENTS(WinControl)

  JV_CONTROL_EVENTS(GraphicControl)
  JV_WINCONTROL_EVENTS(CustomControl)
  JV_WINCONTROL_EVENTS(HintWindow)

{$IFDEF VCL}

function ShiftStateToKeyData(Shift: TShiftState): Longint;

function InheritMsg(ASelf: TControl; Msg: Integer; WParam, LParam: Integer): Integer; overload;
function InheritMsg(ASelf: TControl; Msg: Integer): Integer; overload;
function DispatchMsg(ASelf: TControl; var Msg): Boolean;

{$ENDIF VCL}

implementation

{$IFDEF VCL}

function ShiftStateToKeyData(Shift: TShiftState): Longint;
const
  AltMask = $20000000;
begin
  Result := 0;
  if ssAlt in Shift then
    Result := Result or AltMask;
end;

function InheritMsg(ASelf: TControl; Msg: Integer; WParam, LParam: Integer): Integer;
type
  TMessageHandler = procedure(Self: TObject; var Msg: TMessage);
var
  Proc: TMessageHandler;
  Mesg: TMessage;
begin
  Mesg.Msg := Msg;
  Mesg.WParam := WParam;
  Mesg.LParam := LParam;
  Mesg.Result := 0;
  Proc := @TObject.Dispatch;
  Proc(ASelf, Mesg);
  Result := Mesg.Result;
end;

function InheritMsg(ASelf: TControl; Msg: Integer): Integer;
begin
  Result := InheritMsg(ASelf, Msg, 0, 0);
end;

function DispatchMsg(ASelf: TControl; var Msg): Boolean;
var
  IntfControl: IJvControlEvents;
  IntfWinControl: IJvWinControlEvents;
  PMsg: PMessage;
begin
  PMsg := @Msg;
  { GetInterface is no problem because ASelf is a TComponent derived class that
    is not released by an interface "Release". }
  if ASelf.GetInterface(IJvControlEvents, IntfControl) then
  begin
    Result := True;
    with IntfControl do
      case PMsg^.Msg of
        CM_VISIBLECHANGED:
          VisibleChanged;
        CM_ENABLEDCHANGED:
          EnabledChanged;
        CM_FONTCHANGED:
          FontChanged;
        CM_COLORCHANGED:
          ColorChanged;
        CM_PARENTFONTCHANGED:
          ParentFontChanged;
        CM_PARENTCOLORCHANGED:
          ParentColorChanged;
        CM_PARENTSHOWHINTCHANGED:
          ParentShowHintChanged;
        CM_TEXTCHANGED:
          TextChanged;
        CM_HINTSHOW:
          PMsg^.Result := Integer(HintShow(TCMHintShow(PMsg^).HintInfo^));
        CM_HITTEST:
          with TCMHitTest(PMsg^) do
            Result := Integer(HitTest(XPos, YPos));
        CM_MOUSEENTER:
            MouseEnter(TControl(PMsg^.LParam));
        CM_MOUSELEAVE:
            MouseLeave(TControl(PMsg^.LParam));
        CM_DIALOGCHAR:
          with TCMDialogChar(PMsg^) do
            Result := Ord(WantKey(CharCode, KeyDataToShiftState(KeyData), WideChar(CharCode)));
      else
        Result := False;
      end;
  end
  else
    Result := False;

  if not Result then
  begin
    if ASelf.GetInterface(IJvWinControlEvents, IntfWinControl) then
    begin
      Result := True;
      with IntfWinControl do
        case PMsg^.Msg of
          CM_CURSORCHANGED:
            CursorChanged;
          CM_SHOWINGCHANGED:
            ShowingChanged;
          CM_SHOWHINTCHANGED:
            ShowHintChanged;
          CM_CONTROLLISTCHANGE:
            if PMsg^.LParam <> 0 then
              ControlsListChanging(TControl(PMsg^.WParam), True)
            else
              ControlsListChanged(TControl(PMsg^.WParam), False);
          CM_CONTROLCHANGE:
            if PMsg^.LParam = 0 then
              ControlsListChanging(TControl(PMsg^.WParam), False)
            else
              ControlsListChanged(TControl(PMsg^.WParam), True);
        else
          Result := False;
        end;
    end
    else
      Result := False;
  end;
end;

{$ENDIF VCL}

// *****************************************************************************

JV_CONTROL_EVENTS_IMPL(Control)
JV_WINCONTROL_EVENTS_IMPL(WinControl)

JV_CONTROL_EVENTS_IMPL(GraphicControl)
JV_WINCONTROL_EVENTS_IMPL(CustomControl)
JV_WINCONTROL_EVENTS_IMPL(HintWindow)

end.
