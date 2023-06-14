{

     osFree Turbo Professional Copyright (C) 2022-2023 osFree

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

{$MODE ObjFPC}

unit tpcrt;
  {-Extended CRT unit. Implements TurboPower Turbo Professional TPCRT intarface.}

interface

uses
  crt;

const
  {video mode constants}
  BW40 = 0;
  CO40 = 1;
  C40 = CO40;
  BW80 = 2;
  CO80 = 3;
  C80 = CO80;
  Mono = 7;
  Font8x8 = 256;
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

const
 {Set to True to allow programs to run as background tasks under
  DesqView/TaskView. Must be set False for TSR's.}
  DetectMultitasking : Boolean = False;
  BiosScroll : Boolean = True; {False to use TPCRT routines for clean scrolling}

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

const
  MapColors : Boolean = True; {True to let MapColor map colors for mono visibility}

type
  DisplayType = (MonoHerc, CGA, MCGA, EGA, VGA, PGC);
  HercCardType = (HercNone, HercPlain, HercPlus, HercInColor);
  FlexAttrs = array[0..3] of Byte; {attributes for FlexWrite}

  {record used to save/restore window coordinates}
  WindowCoordinates =
    record
      XL, YL, XH, YH : Byte;
    end;

type
  PackedScreen = array[1..4000] of Byte; {dummy--actual size varies}
  PackedWindow =             {!!do not change!!}
    record
      Size : Word;           {size of packed window, including this header}
      TopRow : Byte;         {coordinates for top left corner of window}
      TopCol : Byte;
      Rows : Byte;           {height of window}
      Cols : Byte;           {width of window}
      AStart : Word;         {index to start of attributes section in Contents}
      CDelta : Word;         {bytes before first PackRec - chars}
      ADelta : Word;         {bytes before first PackRec - attrs}
      Contents : PackedScreen; {the contents of the packed screen}
    end;
  PackedWindowPtr = ^PackedWindow;

type
  LibName = string[12];
  deName = array[1..11] of Char; {first 8 have name, last 3 have extension}
  DirectoryEntry =
    record
      Status : ShortInt;     {0 = in use, -1 = unused, -2 = deleted}
      Name : deName;         {name and extension in FCB format}
      Index : Word;          {index to this member}
      MemberLength : Word;   {# of 128-byte blocks used by member}
      CRC : Word;            {not implemented}
      CreationDate : Word;   {date entry was created--not used}
      LastChangeDate : Word; {date it was last changed--not used}
      CreationTime : Word;   {time entry was created--not used}
      LastChangeTime : Word; {time it was last changed--not used}
      PadCount : Byte;       {unused bytes in last block of member}
      Filler : array[28..32] of Byte; {padded to 32 bytes}
    end;
  DirectoryType = array[0..255] of DirectoryEntry;
  DirectoryPtr = ^DirectoryType;

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

procedure FastWrite(St : string; Row, Col, Attr : Byte);
  {-Write St at Row,Col in Attr (video attribute) without snow}

procedure SetFrameChars(Vertical, Horizontal, LowerRight, UpperRight,
                        LowerLeft, UpperLeft : Char);
  {-Sets the frame characters to be used on subsequent FrameWindow calls.}

procedure WhereXYdirect(var X, Y : Byte);
  {-Read the current position of the cursor directly from the CRT controller}

function GetCrtMode : Byte;
 {-Get the current video mode. Also reinitializes internal variables. May
   reset: CurrentMode, ScreenWidth, ScreenHeight, CurrentPage, and
   VideoSegment.}

procedure GotoXYAbs(X, Y : Byte);
  {-Move cursor to column X, row Y. No error checking done.}

procedure SetVisiblePage(PageNum : Byte);
  {-Set current video page}

procedure ScrollWindowUp(XLo, YLo, XHi, YHi, Lines : Byte);
  {-Scrolls the designated window up the specified number of lines.}

procedure ScrollWindowDown(XLo, YLo, XHi, YHi, Lines : Byte);
  {-Scrolls the designated window down the specified number of lines.}

function CursorTypeSL : Word;
  {-Returns a word. High byte has starting scan line, low byte has ending.}

function CursorStartLine : Byte;
  {-Returns the starting scan line of the cursor}

function CursorEndLine : Byte;
  {-Returns the ending scan line of the cursor.}

procedure SetCursorSize(Startline, EndLine : Byte);
  {-Sets the cursor's starting and ending scan lines.}

procedure NormalCursor;
  {-Set normal scan lines for cursor based on current video mode}

procedure FatCursor;
  {-Set larger scan lines for cursor based on current video mode}

procedure BlockCursor;
  {-Set scan lines for a block cursor}

procedure HiddenCursor;
  {-Hide the cursor}

function ReadCharAtCursor : Char;
  {-Returns character at the current cursor location on the selected page.}

function ReadAttrAtCursor : Byte;
  {-Returns attribute at the current cursor location on the selected page.}

procedure GetCursorState(var XY, ScanLines : Word);
  {-Return the current position and size of the cursor}

procedure RestoreCursorState(XY, ScanLines : Word);
  {-Reset the cursor to a position and size saved with GetCursorState}

procedure FastWriteWindow(St : string; Row, Col, Attr : Byte);
  {-Write a string using window-relative coordinates}

procedure FastText(St : string; Row, Col : Byte);
  {-Write St at Row,Col without changing the underlying video attribute.}

procedure FastTextWindow(St : string; Row, Col : Byte);
  {-Write St at window Row,Col without changing the underlying video attribute.}

procedure FastVert(St : string; Row, Col, Attr : Byte);
  {-Write St vertically at Row,Col in Attr (video attribute)}

procedure FastVertWindow(St : string; Row, Col, Attr : Byte);
  {-Write a string vertically using window-relative coordinates}

procedure FastFill(Number : Word; Ch : Char; Row, Col, Attr : Byte);
  {-Fill Number chs at Row,Col in Attr (video attribute) without snow}

procedure FastFillWindow(Number : Word; Ch : Char; Row, Col, Attr : Byte);
  {-Fill Number chs at window Row,Col in Attr (video attribute) without snow}

procedure FastCenter(St : string; Row, Attr : Byte);
  {-Write St centered on window Row in Attr (video attribute) without snow}

procedure FastFlush(St : string; Row, Attr : Byte);
  {-Write St flush right on window Row in Attr (video attribute) without snow}

procedure FastRead(Number, Row, Col : Byte; var St : string);
  {-Read Number characters from the screen into St starting at Row,Col}

procedure FastReadWindow(Number, Row, Col : Byte; var St : string);
  {-Read Number characters from the screen into St starting at window Row,Col}

procedure ReadAttribute(Number, Row, Col : Byte; var St : string);
  {-Read Number attributes from the screen into St starting at Row,Col}

procedure ReadAttributeWindow(Number, Row, Col : Byte; var St : string);
  {-Read Number attributes from the screen into St starting at window Row,Col}

procedure WriteAttribute(St : String; Row, Col : Byte);
  {-Write string of attributes St at Row,Col without changing characters}

procedure WriteAttributeWindow(St : String; Row, Col : Byte);
  {-Write string of attributes St at window Row,Col without changing characters}

procedure ChangeAttribute(Number : Word; Row, Col, Attr : Byte);
  {-Change Number video attributes to Attr starting at Row,Col}

procedure ChangeAttributeWindow(Number : Word; Row, Col, Attr : Byte);
  {-Change Number video attributes to Attr starting at window Row,Col}

procedure MoveScreen(var Source, Dest; Length : Word);
  {-Move Length words from Source to Dest without snow}

procedure FlexWrite(St : string; Row, Col : Byte; var FAttrs : FlexAttrs);
  {-Write St at Row,Col with flexible color handling}

procedure FlexWriteWindow(St : string; Row, Col : Byte; var FAttrs : FlexAttrs);
  {-Write a string flexibly using window-relative coordinates.}

function SaveWindow(XLow, YLow, XHigh, YHigh : Byte; Allocate : Boolean;
                    var Covers : Pointer) : Boolean;
  {-Allocate buffer space if requested and save window contents}

procedure RestoreWindow(XLow, YLow, XHigh, YHigh : Byte;
                        Deallocate : Boolean; var Covers : Pointer);
  {-Restore screen contents and deallocate buffer space if requested}

procedure StoreWindowCoordinates(var WC : WindowCoordinates);
  {-Store the window coordinates for the active window}

procedure RestoreWindowCoordinates(WC : WindowCoordinates);
  {-Restore previously saved window coordinates}

function PackWindow(XLow, YLow, XHigh, YHigh : Byte) : PackedWindowPtr;
  {-Return a pointer to a packed window, or nil if not enough memory}

procedure DispPackedWindow(PWP : PackedWindowPtr);
  {-Display the packed window pointed to by PWP}

procedure DispPackedWindowAt(PWP : PackedWindowPtr; Row, Col : Byte);
 {-Display the packed window pointed to by PWP at Row,Col. If necessary,
   the coordinates are adjusted to allow it to fit on the screen.}

procedure MapPackedWindowColors(PWP : PackedWindowPtr);
 {-Map the colors in a packed window for improved appearance on mono/B&W
   displays}

procedure DisposePackedWindow(var PWP : PackedWindowPtr);
  {-Dispose of a packed window, setting PWP to nil on exit}

procedure WritePackedWindow(PWP : PackedWindowPtr; FName : string);
 {-Store the packed window pointed to by PWP in FName}

function ReadPackedWindow(FName : string) : PackedWindowPtr;
 {-Read the packed window stored in FName into memory}

function CreateLibrary(var F : file; Name : string;
                       Entries : Byte) : DirectoryPtr;
 {-Create a library with the specified # of directory entries}

function OpenLibrary(var F : file; Name : string) : DirectoryPtr;
 {-Open the specified library and return a pointer to its directory}

procedure CloseLibrary(var F : file; var DP : DirectoryPtr);
  {-Close library F and deallocate its directory}

procedure PackLibrary(LName : string);
 {-Pack a library to remove deleted entries.}

procedure AddWindowToLibrary(PWP : PackedWindowPtr; var F : file;
                             DP : DirectoryPtr; WinName : LibName);
 {-Add a packed window to the specified library}

function ReadWindowFromLibrary(var F : file; DP : DirectoryPtr;
                               WinName : LibName) : PackedWindowPtr;
 {-Read a packed window from a library}

procedure DeleteWindowFromLibrary(var F : file; DP : DirectoryPtr;
                                  WinName : LibName);
 {-Delete a packed window from the specified library}

function MapColor(c : Byte) : Byte;
  {-Map a video attribute for visibility on mono/bw displays}

procedure SetBlink(On : Boolean);
  {-Enable text mode attribute blinking if On is True}

procedure SetCrtBorder(Attr : Byte);
  {-Set border to background color if card type and mode allow}

function Font8x8Selected : Boolean;
  {-Return True if EGA or VGA is active and in 8x8 font}

procedure SelectFont8x8(On : Boolean);
  {-Toggle 8x8 font on or off}

function HercPresent : Boolean;
  {-Return true if a Hercules graphics card is present}

procedure SwitchInColorCard(ColorOn : Boolean);
  {-Activate or deactivate colors on a Hercules InColor card}

function HercGraphicsMode : Boolean;
  {-Return True if a Hercules card is in graphics mode}

function HercModeTestWorks : Boolean;
  {-Return True if HercGraphicsMode will work}

procedure SetHercMode(GraphMode : Boolean; GraphPage : Byte);
 {-Set Hercules card to graphics mode or text mode, and activate specified
   graphics page (if switching to graphics mode).}

function ReadKeyWord : Word;
 {-Waits for keypress, then returns scan and character codes together}

function CheckKbd(var KeyCode : Word) : Boolean;
  {-Returns True (and the key codes) if a keystroke is waiting}

function KbdFlags : Byte;
  {-Returns keyboard status flags as a bit-coded byte}

procedure StuffKey(W : Word);
  {-Stuff one key into the keyboard buffer}

procedure StuffString(S : string);
  {-Stuff the contents of S into the keyboard buffer}

procedure ReInitCrt;
 {-Reinitialize CRT unit's internal variables. For TSR's or programs with
   DOS shells. May reset: CurrentMode, ScreenWidth, ScreenHeight,
   WindMin/WindMax, CurrentPage, CurrentDisplay, CheckSnow, and VideoSegment.}


{Forwarders to CRT}

var
  CheckBreak: boolean absolute Crt.CheckBreak;
  CheckEOF: boolean absolute Crt.CheckEOF;
  DirectVideo: boolean absolute Crt.DirectVideo;
  CheckSnow: boolean absolute Crt.CheckSnow;
  LastMode : word absolute Crt.LastMode;
  TextAttr: byte absolute Crt.TextAttr;
  WindMin: Word absolute Crt.WindMin;
  WindMax: Word absolute Crt.WindMax;
  {$IFNDEF Windows}
  ScreenWidth: Longint absolute Crt.ScreenWidth;
  ScreenHeight: Longint absolute Crt.ScreenHeight;
  {$ELSE}
  ScreenWidth: Longint = 80;
  ScreenHeight: Longint = 25;

procedure SetSafeCPSwitching(F: Boolean);
procedure SetUseACP(F: Boolean);
  {$ENDIF}

var
  CurrentMode : Byte absolute LastMode; {current video mode}

{for backward compatibility with old TPCRT}
var
  CurrentWidth : Word absolute ScreenWidth; {current width of display}

Function GetCurrentHeight: Word;  
Procedure SetCurrentHeight(Value: Word);  

Property  
  CurrentHeight: Word Read GetCurrentHeight Write SetCurrentHeight; {current height of display - 1}

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
procedure LowVideo;
procedure HighVideo;
procedure NormVideo;
procedure Sound(Hz: Word);
procedure NoSound;
procedure InsLine;
procedure DelLine;
procedure AssignCrt(var F: Text);
function KeyPressed: Boolean;
procedure TextMode (Mode: word);

implementation

{$ifdef windows}
uses windows;
{$endif}

procedure SetFrameChars(Vertical, Horizontal, LowerRight, UpperRight,
                        LowerLeft, UpperLeft : Char);
  {-Sets the frame characters to be used on subsequent FrameWindow calls.}
begin
  FrameChars[Vert]:=Vertical;
  FrameChars[Horiz]:=Horizontal;
  FrameChars[LRight]:=LowerRight;
  FrameChars[URight]:=UpperRight;
  FrameChars[LLeft]:=LowerLeft;
  FrameChars[ULeft]:=UpperLeft;
end;

procedure FastWrite(St : string; Row, Col, Attr : Byte);
  {-Write St at Row,Col in Attr (video attribute) without snow}
var
  oldTextAttr: Byte;
  OldX, OldY: Byte;
  WC: WindowCoordinates;
begin
  OldTextAttr:=TextAttr;
  OldX:=WhereX;
  OldY:=WhereY;
  StoreWindowCoordinates(WC);

  TextAttr:=Attr;
  Window(1, 1, ScreenWidth, ScreenHeight);
  GoToXY(Col, Row);
  Write(St);

  TextAttr:=OldTextAttr;
  RestoreWindowCoordinates(WC);
  GoToXY(OldX, OldY);
end;

procedure FrameWindow(LeftCol, TopRow, RightCol, BotRow, FAttr, HAttr : Byte;
                      Header : string);
  {-Draws a frame around a window}
var
  i: byte;
begin
  HiddenCursor;
  FastWrite(FrameChars[ULeft], TopRow, LeftCol, FAttr);
  for i:=LeftCol+1 to RightCol-1 do FastWrite(FrameChars[Horiz], TopRow, i, FAttr);
  FastWrite(FrameChars[URight], TopRow, RightCol, FAttr);

  for i:=TopRow+1 to BotRow-1 do
  begin
    FastWrite(FrameChars[Vert], i, LeftCol, FAttr);
    FastWrite(FrameChars[Vert], i, RightCol, FAttr);
  end;

  FastWrite(FrameChars[LLeft], BotRow, LeftCol, FAttr);
  for i:=LeftCol+1 to RightCol-1 do FastWrite(FrameChars[Horiz], BotRow, i, FAttr);
  FastWrite(FrameChars[LRight], BotRow, RightCol, FAttr);

  if Header<>'' then
  begin
    FastWrite(Header, TopRow, LeftCol+(RightCol-LeftCol) div 2-Length(Header) div 2, HAttr);
  end;
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

procedure WhereXYdirect(var X, Y : Byte);
  {-Read the current position of the cursor directly from the CRT controller}
begin
  X:=ScreenX;
  Y:=ScreenY;
end;


function GetCrtMode : Byte;
 {-Get the current video mode. Also reinitializes internal variables. May
   reset: CurrentMode, ScreenWidth, ScreenHeight, CurrentPage, and
   VideoSegment.}
begin
end;

procedure GotoXYAbs(X, Y : Byte);
  {-Move cursor to column X, row Y. No error checking done.}
begin
end;

procedure SetVisiblePage(PageNum : Byte);
  {-Set current video page}
begin
end;

procedure ScrollWindowUp(XLo, YLo, XHi, YHi, Lines : Byte);
  {-Scrolls the designated window up the specified number of lines.}
begin
end;

procedure ScrollWindowDown(XLo, YLo, XHi, YHi, Lines : Byte);
  {-Scrolls the designated window down the specified number of lines.}
begin
end;

function CursorTypeSL : Word;
  {-Returns a word. High byte has starting scan line, low byte has ending.}
begin
end;

function CursorStartLine : Byte;
  {-Returns the starting scan line of the cursor}
begin
  Result:=Hi(CursorTypeSL);
end;

function CursorEndLine : Byte;
  {-Returns the ending scan line of the cursor.}
begin
  Result:=Lo(CursorTypeSL);
end;

procedure SetCursorSize(Startline, EndLine : Byte);
  {-Sets the cursor's starting and ending scan lines.}
begin
end;

procedure NormalCursor;
  {-Set normal scan lines for cursor based on current video mode}
begin
  SetCursorSize($05, $07);
end;

procedure FatCursor;
  {-Set larger scan lines for cursor based on current video mode}
begin
  SetCursorSize($03, $07);
end;

procedure BlockCursor;
  {-Set scan lines for a block cursor}
begin
  SetCursorSize($00, $07);
end;

procedure HiddenCursor;
  {-Hide the cursor}
begin
  CursorOff;
end;

function ReadCharAtCursor : Char;
  {-Returns character at the current cursor location on the selected page.}
begin
end;

function ReadAttrAtCursor : Byte;
  {-Returns attribute at the current cursor location on the selected page.}
begin
end;

procedure GetCursorState(var XY, ScanLines : Word);
  {-Return the current position and size of the cursor}
begin
  XY:=WhereXY;
  ScanLines:=CursorTypeSL;
end;

procedure RestoreCursorState(XY, ScanLines : Word);
  {-Reset the cursor to a position and size saved with GetCursorState}
begin
  SetCursorSize(Hi(ScanLines), Lo(ScanLines));
  GotoXYAbs(Lo(XY), Hi(XY));
end;

procedure FastWriteWindow(St : string; Row, Col, Attr : Byte);
  {-Write a string using window-relative coordinates}
begin
  FastWrite(St, Row+Hi(WindMin), Col+Lo(WindMin), Attr);
end;

procedure FastText(St : string; Row, Col : Byte);
  {-Write St at Row,Col without changing the underlying video attribute.}
begin
end;

procedure FastTextWindow(St : string; Row, Col : Byte);
  {-Write St at window Row,Col without changing the underlying video attribute.}
begin
  FastText(St, Row+Hi(WindMin), Col+Lo(WindMin));
end;

procedure FastVert(St : string; Row, Col, Attr : Byte);
  {-Write St vertically at Row,Col in Attr (video attribute)}
begin
end;

procedure FastVertWindow(St : string; Row, Col, Attr : Byte);
  {-Write a string vertically using window-relative coordinates}
begin
  FastVert(St, Row+Hi(WindMin), Col+Lo(WindMin), Attr);
end;

procedure FastFill(Number : Word; Ch : Char; Row, Col, Attr : Byte);
  {-Fill Number chs at Row,Col in Attr (video attribute) without snow}
begin
end;

procedure FastFillWindow(Number : Word; Ch : Char; Row, Col, Attr : Byte);
  {-Fill Number chs at window Row,Col in Attr (video attribute) without snow}
begin
  FastFill(Number, Ch, Row+Hi(WindMin), Col+Lo(WindMin), Attr);
end;

procedure FastCenter(St : string; Row, Attr : Byte);
  {-Write St centered on window Row in Attr (video attribute) without snow}
begin
end;

procedure FastFlush(St : string; Row, Attr : Byte);
  {-Write St flush right on window Row in Attr (video attribute) without snow}
begin
end;

procedure FastRead(Number, Row, Col : Byte; var St : string);
  {-Read Number characters from the screen into St starting at Row,Col}
begin
end;

procedure FastReadWindow(Number, Row, Col : Byte; var St : string);
  {-Read Number characters from the screen into St starting at window Row,Col}
begin
  FastRead(Number, Row+Hi(WindMin), Col+Lo(WindMin), St);
end;

procedure ReadAttribute(Number, Row, Col : Byte; var St : string);
  {-Read Number attributes from the screen into St starting at Row,Col}
begin
end;

procedure ReadAttributeWindow(Number, Row, Col : Byte; var St : string);
  {-Read Number attributes from the screen into St starting at window Row,Col}
begin
  ReadAttribute(Number, Row+Hi(WindMin), Col+Lo(WindMin), St);
end;

procedure WriteAttribute(St : String; Row, Col : Byte);
  {-Write string of attributes St at Row,Col without changing characters}
begin
end;

procedure WriteAttributeWindow(St : String; Row, Col : Byte);
  {-Write string of attributes St at window Row,Col without changing characters}
begin
  WriteAttribute(St, Row+Hi(WindMin), Col+Lo(WindMin));
end;

procedure ChangeAttribute(Number : Word; Row, Col, Attr : Byte);
  {-Change Number video attributes to Attr starting at Row,Col}
begin
end;

procedure ChangeAttributeWindow(Number : Word; Row, Col, Attr : Byte);
  {-Change Number video attributes to Attr starting at window Row,Col}
begin
  ChangeAttribute(Number, Row+Hi(WindMin), Col+Lo(WindMin), Attr);
end;

procedure MoveScreen(var Source, Dest; Length : Word);
  {-Move Length words from Source to Dest without snow}
begin
  Move(Source, Dest, Length);
end;

procedure FlexWrite(St : string; Row, Col : Byte; var FAttrs : FlexAttrs);
  {-Write St at Row,Col with flexible color handling}
begin
end;

procedure FlexWriteWindow(St : string; Row, Col : Byte; var FAttrs : FlexAttrs);
  {-Write a string flexibly using window-relative coordinates.}
begin
  FlexWrite(St, Row+Hi(WindMin), Col+Lo(WindMin), FAttrs);
end;

function SaveWindow(XLow, YLow, XHigh, YHigh : Byte; Allocate : Boolean;
                    var Covers : Pointer) : Boolean;
  {-Allocate buffer space if requested and save window contents}
begin
end;

procedure RestoreWindow(XLow, YLow, XHigh, YHigh : Byte;
                        Deallocate : Boolean; var Covers : Pointer);
  {-Restore screen contents and deallocate buffer space if requested}
begin
end;

procedure StoreWindowCoordinates(var WC : WindowCoordinates);
  {-Store the window coordinates for the active window}
begin
  WC.XL := Lo(WindMin)+1;
  WC.YL := Hi(WindMin)+1;
  WC.XH := Lo(WindMax)+1;
  WC.YH := Hi(WindMax)+1;
end;

procedure RestoreWindowCoordinates(WC : WindowCoordinates);
  {-Restore previously saved window coordinates}
begin
  Window(WC.XL, WC.YL, WC.XH, WC.YH);
end;

function PackWindow(XLow, YLow, XHigh, YHigh : Byte) : PackedWindowPtr;
  {-Return a pointer to a packed window, or nil if not enough memory}
begin
end;

procedure DispPackedWindow(PWP : PackedWindowPtr);
  {-Display the packed window pointed to by PWP}
begin
end;

procedure DispPackedWindowAt(PWP : PackedWindowPtr; Row, Col : Byte);
 {-Display the packed window pointed to by PWP at Row,Col. If necessary,
   the coordinates are adjusted to allow it to fit on the screen.}
begin
end;

procedure MapPackedWindowColors(PWP : PackedWindowPtr);
 {-Map the colors in a packed window for improved appearance on mono/B&W
   displays}
begin
end;

procedure DisposePackedWindow(var PWP : PackedWindowPtr);
  {-Dispose of a packed window, setting PWP to nil on exit}
begin
end;

procedure WritePackedWindow(PWP : PackedWindowPtr; FName : string);
 {-Store the packed window pointed to by PWP in FName}
begin
end;

function ReadPackedWindow(FName : string) : PackedWindowPtr;
 {-Read the packed window stored in FName into memory}
begin
end;

function CreateLibrary(var F : file; Name : string;
                       Entries : Byte) : DirectoryPtr;
 {-Create a library with the specified # of directory entries}
begin
end;

function OpenLibrary(var F : file; Name : string) : DirectoryPtr;
 {-Open the specified library and return a pointer to its directory}
begin
end;

procedure CloseLibrary(var F : file; var DP : DirectoryPtr);
  {-Close library F and deallocate its directory}
begin
end;

procedure PackLibrary(LName : string);
 {-Pack a library to remove deleted entries.}
begin
end;

procedure AddWindowToLibrary(PWP : PackedWindowPtr; var F : file;
                             DP : DirectoryPtr; WinName : LibName);
 {-Add a packed window to the specified library}
begin
end;

function ReadWindowFromLibrary(var F : file; DP : DirectoryPtr;
                               WinName : LibName) : PackedWindowPtr;
 {-Read a packed window from a library}
begin
end;

procedure DeleteWindowFromLibrary(var F : file; DP : DirectoryPtr;
                                  WinName : LibName);
 {-Delete a packed window from the specified library}
begin
end;

function MapColor(c : Byte) : Byte;
  {-Map a video attribute for visibility on mono/bw displays}
begin
end;

procedure SetBlink(On : Boolean);
  {-Enable text mode attribute blinking if On is True}
begin
end;

procedure SetCrtBorder(Attr : Byte);
  {-Set border to background color if card type and mode allow}
begin
end;

function Font8x8Selected : Boolean;
  {-Return True if EGA or VGA is active and in 8x8 font}
begin
  Result:=(CurrentMode and Font8x8)=Font8x8;
end;

procedure SelectFont8x8(On : Boolean);
  {-Toggle 8x8 font on or off}
begin
  if (CurrentMode and Font8x8)=Font8x8 then
  begin
    TextMode(LastMode - Font8x8);
  end else begin
    TextMode(LastMode or Font8x8);
  end;
end;

function HercPresent : Boolean;
  {-Return true if a Hercules graphics card is present}
begin
  Result:=False;
end;

procedure SwitchInColorCard(ColorOn : Boolean);
  {-Activate or deactivate colors on a Hercules InColor card}
begin
end;

function HercGraphicsMode : Boolean;
  {-Return True if a Hercules card is in graphics mode}
begin
end;

function HercModeTestWorks : Boolean;
  {-Return True if HercGraphicsMode will work}
begin
end;

procedure SetHercMode(GraphMode : Boolean; GraphPage : Byte);
 {-Set Hercules card to graphics mode or text mode, and activate specified
   graphics page (if switching to graphics mode).}
begin
end;

function ReadKeyWord : Word;
 {-Waits for keypress, then returns scan and character codes together}
begin
  
end;

function CheckKbd(var KeyCode : Word) : Boolean;
  {-Returns True (and the key codes) if a keystroke is waiting}
begin
end;

function KbdFlags : Byte;
  {-Returns keyboard status flags as a bit-coded byte}
begin
end;

procedure StuffKey(W : Word);
  {-Stuff one key into the keyboard buffer}
begin
end;

procedure StuffString(S : string);
  {-Stuff the contents of S into the keyboard buffer}
begin
end;

procedure ReInitCrt;
 {-Reinitialize CRT unit's internal variables. For TSR's or programs with
   DOS shells. May reset: CurrentMode, ScreenWidth, ScreenHeight,
   WindMin/WindMax, CurrentPage, CurrentDisplay, CheckSnow, and VideoSegment.}
begin
end;

{Forwarders to Crt}
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

procedure LowVideo;
begin
  Crt.LowVideo;
end;

procedure NormVideo;
begin
  Crt.NormVideo;
end;

procedure Sound(Hz: Word);
begin
  Crt.Sound(Hz);
end;

procedure NoSound;
begin
  Crt.NoSound;
end;

procedure InsLine;
begin
  Crt.InsLine;
end;

procedure DelLine;
begin
  Crt.DelLine;
end;

procedure AssignCrt(var F: Text);
begin
  Crt.AssignCrt(F);
end;

function KeyPressed: Boolean;
begin
  Result:=Crt.KeyPressed;
end;

procedure TextMode (Mode: word);
begin
  Crt.TextMode(Mode);
end;

Function GetCurrentHeight: Word;  
begin
  Result:=ScreenHeight-1;
end;

Procedure SetCurrentHeight(Value: Word);  
begin
  ScreenHeight:=Value+1;
end;

{$ifdef windows}
procedure SetSafeCPSwitching(F: Boolean);
begin
  Crt.SetSafeCPSwitching(F);
end;

procedure SetUseACP(F: Boolean);
begin
  Crt.SetUseACP(F);
end;

var
  ConsoleInfo: TConsoleScreenBufferinfo;

begin
  if GetConsoleScreenBufferInfo(GetStdHandle(STD_OUTPUT_HANDLE), ConsoleInfo) then
  begin
    ScreenHeight:=ConsoleInfo.dwSize.Y;
    ScreenWidth:=ConsoleInfo.dwSize.X;
  end;
{$endif}
end.
