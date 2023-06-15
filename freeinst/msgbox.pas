Unit MsgBox;

Interface

procedure ShowError(Text: String);

Implementation

uses
  colordef,
  tpcrt,
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

End.
