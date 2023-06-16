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

uses
  SysUtils,
  LVMAPI;

Type
  TPartition=record
    Empty: array[1..16] of Byte;
  end;

Type
  MBRType=(
    MBRInvalid,         { invalid MBR type }
    MBRGeneric,         { standard generic MBR }
    MBRModern,          { modern MBR }
    MBRAAP,             { Advanced Active Partitions MBR }
    MBRNEWLDR,          { NEWLDR MBR }
    MBRSpeedStor,       { AST/NEC, SpeedStor MBR }
    MBROntrack,         { Ontrack Disk Manager }
    MBRHybrid,          { Hybrid MBR }
    MBRProtective       { Protective MBR }
	MBRFreeLdr          { FreeLDR MBR }
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
    DiskSignature: DWord;
    Protect: Word;
    Partitions: Array[1..4] of TPartition;      { Partitions }
    Signature: Word;                            { Signature }
  end;

  TMBRNewLdr=record                             // @todo not finished yet
    JMPS: array[0..1] of byte;
    NEWLDRSignature: array[1..6] of char;
  end;

  TMBRAAP=record                                // @todo not finished yet
    Bootstrap: array[0..427] of byte;           { Bootstrap code area }
    AAPSignature: Word;                         { AAP Signature }
  end;

  TMBRSpeedStor=record                          // @todo not finished yet
    Bootstrap: array[0..379] of byte;           { Bootstrap code area }
    NECSignature: Word;                         { NEC Signature }
  end;

  TMBROntrack=record                            // @todo not finished yet
    Bootstrap: array[0..251] of byte;           { Bootstrap code area }
    DMSignature: Word;                          { DM Signature }
  end;

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
  Buffer: ARRAY [0..511] of Byte;
  MBR: TMBRGeneric absolute buffer;
  NEWLDRMBR: TMBRNewLdr absolute buffer;
  AAP: TMBRAAP absolute buffer;
  NEC: TMBRSpeedStor absolute buffer;
  Ontrack: TMBROntrack absolute buffer;
  Modern: TMBRModern absolute buffer;
begin
  Result:=MBRInvalid;
  ReadMBRSector(DriveNum, Buffer);
  If MBR.Signature=$AA55 then                   { MBR signature found }
  begin
    if (isGPT(DriveNum)) then
    begin
      Result:=MBRProtective;
      // @todo Detect MBRHybrid here, seems hard to do this...
    end else begin
      if NEWLDRMBR.NEWLDRSignature='NEWLDR' then
      begin
        Result:=MBRNEWLDR;
      end else begin
        If (Modern.Zeros=0) and ((Modern.Protect=0) or (Modern.Protect=$5a5a)) then Result:=MBRModern;
        If AAP.AAPSignature=$5678 then Result:=MBRAAP;
        If NEC.NECSignature=$A55A then Result:=MBRSpeedStor;
        If Ontrack.DMSignature=$55AA then Result:=MBROntrack;
      end;
    end;
  end;
end;

end.

