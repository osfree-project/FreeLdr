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

unit tppick;
  {Pick item from list}

interface
  uses tpwindow;

const
  PKSNone = 0;                    {Command values accepted by pick manager}
  PKSAlpha = 1;
  PKSUp = 2;
  PKSDown = 3;
  PKSPgUp = 4;
  PKSPgDn = 5;
  PKSLeft = 6;
  PKSRight = 7;
  PKSExit = 8;
  PKSSelect = 9;
  PKSHelp = 10;
  PKSHome = 11;
  PKSEnd = 12;
  PKSProbe = 13;
  PKSUser0 = 14;                  {User-defined exit commands}
  PKSUser1 = 15;
  PKSUser2 = 16;
  PKSUser3 = 17;
  PKSUser4 = 18;                  {!!.21}
  PKSUser5 = 19;                  {!!.21}
  PKSUser6 = 20;                  {!!.21}
  PKSUser7 = 21;                  {!!.21}
  PKSUser8 = 22;                  {!!.21}
  PKSUser9 = 23;                  {!!.21}

  MaxSearchLen = 16;              {Maximum length of incremental search string}

type
  PKType = PKSNone..PKSUser9;     {All of the pick commands} {!!.21}

  PickColorType =
  (WindowAttr,                    {Color for normal unselected items}
   FrameAttr,                     {Color for window frame}
   HeaderAttr,                    {Color for window header}
   SelectAttr,                    {Color for normal selected item}
   AltNormal,                     {Color for alternate unselected items}
   AltHigh                        {Color for alternate selected item}
   {$IFDEF PickItemDisable}
   ,
   UnpickableAttr                 {Color for unpickable item}
   {$ENDIF}
   );
  PickColorArray = array[PickColorType] of Byte;

  SrchString = String[MaxSearchLen]; {Maximum search string size}

  SrchType =
  (NoPickSrch,                    {Alpha characters ignored}
   StringPickSrch,                {Incremental search}
   StringAltSrch,                 {Alternate incremental search}
   CharPickSrch,                  {Single char search}
   CharPickNow);                  {Single char search, exit on match}

  PickOrientType =
  (PickOrientNone,                {No orientation selected}
   PickVertical,                  {Items arranged vertically}
   PickHorizontal,                {Items arranged horizontally}
   PickSnaking);                  {Items arranged vertically, snaking}

const
  {Size control for picklist}
  PickMinRows : Word = 0;         {Minimum rows in window}
  PickMaxRows : Word = 9999;      {Maximum rows in window}
  PickMatrix : Byte = 1;          {Number of items across in window}

  {Appearance control for picklist}
  PickStick : Boolean = True;     {True to "stick" at top/bottom on scrolling picklists}
  PickMore : Boolean = True;      {Show "more" markers for items out of window}
  PickAlterPageRow : Boolean = True; {False to leave row fixed after PgUp/PgDn}

  {Search control for picklist}
  PickSrch : SrchType = NoPickSrch; {Disable character and string searches}
  SrchStart : Byte = 1;           {Starting position of search in item string}
  PickSrchStat : Boolean = True;  {True to show status of incremental searches}

  {Cursor control for picklist}
  HideCursor : Boolean = True;    {False to leave hardware cursor on screen}

  {$IFDEF UseMouse}
  {Mouse control for picklist}
  PickMouseScroll : Boolean = True; {True to support mouse scrolling}
  PickMousePage : Boolean = False; {True to scroll by one page per click}
  PickMouseEnabled : Boolean = False; {True if mouse is enabled}
  PrevSlid : Byte = 0;            {Previous scroll bar slider position}
  PickMouseWindow : Boolean = True; {True if mouse window around pick window} {!!.21}
  {$ENDIF}

  {Color control for picklist}
  AltPickAttr : Boolean = False;  {If True, special color attributes used to pick item}

  {$IFDEF PickItemDisable}
  {User control as to whether the choice is pickable}
  Pickable : Boolean = True;      {User controlled variable for pickable items}
  {$ENDIF}

  {.F-}
  {Keystroke to command mapping}
  PickKeyMax = 111;
  PickKeyID : string[16] = 'tppick key array';
  PickKeySet : array[0..PickKeyMax] of Byte =
  (
  3, $00, $48, PKSUp,       {Up}
  3, $00, $50, PKSDown,     {Down}
  3, $00, $49, PKSPgUp,     {PgUp}
  3, $00, $51, PKSPgDn,     {PgDn}
  3, $00, $4B, PKSLeft,     {Left}
  3, $00, $4D, PKSRight,    {Right}
  3, $00, $3B, PKSHelp,     {F1}
  3, $00, $47, PKSHome,     {Home}
  3, $00, $4F, PKSEnd,      {End}
  2, $05,      PKSUp,       {^E}
  2, $17,      PKSUp,       {^W}
  2, $18,      PKSDown,     {^X}
  2, $1A,      PKSDown,     {^Z}
  2, $12,      PKSPgUp,     {^R}
  2, $03,      PKSPgDn,     {^C}
  2, $13,      PKSLeft,     {^S}
  2, $04,      PKSRight,    {^D}
  2, $1B,      PKSExit,     {Esc}
  2, $0D,      PKSSelect,   {Enter}
  3, $11, $12, PKSHome,     {^QR}
  3, $11, $03, PKSEnd,      {^QC}
  {$IFDEF UseMouse}
  3, $00, $EF, PKSProbe,    {Click left}
  3, $00, $EE, PKSExit,     {Click right}
  3, $00, $ED, PKSHelp,     {Click both}
  {$ELSE}
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0,
  {$ENDIF}
  0, 0, 0, 0, 0, 0,         {Space for customization}
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  );
  {.F+}

var
  {External control pointers for picklist}
  PickKeyPtr : Pointer;           {User defined keyboard function}
  PickUserPtr : Pointer;          {User defined routine for each pick move}
  PickHelpPtr : Pointer;          {If not nil, routine is called when help key pressed}
  PickSrchPtr : Pointer;          {User defined routine for pick searching}

  PickCmdNum : PKType;            {Command number used to exit pick}
  PickChar : Char;                {Character used to exit pick}

  SStr : SrchString;              {Holder for search string}
  Slen : Byte absolute SStr;      {Length of search string}


function PickWindow
  (StringFunc : Pointer;          {Pointer to function to return each item string}
   NumItems : Word;               {Number of items to pick from}
   XLow, YLow : Byte;             {Window coordinates, including frame if any}
   XHigh, YHigh : Byte;           {Window coordinates, including frame if any}
   DrawFrame : Boolean;           {True to draw a frame around window}
   Colors : PickColorArray;       {Video attributes to use}
   Header : String;               {Title for window}
   var Choice : Word              {The item selected, in the range 1..NumItems}
   ) : Boolean;                   {True if PickWindow was successful}
  {-Display a window, let user scroll around in it, and return choice.
    Choice returned is in the range 1..NumItems.}

procedure FillPickWindow
  (W : WindowPtr;                 {Which window to display pick list}
   StringFunc : Pointer;          {Pointer to function to return each item string}
   NumItems : Word;               {Number of items in PickArray}
   Colors : PickColorArray;       {Video attributes to use}
   Choice : Word;                 {Choice,FirstChoice tell how items should be drawn}
   FirstChoice : Word);           {...in a manner consistent with PickBar}
  {-Display a window, fill it with choices, and return.
    Choice specifies the initial item highlighted.}

procedure PickBar
  (W : WindowPtr;                 {The window to operate in}
   StringFunc : Pointer;          {Pointer to function to return items}
   NumItems : Word;               {The number of items to pick from}
   Colors : PickColorArray;       {Video attributes to use}
   EraseBar : Boolean;            {Should we recolor the bar when finished?}
   var Choice : Word;             {The item selected, range 1..NumItems}
   var FirstChoice : Word);       {Choice appearing in upper left corner of window}
  {-Choose from a pick list already displayed on the screen}

procedure EvaluatePickCommand
  (W : WindowPtr;                 {The window to operate in}
   StringFunc : Pointer;          {Pointer to function to return items}
   NumItems : Word;               {The number of items to pick from}
   var Choice : Word;             {The item selected, range 1..NumItems}
   var FirstChoice : Word;        {The item in the upper left corner}
   var Cmd : PKType);             {Command to evaluate, modified only if mouse select}
  {-Evaluate a pick command}

{$IFDEF EnablePickOrientations}
procedure SetVerticalPick;
procedure SetHorizontalPick;
procedure SetSnakingPick;
  {-Select a pick orientation}

function PickOrientation : PickOrientType;
  {-Return the current pick orientation}
{$ENDIF}

function AddPickCommand(Cmd : PKType; NumKeys : Byte; Key1, Key2 : Word) : Boolean;
  {-Add a new command key assignment or change an existing one}

  {$IFDEF UseMouse}
procedure EnablePickMouse;
  {-Enable mouse control of pick lists}

procedure DisablePickMouse;
  {-Disable mouse control of pick lists}
  {$ENDIF}

  {the following variables are reserved for internal use by TurboPower}
const
  PrivatePick : Boolean = False;
  PrivatePickAttr : Byte = 0;

implementation

function PickWindow
  (StringFunc : Pointer;          {Pointer to function to return each item string}
   NumItems : Word;               {Number of items to pick from}
   XLow, YLow : Byte;             {Window coordinates, including frame if any}
   XHigh, YHigh : Byte;           {Window coordinates, including frame if any}
   DrawFrame : Boolean;           {True to draw a frame around window}
   Colors : PickColorArray;       {Video attributes to use}
   Header : String;               {Title for window}
   var Choice : Word              {The item selected, in the range 1..NumItems}
   ) : Boolean;                   {True if PickWindow was successful}
  {-Display a window, let user scroll around in it, and return choice.
    Choice returned is in the range 1..NumItems.}
begin
end;

procedure FillPickWindow
  (W : WindowPtr;                 {Which window to display pick list}
   StringFunc : Pointer;          {Pointer to function to return each item string}
   NumItems : Word;               {Number of items in PickArray}
   Colors : PickColorArray;       {Video attributes to use}
   Choice : Word;                 {Choice,FirstChoice tell how items should be drawn}
   FirstChoice : Word);           {...in a manner consistent with PickBar}
  {-Display a window, fill it with choices, and return.
    Choice specifies the initial item highlighted.}
begin
end;

procedure PickBar
  (W : WindowPtr;                 {The window to operate in}
   StringFunc : Pointer;          {Pointer to function to return items}
   NumItems : Word;               {The number of items to pick from}
   Colors : PickColorArray;       {Video attributes to use}
   EraseBar : Boolean;            {Should we recolor the bar when finished?}
   var Choice : Word;             {The item selected, range 1..NumItems}
   var FirstChoice : Word);       {Choice appearing in upper left corner of window}
  {-Choose from a pick list already displayed on the screen}
begin
end;

procedure EvaluatePickCommand
  (W : WindowPtr;                 {The window to operate in}
   StringFunc : Pointer;          {Pointer to function to return items}
   NumItems : Word;               {The number of items to pick from}
   var Choice : Word;             {The item selected, range 1..NumItems}
   var FirstChoice : Word;        {The item in the upper left corner}
   var Cmd : PKType);             {Command to evaluate, modified only if mouse select}
  {-Evaluate a pick command}
begin
end;

procedure SetVerticalPick;
begin
end;

procedure SetHorizontalPick;
begin
end;

procedure SetSnakingPick;
  {-Select a pick orientation}
begin
end;

function PickOrientation : PickOrientType;
  {-Return the current pick orientation}
begin
end;

function AddPickCommand(Cmd : PKType; NumKeys : Byte; Key1, Key2 : Word) : Boolean;
  {-Add a new command key assignment or change an existing one}
begin
end;

procedure EnablePickMouse;
  {-Enable mouse control of pick lists}
begin
end;

procedure DisablePickMouse;
  {-Disable mouse control of pick lists}
begin
end;

end.