{*************************************
 *  System-dependent implementation  *
 *  of low-level functions for OS/2  *
 *************************************}

unit Impl_OS2;

interface

{$I os2types.pas}

procedure Open_Disk(Drive: AnsiString; var DevHandle: Hfile);
procedure Read_Disk(devhandle: Hfile; var buf; buf_len: Ulong);
procedure Write_Disk(devhandle: Hfile; var buf; buf_len: Ulong);
procedure Close_Disk(DevHandle: Hfile);
procedure Lock_Disk(DevHandle: Hfile);
procedure Unlock_Disk(DevHandle: Hfile);


procedure Fat32FSctrl(DevHandle: Hfile);
procedure Fat32WriteSector(DevHandle: hfile; ulSector: ULONG; nSectors: USHORT; var buf);

implementation

uses
   Os2def, Common,
{$IFDEF FPC}
   Utl, SysLow, Doscalls,
{$ELSE}
   VpUtils, VpSysLow, Os2base,
{$ENDIF}
   Strings, SysUtils, Crt, Dos;

Procedure Read_Disk(devhandle: Hfile; VAR buf; buf_len: Ulong);
Var
  ulBytesRead   : ULONG;          // Number of bytes read by DosRead
  rc            : APIRET;         // Return code
  s3            : STRING[3];
  FH            : Integer;        // File handle for backup file

Begin
rc := DosRead (DevHandle,               // File Handle
               buf,                     // String to be read
               buf_len,                 // Length of string to be read
               ulBytesRead);            // Bytes actually read
If (rc <> NO_ERROR) Then
  Begin
  Writeln('DosRead error: return code = ', rc);
  Halt(1);
  End;

// Write backup file of data read
i := 0;
Repeat
  Str(i:3,s3);
  If pos(' ',s3) = 1 Then s3[1] := '0';
  If pos(' ',s3) = 2 Then s3[2] := '0';
  i:=succ(i);
  If I > 999 Then exit;
Until NOT FileExists ('Drive-'+drive1[1]+'.'+s3);
Writeln('Backup bootsector file created:  Drive-',drive1[1],'.',s3);
FH := FileCreate( 'Drive-'+drive1[1]+'.'+s3);
FileWrite( FH, buf, ulBytesRead );
FileClose( FH );
End;


Procedure Write_Disk(devhandle: Hfile; VAR buf; buf_len: Ulong);
Var
  ulWrote       : ULONG;        // Number of bytes written by DosWrite
  //ulLocal       : ULONG;        // File pointer position after DosSetFilePtr
  rc            : APIRET;       // Return code

Begin
rc := DosWrite (DevHandle,      // File handle
                buf,            // String to be written
                buf_len,        // Size of string to be written
                ulWrote);       // Bytes actually written
If (rc <> NO_ERROR) Then
  Begin
  Writeln('DosWrite error: return code = ', rc);
  Halt(1);
  End;
Writeln(ulWrote,' Bytes written to disk');
End;


// Fat32FSctl is needed to work around bugs in FAT32.IFS still not fixed in driver  v0.99.13
Procedure Fat32FSctrl(DevHandle: Hfile);

Const
  ulDeadFace: ULONG  = $DEADFACE;
  FAT32_SECTORIO =     $9014;

Var
  ulDataLen   : ULong;                        // Input and output data size
  rc          : ApiRet;                       // Return code
  ulParamSize : Ulong;


Begin
ulDataLen := 0;
ulParamSize := sizeof( ulDeadFace );

rc := DosFSCtl( nil , 0, ulDataLen,
               @ulDeadFace, ulParamSize, ulParamSize,
               FAT32_SECTORIO,
               nil,
               devhandle,
               FSCTL_HANDLE );

if rc <> No_Error then
  begin
  Writeln('DosFSCtl error: return code = ', rc);
  Halt(1);
  end;
End;

Procedure fat32WriteSector( DevHandle: hfile; ulSector: ULONG; nSectors: USHORT; VAR buf );

Const
 IOCTL_FAT32       =  IOCTL_GENERAL;
 FAT32_READSECTOR  =  $FD ;
 FAT32_WRITESECTOR =  $FF;

Var
  wsd: Packed Record
       ulSector:  ULONG;
       nSectors:  USHORT;
       End;

  ulParamSize:  ULONG ;
  ulDataSize:   ULONG ;
  rc:           ULONG ;

Begin
wsd.ulSector := ulSector;
wsd.nSectors := nSectors;

ulParamSize := sizeof( wsd );
ulDataSize := wsd.nSectors * 512;

{$IFDEF FPC}
rc := DosDevIOCtl( DevHandle, IOCTL_FAT32, FAT32_WRITESECTOR,
                  wsd, ulParamSize, ulParamSize,
                  buf, ulDataSize, ulDataSize );
{$ELSE}
rc := DosDevIOCtl( DevHandle, IOCTL_FAT32, FAT32_WRITESECTOR,
                  @wsd, ulParamSize, @ulParamSize,
                  @buf, ulDataSize, @ulDataSize );
{$ENDIF}

If rc <> No_Error Then
  Begin
  Writeln('DosDevIOCtl() : FAT32_WRITESECTOR failed, return code = ', rc);
  Halt(1);
  End;

End;

Procedure Open_Disk(Drive: AnsiString; var DevHandle: Hfile);

Var
  rc          : ApiRet; // Return code
  Action      : ULong;  // Open action
  hdl         : LongInt;

Begin
// Opens the device to get a handle
//cbfile := 0;
//  DosOpen can be changed to DosOpenL if VP has been updated to support it
rc := DosOpen(
  Drive,                            // File path name
  Hdl,
  Action,                           // Action taken
  0,                                // File primary allocation
  file_Normal,                      // File attribute
  open_Action_Open_if_Exists,       // Open function type
//  open_Flags_NoInherit Or
  open_Share_DenyNone  Or
  open_Access_ReadWrite Or
  OPEN_FLAGS_DASD ,                 // Open mode of the file
  nil);                             // No extended attribute

DevHandle := Word(hdl);

If rc <> No_Error Then
  Begin
  Writeln('DosOpen error on drive ',drive,'  Errorcode = ',rc);
  Halt(1);
  End;
End;

Procedure Close_Disk(DevHandle: Hfile);

Var
  rc          : ApiRet; // Return code
  //Action      : ULong;  // Open action

Begin
rc := DosClose(DevHandle);
If rc <> No_Error Then
  Begin
  Writeln('DosClose ERROR. RC = ',rc);
  End;
End;


Procedure Lock_Disk(DevHandle: Hfile);

Var
  rc          : ApiRet;   // Return code
  //Action      : ULong;    // Open action
  //ParmRec     : packed record    // Input parameter record
  //  Command : ULong;      // specific to the call we make
  //  Addr0   : ULong;
  //  Bytes   : UShort;
  //  end;
  //ParmLen     : ULong;    // Parameter length in bytes
  //DataLen     : ULong;    // Data length in bytes
  lockbyte    : ULong;      //command and data parameter

Begin
// First open the device to get a handle

{$IFDEF FPC}
rc := DosDevIOCtl(
  DevHandle,                  // Handle to device
  ioctl_Disk,                 // Category of request
  dsk_LockDrive,              // Function being requested
  LockByte,                   // Input/Output parameter list
  1,                          // Maximum output parameter size
  LockByte,                   // Input:  size of parameter list
                              // Output: size of parameters returned
  LockByte,                   // Input/Output data area
  1,                          // Maximum output data size
  LockByte);                  // Input:  size of input data area
                              // Output: size of data returned
{$ELSE}
rc := DosDevIOCtl(
  DevHandle,                  // Handle to device
  ioctl_Disk,                 // Category of request
  dsk_LockDrive,              // Function being requested
  @LockByte,                  // Input/Output parameter list
  1,                          // Maximum output parameter size
  @LockByte,                  // Input:  size of parameter list
                              // Output: size of parameters returned
  @LockByte,                  // Input/Output data area
  1,                          // Maximum output data size
  @LockByte);                 // Input:  size of input data area
                              // Output: size of data returned
{$ENDIF}

If rc <> No_Error Then
  Begin
  Writeln('Drive lock error: return code = ', rc);
  // Halt(1);
  End
else
  Begin
  // Writeln('Drive is now locked !!!');
  End;
End;


Procedure Unlock_Disk(DevHandle: Hfile);

Var
  rc          : ApiRet; // Return code
  //Action      : ULong;  // Open action
  //ParmRec     : packed record  // Input parameter record
  //  Command : ULong;    // specific to the call we make
  //  Addr0   : ULong;
  //  Bytes   : UShort;
  //end;
  //ParmLen     : ULong;  // Parameter length in bytes
  //DataLen     : ULong;  // Data length in bytes
  lockbyte    : LongInt;   //command and data parameter

Begin

{$IFDEF FPC}
rc := DosDevIOCtl(
  DevHandle,                   // Handle to device
  ioctl_Disk,                  // Category of request
  dsk_UnlockDrive,             // Function being requested
  LockByte,                    // Input/Output parameter list
  1,                           // Maximum output parameter size
  LockByte,                    // Input:  size of parameter list
                               // Output: size of parameters returned
  LockByte,                    // Input/Output data area
  1,                           // Maximum output data size
  LockByte);                   // Input:  size of input data area
                               // Output: size of data returned
{$ELSE}
rc := DosDevIOCtl(
  DevHandle,                   // Handle to device
  ioctl_Disk,                  // Category of request
  dsk_UnlockDrive,             // Function being requested
  @LockByte,                   // Input/Output parameter list
  1,                           // Maximum output parameter size
  @LockByte,                   // Input:  size of parameter list
                               // Output: size of parameters returned
  @LockByte,                   // Input/Output data area
  1,                           // Maximum output data size
  @LockByte);                  // Input:  size of input data area
{$ENDIF}

If rc <> No_Error Then
  Begin
  Writeln('DosDevIOCtl (UNLOCK) error: return code = ', rc);
  //  Halt(1);
  End
Else
  Begin
  //  Writeln('Drive UNLOCKed successfully ');
  End;

End;

end.
