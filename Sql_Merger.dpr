program Sql_Merger;

uses
  Forms,
  sqlmerger in 'sqlmerger.pas' {Form1};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Sql Merger';
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
