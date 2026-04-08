program ApfMeasurement;

uses
  Vcl.Forms,
  uFrmMain in 'uFrmMain.pas' {frmMain},
  Lusbapi in 'Lusbapi.pas',
  uAdc in 'uAdc.pas',
  uAdcCommonTypes in 'uAdcCommonTypes.pas',
  uAdcThread in 'uAdcThread.pas',
  uCalculations in 'uCalculations.pas',
  uComplex in 'uComplex.pas',
  uFrmResonance in 'uFrmResonance.pas' {frmResonance: TFrame},
  uFrmSettings in 'uFrmSettings.pas' {frmSettings};

{$R *.res}

begin
  {$IFDEF DEBUG}
  System.ReportMemoryLeaksOnShutdown := True;
  {$ENDIF}
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.CreateForm(TfrmSettings, frmSettings);
  Application.Run;
end.
