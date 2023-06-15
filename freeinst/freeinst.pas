{

     osFree FreeLDR Installer (C) 2010 by Yoda
     Copyright (C) 2022 osFree

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

Program freeinst;

{&Linker
DESCRIPTION '@#osFree:0.0.1.16á#@##1## 11 may 2010 11:05:10ÿÿÿ  Asus SMP::en:us:1::@@  Installation app for FreeLDR'
}

// Compiler settings
{$H+,I+,P+,Q+,R+,S+,T-,V-,X+}
{$IFNDEF FPC}{$B-,W-,J+}{$ENDIF}
{&AlignCode+,AlignData+,AlignRec-,Cdecl-,Delphi+,Frame+}
{&Open32-,Optimise+,OrgName-,Speed+}
{$codePage CP437}
{$M 32768}

Uses
{$IFDEF WIN32}
              windows,
{$ENDIF}
              Common, Utl, SysLow,
{$IFDEF OS2}
              Os2def,
{$IFNDEF FPC} Os2base, {$ELSE} Doscalls, {$ENDIF}
              Impl_OS2,
{$ENDIF}
{$IFDEF WIN32}
              Impl_W32,
{$ENDIF}
{$IFDEF DPMI32}
              Impl_D32,
{$ENDIF}
{$IFDEF LINUX}
              Impl_LNX,
{$ENDIF}
              Strings, SysUtils, StrUtils, Dos,
              tpcrt, tpwindow, colordef, tpmenu, // Turbo Professional
			  msgbox,
              lvmapi, // OS/2 Logical Volume Manager
              mbr, // MBR
              FreeMBR; // FreeMBR

{$IFDEF FPC}
{$I os2types.pas}
{$ENDIF}

Var
  BlockBuf:     Hdr;
  Bbuf:         BBlockbuf;
  F32Buf:       FAT32Buf;
  HPbuf:        HPFSbuf;
  DevHandle:    Hfile;
  Drive2:       Array[0..2] of Char =(#0,#0,#0);
  Drive:        PChar;
  DriveT:       tDrivetype;     // FS type on selected drive
  PartNr:       Byte;           // Partition number
  ifsbuf:       Array[0..1000000] of Char;

{******************************************************************************************}

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
    MenuItem('Physical drive '+IntToStr(DrivesArray[i].DriveNumber)+' '+DriveStatus.Drive_Name+' '+IntToStr(Trunc(Extended(DrivesArray[i].DriveSize)*512/1024/1024))+'MB ('+IfThen(DriveStatus.Corrupt_Partition_Table, 'Corrupt',IfThen(isGPT(DrivesArray[i].DriveNumber),'GPT','MBR'))+')', p, 16, DrivesArray[i].DriveNumber, '');
    if DriveStatus.Corrupt_Partition_Table then ShowError('Physical Drive ('+IntToStr(DrivesArray[i].DriveNumber)+'):'#10#13#10#13'Partition table is corrupt');
    if DriveStatus.Unusable then ShowError('Physical Drive ('+IntToStr(DrivesArray[i].DriveNumber)+'):'#10#13#10#13'Unusable');
  end;
  ResetMenu(YN);
  Result:=MenuChoice(YN, SelectKey);
end;

// Backup MBR sector to a file
Procedure Backup_MBR_sector;
var
  F: integer;
begin
  ReadMBRSector(SelectDisk,sector0);
  F:=FileCreate('MBR.BIN');
  FileWrite(F, sector0, SizeOf(sector0));
  FileClose(F);
  ShowOK;
End;


// Rewrite start of preldr0 file acording to filesystem needs
Procedure Fix_Preldr0(DriveT:TdriveType);
Var
  FH:           Integer;
  //Count:        Word;
  ldr0:         Packed Record
                head:           Array[0..1] Of Byte;
                l1:             Word;
                l2:             Word;
                force_lba:      Byte;
                Bundle:         Byte;
                head2:          Array[0..3] Of Byte;
                head3:          Array[0..29] Of Byte;
                PartNr:         Byte;                   // NOT used anymore
                Zero1:          Byte;
                FS:             str16;
                End;
  Length :      Word;

Begin
FillChar(ldr0, sizeof(ldr0),0);
FH := FileOpen( Drive1+'\boot\loader\preldr0.mdl', fmOpenReadWrite OR fmShareDenyNone);
If FH > 0 Then
  Begin
  //Count  := Word(Fileread( FH, ldr0, 60 ));
  Fileread( FH, ldr0, 60 );
  length := Word(FileSeek( FH, 0, 2 ));
  End
 Else
  Begin
  Writeln('OS/2 Error ',-FH,' opening preldr0.mdl');
  Halt(1);
  End;

With ldr0 DO
  Begin
  //  PartNr := PartNr1;
  l1 := 0;
  l2 := Length;

  Case DriveT Of
    dtHDFat,
    dtFloppy:   Begin
                l2 := 0;
                FS := fat;
                End;
    dtHDFat32:  FS := fat;
    dtHDHPFS:   FS := hpfs;
    dtHDJFS:    FS := jfs;
    End;
  End;
FileSeek( FH, 0, 0 );
FileWrite( FH, ldr0, 60 );
FileClose( FH );
End;





// Install FreeLDR on FAT (12/16) partition + floppy
Procedure Install_Fat;
Var
  FH          : Integer;
  FreeLdr0:     Sector0Buf;
  wDevHandle:   LongInt;
Begin
Writeln('Going to install FreeLDR on ',drive1);
PartNr := 0;
wDevHandle := DevHandle;
Open_Disk(Drive,wDevHandle);            // Get drivehandle
DevHandle := wDevHandle;
Lock_Disk(devhandle);
Read_Disk(devhandle,Sector0,Sector0Len);
Unlock_Disk(devhandle);
Close_Disk(DevHandle);
FH := FileOpen( drive1+'\boot\sectors\fatboot.bin', fmOpenRead OR fmShareDenyNone);
If FH > 0 Then
  Begin
  FileRead( FH, FreeLdr0, Sector0Len );
  FileClose( FH );

  // Set OEM ID
  StrMove( FreeLdr0+3, osFree, 8 );

  //  Rewrite BPB from HD
  StrMove( FreeLdr0+11, @Sector0[11], 51 );

  Sector0 := FreeLdr0;
  End
 Else
  Begin
  Writeln('OS/2 Error ',-FH,' opening FatBoot.bin');
  Halt(1);
  End;
wDevHandle := DevHandle;
Open_Disk(Drive,wDevHandle);            // Get drivehandle
DevHandle := wDevHandle;
Lock_Disk(devhandle);
Write_Disk(devhandle,Sector0,Sector0Len);
Unlock_Disk(devhandle);
Close_Disk(DevHandle);
Fix_Preldr0(DriveT);
Writeln('Installation of osFree on partition ',drive1,' ended successfully.');
Write('Press <Enter> to continue... ');
Readln;
End;


// FAT32 install
//
Procedure Install_Fat32;
Type
  Free0 = Packed Record
        jmp:            Array[0..2] Of Byte;
        Oem_Id:         Str8;
        Bpb:            Array[0..78] Of Char;
        Boot_Code:      Array[0..410] Of Byte;
        FSD_LoadSeg:    Word;
        FSD_Entry:      Word;
        FSD_Len:        Byte;
        FSD_Addr:       Cardinal;
        Boot_End:       Word;
        End;

Var
  FreeSect0 :           Free0;
  //Fs0, BB,
  F32bb:                Pchar;
  FH:                   Integer;
  //mini_hdr:             hdr;
  Count, Count1:        Word;
  wDevHandle:           LongInt;

Begin
Writeln('Going to install FreeLDR on ',drive1);
Open_Disk(Drive,wDevHandle);            // Get drivehandle
DevHandle:= wDevHandle;
Lock_Disk(devhandle);
Read_Disk(devhandle,F32Buf,BblockLen);
Unlock_Disk(devhandle);
Close_Disk(DevHandle);
F32bb := @F32Buf;
FH := FileOpen( drive1+'\boot\sectors\bootsect_1.bin', fmOpenRead OR fmShareDenyNone);
If FH > 0 Then
  Begin
  FileRead( FH, FreeSect0, Sector0Len );
  FileClose( FH );
  With FreeSect0 Do
    Begin
    Oem_Id := Str8(osFree);
    //  Rewrite BPB from HD
    //  For FAT32:                 79 bytes
    StrMove( bpb, @F32Bb[11], 79);
    FSD_LoadSeg:=$0800;
    FSD_Entry:=0;
    FSD_Len:=(BblockLen - 1024) div 512;
    FSD_Addr:=2;
    End;
  StrMove (F32Bb, @FreeSect0, 512);
  End
 Else
  Begin
  Writeln('OS/2 Error ',-FH,' opening ',drive1,'\boot\sectors\BootSect_1.bin');
  Halt(1);
  End;
FH := FileOpen( drive1+'\boot\loader\preldr_mini.mdl', fmOpenRead OR fmShareDenyNone);
If FH > 0 Then
  Begin
  Count := Word(FileRead( FH, F32bb[1024], Sizeof( Blockbuf ) ));
  FileClose( FH );
  End
 Else
  Begin
  Writeln('OS/2 Error ',-FH,' opening preldr_mini.mdl');
  Halt(1);
  End;
FH := FileOpen( drive1+'\boot\loader\fsd\fat.mdl', fmOpenRead OR fmShareDenyNone);
If FH > 0 Then
  Begin
  Count1 := Word(FileRead( FH, F32bb[1024+count], Sizeof( Blockbuf ) - count ));
  FileClose( FH );
  End
 Else
  Begin
  Writeln('OS/2 Error ',-FH,' opening fat.mdl');
  Halt(1);
  End;

With F32Buf Do
  Begin
  FS_Len      := Count1;
  Preldr_Len  := Count;
  Bundle      := $80;
  PartitionNr := 0;             // Previous = PartNr not used anymore
  FS := fat;
  End;

Open_Disk(Drive,wDevHandle);    // Get drivehandle
DevHandle:= wDevHandle;
Lock_Disk(devhandle);
{$ifdef OS2}
      Fat32FSctrl(Devhandle);
      fat32WriteSector(DevHandle, 0, BBlockLen DIV 512, F32Buf);
{$else}
      Write_Disk(DevHandle, F32Buf, BBlockLen);
{$endif}
Unlock_Disk(devhandle);
Close_Disk(DevHandle);
Fix_Preldr0(DriveT);
Writeln('Installation of osFree Bootsectors on FAT32 partition ',drive1,' ended successfully.');
Write('Press <Enter> to continue... ');
Readln;
End;



// HPFS install
// BootBlock max 16 sectors
Procedure Install_HPFS;
Const
    osFree: Str8  = 'IBM Free' ;

Type
  Free0 = Packed Record
        jmp:            Array[0..2] Of Byte;
        Oem_Id:         Str8;
        Bpb:            Array[0..50] Of Char;
        Boot_Code:      Array[0..438] Of Byte;
        FSD_LoadSeg:    Word;
        FSD_Entry:      Word;
        FSD_Len:        Byte;
        FSD_Addr:       Cardinal;
        Boot_End:       Word;
        End;

Var
  FreeSect0 :           Free0;
  //Fs0,bb,
  F32bb:         Pchar;
  FH:                   Integer;
  //mini_hdr:             hdr;
  Count, Count1:        Word;
  wDevHandle:           LongInt;

Begin
FillChar(HPbuf,SizeOf(HPbuf),0);
PartNr := 0;
Open_Disk(Drive,wDevHandle);                   // Get drivehandle
DevHandle:= wDevHandle;
Lock_Disk(devhandle);
Read_Disk(devhandle,HPbuf,BblockLen);          // Read 8k
Unlock_Disk(devhandle);
Close_Disk(DevHandle);
F32bb := @HPbuf;
FH := FileOpen( drive1+'\boot\sectors\bootsect_1.bin', fmOpenRead OR fmShareDenyNone);
If FH > 0 Then
  Begin
  FileRead( FH, FreeSect0, Sector0Len );
  FileClose( FH );
  With FreeSect0 Do
    Begin
    Oem_Id := osFree;                           // Insert new OEM ID, 'IBM is required as first 3 letters or mounting of IFS will fail
    StrMove( bpb, @F32Bb[11], 51);              // Copy bpb from HD, 51 bytes
    FSD_LoadSeg:=$0800;                         // FSD load address
    FSD_Entry:=0;                               // FSD entry point
    FSD_Len:=(BblockLen - 512) div 512;         // Length of boot block in sectors
    FSD_Addr:=1;                                // Startsector for boot block
    End;
  StrMove (F32Bb, @FreeSect0, 512);
  End
 Else
  Begin
  Writeln('OS/2 Error ',-FH,' opening BootSect_1.bin');
  Halt(1);
  End;
FH := FileOpen( drive1+'\boot\loader\preldr_mini.mdl', fmOpenRead OR fmShareDenyNone);
If FH > 0 Then
  Begin
  Count := Word(FileRead( FH, F32bb[512], BblockLen - 512 ));
  FileClose( FH );
  End
 Else
  Begin
  Writeln('OS/2 Error ',-FH,' opening preldr_mini.mdl');
  Halt(1);
  End;
FH := FileOpen( drive1+'\boot\loader\fsd\hpfs.mdl', fmOpenRead OR fmShareDenyNone);
If FH > 0 Then
  Begin
  Count1 := Word(FileRead( FH, F32bb[512+count], BblockLen - ( count + 512 ) ));
  FileClose( FH );
  End
 Else
  Begin
  Writeln('OS/2 Error ',-FH,' opening hpfs.mdl');
  Halt(1);
  End;

With HPbuf Do
  Begin
  FS_Len      := Count1;
  Preldr_Len  := Count;
  Bundle      := $80;
  PartitionNr := PartNr;        // not used anymore
  FS := hpfs;
  End;

Open_Disk(Drive,wDevHandle);            // Get drivehandle
DevHandle:= wDevHandle;
Lock_Disk(devhandle);
Write_Disk(DevHandle,HPbuf,BBlockLen);
Unlock_Disk(devhandle);
Close_Disk(DevHandle);

Fix_Preldr0(DriveT);
Writeln('Installation of osFree bootsectors on partition ',drive1,' ended successfully.');
Write('Press <Enter> to continue... ');
Readln;
End;

// JFS version check is needed, because beta versions af JFS TRAPS
// when we write in DASD mode.
Function JFS_version_check:Boolean;
Var
  FH: Integer;
  xx,ii,l1,p1,p2: Longint;
  S1,jver: String[255];
  ifsPbuf:      Pchar;

Begin
JFS_version_check := False;
FH := FileOpen( GetBootDrive+':\os2\JFS.IFS', fmOpenRead OR fmShareDenyNone);
If FH > 0 Then
  Begin
  ifsPbuf := ifsbuf;
  XX:=FileRead( FH, ifsbuf, 1000000 );
  FileClose( FH );
  ii:= 0;
  Repeat
    S1 := StrPas(ifsPbuf+ii);
    p1 := pos('@#SSI:',S1);
    p2 := pos('@#IBM:',S1);
    If p1 > 0 Then
      Begin
      jver := copy(s1,p1+6,pos('#',copy(s1,p1+6,255))-1);
      If pos('pasha',s1) > 0 Then
        Begin
        Writeln('Version is from Pasha, it is OK ! ');
        JFS_version_check := True;
        End
        Else
          Begin
          ClrScr;
          Writeln;
          Writeln('  ***********************   W A R N I N G  ****************************');
          Writeln('  ***********                                              ************');
          Writeln('  ***********                                              ************');
          Writeln('  ***********   You have a BETA version of JFS installed   ************');
          Writeln('  ***********                                              ************');
          Writeln('  ***********                                              ************');
          Writeln('  ***********          Do NOT try to install osFree        ************');
          Writeln('  ***********                                              ************');
          Writeln('  ***********         on any of your JFS partitions,       ************');
          Writeln('  ***********                                              ************');
          Writeln('  ***********       as this will TRAP your system !!!!     ************');
          Writeln('  ***********                                              ************');
          Writeln('  ***********                                              ************');
          Writeln('  ***********                                              ************');
          Writeln('  ***********   Please ask Mensys for an updated version   ************');
          Writeln('  ***********                                              ************');
          Writeln('  ***********       of eCS JFS  or use IBM version !       ************');
          Writeln('  ***********                                              ************');
          Writeln('  ***********                                              ************');
          Writeln('  *********************************************************************');
          Writeln(#8#88);
          writeln;
          End;
      End;
    If p2 > 0 Then
      Begin
      jver := copy(s1,p2+6,pos('#',copy(s1,p2+6,255))-1);
      Writeln(s1);
      Writeln('IBM JFS version is: ',jver);
      JFS_version_check := True;
      End;
    l1 := length(s1);
    If l1 = 0 Then l1 := 1;
    ii:=II+l1;
  Until (ii >=xx) or (p2 > 0) or (p1 > 0)
  End
  Else
   Writeln('Can''t find JFS.IFS');

END;


// JFS install
// BootBlock including bootsector max 16 sectors for now, but can be extended

Procedure Install_JFS;
Const
    osFree: Str8  = '[osFree]' ;

Type
  Free0 = Packed Record
        jmp:            Array[0..2] Of Byte;
        Oem_Id:         Str8;
        Bpb:            Array[0..50] Of Char;
        Boot_Code:      Array[0..438] Of Byte;
        FSD_LoadSeg:    Word;
        FSD_Entry:      Word;
        FSD_Len:        Byte;
        FSD_Addr:       Cardinal;
        Boot_End:       Word;
        End;

Var
  FreeSect0 :           Free0;
  //Fs0,bb,
  F32bb:               Pchar;
  FH:                   Integer;
  //mini_hdr:             hdr;
  Count, Count1:        Word;
  wDevHandle:           LongInt;

Begin
//JFS_version_check;
Open_Disk(Drive,wDevHandle);                    // Get drivehandle
DevHandle:= wDevHandle;
Lock_Disk(devhandle);
Read_Disk(devhandle,HPbuf,BblockLen);           // Read boot block
Unlock_Disk(devhandle);
Close_Disk(DevHandle);
F32bb := @HPbuf;
FH := FileOpen( drive1+'\boot\sectors\bootsect_1.bin', fmOpenRead OR fmShareDenyNone);
If FH > 0 Then
  Begin
  FileRead( FH, FreeSect0, Sector0Len );
  FileClose( FH );
  With FreeSect0 Do
    Begin
    Oem_Id := osFree;                           // Insert new OEM ID, 'IBM is required as first 3 letters or mounting of IFS will fail
    StrMove( bpb, @F32Bb[11], 51);              // Copy bpb from HD, 51 bytes
    FSD_LoadSeg:=$0800;                         // FSD load address
    FSD_Entry:=0;                               // FSD entry point
    FSD_Len:=(BblockLen - 512) div 512;         // Length of boot block in sectors
    FSD_Addr:=1;                                // Startsector for boot block
    End;
  FillChar(HPbuf,SizeOf(HPbuf),255);            // Wipe HPbug again
  StrMove (F32Bb, @FreeSect0, 512);
  End
 Else
  Begin
  Writeln('OS/2 Error ',-FH,' opening BootSect_1.bin');
  Halt(1);
  End;

// Prepare BootBlock
FH := FileOpen( drive1+'\boot\loader\preldr_mini.mdl', fmOpenRead OR fmShareDenyNone);
If FH > 0 Then
  Begin
  Count := Word(FileRead( FH, F32bb[512], BblockLen - 512 ));
  FileClose( FH );
  End
 Else
  Begin
  Writeln('OS/2 Error ',-FH,' opening preldr_mini.mdl');
  Halt(1);
  End;
FH := FileOpen( drive1+'\boot\loader\fsd\jfs.mdl', fmOpenRead OR fmShareDenyNone);
If FH > 0 Then
  Begin
  Count1 := Word(FileRead( FH, F32bb[512+count], BblockLen - ( count + 512 ) ));
  FileClose( FH );
  End
 Else
  Begin
  Writeln('OS/2 Error ',-FH,' opening jfs.mdl');
  Halt(1);
  End;

With HPbuf Do
  Begin
  FS_Len      := Count1;
  Preldr_Len  := Count;
  Bundle      := $80;
  PartitionNr := 0;             // WAS PartNr;
  FS := jfs;
  End;

Open_Disk(Drive,wDevHandle);            // Get drivehandle
DevHandle:= wDevHandle;
Lock_Disk(devhandle);
Write_Disk(DevHandle,HPbuf,BBlockLen);
Unlock_Disk(devhandle);
Close_Disk(DevHandle);

Fix_Preldr0(DriveT);
Writeln('FreeLDR installed successfully on JFS volumen ',drive1,' ');
Write('Press <Enter> to continue... ');
Readln;
End;

{**** Boot Block operations ******}


Procedure Backup_BootBlock;
var
  wDevHandle:     LongInt;
Begin
  FillChar(Bbuf,SizeOf(Bbuf),0);
  Open_Disk(Drive,wDevHandle);
  DevHandle:= wDevHandle;
  Read_Disk(DevHandle,Bbuf,BblockLen);
  ShowOK;
  Close_Disk(DevHandle);
End;

Procedure Restore_BootBlock;
Var
  Filename:     String;
  FH:   Integer;
  key:  Char;
  BufSize:      Integer;
  wDevHandle:   LongInt;

Begin
Writeln(#8#8#8#8#8#8#8#8#8#8#8#8#8#8#8,'Enter name of the bootblockfile to restore ');
Write('(Default is Drive-',drive1[1],'.000: ');
Readln(filename);
If filename = '' Then Filename := 'Drive-'+drive1[1]+'.000';

FH := FileOpen( filename, fmOpenRead OR fmShareDenyNone);
Writeln('Restoring ',filename, 'to Bootblock (sector 1)');
FillChar(Bbuf,SizeOf(Bbuf),0);

If FH > 0 Then
  Begin
  FileRead( FH, BBuf, BBlockLen );
  FileClose( FH );
  BufSize := BBlockLen;
  If DriveT = dtHDFAT Then
    Begin
    Writeln('You are trying to restore a BootBlock to a FAT partition. (8k)');
    Writeln('Normally you should only restore the BootSector (512 bytes)');
    Writeln('Press S to only restore bootSector or B to restore 8k bootBlock');
    key := upcase(readkey);
    If key <> 'B' Then BufSize := 512;
    End;
  Open_Disk(Drive,wDevHandle);
  DevHandle:= wDevHandle;
  Lock_Disk(devhandle);
  If DriveT = dtHDFAT32 Then
    Begin
{$ifdef OS2}
      Fat32FSctrl(Devhandle);
      fat32WriteSector(DevHandle, 0, BBlockLen DIV 512, BBuf);
{$else}
      Write_Disk(DevHandle, BBuf, BBlockLen);
{$endif}
    End
   Else Write_Disk(devhandle,BBuf,BufSize);
  Unlock_Disk(devhandle);
  Close_Disk(DevHandle);
  End;
  ShowOK;
End;

Procedure InitDesktop;
begin
  HighVideo;
  TextBackground(White);
  TextColor(Black);
  ClrScr;
  WriteLn;
  Writeln(' ',version);
  Writeln(' '#205#205#205#205#205#205#205#205#205#205#205#205#205#205#205#205#205);
end;

Procedure SelectDrive;
Var
 Drives: DriveSet;
 Drive3: Char;
 Desc: String;
 Pstn: Byte;
type
  MakeCommands =             {codes returned by each menu selection}
  (Mnone                    {no command}
  );
var
  YN: Menu;
  SelectKey: Char;
Begin
  GetValidDrives( Drives );

  ClrScr;
  Writeln( 'This system has the following drives available for install: ' );
  Writeln;

  YN:=NewMenu([], nil);
  SubMenu(20, 7, 0, Vertical, SingleFrameChars, MenuColors, '');

  Pstn:=1;
  for Drive3 := 'A' to 'Z' do
    if Drive3 in Drives then IF GetDriveType(drive3) IN [dtFloppy,dthdfat,dthdfat32,dthdhpfs,dthdjfs,
                                                       dthdntfs, dthdext2] Then
    begin
      case GetDriveType( Drive3 ) of
        dtFloppy    : Desc := 'Floppy drive';
        dtHDFAT     : Desc := 'Hard disk (FAT format)';
        dtHDHPFS    : Desc := 'Hard disk (HPFS format)';
        dtHDJFS     : Desc := 'Hard disk (JFS format)';
        dtHDFAT32   : Desc := 'Hard disk (FAT32 format)';
        dtHDExt2    : Desc := 'Hard disk (EXT2 format)';
        dtHDNTFS    : Desc := 'Hard disk (NTFS format)';
        dtNovellNet : Desc := 'Novell Netware drive';
        dtCDRom     : Desc := 'CD-ROM drive';
        dtLAN       : Desc := 'IBM network drive';
        dtTVFS      : Desc := 'TVFS virtual drive';
        dtRAMFS     : Desc := 'RAM drive';
        dtNDFS32    : Desc := 'Netdrive virtual drive';
        dtInvalid   : Desc := 'Invalid or unknown drive type';
      end;
      MenuItem(' '+Drive3+': '+Desc, Pstn, 2, Ord(Drive3), '');
          Inc(Pstn);
    end;

  ResetMenu(YN);

  Drive1 := upcase(Chr(MenuChoice(YN, SelectKey))) + ':' ;
  Drive  := StrPCopy(Drive,drive1);
  DriveT := GetDriveType(drive1[1]);
end;


{$IFDEF WIN32}
Const
 SECURITY_NT_AUTHORITY: TSIDIdentifierAuthority = (Value: (0, 0, 0, 0, 0, 5));
 SECURITY_BUILTIN_DOMAIN_RID = $00000020;
 DOMAIN_ALIAS_RID_ADMINS     = $00000220;
 DOMAIN_ALIAS_RID_USERS      = $00000221;
 DOMAIN_ALIAS_RID_GUESTS     = $00000222;
 DOMAIN_ALIAS_RID_POWER_USERS= $00000223;

 function CheckTokenMembership(TokenHandle: THandle; SidToCheck: PSID; var IsMember: BOOL): BOOL; stdcall; external advapi32;

 function  UserInGroup(Group :DWORD) : Boolean;
 var
  pIdentifierAuthority :TSIDIdentifierAuthority;
  pSid : Windows.PSID;
  IsMember    : BOOL;
 begin
  pIdentifierAuthority := SECURITY_NT_AUTHORITY;
  Result := AllocateAndInitializeSid(pIdentifierAuthority,2, SECURITY_BUILTIN_DOMAIN_RID, Group, 0, 0, 0, 0, 0, 0, pSid);
  try
    if Result then
      if not CheckTokenMembership(0, pSid, IsMember) then //passing 0 means which the function will be use the token of the calling thread.
         Result:= False
      else
         Result:=IsMember;
  finally
     FreeSid(pSid);
  end;
 end;

procedure InitWindows;
begin
  if not UserInGroup(DOMAIN_ALIAS_RID_ADMINS) then
  begin
    WriteLn;
    WriteLn('This program must be run as Administrator');
    Halt(-1);
  end;

  // Tune FPC CRT for correct codepage usage
//  SetSafeCPSwitching(True);
//  SetUseACP(False);
//  SetTextCodePage(Output, 437);
  SetConsoleOutputCP(437);
  //CrtCodepage(437);
end;
{$ENDIF}

procedure InitTPro;
begin
  // Configure TPCRT
  FrameChars:=BoldFrameChars;
end;

procedure Install_LDR;
Begin
  Case DriveT Of
    dtFloppy    : Install_Fat;
    dtHDFAT     : Install_Fat;
    dtHDFAT32   : Install_Fat32;
    dtHDHPFS    : Install_HPFS;
    dtHDJFS     : Install_JFS;
  //           dtHDNTFS  : Install_;  No Writeble IFS exists for OS/2
  //           dtHDExt2  : Install_;  Wonder if it will work on OS/2 ???
    Else Begin
      Writeln('We do not yet support support the filesystem on your ',drive1,' partition');
      Writeln('Press <Enter> to continue');
      Readln;
    End;
  End;
End;

Procedure ManageMBR;
type
  MakeCommands =             {codes returned by each menu selection}
  (Mnone,                    {no command}
   MInstallMBR,                    {main menu root}
   MBackUpMBR,
   MRestoreMBR,
   MExit
  );
Var
  MBRMenu: Menu;
  SelectKey: Char;
  MK: MenuKey;
begin
    MBRMenu:=NewMenu([], nil);
    SubMenu(20, 7, 25, Vertical, SingleFrameChars, MenuColors, '');
    MenuItem(' 1: Install new MBR for FreeLDR', 1, 2, Ord(MInstallMBR), 'Install new Master Boot Record on selected drive');
    MenuItem(' 2: Backup MBR sector', 2, 2, Ord(MBackupMBR), 'Make back up copy of Master Boot Record from selected drive');
    MenuItem(' 3: Restore MBR sector', 3, 2, Ord(MRestoreMBR), 'Restore MBR sector from backup file');
    MenuItem(' 0: Exit', 4, 2, Ord(MExit), 'Exit FreeLDR installer');
    ResetMenu(MBRMenu);
    MK:=MenuChoice(MBRMenu, SelectKey);
    repeat
      case MK of
        Ord(MInstallMBR): Install_MBR;
        Ord(MBackUpMBR): Backup_MBR_sector;
        Ord(MRestoreMBR): Restore_MBR_Sector;
      end;
    until MK=Ord(Mexit);
end;

Procedure ManageFreeLDR;
type
  MakeCommands =             {codes returned by each menu selection}
  (Mnone,                    {no command}
   MInstallFreeLdr,
   MBackupBootBlock,
   MRestoreBootBlock,
   MChangePartition,
   MExit
  );
var
  LDRMenu: Menu;
  SelectKey: Char;
  MK: MenuKey;
begin
    ClrScr;
    Writeln;
    Writeln('                   Partition ',drive1,' is selected for install');
    Writeln;

    SelectDrive;              // Ask user which drive to install to.

    LDRMenu:=NewMenu([], nil);
    SubMenu(20, 7, 25, Vertical, SingleFrameChars, MenuColors, '');
    MenuItem(' 1: Install FreeLDR on a partition', 1, 2, Ord(MInstallFreeLdr), 'Install FreeLDR on selected partition');
    MenuItem(' 2: Backup a BootBlock', 2, 2, Ord(MBackUpBootBlock), 'Make back up copy of Master Boot Record from selected partition');
    MenuItem(' 3: Restore a BootBlock', 3, 2, Ord(MRestoreBootBlock), 'Restore a BootBlock from backup file');
    MenuItem(' 4: Change partition', 4, 2, Ord(MChangePartition), 'Change partition to install, backup or restore to');
    MenuItem(' 0: Exit', 8, 2, Ord(MExit), 'Exit FreeLDR installer');
    ResetMenu(LDRMenu);

    repeat
      MK:=MenuChoice(LDRMenu, SelectKey);
      case MK of
        Ord(MInstallFreeLdr): Install_LDR;
        Ord(MBackUpBootBlock): BackUp_BootBlock;
        Ord(MRestoreBootBlock): Restore_Bootblock;
        Ord(MChangePartition): SelectDrive;
      end;
	until MK=Ord(MExit);
end;

var
  OldExitProc: Pointer;

procedure MyExitProc;
begin
  LvmCloseEngine();      { Close all drives }
  ExitProc:=OldExitProc; { reset the old exitproc }
end;


{ ***********************************************************************************************************
  ********************************************       MAIN      **********************************************
  *********************************************************************************************************** }

type
  MMainCommands =             {codes returned by each menu selection}
  (Mnone,                    {no command}
   MManageMBR,                    {main menu root}
   MManageFreeLdr,
   MExit
  );
var
  MainMenu: Menu;
  SelectKey: Char;
  MK: MenuKey;
Begin
{$IFDEF WIN32}
  InitWindows;
{$ENDIF}
  InitTPro;

  Drive := Drive2;
{
  If ParamCount > 0 Then
    Drive1 := ParamStr(1)  // Driveletter expected as first parameter on cmd line.
  Else
    Drive1 := copy(ParamStr(0),1,2);  // Get driveletter where this app is started from.
  Drive := StrPCopy(Drive,drive1);

  DriveT := GetDriveType(drive1[1]);
}
  InitDesktop;
  ShowWarning;
  if LvmOpenEngine(False)<>0 then
  begin
    WriteLn('Cannot open LVM Engine.');
    Halt(255);
  end;

  OldExitProc   := ExitProc;
  ExitProc      := @MyExitProc;

  MainMenu:=NewMenu([], nil);
  SubMenu(20, 7, 25, Vertical, SingleFrameChars, MenuColors, 'Select operations');
  MenuItem(' 1: Manage MBR', 1, 2, Ord(MManageMBR), 'Perfom operations with Master Boot Record on selected drive');
  MenuItem(' 2: Manage FreeLDR', 2, 2, Ord(MManageMBR), 'Perfom operations with FreeLDR on selected partition');
  MenuItem(' 0: Exit', 3, 2, Ord(MExit), 'Exit FreeLDR installer');
  ResetMenu(MainMenu);

  Repeat
    MK:=MenuChoice(MainMenu, SelectKey);
    case MK of
      Ord(MManageMBR): ManageMBR;
      Ord(MManageFreeLDR): ManageFreeLDR;
    end;
  Until MK=Ord(MExit);
End.

