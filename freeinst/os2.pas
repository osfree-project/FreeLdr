// |---------------------------------------------------------|
// |                                                         |
// |     Virtual Pascal Runtime Library.  Version 2.1.       |
// |     System Interface Layer for OS/2                     |
// |     ----------------------------------------------------|
// |     Copyright (C) 1995-2003 vpascal.com                 |
// |                                                         |
// |---------------------------------------------------------|

// PmWin and PmShApi function prototypes without Os2PmApi

// If CHECK_NO_PM is defined, the executable is bigger, the
// program temporarily uses more resources, but does not hang
// if PM-functions like SysClipCanPaste are called in an
// environment without Presentation Manager

// By default, we live with this overhead:
{$DEFINE CHECK_NO_PM}

{$I os2types.pas}

function SysGetBootDrive: Char;
Var
  Res : Word;
  rc  : Longint;

begin
  rc := DosQuerySysInfo( qsv_boot_drive, qsv_boot_drive, Res, Sizeof( Res ));
  If rc = no_Error then
    SysGetBootDrive := Chr( Res + ord('A') - 1 )
  else
    SysGetBootDrive := #0;
end;

function SysGetDriveType(Drive: Char): TDriveType;
Var
  BufLen    : LongInt;
  FSQb      : PFSQBuffer2;
  DrvName   : String[3];
  Ordinal   : Word;
  aName     : pChar;
  rc        : Word;
  //DiskSize  : Word;

begin
  SysGetDriveType := dtInvalid;
  BufLen := 100;
  GetMem( FSQb, BufLen );
  DrvName := Drive+':'#0;
  Ordinal := 0;
  rc := DosQueryFSAttach( @DrvName[1], Ordinal, fsail_QueryName, {$ifdef FPC} FSqb^, {$else} FSqb, {$endif} BufLen );
  if rc = 0 then
    With FsqB^ do
    begin
    {$ifdef FPC}
      aName := @Name + NameLen + 1;
    {$else}
      aName := szName + cbName + 1;
    {$endif}
      If strComp( aName, 'FAT' ) = 0 then
        If Drive <= 'B' then
          SysGetDriveType := dtFloppy
        else
          SysGetDriveType := dtHDFAT
      else if strComp( aName, 'HPFS' ) = 0 then
        If Drive <= 'B' then
          SysGetDriveType := dtFloppy
        else
          SysGetDriveType := dtHDHPFS
      else If StrComp( aName, 'NETWARE' ) = 0 then
        SysGetDriveType := dtNovellNet
      else If StrComp( aName, 'CDFS' ) = 0 then
        SysGetDriveType := dtCDRom
      else If StrComp( aName, 'TVFS' ) = 0 then
        SysGetDriveType := dtTVFS
      else If StrComp( aName, 'ext2' ) = 0 then
        SysGetDriveType := dtHDExt2
      else If StrComp( aName, 'LAN' ) = 0 then
        SysGetDriveType := dtLAN
      else If StrComp( aName, 'JFS' ) = 0 then
        SysGetDriveType := dthdJFS
      else If StrComp( aName, 'FAT32' ) = 0 then
        SysGetDriveType := dthdFAT32
      else If StrComp( aName, 'NTFS' ) = 0 then
        SysGetDriveType := dthdNTFS
      else If StrComp( aName, 'RAMFS' ) = 0 then
        SysGetDriveType := dtRAMFS
      else If StrComp( aName, 'NDFS32' ) = 0 then
        SysGetDriveType := dtNDFS32;
    end;

  FreeMem( FSQb, 100 );
end;

function SysGetValidDrives: Longint;
var
  CurDrive, res: Longint;
begin
  DosQueryCurrentDisk(CurDrive, res);
  if res <> 0
    then SysGetValidDrives := res
    else SysGetValidDrives := 0;
end;

