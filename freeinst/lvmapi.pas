{

     LVM support

     Copyright (C) 2022-2023 osFree

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

unit LVMApi;

{This is LVM support/emulation library. Under OS/2 it uses real LVM.DLL, but
under Win32/Linux/DOS it emulates required functions.}

interface

{$PACKRECORDS 1}

uses
{$ifdef Windows}
  Windows,
{$endif}
{$ifdef OS2}
  LVM,
{$endif}
  StrUtils, SysUtils;

var
  Terminology: Byte;

const
  BYTES_PER_SECTOR=512;

const
  LVM_ENGINE_NO_ERROR                          = 0;
  LVM_ENGINE_OUT_OF_MEMORY                     = 1;
  LVM_ENGINE_IO_ERROR                          = 2;
  LVM_ENGINE_BAD_HANDLE                        = 3;
  LVM_ENGINE_INTERNAL_ERROR                    = 4;
  LVM_ENGINE_ALREADY_OPEN                      = 5;
  LVM_ENGINE_NOT_OPEN                          = 6;
  LVM_ENGINE_NAME_TOO_BIG                      = 7;
  LVM_ENGINE_OPERATION_NOT_ALLOWED             = 8;
  LVM_ENGINE_DRIVE_OPEN_FAILURE                = 9;
  LVM_ENGINE_BAD_PARTITION                     =10;
  LVM_ENGINE_CAN_NOT_MAKE_PRIMARY_PARTITION    =11;
  LVM_ENGINE_TOO_MANY_PRIMARY_PARTITIONS       =12;
  LVM_ENGINE_CAN_NOT_MAKE_LOGICAL_DRIVE        =13;
  LVM_ENGINE_REQUESTED_SIZE_TOO_BIG            =14;
  LVM_ENGINE_1024_CYLINDER_LIMIT               =15;
  LVM_ENGINE_PARTITION_ALIGNMENT_ERROR         =16;
  LVM_ENGINE_REQUESTED_SIZE_TOO_SMALL          =17;
  LVM_ENGINE_NOT_ENOUGH_FREE_SPACE             =18;
  LVM_ENGINE_BAD_ALLOCATION_ALGORITHM          =19;
  LVM_ENGINE_DUPLICATE_NAME                    =20;
  LVM_ENGINE_BAD_NAME                          =21;
  LVM_ENGINE_BAD_DRIVE_LETTER_PREFERENCE       =22;
  LVM_ENGINE_NO_DRIVES_FOUND                   =23;
  LVM_ENGINE_WRONG_VOLUME_TYPE                 =24;
  LVM_ENGINE_VOLUME_TOO_SMALL                  =25;
  LVM_ENGINE_BOOT_MANAGER_ALREADY_INSTALLED    =26;
  LVM_ENGINE_BOOT_MANAGER_NOT_FOUND            =27;
  LVM_ENGINE_INVALID_PARAMETER                 =28;
  LVM_ENGINE_BAD_FEATURE_SET                   =29;
  LVM_ENGINE_TOO_MANY_PARTITIONS_SPECIFIED     =30;
  LVM_ENGINE_LVM_PARTITIONS_NOT_BOOTABLE       =31;
  LVM_ENGINE_PARTITION_ALREADY_IN_USE          =32;
  LVM_ENGINE_SELECTED_PARTITION_NOT_BOOTABLE   =33;
  LVM_ENGINE_VOLUME_NOT_FOUND                  =34;
  LVM_ENGINE_DRIVE_NOT_FOUND                   =35;
  LVM_ENGINE_PARTITION_NOT_FOUND               =36;
  LVM_ENGINE_TOO_MANY_FEATURES_ACTIVE          =37;
  LVM_ENGINE_PARTITION_TOO_SMALL               =38;
  LVM_ENGINE_MAX_PARTITIONS_ALREADY_IN_USE     =39;
  LVM_ENGINE_IO_REQUEST_OUT_OF_RANGE           =40;
  LVM_ENGINE_SPECIFIED_PARTITION_NOT_STARTABLE =41;
  LVM_ENGINE_SELECTED_VOLUME_NOT_STARTABLE     =42;
  LVM_ENGINE_EXTENDFS_FAILED                   =43;
  LVM_ENGINE_REBOOT_REQUIRED                   =44;
  LVM_ENGINE_CAN_NOT_OPEN_LOG_FILE             =45;
  LVM_ENGINE_CAN_NOT_WRITE_TO_LOG_FILE         =46;
  LVM_ENGINE_REDISCOVER_FAILED                 =47;

const
  PARTITION_NAME_SIZE = 20;
  VOLUME_NAME_SIZE = 20;
  DISK_NAME_SIZE = 20;
  FILESYSTEM_NAME_SIZE = 20;

Type
  DoubleWord=Cardinal;

type
  LBA=LongWord;
  Cardinal32=Cardinal;
  ADDRESS=Pointer;

  TDriveControl=packed record
    DriveNumber: CARDINAL32;                   (* OS/2 Drive Number for this drive. *)
    DriveSize: CARDINAL32;                     (* The total number of sectors on the drive. *)
    DriveSerialNumber: DWord;                  (* The serial number assigned to this drive.  For info. purposes only. *)
    DriveHandle: ADDRESS;                      (* Handle used for operations on the disk that this record corresponds to. *)
    CylinderCount: CARDINAL32;                 (* The number of cylinders on the drive. *)
    HeadsPerCylinder: CARDINAL32;              (* The number of heads per cylinder for this drive. *)
    SectorsPerTrack: CARDINAL32;               (* The number of sectors per track for this drive. *)
    DriveIsPRM: BOOLEAN;                       (* Set to TRUE if this drive is a PRM. *)
    Reserved: array[0..2] of byte;             (* Alignment. *)
  end;

  TDrivesArray=Array of TDriveControl;

  TDriveInformation=record
    Total_Available_Sectors: CARDINAL32;        // The number of sectors on the disk which are not currently assigned to a partition.
    Largest_Free_Block_Of_Sectors: CARDINAL32;  // The number of sectors in the largest contiguous block of available sectors.
    Corrupt_Partition_Table: BOOLEAN;           // If TRUE, then the partitioning information found on the drive is incorrect!
    Unusable: BOOLEAN;                          // If TRUE, the drive's MBR is not accessible and the drive can not be partitioned.
    IO_Error: BOOLEAN;                          // If TRUE, then the last I/O operation on this drive failed!
    Is_Big_Floppy: BOOLEAN;                     // If TRUE, then the drive is a PRM formatted as a big floppy (i.e. the old style removable media support).
    Drive_Name: Array[0..DISK_NAME_SIZE-1] of Char; // User assigned name for this disk drive.
  end;

  TPartitionInformation=record
    Partition_Handle: ADDRESS;                      // The handle used to perform operations on this partition.
    Volume_Handle: ADDRESS;                         // If this partition is part of a volume, this will be the handle of
                                                    //the volume.  If this partition is NOT part of a volume, then this
                                                    //handle will be 0.
    Drive_Handle: ADDRESS;                          // The handle for the drive this partition resides on.
    Partition_Serial_Number: DoubleWord;            // The serial number assigned to this partition.
    Partition_Start: CARDINAL32;                    // The LBA of the first sector of the partition.
    True_Partition_Size: CARDINAL32;                // The total number of sectors comprising the partition.
    Usable_Partition_Size: CARDINAL32;              // The size of the partition as reported to the IFSM.  This is the
                                                    //size of the partition less any LVM overhead.
    Boot_Limit: CARDINAL32;                         // The maximum number of sectors from this block of free space that can be used to
                                                    //create a bootable partition if you allocate from the beginning of the block of
                                                    //free space.
    Spanned_Volume: BOOLEAN;                        // TRUE if this partition is part of a multi-partition volume.
    Primary_Partition: BOOLEAN;                     // True or False.  Any non-zero value here indicates that
                                                    //this partition is a primary partition.  Zero here indicates
                                                    //that this partition is a "logical drive" - i.e. it resides
                                                    //inside of an extended partition.
    Active_Flag: BYTE;                              // 80 = Partition is marked as being active.
                                                    // 0 = Partition is not active.
    OS_Flag: BYTE;                                  // This field is from the partition table.  It is known as the
                                                    //OS flag, the Partition Type Field, Filesystem Type, and
                                                    //various other names.

                                                    //Values of interest

                                                    //If this field is: (values are in hex)

                                                    //07 = The partition is a compatibility partition formatted for use
                                                    //with an installable filesystem, such as HPFS or JFS.
                                                    //00 = Unformatted partition
                                                    //01 = FAT12 filesystem is in use on this partition.
                                                    //04 = FAT16 filesystem is in use on this partition.
                                                    //0A = OS/2 Boot Manager Partition
                                                    //35 = LVM partition
                                                    //84 = OS/2 FAT16 partition which has been relabeled by Boot Manager to "Hide" it.
    Partition_Type: BYTE;                           // 0 = Free Space
                                                    //1 = LVM Partition (Part of an LVM Volume.)
                                                    //2 = Compatibility Partition
                                                    //All other values are reserved for future use.
    Partition_Status: BYTE;                         // 0 = Free Space
                                                    //1 = In Use - i.e. already assigned to a volume.
                                                    //2 = Available - i.e. not currently assigned to a volume.
    On_Boot_Manager_Menu: BOOLEAN;                  // Set to TRUE if this partition is not part of a Volume yet is on the Boot Manager Menu.
    Reserved: BYTE;                                 // Alignment.
    Volume_Drive_Letter: char;                      // The drive letter assigned to the volume that this partition is a part of.
    Drive_Name: Array[0..DISK_NAME_SIZE-1] of char;   // User assigned name for this disk drive.
    File_System_Name: Array[0..FILESYSTEM_NAME_SIZE-1] of char;// The name of the filesystem in use on this partition, if it is known.
    Partition_Name: Array[0..PARTITION_NAME_SIZE-1] of char;   // The user assigned name for this partition.
    Volume_Name: Array[0..VOLUME_NAME_SIZE-1] of char;         // If this partition is part of a volume, then this will be the
                                                             //name of the volume that this partition is a part of.  If this
                                                             //record represents free space, then the Volume_Name will be
                                                             //"FREE SPACE xx", where xx is a unique numeric ID generated by
                                                             //LVM.DLL.  Otherwise it will be an empty string.
  end;

  TPartitionsArray=Array of TPartitionInformation;

function LvmOpenEngine(Ignore_CHS: Boolean): CARDINAL32;
procedure LvmCloseEngine();
function LvmCommitChanges(): CARDINAL32;
function LvmGetDriveControlData: TDrivesArray;
function LvmGetPartitions(Hndl: ADDRESS): TPartitionsArray;
function LvmFreeEngineMemory(LVMObject: ADDRESS): CARDINAL32;
function LvmReadSectors(Drive_Number: CARDINAL32; Starting_Sector: LBA; Sectors_To_Read: CARDINAL32; var Buffer): CARDINAL32;
function LvmWriteSectors(Drive_Number: CARDINAL32; Starting_Sector: LBA; Sectors_To_Write: CARDINAL32; var Buffer): CARDINAL32;
function LvmGetDriveHandle(Drive_Number: CARDINAL32): ADDRESS;
function LvmGetDriveStatus(Drive_Handle: ADDRESS): TDriveInformation;
function LvmGetPartitionType(PartitionType: BYTE): String;
function LvmGetPartitionStatus(PartitionStatus: BYTE): String;
procedure LvmSetTerms(Term: Byte);


implementation

var
  DrivesArray: TDrivesArray;

{$ifdef Windows}
const
  IOCTL_STORAGE_QUERY_PROPERTY = $2D1400;
  IOCTL_DISK_GET_PARTITION_INFO_EX   = $0070048;
  IOCTL_DISK_GET_DRIVE_LAYOUT = $0007400c;
  
type
STORAGE_PROPERTY_QUERY = packed record
  PropertyId: DWORD;
  QueryType: DWORD;
  AdditionalParameters: array[0..3] of Byte;
end;

STORAGE_DEVICE_DESCRIPTOR = packed record
  Version: ULONG;
  Size: ULONG;
  DeviceType: Byte;
  DeviceTypeModifier: Byte;
  RemovableMedia: Boolean;
  CommandQueueing: Boolean;
  VendorIdOffset: ULONG;
  ProductIdOffset: ULONG;
  ProductRevisionOffset: ULONG;
  SerialNumberOffset: ULONG;
  STORAGE_BUS_TYPE: DWORD;
  RawPropertiesLength: ULONG;
  RawDeviceProperties: array[0..511] of Byte;
end;

type DISK_GEOMETRY=record
    Cylinders: Int64;
    MediaType: Integer;
    TracksPerCylinder: DWORD;
    SectorsPerTrack: DWORD;
    BytesPerSector: DWORD;
  end;

type DISK_GEOMETRY_EX=record
    Geometry: DISK_GEOMETRY;
    DiskSize: int64;
    Data: Array[0..0] of BYTE;
  end;
  PDISK_GEOMETRY_EX=^DISK_GEOMETRY_EX;

const
  IOCTL_DISK_GET_DRIVE_GEOMETRY_EX = $00700A0;
{$endif}

function LvmOpenEngine(Ignore_CHS: Boolean): CARDINAL32;
{$ifdef Windows}
type
  PCharArray = ^TCharArray;
  TCharArray = array[0..32767] of Char;
var
  hdl: HANDLE;
  s: AnsiString;
  Drive: Integer;
  buffer: DISK_GEOMETRY_EX;

  /////////
  Returned: Cardinal;
  Status: LongBool;
  PropQuery: STORAGE_PROPERTY_QUERY;
  DeviceDescriptor: STORAGE_DEVICE_DESCRIPTOR;
  PCh: PChar;
{$endif}
{$ifdef OS2}
var
  Res: CARDINAL32;
{$endif}
begin
{$ifdef OS2}
  Open_LVM_Engine(Ignore_CHS, @Res);
  Result:=Res;
{$endif}
{$ifdef Windows}
  for Drive:=0 to 15 do
  begin
    // create a handle to the device
    s := '\\.\PhysicalDrive' + IntToStr(Drive);
    hdl:=CreateFileA(PChar(s),
         GENERIC_READ or GENERIC_WRITE,
         FILE_SHARE_READ or FILE_SHARE_WRITE,
         nil,
         OPEN_EXISTING,
         0,
         0);
  
  
    if hdl <> INVALID_HANDLE_VALUE then
    begin
      SetLength(DrivesArray, Length(DrivesArray)+1);
      with DrivesArray[Length(DrivesArray)-1] do
      begin
        DriveHandle:=ADDRESS(hdl);
        DriveNumber:=Drive+1;

        ZeroMemory(@PropQuery, SizeOf(PropQuery));
        ZeroMemory(@DeviceDescriptor, SizeOf(DeviceDescriptor));

        DeviceDescriptor.Size := SizeOf(DeviceDescriptor);

        Status := DeviceIoControl(
                                hdl,
                                IOCTL_STORAGE_QUERY_PROPERTY,
                                @PropQuery,
                                SizeOf(PropQuery),
                                @DeviceDescriptor,
                                DeviceDescriptor.Size,
                                Returned,
                                nil
                        );

        if not Status then RaiseLastOSError;

        if DeviceDescriptor.SerialNumberOffset <> 0 then
        begin
          PCh := @PCharArray(@DeviceDescriptor)^[DeviceDescriptor.SerialNumberOffset];
          DriveSerialNumber:=HexToBin(PCh, PChar(@Result), SizeOf(Cardinal));
        end;
        DriveIsPRM:=DeviceDescriptor.RemovableMedia;

        Status := DeviceIoControl(hdl,
                                        IOCTL_DISK_GET_DRIVE_GEOMETRY_EX,
                                        nil,
                                        0,
                                        @buffer,
                                        sizeof(buffer),
                                        returned,
                                        nil);

        if not Status then RaiseLastOSError;

        //DriveSize:=buffer.disksize/buffer.geometry.BytesPerSector;
        SectorsPerTrack:=buffer.geometry.SectorsPerTrack;
        CylinderCount:=buffer.geometry.cylinders;
        HeadsPerCylinder:=buffer.geometry.TracksPerCylinder;
  
      end;
    end;
  end;
{$endif}
  result:=LVM_ENGINE_NO_ERROR;
end;

procedure LvmCloseEngine();
{$ifdef windows}
var
        i: integer;
{$endif}
begin
{$ifdef OS2}
  Close_LVM_Engine;
{$endif}
{$ifdef windows}
  for i:=Low(DrivesArray) to High(DrivesArray) do
  begin
    CloseHandle(HANDLE(DrivesArray[i].DriveHandle));
  end;
{$endif}
end;

function LvmCommitChanges(): CARDINAL32;
{$ifdef OS2}
var
  Res: CARDINAL32;
{$endif}
begin
{$ifdef OS2}
  Commit_Changes(@Res);
  Result:=Res;
{$endif}
{$ifdef Windows}
  result:=LVM_ENGINE_NO_ERROR;
{$endif}
end;

function LvmGetDriveControlData: TDrivesArray;
{$ifdef OS2}
var
  Res: CARDINAL32;
  DCA: Drive_Control_Array;
  i: integer;
{$endif}
begin
{$ifdef OS2}
  DCA:=Get_Drive_Control_Data(@Res);
  SetLength(DrivesArray, DCA.Count);
  For i:=Low(DrivesArray) to High(DrivesArray) do
  begin
    DrivesArray[i]:=TDriveControl(DCA.Drive_Control_Data[i]);
  end;
{$endif}
  result:=DrivesArray;
end;

var
  PartitionsArray: TPartitionsArray;

function LvmGetPartitions(Hndl: ADDRESS): TPartitionsArray;
{$ifdef OS2}
var
  Res: CARDINAL32;
  PIA: Partition_Information_Array;
  i: integer;
{$endif}
{$ifdef WINDOWS}
type
   MyDRIVE_LAYOUT_INFORMATION = record
          PartitionCount : DWORD;
          Signature : DWORD;
          PartitionEntry : array[0..15] of PARTITION_INFORMATION;
       end;

var
  buffer: MyDRIVE_LAYOUT_INFORMATION;
  Returned: Cardinal;
  Status: LongBool;
  i:integer;
{$endif}
begin
{$ifdef OS2}
  PIA:=Get_Partitions(Hndl, @Res);
  SetLength(PartitionsArray, PIA.Count);
  For i:=Low(PartitionsArray) to High(PartitionsArray) do
  begin
    PartitionsArray[i]:=TPartitionInformation(PIA.Partition_Array[i]);
  end;
  Result:=PartitionsArray;
{$endif}
{$ifdef WINDOWS}
    Status := DeviceIoControl(HANDLE(Hndl),
                                    IOCTL_DISK_GET_DRIVE_LAYOUT,
                                    nil,
                                    0,
                                    @buffer,
                                    sizeof(buffer),
                                    returned,
                                    nil);

    if not Status then RaiseLastOSError;
	
	SetLength(PartitionsArray, buffer.PartitionCount);
{$if 0}
    Partition_Handle: ADDRESS;                      // The handle used to perform operations on this partition.
    Volume_Handle: ADDRESS;                         // If this partition is part of a volume, this will be the handle of
                                                    //the volume.  If this partition is NOT part of a volume, then this
                                                    //handle will be 0.
    Drive_Handle: ADDRESS;                          // The handle for the drive this partition resides on.
    Partition_Serial_Number: DoubleWord;            // The serial number assigned to this partition.
    Partition_Start: CARDINAL32;                    // The LBA of the first sector of the partition.
    True_Partition_Size: CARDINAL32;                // The total number of sectors comprising the partition.
    Usable_Partition_Size: CARDINAL32;              // The size of the partition as reported to the IFSM.  This is the
                                                    //size of the partition less any LVM overhead.
    Boot_Limit: CARDINAL32;                         // The maximum number of sectors from this block of free space that can be used to
                                                    //create a bootable partition if you allocate from the beginning of the block of
                                                    //free space.
    Spanned_Volume: BOOLEAN;                        // TRUE if this partition is part of a multi-partition volume.
    Primary_Partition: BOOLEAN;                     // True or False.  Any non-zero value here indicates that
                                                    //this partition is a primary partition.  Zero here indicates
                                                    //that this partition is a "logical drive" - i.e. it resides
                                                    //inside of an extended partition.
    Active_Flag: BYTE;                              // 80 = Partition is marked as being active.
                                                    // 0 = Partition is not active.
    OS_Flag: BYTE;                                  // This field is from the partition table.  It is known as the
                                                    //OS flag, the Partition Type Field, Filesystem Type, and
                                                    //various other names.

                                                    //Values of interest

                                                    //If this field is: (values are in hex)

                                                    //07 = The partition is a compatibility partition formatted for use
                                                    //with an installable filesystem, such as HPFS or JFS.
                                                    //00 = Unformatted partition
                                                    //01 = FAT12 filesystem is in use on this partition.
                                                    //04 = FAT16 filesystem is in use on this partition.
                                                    //0A = OS/2 Boot Manager Partition
                                                    //35 = LVM partition
                                                    //84 = OS/2 FAT16 partition which has been relabeled by Boot Manager to "Hide" it.
    Partition_Type: BYTE;                           // 0 = Free Space
                                                    //1 = LVM Partition (Part of an LVM Volume.)
                                                    //2 = Compatibility Partition
                                                    //All other values are reserved for future use.
    Partition_Status: BYTE;                         // 0 = Free Space
                                                    //1 = In Use - i.e. already assigned to a volume.
                                                    //2 = Available - i.e. not currently assigned to a volume.
    On_Boot_Manager_Menu: BOOLEAN;                  // Set to TRUE if this partition is not part of a Volume yet is on the Boot Manager Menu.
    Reserved: BYTE;                                 // Alignment.
    Volume_Drive_Letter: char;                      // The drive letter assigned to the volume that this partition is a part of.
    Drive_Name: Array[0..DISK_NAME_SIZE-1] of char;   // User assigned name for this disk drive.
    File_System_Name: Array[0..FILESYSTEM_NAME_SIZE-1] of char;// The name of the filesystem in use on this partition, if it is known.
    Partition_Name: Array[0..PARTITION_NAME_SIZE-1] of char;   // The user assigned name for this partition.
    Volume_Name: Array[0..VOLUME_NAME_SIZE-1] of char;         // If this partition is part of a volume, then this will be the
                                                             //name of the volume that this partition is a part of.  If this
                                                             //record represents free space, then the Volume_Name will be
                                                             //"FREE SPACE xx", where xx is a unique numeric ID generated by
                                                             //LVM.DLL.  Otherwise it will be an empty string.
{$endif}

  For i:=Low(PartitionsArray) to High(PartitionsArray) do
  begin
    with PartitionsArray[i] do
	begin
	  OS_Flag:=buffer.PartitionEntry[i].PartitionType;
      if OS_Flag=0 then 
	  begin
	    Partition_Type:=0;
	    Partition_Status:=0;
	  end else begin
        Partition_Type:=2;
        Partition_Status:=1;
      end;
	  Partition_Start:=buffer.PartitionEntry[i].StartingOffset.LowPart;
	  Active_Flag:=byte(buffer.PartitionEntry[i].BootIndicator)*$80;
	  True_Partition_Size:=Trunc(buffer.PartitionEntry[i].PartitionLength.QuadPart/512);
	  Boot_Limit:=buffer.PartitionEntry[i].HiddenSectors;
//	  PartitionNumber: DWORD;
          //RecognizedPartition : BYTEBOOL;
          //RewritePartition    : BYTEBOOL;

	end;
  end;
  Result:=PartitionsArray;
{$endif}
end;

function LvmFreeEngineMemory(LVMObject: ADDRESS): CARDINAL32;
begin
{$ifdef OS2}
  Free_Engine_Memory(LVMObject);
  result:=LVM_ENGINE_NO_ERROR;
{$endif}
{$ifdef Windows}
  result:=LVM_ENGINE_NO_ERROR;
{$endif}
end;

function LvmReadSectors(Drive_Number: CARDINAL32; Starting_Sector: LBA; Sectors_To_Read: CARDINAL32; var Buffer): CARDINAL32;
{$ifdef windows}
var
  DataLen: LongWord;
  Hndl: HANDLE;
{$endif}
{$ifdef OS2}
var
  Res: CARDINAL32;
{$endif}
begin
{$ifdef OS2}
  Read_Sectors(Drive_Number, Starting_Sector, Sectors_To_Read, @Buffer, @Res);
  Result:=Res;
{$endif}

{$ifdef windows}
  Hndl:=HANDLE(LvmGetDriveHandle(Drive_Number));
  SetFilePointer(Hndl, Starting_Sector*512, nil, FILE_BEGIN);
  if ReadFile(Hndl, Buffer, Sectors_To_Read*512, DataLen, nil)=false then writeln('error');
  result:=LVM_ENGINE_NO_ERROR;
{$endif}
end;

function LvmWriteSectors(Drive_Number: CARDINAL32; Starting_Sector: LBA; Sectors_To_Write: CARDINAL32; var Buffer): CARDINAL32;
{$ifdef windows}
var
  Hndl: HANDLE;
  DataLen: LongWord;
{$endif}
{$ifdef OS2}
var
  Res: CARDINAL32;
{$endif}
begin
{$ifdef OS2}
  Write_Sectors(Drive_Number, Starting_Sector, Sectors_To_Write, @Buffer, @Res);
  Result:=Res;
{$endif}

{$ifdef windows}
  Hndl:=HANDLE(LvmGetDriveHandle(Drive_Number));
  SetFilePointer(Hndl, Starting_Sector*512, nil, FILE_BEGIN);
  WriteFile(Hndl, Buffer, Sectors_To_Write*512, DataLen, nil);
  result:=LVM_ENGINE_NO_ERROR;
{$endif}
end;

function LvmGetDriveHandle(Drive_Number: CARDINAL32): ADDRESS;
var
  i: integer;
begin
  Result:=nil;
  for i:=Low(DrivesArray) to High(DrivesArray) do
  begin
    if DrivesArray[i].DriveNumber=Drive_Number then
    begin
      Result:=DrivesArray[i].DriveHandle;
      Break;
    end;
  end;
end;

function LvmGetDriveStatus(Drive_Handle: ADDRESS): TDriveInformation;
{$ifdef OS2}
var
  Res: CARDINAL32;
{$endif}
begin
{$ifdef OS2}
  Result:=TDriveInformation(Get_Drive_Status(Drive_Handle, @Res));
{$endif}
{$ifdef Windows}
  {$if 0}
  TDriveInformation=record
    Total_Available_Sectors: CARDINAL32;        // The number of sectors on the disk which are not currently assigned to a partition.
    Largest_Free_Block_Of_Sectors: CARDINAL32;  // The number of sectors in the largest contiguous block of available sectors.
    Corrupt_Partition_Table: BOOLEAN;           // If TRUE, then the partitioning information found on the drive is incorrect!
    Unusable: BOOLEAN;                          // If TRUE, the drive's MBR is not accessible and the drive can not be partitioned.
    IO_Error: BOOLEAN;                          // If TRUE, then the last I/O operation on this drive failed!
    Is_Big_Floppy: BOOLEAN;                     // If TRUE, then the drive is a PRM formatted as a big floppy (i.e. the old style removable media support).
    Drive_Name: Array[0..DISK_NAME_SIZE-1] of Char; // User assigned name for this disk drive.
  end;
  {$endif}
{$endif}
end;

Function LvmGetPartitionType(PartitionType: BYTE): String;
begin
  Case PartitionType of
    0: Result:='Free Space';
    1: Result:=IfThen(Terminology=2, 'Advanced' ,'LVM');
    2: Result:=IfThen(Terminology=2, 'Standard', 'Compatibility');
  end;
end;

Function LvmGetPartitionStatus(PartitionStatus: BYTE): String;
begin
  Case PartitionStatus of
    0: Result:='Free Space';
    1: Result:='In Use';
    2: Result:='Available';
  end;
end;

procedure LvmSetTerms(Term: Byte);
begin
  Terminology:=Term;
end;

begin
  Terminology:=2;
end.
