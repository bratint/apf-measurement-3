unit uFrmResonance;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls,
  Vcl.Samples.Spin, Vcl.Buttons,
  uAdc, uAdcCommonTypes;

type
  TfrmResonance = class(TFrame)
    pnMain: TPanel;
    chWatch: TCheckBox;
    lblFreq: TLabel;
    edFreq: TEdit;
    edMinus: TEdit;
    edPlus: TEdit;
    lblMinus: TLabel;
    lblPlus: TLabel;
    btnFreqApply: TBitBtn;
    btnFreqCancel: TBitBtn;
    lblAmplitude: TLabel;
    seAmplitudeN: TSpinEdit;
    lblAmplitudeN: TLabel;
    lblFreqAmplitude: TLabel;
    edFreqAmplitude: TEdit;
    lblResistance: TLabel;
    edResistance: TEdit;
    lblPhase: TLabel;
    lblPhaseN: TLabel;
    sePhaseN: TSpinEdit;
    sePhaseDN: TSpinEdit;
    edQuality: TEdit;
    edFreqPhase: TEdit;
    lblFreqPhase: TLabel;
    lblQuality: TLabel;
    btnNApply: TBitBtn;
    btnNCancel: TBitBtn;
    lblSteps: TLabel;
    edSteps: TEdit;
    shWatch: TShape;
    lblDelay: TLabel;
    edDelay: TEdit;
    procedure btnFreqApplyClick(Sender: TObject);
    procedure btnNApplyClick(Sender: TObject);
    procedure chWatchClick(Sender: TObject);
    procedure edFreqChange(Sender: TObject);
    procedure edMinusChange(Sender: TObject);
    procedure edPlusChange(Sender: TObject);
    procedure edStepsChange(Sender: TObject);
    procedure seAmplitudeNChange(Sender: TObject);
    procedure sePhaseNChange(Sender: TObject);
    procedure sePhaseDNChange(Sender: TObject);
    procedure btnFreqCancelClick(Sender: TObject);
    procedure btnNCancelClick(Sender: TObject);
    procedure edDelayChange(Sender: TObject);
  private
    FControlsUpdating: Boolean;
    FEditFreqChanged, FEditPlusChanged, FEditMinusChanged, FEditStepsChanged, FEditDelayChanged: Boolean;
    FCurrentWatch: Boolean;
    FCurrentFreq, FCurrentPlus, FCurrentMinus: Double;
    FCurrentSteps, FCurrentDelay, FCurrentAmplitudeN, FCurrentPhaseN, FCurrentPhaseDN: Integer;
    procedure SetFreqControlsDefaultState;
    procedure SetNControlsDefaultState;
  public
    ResonanceIndex: Integer;
    procedure UpdateControls(const AResonanceParameters: TResonanceParameters; const AResonanceWatchingData: TResonanceWatchingData);
    procedure ProcessMeasureStart(AParams: TResonanceMeasurementParameters);
  end;

implementation

{$R *.dfm}

uses
  uFrmMain;

procedure TfrmResonance.btnFreqApplyClick(Sender: TObject);
begin
  AdcManager.MeasurementResult.SetFrequencyRange(ResonanceIndex, StrToFloat(edFreq.Text), StrToFloat(edMinus.Text), StrToFloat(edPlus.Text), StrToInt(edSteps.Text), StrToInt(edDelay.Text), chWatch.Checked);
  SetFreqControlsDefaultState;
end;

procedure TfrmResonance.btnFreqCancelClick(Sender: TObject);
begin
  FControlsUpdating := True;

  chWatch.Checked := FCurrentWatch;
  edFreq.Text := FloatToStr(FCurrentFreq);
  edPlus.Text := FloatToStr(FCurrentPlus);
  edMinus.Text := FloatToStr(FCurrentMinus);
  edSteps.Text := IntToStr(FCurrentSteps);
  edDelay.Text := IntToStr(FCurrentDelay);

  FControlsUpdating := False;
  SetFreqControlsDefaultState;
end;

procedure TfrmResonance.btnNApplyClick(Sender: TObject);
begin
  AdcManager.MeasurementResult.SetMovingAverageParams(ResonanceIndex, seAmplitudeN.Value, sePhaseN.Value, sePhaseDN.Value);
  frmMain.UpdateForResonance(ResonanceIndex);
  FCurrentAmplitudeN := seAmplitudeN.Value;
  FCurrentPhaseN := sePhaseN.Value;
  FCurrentPhaseDN := sePhaseDN.Value;
  SetNControlsDefaultState;
end;

procedure TfrmResonance.btnNCancelClick(Sender: TObject);
begin
  FControlsUpdating := True;

  seAmplitudeN.Value := FCurrentAmplitudeN;
  sePhaseN.Value := FCurrentPhaseN;
  sePhaseDN.Value := FCurrentPhaseDN;

  FControlsUpdating := False;
  SetNControlsDefaultState;
end;

procedure TfrmResonance.chWatchClick(Sender: TObject);
begin
  if FControlsUpdating then Exit;
  if Measuring then
    begin
      shWatch.Show;
      btnFreqApply.Show;
      btnFreqCancel.Show;
    end;
end;

procedure TfrmResonance.edDelayChange(Sender: TObject);
begin
  if FControlsUpdating then Exit;
  if Measuring and not FEditDelayChanged then
    begin
      FEditDelayChanged := True;
      edDelay.Color := CL_CHANGED_EDIT;
      btnFreqApply.Show;
      btnFreqCancel.Show;
    end;
end;

procedure TfrmResonance.edFreqChange(Sender: TObject);
begin
  if FControlsUpdating then Exit;
  if Measuring and not FEditFreqChanged then
    begin
      FEditFreqChanged := True;
      edFreq.Color := CL_CHANGED_EDIT;
      btnFreqApply.Show;
      btnFreqCancel.Show;
    end;
end;

procedure TfrmResonance.edMinusChange(Sender: TObject);
begin
  if FControlsUpdating then Exit;
  if Measuring and not FEditMinusChanged then
    begin
      FEditMinusChanged := True;
      edMinus.Color := CL_CHANGED_EDIT;
      btnFreqApply.Show;
      btnFreqCancel.Show;
    end;
end;

procedure TfrmResonance.edPlusChange(Sender: TObject);
begin
  if FControlsUpdating then Exit;
  if Measuring and not FEditPlusChanged then
    begin
      FEditPlusChanged := True;
      edPlus.Color := CL_CHANGED_EDIT;
      btnFreqApply.Show;
      btnFreqCancel.Show;
    end;
end;

procedure TfrmResonance.edStepsChange(Sender: TObject);
begin
  if FControlsUpdating then Exit;
  if Measuring and not FEditStepsChanged then
    begin
      FEditStepsChanged := True;
      edSteps.Color := CL_CHANGED_EDIT;
      btnFreqApply.Show;
      btnFreqCancel.Show;
    end;
end;

procedure TfrmResonance.seAmplitudeNChange(Sender: TObject);
begin
  if FControlsUpdating then Exit;
  if MeasureWasStarted then
    begin
      seAmplitudeN.Color := CL_CHANGED_EDIT;
      btnNApply.Show;
      btnNCancel.Show;
    end;
end;

procedure TfrmResonance.sePhaseDNChange(Sender: TObject);
begin
  if FControlsUpdating then Exit;
  if MeasureWasStarted then
    begin
      sePhaseDN.Color := CL_CHANGED_EDIT;
      btnNApply.Show;
      btnNCancel.Show;
    end;
end;

procedure TfrmResonance.sePhaseNChange(Sender: TObject);
begin
  if FControlsUpdating then Exit;
  if MeasureWasStarted then
    begin
      sePhaseN.Color := CL_CHANGED_EDIT;
      btnNApply.Show;
      btnNCancel.Show;
    end;
end;

procedure TfrmResonance.SetFreqControlsDefaultState;
begin
  FEditFreqChanged := False;
  FEditPlusChanged := False;
  FEditMinusChanged := False;
  FEditStepsChanged := False;
  FEditDelayChanged := False;
  shWatch.Hide;
  chWatch.Refresh;
  edFreq.Color := clWindow;
  edMinus.Color := clWindow;
  edPlus.Color := clWindow;
  edSteps.Color := clWindow;
  edDelay.Color := clWindow;
  btnFreqApply.Hide;
  btnFreqCancel.Hide;
end;

procedure TfrmResonance.SetNControlsDefaultState;
begin
  seAmplitudeN.Color := clWindow;
  sePhaseN.Color := clWindow;
  sePhaseDN.Color := clWindow;
  btnNApply.Hide;
  btnNCancel.Hide;
end;

procedure TfrmResonance.UpdateControls(const AResonanceParameters: TResonanceParameters; const AResonanceWatchingData: TResonanceWatchingData);
begin
  FControlsUpdating := True;

  edFreqAmplitude.Text := FloatToStr(AResonanceParameters.ResonantFrequency);
  edResistance.Text := FloatToStr(AResonanceParameters.ResonantResistance);
  edFreqPhase.Text := FloatToStr(AResonanceParameters.MaxPhaseDerivativeFrequency);
  edQuality.Text := FloatToStr(AResonanceParameters.QualityFactor);

  FCurrentWatch := AResonanceWatchingData.NeedWatch;

  if FEditFreqChanged then
    begin
      if FCurrentFreq <> AResonanceWatchingData.ResonantFrequency then
        edFreq.Color := CL_EDIT_CONFLICT;
    end
  else
    edFreq.Text := FloatToStr(AResonanceWatchingData.ResonantFrequency);
  FCurrentFreq := AResonanceWatchingData.ResonantFrequency;

  if FEditMinusChanged then
    begin
      if FCurrentMinus <> AResonanceWatchingData.MinusFrequency then
        edMinus.Color := CL_EDIT_CONFLICT;
    end
  else
    edMinus.Text := FloatToStr(AResonanceWatchingData.MinusFrequency);
  FCurrentMinus := AResonanceWatchingData.MinusFrequency;

  if FEditPlusChanged then
    begin
      if FCurrentPlus <> AResonanceWatchingData.PlusFrequency then
        edPlus.Color := CL_EDIT_CONFLICT;
    end
  else
    edPlus.Text := FloatToStr(AResonanceWatchingData.PlusFrequency);
  FCurrentPlus := AResonanceWatchingData.PlusFrequency;

  if FEditStepsChanged then
    begin
      if FCurrentSteps <> AResonanceWatchingData.Steps then
        edSteps.Color := CL_EDIT_CONFLICT;
    end
  else
    edSteps.Text := IntToStr(AResonanceWatchingData.Steps);
  FCurrentSteps := AResonanceWatchingData.Steps;

  if FEditDelayChanged then
    begin
      if FCurrentDelay <> AResonanceWatchingData.Delay then
        edDelay.Color := CL_EDIT_CONFLICT;
    end
  else
    edDelay.Text := IntToStr(Round(AResonanceWatchingData.Delay));
  FCurrentDelay := AResonanceWatchingData.Delay;

  FControlsUpdating := False;
end;

procedure TfrmResonance.ProcessMeasureStart(AParams: TResonanceMeasurementParameters);
begin
  FCurrentWatch := AParams.NeedWatch;
  FCurrentFreq := AParams.ResonantFrequency;
  FCurrentPlus := AParams.MinusResonantFrequency;
  FCurrentMinus := AParams.PlusResonantFrequency;
  FCurrentSteps := AParams.Steps;
  FCurrentDelay := AParams.Delay;
  FCurrentAmplitudeN := AParams.MagnitudeMovingAveragePointsCount;
  FCurrentPhaseN := AParams.PhaseMovingAveragePointsCount;
  FCurrentPhaseDN := AParams.PhaseDerivativeMovingAveragePointsCount;
  SetFreqControlsDefaultState;
  SetNControlsDefaultState;
end;

end.
