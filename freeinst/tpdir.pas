{

     osFree Turbo Professional Copyright (C) 2022-2023 osFree

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

{$MODE ObjFPC}

unit tpdir;
  {-File/Directory selection}

interface

uses
  tpcrt,
  tppick;
  
const
  UseFileFrame : Boolean = True; {True to draw frame around pick window}
  SeparateDirs : Boolean = True; {True to sort dirs and files apart}
  DirsUpper : Boolean = True; {True to display directories uppercase}
  FilesUpper : Boolean = False; {True to display files uppercase}
  ShowExtension : Boolean = True; {True to display file extension as well as name}
  ReturnCompletePath : Boolean = True; {True to return complete pathnames for files}

  ShowSizeDateTime : Boolean = False; {True to show size/date/time}
  SizeDisplay : (SizeNone,   {Don't display the file size}
    SizeBytes,               {Display size in bytes}
    SizeKBytes)              {Display size in kilobytes}
  = SizeBytes;
  DirDisplayStr : string[5] = '<dir>'; {Displayed in size column for subdirs}
  DatePicture : string[12] = 'Mm/dd/yy'; {Format for file date}
  TimePicture : string[12] = 'Hh:mmt'; {Format for file time}

function GetFileName
  (Mask : string;            {Search mask}
    FileAttr : Byte;         {Search attribute for files}
    XLow, YLow : Byte;       {Upper left corner of window, including frame}
    YHigh, PickCols : Byte;  {Lower row, and number of columns of files}
    Colors : PickColorArray; {Video attributes to use}
    var FileName : string    {Full path of selected file}
    ) : Word;
  {-Given a mask (which may or may not contain wildcards),
    popup a directory window, let user choose, and return pathname.
    Returns zero for success, non-zero for error.
    Error codes:
      0 = Success
      1 = Path not found
      2 = No matching files
      3 = New file
      4 = Insufficient memory
      5 = Won't fit on screen
      6 = No pick orientation !!.10
    else  Turbo critical error code
  }

function ChangeDirectory
  (Mask : string;           {New directory or mask}
   XLow, YLow : Byte;       {Upper left corner of window, including frame}
   YHigh, PickCols : Byte;  {Lower row, and number of columns of files}
   Colors : PickColorArray  {Video attributes to use}
   ) : Word;
 {-Given a mask (which may or may not contain wildcards),
   change to that directory and if a wildcard is specified,
   show the directories there and allow selection.
   If no error occurs, the current directory will be the
   final selection when the routine exits. The returned
   status word is a Turbo IoResult value, with the following
   exceptions:
      4 = Insufficient memory
      5 = Won't fit on screen
 }

function CompleteFileName(Name : string) : string;
  {-Convert a potentially relative file name into a complete one}

implementation

function GetFileName
  (Mask : string;            {Search mask}
    FileAttr : Byte;         {Search attribute for files}
    XLow, YLow : Byte;       {Upper left corner of window, including frame}
    YHigh, PickCols : Byte;  {Lower row, and number of columns of files}
    Colors : PickColorArray; {Video attributes to use}
    var FileName : string    {Full path of selected file}
    ) : Word;
  {-Given a mask (which may or may not contain wildcards),
    popup a directory window, let user choose, and return pathname.
    Returns zero for success, non-zero for error.
    Error codes:
      0 = Success
      1 = Path not found
      2 = No matching files
      3 = New file
      4 = Insufficient memory
      5 = Won't fit on screen
      6 = No pick orientation !!.10
    else  Turbo critical error code
  }
begin
end;

function ChangeDirectory
  (Mask : string;           {New directory or mask}
   XLow, YLow : Byte;       {Upper left corner of window, including frame}
   YHigh, PickCols : Byte;  {Lower row, and number of columns of files}
   Colors : PickColorArray  {Video attributes to use}
   ) : Word;
 {-Given a mask (which may or may not contain wildcards),
   change to that directory and if a wildcard is specified,
   show the directories there and allow selection.
   If no error occurs, the current directory will be the
   final selection when the routine exits. The returned
   status word is a Turbo IoResult value, with the following
   exceptions:
      4 = Insufficient memory
      5 = Won't fit on screen
 }
begin
end;

function CompleteFileName(Name : string) : string;
  {-Convert a potentially relative file name into a complete one}
begin
end;

end.
