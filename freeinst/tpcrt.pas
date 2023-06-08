{

     osFree Turbo Professional Copyright (C) 2022 osFree

     All rights reserved.

     Redistribution  and  use  in  source  and  binary  forms, with or without
modification, are permitted provided that the following conditions are met:

     *  Redistributions of source code must retain the above copyright notice,
this list of conditions and the following disclaimer.
     *  Redistributions  in  binary  form  must  reproduce the above copyright
notice,   this  list  of  conditions  and  the  following  disclaimer  in  the
documentation and/or other materials provided with the distribution.
     * Neither the name of the osFree nor the names of its contributors may be
used  to  endorse  or  promote  products  derived  from  this software without
specific prior written permission.

     THIS  SOFTWARE  IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
IS"  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED.  IN  NO  EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
FOR  ANY  DIRECT,  INDIRECT,  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES  (INCLUDING,  BUT  NOT  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES;  LOSS  OF  USE,  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED  AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR  TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

}

unit tpcrt;

interface

uses
  crt;

const
  {color constants}
  Black = 0;
  Blue = 1;
  Green = 2;
  Cyan = 3;
  Red = 4;
  Magenta = 5;
  Brown = 6;
  LightGray = 7;
  DarkGray = 8;
  LightBlue = 9;
  LightGreen = 10;
  LightCyan = 11;
  LightRed = 12;
  LightMagenta = 13;
  Yellow = 14;
  White = 15;
  Blink = 128;

type
  FrameCharType = (ULeft, LLeft, URight, LRight, Horiz, Vert);
  FrameArray = array[FrameCharType] of Char;
const
  FrameChars : FrameArray = 'ÕÔ¸¾Í³';

{ Predefined FrameChars (not present in original TPCRT)}
  DefaultFrameChars : FrameArray = 'ÕÔ¸¾Í³';
  SingleFrameChars : FrameArray = #$DA#$C0#$BF#$D9#$C4#$B3;
  DoubleFrameChars : FrameArray = #$C9#$C8#$BB#$BC#$CD#$BA;
  BoldFrameChars : FrameArray = #$DB#$DB#$DB#$DB#$DB#$DB;

procedure FrameWindow(LeftCol, TopRow, RightCol, BotRow, FAttr, HAttr : Byte;
                      Header : string);
  {-Draws a frame around a window}

function WhereXAbs: Byte;
  {-Return absolute column coordinate of cursor}

function WhereYAbs: Byte;
  {-Return absolute row coordinate of cursor}

function WhereXY: Word;
  {-Return absolute coordinates of cursor}

function ScreenX: Byte;
  {-Return absolute column coordinate of cursor}

function ScreenY: Byte;
  {-Return absolute row coordinate of cursor}

{Forwarders to CRT}
var
  TextAttr: byte absolute Crt.TextAttr;
  WindMin: Word absolute Crt.WindMin;
  WindMax: Word absolute Crt.WindMax;
  ScreenWidth: Longint absolute Crt.ScreenWidth;
  ScreenHeight: Longint absolute Crt.ScreenHeight;

procedure ClrScr;
procedure TextBackground(C: byte);
procedure TextColor(C: byte);
procedure Window(X1, Y1, X2, Y2: byte);
procedure GoToXY(X, Y: byte);
function WhereX: byte;
function WhereY: byte;
procedure ClrEOL;
function ReadKey: Char;
procedure Delay(MS: Word);
procedure HighVideo;

implementation

procedure FrameWindow(LeftCol, TopRow, RightCol, BotRow, FAttr, HAttr : Byte;
                      Header : string);
  {-Draws a frame around a window}
var
  i: byte;
  oldTextAttr: Byte;
  OldWindMin, OldWindMax: Word;
  OldX, OldY: Byte;
begin
  CursorOff;
  OldTextAttr:=TextAttr;
  OldWindMin:=WindMin;
  OldWindMax:=WindMax;
  OldX:=WhereX;
  OldY:=WhereY;
  TextAttr:=FAttr;
  Window(1, 1, ScreenWidth, ScreenHeight);
  GoToXY(LeftCol, TopRow);
  write(FrameChars[ULeft]);
  for i:=LeftCol+1 to RightCol-1 do write(FrameChars[Horiz]);
  write(FrameChars[URight]);

  for i:=TopRow+1 to BotRow-1 do
  begin
    GoToXY(LeftCol, i);
    write(FrameChars[Vert]);
    GoToXY(RightCol, i);
    write(FrameChars[Vert]);
  end;

  gotoxy(LeftCol, BotRow);
  write(FrameChars[LLeft]);
  for i:=LeftCol+1 to RightCol-1 do write(FrameChars[Horiz]);
  write(FrameChars[LRight]);

  if Header<>'' then
  begin
    TextAttr:=HAttr;
    GoToXY(LeftCol+(RightCol-LeftCol) div 2-Length(Header) div 2, TopRow);
    Write(Header);
  end;

  TextAttr:=OldTextAttr;
  Window(Lo(OldWindMin)+1, Hi(OldWindMin)+1, Lo(OldWindMax)+1, Hi(OldWindMax)+1);
  GoToXY(OldX, OldY);
end;

function WhereXAbs: Byte;
  {-Return absolute column coordinate of cursor}
begin
  Result:=WhereX+Lo(WindMin);
end;

function WhereYAbs: Byte;
  {-Return absolute row coordinate of cursor}
begin
  Result:=WhereY+Hi(WindMin);
end;

function ScreenX: Byte;
  {-Return absolute column coordinate of cursor}
begin
  Result:=WhereX+Lo(WindMin);
end;

function ScreenY: Byte;
  {-Return absolute row coordinate of cursor}
begin
  Result:=WhereY+Hi(WindMin);
end;

function WhereXY: Word;
  {-Return absolute coordinates of cursor}
begin
  Result:=$ff*(WhereY)+(WhereX)+WindMin;
end;

procedure ClrScr;
begin
  Crt.ClrScr;
end;

procedure TextBackground(C: byte);
begin
  Crt.TextBackground(C);
end;

procedure TextColor(C: byte);
begin
  Crt.TextColor(C);
end;

procedure Window(X1, Y1, X2, Y2: byte);
begin
  Crt.Window(X1, Y1, X2, Y2);
end;

procedure GoToXY(X, Y: byte);
begin
  Crt.GoToXY(X, Y);
end;

function WhereX: byte;
begin
  Result:=Crt.WhereX;
end;

function WhereY: byte;
begin
  Result:=Crt.WhereY;
end;

procedure ClrEOL;
begin
  Crt.ClrEOL;
end;

function ReadKey: Char;
begin
  Result:=Crt.ReadKey;
end;

procedure Delay(MS: Word);
begin
  Crt.Delay(MS);
end;

procedure HighVideo;
begin
  Crt.HighVideo;
end;

end.
