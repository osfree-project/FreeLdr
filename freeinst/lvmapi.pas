{

     LVM support

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

unit LVMApi;

{This is LVM support/emulation library. Under OS/2 it uses real LVM.DLL, but
under Win32/Linux/DOS it emulates required functions.}

interface

uses
{$ifdef Windows}
  Windows,
{$endif}
{$ifdef OS2}
  LVM,
{$endif}
  StrUtils, SysUtils;
  
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

type
  LBA=LongWord;
  Cardinal32=Longword;
  ADDRESS=Pointer;

// @todo check real packing!!!
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
  
function LvmOpenEngine(Ignore_CHS: Boolean): CARDINAL32;
procedure LvmCloseEngine();
function LvmCommitChanges(): CARDINAL32;
function LvmGetDriveControlData: TDrivesArray;
function LvmFreeEngineMemory(LVMObject: ADDRESS): CARDINAL32;
function LvmReadSectors(Drive_Number: CARDINAL32; Starting_Sector: LBA; Sectors_To_Read: CARDINAL32; var Buffer): CARDINAL32;
function LvmWriteSectors(Drive_Number: CARDINAL32; Starting_Sector: LBA; Sectors_To_Write: CARDINAL32; var Buffer): CARDINAL32;

implementation

var
  DrivesArray: TDrivesArray;

{$ifdef Windows}
const
  IOCTL_STORAGE_QUERY_PROPERTY = $2D1400;
  
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
  Res: CARDINAL32;
{$endif}
begin
{$ifdef OS2}
  Open_LVM_Engine(Ignore_CHS, &Res);
  Return:=Res;
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
		DriveNumber:=Drive+1; // @todo DriveNumber is 1 based in LVM?

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
  Commit_Changes(&Res);
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
{$endif}
begin
{$ifdef OS2}
  Result:=Get_Drive_Control_Data(&Res);
{$endif}
{$ifdef Windows}
  result:=DrivesArray;
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
	i: integer;
	DataLen: LongWord;
{$endif}
{$ifdef OS2}
	Res: CARDINAL32;
{$endif}
begin
{$ifdef OS2}
  Read_Sectors(Drive_Number, Starting_Sector, Sectors_To_Read, Buffer: ADDRESS, &Res);
  Result:=Res;
{$endif}

{$ifdef windows}
	for i:=Low(DrivesArray) to High(DrivesArray) do
	begin
		if DrivesArray[i].DriveNumber=Drive_Number then
		begin
			SetFilePointer(HANDLE(DrivesArray[i].DriveHandle), Starting_Sector*512, nil, FILE_BEGIN);
			if ReadFile(HANDLE(DrivesArray[i].DriveHandle), Buffer, Sectors_To_Read*512, DataLen, nil)=false then writeln('error');
			break;
		end;
	end;
{$endif}
end;

function LvmWriteSectors(Drive_Number: CARDINAL32; Starting_Sector: LBA; Sectors_To_Write: CARDINAL32; var Buffer): CARDINAL32;
var
{$ifdef windows}
	i: integer;
	DataLen: LongWord;
{$endif}
{$ifdef OS2}
	Res: CARDINAL32;
{$endif}
begin
{$ifdef OS2}
	Write_Sectors(Drive_Number, Starting_Sector, Sectors_To_Write, Buffer, &Res);
	Result:=Res;
{$endif}

{$ifdef windows}
	for i:=Low(DrivesArray) to High(DrivesArray) do
	begin
		if DrivesArray[i].DriveNumber=Drive_Number then
		begin
			SetFilePointer(HANDLE(DrivesArray[i].DriveHandle), Starting_Sector*512, nil, FILE_BEGIN);
			WriteFile(HANDLE(DrivesArray[i].DriveHandle), Buffer, Sectors_To_Write*512, DataLen, nil);
			break;
		end;
	end;
{$endif}
end;

end.
