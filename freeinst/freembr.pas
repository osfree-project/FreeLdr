{

     osFree FreeLDR Installer
     Copyright (C) 2010 by Yoda
     Copyright (C) 2023 osFree

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

unit freembr;

interface

Procedure Install_MBR;

implementation

uses colordef,
     tpcrt,
     tpmenu,
     tpwindow,
     common,
     mbr,
     StrUtils,
     SysUtils,
     lvmapi,
	 msgbox;

const
  MenuColors : MenuColorArray =
  ($08+CyanOnBlue,                      {FrameColor}
    $4E,                     {HeaderColor}
    WhiteOnBlue,             {BodyColor}
    BlueOnLtGray,            {SelectColor}
    YellowOnBlue,            {HiliteColor}
    WhiteOnBlack,            {HelpColor}
    $17,                     {DisabledColor}
    $03                      {ShadowColor}
    );

function SelectDisk(): Byte;
var
  YN: Menu;
  SelectKey: Char;
Var
  i: integer;
  DrivesArray: TDrivesArray;
  p: integer;
  DriveStatus: TDriveInformation;
begin
  YN:=NewMenu([], nil);
  SubMenu(16, 5, 0, Vertical, SingleFrameChars, MenuColors, 'Select drive');
  DrivesArray:=LvmGetDriveControlData();
  p:=0;
  for i:=Low(DrivesArray) to High(DrivesArray) do
  begin
    inc(p);
    DriveStatus:=LvmGetDriveStatus(LvmGetDriveHandle(DrivesArray[i].DriveNumber));
    MenuItem('Physical drive '+IntToStr(DrivesArray[i].DriveNumber)+' '+DriveStatus.Drive_Name+' '+IntToStr(Trunc(Extended(DrivesArray[i].DriveSize)*512/1024/1024))+'MB ('+IfThen(DriveStatus.Corrupt_Partition_Table, 'Corrupt',IfThen(isGPT(DrivesArray[i].DriveNumber),'GPT','MBR'))+')', p, 0, DrivesArray[i].DriveNumber, '');
    if DriveStatus.Corrupt_Partition_Table then ShowError('Physical Drive ('+IntToStr(DrivesArray[i].DriveNumber)+'):'#10#13#10#13'Partition table is corrupt');
    if DriveStatus.Unusable then ShowError('Physical Drive ('+IntToStr(DrivesArray[i].DriveNumber)+'):'#10#13#10#13'Unusable');
  end;
  ResetMenu(YN);
  Result:=MenuChoice(YN, SelectKey);
end;

function SelectPartition(Handle: ADDRESS): Byte;
var
  YN: Menu;
  SelectKey: Char;
Var
  i: integer;
  p: integer;
  lp: integer;
  PA: TPartitionsArray;
begin
  YN:=NewMenu([], nil);
  SubMenu(10, 5, 0, Vertical, SingleFrameChars, MenuColors, 'Select partition');
  PA:=LvmGetPartitions(Handle);
  MenuItem('Another disk', 1, 0, 1, '');
  MenuItem('Active Partition', 2, 0, 2, '');
  p:=0;
  For i:=Low(PA) to High(PA) do
  begin
    if PA[i].Primary_Partition then
    begin
      inc(p);
      MenuItem('Partition '+PA[i].Partition_Name+' '+IntToStr(Trunc(Extended(PA[i].True_Partition_Size)*512/1024/1024))+' MB '+IfThen(PA[i].Primary_Partition,'Primary','Logical')+' '+LvmGetPartitionType(PA[i].Partition_Type)+' '+LvmGetPartitionStatus(PA[i].Partition_Status), p+2, 0, p+2{DrivesArray[i].DriveNumber}, '');
    end;
  end;
  lp:=p;
  For i:=Low(PA) to High(PA) do
  begin
    if not PA[i].Primary_Partition then
    begin
      inc(p);
      MenuItem('Partition '+PA[i].Partition_Name+' '+IntToStr(Trunc(Extended(PA[i].True_Partition_Size)*512/1024/1024))+' MB '+IfThen(PA[i].Primary_Partition,'Primary','Logical')+' '+LvmGetPartitionType(PA[i].Partition_Type)+' '+LvmGetPartitionStatus(PA[i].Partition_Status), p+2, 0, p+2{DrivesArray[i].DriveNumber}, '');
    end;
  end;
  ResetMenu(YN);
  Result:=MenuChoice(YN, SelectKey);
  If Result>lp+2 then Result:=Result+lp;
end;

// Install MBR for FreeLDR

Procedure Install_MBR;
VAR
  Drive:        Byte;
  bootNr:       Byte;
  BootDrv:      Byte;
  FH:           Integer;
  FreeMBR:      Sector0Buf;
Begin
  Drive:=SelectDisk;    {Select drive to install MBR}
  BootDrv:=Drive+$7f;   {by default next boot drive is same as install drive}

  BootNr:=SelectPartition(LvmGetDriveHandle(Drive)); {Select partition to boot from}

  if BootNr=1 then      {user want to chanboot from another drive}
  begin
    BootDrv:=SelectDisk+$7f;    {Change next boot drive}
    BootNr:=0;                  {No meaning in case of chainboot}
  end;

  if BootNr=2 then              {User wants to boot from active partition}
  begin
    BootNr:=0;                  {Boot from active partition}
  end else begin
    BootNr:=BootNr-2;           {Fix partition number to boot from}
  end;

  ReadMBRSector(Drive, sector0);        {Read current MBR}

                                        {Read FreeMBR}
  FH := FileOpen( drive1+'\boot\sectors\mbr.bin', fmOpenRead OR fmShareDenyNone);
  If FH > 0 Then
  Begin
    FileRead( FH, FreeMBR, Sector0Len );
    FileClose( FH );
    StrMove( @FreeMBR[$1b8], @Sector0[$1b8], 72 );    {Rewrite Partition Table and NTFS sig from HD}
    FreeMBR[$1bc] := chr(BootNr);                     {Insert partition bootnumber}
    FreeMBR[$1bd] := chr(BootDrv);                    {Insert disk boot number}
    Sector0 := FreeMBR;
    WriteMBRSector(Drive, sector0);
    Writeln(#10,'Your MBR have been upgraded to FreeLDR , Press <Enter> to continue ');
    Readln;
  End
  Else
  Begin
    ShowError('OS/2 Error '+IntToStr(-FH)+' opening MBR.bin');
    Halt(1);
  End;
End;

end.
