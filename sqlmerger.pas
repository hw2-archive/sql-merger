{
 *
 * Copyright (C) 2005-2009 UDW-SOFTWARE <http://udw.altervista.com/>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
}

unit sqlmerger;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls, FileCtrl, Menus, CheckLst, Buttons, Grids,
  OleCtrls, SHDocVw, Wininet,IniFiles, ExtCtrls, ShellApi, DBCtrls, DBGrids,
  IWControl, IWDBStdCtrls,shlobj, ToolWin, ActnMan, ActnCtrls, ActnMenus,
  XPStyleActnCtrls, ActnList, XPMan;

const
  clguid   = 0;
  clname = 1;
  clpath = 2;
  MaxThreads  =  1;


 Type thread = class(TThread)
  protected
     // Protected declarations
   procedure      Execute; override;
   procedure      handlelabelstatus;
  public
   constructor Create(susp:boolean);
  end;



type
  TGridCracker = class(TStringgrid);
  TForm1 = class(TForm)
    MergeBtn: TbitBtn;
    AddBtn: TbitBtn;
    DelBtn: TbitBtn;
    MoveGroup: TGroupBox;
    UpBtn: TBitBtn;
    DownBtn: TBitBtn;
    StringGrid1: TStringGrid;
    WebBrowser1: TWebBrowser;
    Versione: TLabel;
    PathOption: TCheckBox;
    Timer1: TTimer;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    ActionManager1: TActionManager;
    ActionMainMenuBar1: TActionMainMenuBar;
    HelpSection: TAction;
    About: TAction;
    XPManifest1: TXPManifest;
    procedure Sortgrid(Grid : TStringGrid; SortCol:integer);
    procedure CheckVersion;
    procedure AddBtnClick(Sender: TObject);
    procedure DelBtnClick(Sender: TObject);
    procedure UpBtnClick(Sender: TObject);
    procedure DownBtnClick(Sender: TObject);
    procedure MergeBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure VersioneClick(Sender: TObject);
    procedure StringGrid1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure OpenDialog2CanClose(Sender: TObject; var CanClose: Boolean);
    procedure OpenDialog1CanClose(Sender: TObject; var CanClose: Boolean);
    procedure HelpBugReport1Click(Sender: TObject);
    procedure Info1Click(Sender: TObject);
    procedure HelpSectionExecute(Sender: TObject);
    procedure AboutExecute(Sender: TObject);
  private
    { Private declarations }
  public
    AppPath,InfoFile,NavUrl,Version:string;
    LauncherIni: TIniFile;
    Crescente: boolean;

  end;

var
  Form1: TForm1;
  ThreadCounter,GridCounter:integer;
  UpdatedCheck:boolean;

implementation

{$R *.dfm}


{
procedure TForm1.FolderBtnClick(Sender: TObject);
var
  BrowseInfo  : TBrowseInfo;
  PIDL        : PItemIDList;
  DisplayName : array[0..MAX_PATH] of Char;
begin

  FillChar(BrowseInfo,SizeOf(BrowseInfo),#0);
  BrowseInfo.hwndOwner      := Handle;
  BrowseInfo.pszDisplayName := @DisplayName[0];
  BrowseInfo.lpszTitle      := 'Select Directory';
  BrowseInfo.ulFlags        := BIF_RETURNONLYFSDIRS;

  PIDL := SHBrowseForFolder(BrowseInfo);

  if Assigned(PIDL) then
    if SHGetPathFromIDList(PIDL, DisplayName) then
    begin
      PathFile.text:=DisplayName;
      PathFile.Text:=PathFile.Text+'\';
    end;
end;

}



//#############################################################################
//
// FUNZIONI DEL THREAD         (SHARED)
//
//#############################################################################



procedure ThreadCreate(susp:boolean);
 var dwThreads:     Integer;
begin
   // Increase the thread counter
   try
   InterlockedIncrement(ThreadCounter)
   finally
    dwThreads:=InterlockedDecrement(ThreadCounter);
   end;

   if (dwThreads < MaxThreads) then
    Thread.Create(susp);
     // Perform inherited (don't suspend)
end;


procedure Thread.Execute;
begin
  Form1.CheckVersion;
  Synchronize(self,Handlelabelstatus);
end;

procedure Thread.handlelabelstatus;
var state:string;
begin

if updatedCheck then
 begin
    state:='Out of date'#13#10'   [CLICK HERE]';
    Form1.Versione.Font.Color:=clRed;
 end
 else
 begin
    state:=' [Updated] ';
    Form1.Versione.Font.Color:=clGreen;
 end;

  Form1.Versione.Caption:='Version: ' + Form1.Version +' '+state;

end;

constructor Thread.Create(susp:boolean);
begin
    inherited Create(susp);
    // Set thread props
    InterlockedIncrement(ThreadCounter);
    FreeOnTerminate:=True;
    Priority:=tpLower;
end;


// FUNZIONI SUPPORTO



function ExecuteFile(const FileName,Params,DefaultDir: String; ShowCmd: Integer): THandle;
begin
  Result:=ShellExecute(Application.Handle,nil,PChar(FileName),PChar(Params),PChar(DefaultDir),ShowCmd);
end;

function GetInetFile(const fileURL, FileName: String):boolean;
const
  BufferSize=1024;
var
  hSession, hURL:HInternet;
  Buffer: array[1..BufferSize] of Byte;
  BufferLen: DWORD;
  sAppName: string;
  f:File;
begin
  result :=false;
  sAppName := ExtractFileName(Application.ExeName);
  hSession := InternetOpen(PChar(sAppName), INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, 0);
  try
    hURL := InternetOpenURL(hSession, PChar(fileURL), nil, 0, 0, 0);
    try
      AssignFile(f, FileName);
      Rewrite(f, 1);
    repeat
      InternetReadFile(hURL, @Buffer, SizeOf(Buffer), BufferLen);
      BlockWrite(f, Buffer, BufferLen)
    until BufferLen = 0;
      CloseFile(f);
      result := true;
    finally
    end
  finally
  end;
  InternetCloseHandle(hURL);
  InternetCloseHandle(hSession);
end;



function CheckIntFile(const fileURL: String):boolean;
const
  BufferSize=1024;
var
  hSession, hURL:HInternet;
  sAppName: string;
begin
  hURL:=nil;
  sAppName := ExtractFileName(Application.ExeName);
  hSession := InternetOpen(PChar(sAppName), INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, 0);
  if hSession<>nil then
  begin
    hURL:= InternetOpenURL(hSession, PChar(fileURL), nil, 0, 0, 0);
    if hURL<>nil then result := true
    else result:=false;
    InternetCloseHandle(hURL);
  end
  else
   result:=false;

InternetCloseHandle(hSession);
end;


function VersioneApplicazione(const PathApplicazione: string): string;
var
    DimVariabile1: dword;
    DimVariabile2: dword;
    Puntatore1: Pointer;
    Puntatore2: Pointer;
begin
    Result := '';
    DimVariabile1 := GetFileVersionInfoSize(PChar(PathApplicazione), DimVariabile2);
    if DimVariabile1 > 0 then
    begin
        GetMem(Puntatore1, DimVariabile1);
        try
        GetFileVersionInfo(PChar(PathApplicazione), 0, DimVariabile1, Puntatore1); // ottengo i dati della versione
        VerQueryValue(Puntatore1, '\', Puntatore2, DimVariabile2);
        with TVSFixedFileInfo(Puntatore2^) do
        Result := Result + // Costruisco la stringa di versione
        IntToStr(HiWord(dwFileVersionMS)) + '.' +
        IntToStr(LoWord(dwFileVersionMS)) + '.' +
        IntToStr(HiWord(dwFileVersionLS)) + '.' +
        IntToStr(LoWord(dwFileVersionLS));
        finally
        FreeMem(Puntatore1);
        end;
    end;
end;


procedure TForm1.CheckVersion;
var RestarterVer:string;
begin
  { controllo versioni dal web}

  Versione.Color:=clBlack;
  Versione.Caption:='Checking Version..';

  RestarterVer:='1';

  DeleteFile(InfoFile);
  if CheckIntFile(NavURL+InfoFile) and GetInetFile(NavURL+InfoFile, InfoFile) then
  if FileExists(InfoFile) then
      begin
       LauncherIni:=TIniFile.Create(GetCurrentDir+'\'+InfoFile);
       RestarterVer:=LauncherIni.ReadString('SQLMERGER','version','1');
       LauncherIni.Free;
       DeleteFile(InfoFile);
      end;

  UpdatedCheck:= (RestarterVer<>'1') AND (Version<RestarterVer);

end;



procedure TForm1.Sortgrid(Grid : TStringGrid; SortCol:integer);
{A simple exchange sort of grid rows}
var
   i,j : integer;
   temp:tstringlist;
begin

  temp:=tstringlist.create;
  with Grid do
  for i := FixedRows to RowCount - 2 do  {because last row has no next row}
  for j:= i+1 to rowcount-1 do {from next row to end}
  if ( (crescente) AND (AnsiCompareText(Cells[SortCol, i], Cells[SortCol,j]) > 0 ) )
     OR ( not crescente AND (AnsiCompareText(Cells[SortCol, i], Cells[SortCol,j]) < 0 ))
  then
  begin
      temp.assign(rows[j]);
      rows[j].assign(rows[i]);
      rows[i].assign(temp);
  end;
  temp.free;
  crescente:=not crescente;
end;




///////////////////////////////////////////////////


procedure TForm1.AddBtnClick(Sender: TObject);
begin
  OpenDialog1.Execute;
end;

procedure TForm1.OpenDialog1CanClose(Sender: TObject;
  var CanClose: Boolean);
  var i:integer;
begin
   StringGrid1.RowCount:=StringGrid1.RowCount+OpenDialog1.Files.Count;
     for i := 0 to OpenDialog1.Files.Count-1 do
       begin
         inc(GridCounter);
         StringGrid1.Cols[clguid].Add(inttostr(GridCounter));
         StringGrid1.Cols[clname].Add(ExtractFileName(OpenDialog1.Files[I]));
         StringGrid1.Cols[clpath].Add(OpenDialog1.Files[I]);
       end;

  stringgrid1.FixedRows:=1;   // reimposta la fixed row
end;

procedure TForm1.OpenDialog2CanClose(Sender: TObject;
  var CanClose: Boolean);
begin
 // PathFile.text:= OpenDialog2.Files.Strings[0]
end;


procedure TForm1.DelBtnClick(Sender: TObject);
begin
if StringGrid1.Row>=1 then
  TGridCracker(StringGrid1).DeleteRow(StringGrid1.Row);
end;

procedure TForm1.UpBtnClick(Sender: TObject);
begin
 if (StringGrid1.Row>1) then
 TGridCracker(StringGrid1).MoveRow(StringGrid1.Row,StringGrid1.Row-1);
end;

procedure TForm1.DownBtnClick(Sender: TObject);
begin

 if (StringGrid1.Row>0) and (StringGrid1.Row+1<StringGrid1.RowCount) then
  TGridCracker(StringGrid1).MoveRow(StringGrid1.Row,StringGrid1.Row+1);
end;

procedure TForm1.MergeBtnClick(Sender: TObject);
var x,files:string;
    I,count:integer;
    Mfile,merged:TextFile;
begin
  x:='';

 count:=0;

if SaveDialog1.Execute then
begin
 AssignFile(merged,saveDialog1.FileName);
 Rewrite(merged);
 For i:=1 to StringGrid1.RowCount-1 do
 begin
   files:=StringGrid1.Cells[clpath,I];
   if FileExists(files) then
   begin
      inc(count);
       AssignFile(Mfile,files);
             reset(Mfile);

      writeln(merged,'');
      writeln(merged,'-- ========================');
      if PathOption.Checked then
       writeln(merged,'--  '+ExtractFileName(files))
      else
       writeln(merged,'--  '+ExtractFileName(files)+'  IN  '+ExtractFilePath(files));
      writeln(merged,'-- ========================');
      writeln(merged,'');

      while Not Eof(Mfile) do
      begin
         ReadLn(Mfile,x);
         writeln(merged,x);
      end;
      CloseFile(Mfile);
   end;
 end;
 CloseFile(merged);

 if count>0 then
  showMessage('Successfull Merged '+inttostr(count)+' Sql files !')
 else
  showMessage('No Sql Merged');

end;

end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  AppPath:=ExtractFilePath(Application.ExeName);
  Version:=VersioneApplicazione(Application.ExeName);
  NavUrl:='http://udw.altervista.org/udwinfo/sqlmerger/';
  InfoFile:='inform.ini';
  GridCounter:=0;
  crescente:=true;
  StringGrid1.Cols[clguid].Strings[0]:='ID';
  StringGrid1.Cols[clname].Strings[0]:='Name';
  StringGrid1.Cols[clpath].Strings[0]:='Path';
  WebBrowser1.Navigate(NavUrl+'stats.html?I=Sql_'+Version);
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  ThreadCreate(false);
  Timer1.Enabled:=false;
end;

procedure TForm1.VersioneClick(Sender: TObject);
begin
  ExecuteFile(NavUrl+'redirects.php?selection=sql_download', '', '', 0);
end;

procedure TForm1.StringGrid1MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var c,j:integer;
  rect:trect;
begin
  with StringGrid1 do
  if y<rowheights[0] then   {make sure row 0 was clicked}
  begin
    for j:= 0 to colcount-1 do {determine which column was clicked}
    begin
      rect := cellrect(j,0);
      if (rect.Left < x) and (rect.Right> x) then
      begin
        c := j;
        break;
      end;
    end;
    sortgrid(StringGrid1,c);
  end;
end;

procedure TForm1.HelpBugReport1Click(Sender: TObject);
begin
  ExecuteFile(NavUrl+'redirects.php?selection=help_section', '', '', 0);
end;

procedure TForm1.Info1Click(Sender: TObject);
begin
 messagedlg('SQL Merger '+version+' : software freeware'+#13#10+'created by HW2-Yehonal from UDW community',mtinformation,[mbok,mbhelp],0);
end;

procedure TForm1.HelpSectionExecute(Sender: TObject);
begin
 ExecuteFile(NavUrl+'redirects.php?selection=help_section', '', '', 0);
end;

procedure TForm1.AboutExecute(Sender: TObject);
begin
 messagedlg('SQL Merger '+version+' [Freeware]'+#13#10+'Created by HW2-Yehonal from UDW community',mtinformation,[mbok,mbhelp],0);
end;

end.
