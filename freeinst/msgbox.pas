Unit MsgBox;

Interface

procedure ShowError(Text: String);
procedure ShowWarning;
procedure ShowOK;

Implementation

uses
  colordef,
  tpcrt,
  tpmenu,
  tpwindow;
  
procedure ShowError(Text: String);
var
  W: WindowPtr;
Begin
  MakeWindow(W, 17, 7, 63, 13, True, True, True, WhiteOnBlack, LtRedOnBlack, LtRedOnBlack, ' WARNING! ');
  DisplayWindow(W);
  Writeln;
  Writeln(Text);
  DisposeWindow(W);
  ReadLn;

  // @todo temporary solution until implement KillWindow or EraseTopWindow
  Window(1,5,80,25);
  TextBackground(White);
  TextColor(Black);
  ClrScr;
end;

procedure ShowOK;
const
  Colors : MenuColorArray =
  ($17,                      {FrameColor}
    $4E,                     {HeaderColor}
    WhiteOnBlue,             {BodyColor}
    BlueOnLtGray,            {SelectColor}
    YellowOnBlue,            {HiliteColor}
    WhiteOnBlack,            {HelpColor}
    $17,                     {DisabledColor}
    $03                      {ShadowColor}
    );

type
  MakeCommands =             {codes returned by each menu selection}
  (Mnone,                    {no command}
   Mok);
var
  W: WindowPtr;
  YN: Menu;
  SelectKey: Char;
Begin
  MakeWindow(W, 17, 8, 63, 14, True, True, True, YellowOnBlue, WhiteOnBlue, YellowOnBlue, ' Information ');
  DisplayWindow(W);
  Writeln;
  Writeln(' Choose OK to continue ');

  YN:=NewMenu([], nil);
  SubMenu(37, 12, 0, Vertical, LotusFrame, Colors, '');
  MenuItem(' OK ', 1, 2, Ord(Mok), '');
  ResetMenu(YN);
  MenuChoice(YN, SelectKey);

  DisposeWindow(W);

  // @todo temporary solution until implement KillWindow or EraseTopWindow
  Window(1,5,80,25);
  TextBackground(White);
  TextColor(Black);
  ClrScr;
end;

procedure ShowWarning;
const
  Colors : MenuColorArray =
  (RedOnRed,                 {FrameColor}
    $4E,                     {HeaderColor}
    WhiteOnBlack,            {BodyColor}
    BlackOnLtGray,           {SelectColor}
    YellowOnBlack,           {HiliteColor}
    WhiteOnBlack,            {HelpColor}
    $17,                     {DisabledColor}
    $03                      {ShadowColor}
    );

type
  MakeCommands =             {codes returned by each menu selection}
  (Mnone,                    {no command}
   Myes,                    {main menu root}
   Mno);              {select item to edit}
var
  W: WindowPtr;
  YN: Menu;
  SelectKey: Char;
Begin
  MakeWindow(W, 17, 5, 63, 19, True, True, True, WhiteOnBlack, LtRedOnBlack, LtRedOnBlack, ' WARNING! ');
  DisplayWindow(W);
  Writeln;
  Writeln(' This is experimental software that');
  Writeln(' can *COMPLETELY* destroy your harddisk(s).');
  Writeln;
  Writeln(' Don''t use this software, unless you have');
  WriteLn(' a full system backup of all your HDs');
  WriteLn;
  WriteLn(' Are you sure, you want to continue?');

  YN:=NewMenu([], nil);
  SubMenu(37, 15, 0, Vertical, LotusFrame, Colors, '');
  MenuItem(' Yes ', 1, 2, Ord(Myes), '');
  MenuItem(' No ', 2, 2, Ord(Mno), '');
  ResetMenu(YN);
  if MenuChoice(YN, SelectKey)=ord(Mno) then Halt(9);;

  DisposeWindow(W);

  // @todo temporary solution until implement KillWindow or EraseTopWindow
  Window(1,5,80,25);
  TextBackground(White);
  TextColor(Black);
  ClrScr;
end;

End.
