{

     osFree FreeLDR Installer (C) 2010 by Yoda
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

unit MBR;

interface

procedure ReadMBRSector(DriveNum: Byte; var MBRBuffer);
procedure WriteMBRSector(DriveNum: Byte; var MBRBuffer);
function isGPT(DriveNum: Byte): Boolean;

implementation

uses
  Windows,
  SysUtils,
  LVM;

const
  BIOSDISK_READ               = $0;
  BIOSDISK_WRITE              = $1;

  METHOD_BUFFERED             = $00000000;
  FILE_ANY_ACCESS             = $00000000;
  FILE_DEVICE_FILE_SYSTEM     = $00000009;

  FSCTL_LOCK_VOLUME           = (FILE_DEVICE_FILE_SYSTEM shl 16) or
                                (FILE_ANY_ACCESS shl 14) or 
                                ($6 shl 2) or METHOD_BUFFERED;
  FSCTL_UNLOCK_VOLUME         = (FILE_DEVICE_FILE_SYSTEM shl 16) or
                                (FILE_ANY_ACCESS shl 14) or 
                                ($7 shl 2) or METHOD_BUFFERED;

Type
  TPartition=record
    Empty: array[1..16] of Byte;
  end;

Type
  MBRType=(
    MBRInvalid,		{ invalid MBR type }
    MBRGeneric,		{ standard generic MBR }
    MBRModern,  	{ modern MBR }
    MBRAAP,		{ Advanced Active Partitions MBR }
    MBRNEWLDR,  	{ NEWLDR MBR }
    MBRSpeedStor,	{ AST/NEC, SpeedStor MBR }
    MBROntrack,		{ Ontrack Disk Manager }
    MBRHybrid,		{ Hybrid MBR }
    MBRProtective	{ Protective MBR }
  );

Type
  TMBRGeneric=record
    Bootstrap: Array[0..445] of Byte;		{ Bootstrap code area }
    Partitions: Array[1..4] of TPartition;	{ Partitions }
    Signature: Word;				{ Signature }
  end;

  TMBRModern=record
    Bootstrap1: Array[0..217] of Byte;		{ First Bootstrap code area }
    Zeros: Array[0..1] of Byte;			{ Zeros }
    Drive: Byte;
    Seconds: Byte;
    Minutes: Byte;
    Hours: Byte;
    Bootstrap2: Array[0..215] of Byte;		{ First Bootstrap code area }
    DiskSignature: DWord;
    Protect: Word;
    Partitions: Array[1..4] of TPartition;	{ Partitions }
    Signature: Word;				{ Signature }
  end;

  TMBRNewLdr=record				// @todo not finished yet
    JMPS: array[0..1] of byte;
    NEWLDRSignature: array[1..6] of char;
  end;

Type
  TGPTHeader=packed record
    MBR: TMBRGeneric;
    Signature: Array[0..7] of Char;
  end;

function isGPT(DriveNum: Byte): Boolean;
var
	Buffer: ARRAY [0..1023] of Byte;
	GPT: TGPTHeader absolute buffer;
begin
	LvmReadSectors(DriveNum, 0, 2, Buffer);
	Result:=GPT.Signature='EFI PART';
end;

function MBRDetect(DriveNum: Byte): MBRType;
var
	Buffer:  ARRAY [0..511] of Byte;
	MBR: TMBRGeneric absolute buffer;
	NEWLDRMBR: TMBRNewLdr absolute buffer;
begin
	Result:=MBRInvalid;
	LvmReadSectors(DriveNum, 0, 1, Buffer);
	If MBR.Signature<>$aa55 then exit;	{ No MBR signature found }
	if (isGPT(DriveNum)) then
	begin
		Result:=MBRProtective;
		// @todo Detect MBRHybrid here
	end else begin
		if NEWLDRMBR.NEWLDRSignature='NEWLDR' then
		begin
			Result:=MBRNEWLDR;
		end else begin
			// @todo AAP
			// @todo SpeedStor/NEC
			// @todo Ontrack
		end;
	end;
end;

procedure ReadMBRSector(DriveNum: Byte; var MBRBuffer);
begin
	LvmReadSectors(DriveNum, 0, 1, MBRBuffer);
end;

procedure WriteMBRSector(DriveNum: Byte; var MBRBuffer);
begin
	LvmWriteSectors(DriveNum, 0, 1, MBRBuffer);
end;

end.

