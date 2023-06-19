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

{API to handle MBR}

interface

procedure ReadMBRSector(DriveNum: Byte; var MBRBuffer);
procedure WriteMBRSector(DriveNum: Byte; var MBRBuffer);
function isGPT(DriveNum: Byte): Boolean;

implementation

{$PACKRECORDS 1}

uses
  LVMAPI;

Type
  TCHS=record                                   // @todo not finished yet
    Empty: array[1..3] of Byte;
  end;

  TLBA=record                                   // @todo not finished yet
    Empty: array[1..4] of Byte;
  end;

  TPartition=record
    PartitionStatus: Byte;                      { Status or physical drive (bit 7 set is for active or bootable }
    FirstSectorCHS: TCHS;                       { CHS address of first absolute sector in partition }
    PartitionType: Byte;                        { Type of partition }
    LastSectorCHS: TCHS;                        { CHS address of last absolute sector in partition }
    FirstSectorLBA: TLBA;                       { LBA of first absolute sector in the partition }
    Size: DWord;                                { Number of sectors in partition }
  end;

Type
  MBRType=(
    MBRInvalid,                                 { invalid MBR type }
    MBRGeneric,                                 { standard generic MBR }
    MBRModern,                                  { modern MBR }
    MBRAAP,                                     { Advanced Active Partitions MBR }
    MBRNEWLDR,                                  { NEWLDR MBR }
    MBRSpeedStor,                               { AST/NEC, SpeedStor MBR }
    MBROntrack,                                 { Ontrack Disk Manager }
    MBRHybrid,                                  { Hybrid MBR }
    MBRProtective,                              { Protective MBR }
    MBRFreeLdr                                  { FreeLDR MBR }
  );

Type
  TMBRGeneric=record
    Bootstrap: Array[0..445] of Byte;           { Bootstrap code area }
    Partitions: Array[1..4] of TPartition;      { Partitions }
    Signature: Word;                            { Signature }
  end;

  TMBRModern=record
    Bootstrap1: Array[0..217] of Byte;          { First Bootstrap code area }
    Zeros: Word;                                { Zeros }
    Drive: Byte;
    Seconds: Byte;
    Minutes: Byte;
    Hours: Byte;
    Bootstrap2: Array[0..215] of Byte;          { Second Bootstrap code area }
    DiskSignature: DWord;                       { NT disk signature }
    Protect: Word;                              { }
    Partitions: Array[1..4] of TPartition;      { Partitions }
    Signature: Word;                            { Signature }
  end;

  TAAPPartition=record                          // @todo not finished yet
    Empty: array[1..16] of byte;
  end;

  TMBRNewLdr=record                             // @todo Bootstrap code can start from 0x000C/0x0018/0x001E
    JMPS: array[0..1] of byte;                  { JMP to Bootstrap code }
    NEWLDRSignature: array[1..6] of char;       { NEWLDR Signature }
    Drive: Byte;                                { LOADER physical drive and boot flag }
    LoaderCHS: TCHS;                            { CHS address of LOADER boot sector or image file }
    DLMin: Byte;                                { Allowed DL minimum (?) }
    Reserver: Array[1..3] of Byte;              { Reserved (default: 0x000000) }
    LoaderLBA: TLBA;                            { LBA of LOADER boot sector or image file }
    Patch: Word;                                { Patch offset of VBR boot unit }
    Checksum: Word;                             { Checksum (0x0000 if not used) }
    OEMSignature: array[1..6] of Char;          { OEM loader signature ("MSWIN4" for REAL/32 }
    Bootstrap: array[1..397] of Byte;           { Bootstrap code }
    AAPSignature: Word;                         { AAP Signature }
    AAPPartition: TAAPPartition;                { AAP Partition }
    Partitions: Array[1..4] of TPartition;      { Partitions }
    Signature: Word;                            { Signature }
  end;

  TMBRAAP=record
    Bootstrap: array[0..427] of byte;           { Bootstrap code area }
    AAPSignature: Word;                         { AAP Signature }
    AAPPartition: TAAPPartition;                { AAP Partition }
    Partitions: Array[1..4] of TPartition;      { Partitions }
    Signature: Word;                            { Signature }
  end;

  TMBRSpeedStor=record
    Bootstrap: array[0..379] of byte;           { Bootstrap code area }
    NECSignature: Word;                         { NEC Signature }
    Partitions: Array[1..8] of TPartition;      { Partitions }
    Signature: Word;                            { Signature }
  end;

  TMBROntrack=record
    Bootstrap: array[0..251] of byte;           { Bootstrap code area }
    DMSignature: Word;                          { DM Signature }
    Partitions: Array[1..16] of TPartition;     { Partitions }
    Signature: Word;                            { Signature }
  end;

  TMBRFreeLdr=record
    Bootstrap1: Array[0..439] of Byte;          { First Bootstrap code area }
    DiskSignature: DWord;                       { NT Signature }
    Chain: Byte;                                { Chain disk in INT13H format}
    Partition: Byte;                            { Boot partition or Zero to use Active Partition}
    Partitions: Array[1..4] of TPartition;      { Partitions }
    Signature: Word;                            { Signature }
  end;

  TGPTHeader=record
    MBR: TMBRGeneric;                           { MBR }
    Signature: Array[0..7] of Char;             { GPT Signature }
  end;

function isGPT(DriveNum: Byte): Boolean;
var
  Buffer: ARRAY [0..1023] of Byte;
  GPT: TGPTHeader absolute buffer;
begin
  LvmReadSectors(DriveNum, 0, 2, Buffer);
  Result:=GPT.Signature='EFI PART';
end;

procedure ReadMBRSector(DriveNum: Byte; var MBRBuffer);
begin
  LvmReadSectors(DriveNum, 0, 1, MBRBuffer);
end;

procedure WriteMBRSector(DriveNum: Byte; var MBRBuffer);
begin
  LvmWriteSectors(DriveNum, 0, 1, MBRBuffer);
end;

function MBRDetect(DriveNum: Byte): MBRType;
var
  Buffer: ARRAY [0..511] of Byte;               { Actual MBR storage }
  MBR: TMBRGeneric absolute buffer;             { MBRGeneric alias }
  NEWLDRMBR: TMBRNewLdr absolute buffer;        { MBRNewLdr alias }
  AAP: TMBRAAP absolute buffer;                 { MBRAAP alias }
  NEC: TMBRSpeedStor absolute buffer;           { MBRSpeedStor alias }
  Ontrack: TMBROntrack absolute buffer;         { MBROntrack alias }
  Modern: TMBRModern absolute buffer;           { MBRModern alias }
begin
  Result:=MBRInvalid;                           { By default no MBR found }
  ReadMBRSector(DriveNum, Buffer);              { Read MBR from Drive }
  If MBR.Signature=$AA55 then                   { MBR signature found }
  begin
    Result:=MBRGeneric;                         { Standard MBR by default }
    if (isGPT(DriveNum)) then                   { Check is GPT presented }
    begin
      Result:=MBRProtective;                    { If so, then we have or Protective or Hybrid MBR }
      // @todo Detect MBRHybrid here, seems hard to do this...
    end else begin
      {Modern detection is not safe, but works in most cases because Zeroes not often can be found in other MBRs.}
      If (Modern.Zeros=0) and ((Modern.Protect=0) or (Modern.Protect=$5a5a)) then Result:=MBRModern;  {Check for Modern MBR }
      If NEC.NECSignature=$A55A then Result:=MBRSpeedStor;           {Check for NEC MBR }
      If Ontrack.DMSignature=$55AA then Result:=MBROntrack;          {Check for Disk Manager MBR }
      If AAP.AAPSignature=$5678 then Result:=MBRAAP;                 {Check for AAR MBR }
      if NEWLDRMBR.NEWLDRSignature='NEWLDR' then Result:=MBRNEWLDR;  { Check for NEWLDR MBR }
    end;
  end;
end;

end.
