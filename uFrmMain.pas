unit uFrmMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  System.UITypes, System.Generics.Collections, System.Actions,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Samples.Spin, Vcl.StdCtrls,
  Vcl.Buttons, Vcl.Samples.Gauges, Vcl.ComCtrls, Vcl.ExtCtrls, Vcl.ActnList,
  uAdc, uAdcCommonTypes, uFrmResonance, uFrmSettings;

const
  CL_CHANGED_EDIT = $AAFFFF;
  CL_EDIT_CONFLICT = $99AAFF;
  CL_PLOT_BACKGROUND = $FFFFFF;
  CL_MAGNITUDE_LINE = $FF0000;
  CL_MAGNITUDE_PALE_LINE = $FFAAAA;
  CL_PHASE_LINE = $0000FF;
  CL_PHASE_PALE_LINE = $AAAAFF;
  CL_PHASE_DERIVATIVE_LINE = $FF00FF;
  CL_PHASE_DERIVATIVE_PALE_LINE = $FFAAFF;
  CL_RESONANCE_FRAME_MEASURING = $BAE2BA;
  CL_RESONANCE_FRAME_VIEWED = $ADEFEF;
  CL_RESONANCE_FRAME_VIEWED_MEASURING = $ADEFCE;

type

  TfrmMain = class(TForm)
    pnMain: TPanel;
    btnStart: TButton;
    btnStop: TButton;
    ggProgress: TGauge;
    ggBufferFilling: TGauge;
    stbBottom: TStatusBar;
    sbResonances: TScrollBox;
    shInputChannelOverflow: TShape;
    shOutputChannelOverflow: TShape;
    rbStandartDeviation: TRadioButton;
    rbFourierTransform: TRadioButton;
    edDacOutput: TEdit;
    lblDacOutput: TLabel;
    btnDacOutputApply: TBitBtn;
    chExcel: TCheckBox;
    chSeries: TCheckBox;
    lblCalculationKind: TLabel;
    lblResonances: TLabel;
    edResonancesCount: TEdit;
    btnDeleteResonance: TButton;
    btnAddResonance: TButton;
    cbResonances: TComboBox;
    imgPlot: TImage;
    pnTop: TPanel;
    splitMain: TSplitter;
    ActionListMain: TActionList;
    actShowSettings: TAction;
    btnDacOutputCancel: TBitBtn;
    TimerExcelSaving: TTimer;
    actRefreshPlot: TAction;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnAddResonanceClick(Sender: TObject);
    procedure btnDeleteResonanceClick(Sender: TObject);
    procedure btnDacOutputApplyClick(Sender: TObject);
    procedure btnStartClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure chExcelClick(Sender: TObject);
    procedure imgPlotMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure cbResonancesChange(Sender: TObject);
    procedure actShowSettingsExecute(Sender: TObject);
    procedure btnDacOutputCancelClick(Sender: TObject);
    procedure edDacOutputChange(Sender: TObject);
    procedure TimerExcelSavingTimer(Sender: TObject);
    procedure actRefreshPlotExecute(Sender: TObject);
  private
    FControlsUpdating: Boolean;
    FResonances: TList<TfrmResonance>;
    FLastResonance, FMeasuringResonance, FDisplayingResonance: Integer;
    FCurrentDacOutput: Double;
    FPhaseOnCurrentPlot: Boolean;
    procedure UpdateControls(const AResonance: Integer);
    procedure DrawPoint(const APoint: TPoint);
    procedure UpdatePlot(const AResonance: Integer);
    procedure SetDacOutputControlsDefaultState;
    procedure SetControlsEnabled(const AMeasuring: Boolean);
    procedure SetDisplayedResonance(const AResonance: Integer);
    procedure ResetResonanceFramesColors;
    procedure SetResonanceFramesColors;
    procedure ProcessMeasureStart(AParams: TStartMeasureParameters);
    procedure ProcessMeasureStop;
    procedure SaveToExcel;
    procedure HandleErrorMessage(var AMessage: TMessage); message WM_ADC_ERROR_MESSAGE;
    procedure HandleMeasureCompletedMessage(var AMessage: TMessage); message WM_MEASURE_COMPLETED;
    procedure HandleIterationCompletedMessage(var AMessage: TMessage); message WM_ITERATION_COMPLETED;
    procedure HandleMeasurementStateUpdated(var AMessage: TMessage); message WM_MEASUREMENT_STATE_UPDATED;
  public
    procedure UpdateForResonance(const AResonance: Integer);
  end;

var
  frmMain: TfrmMain;
  AdcManager: TAdcManager = nil;
  Measuring: Boolean = False;
  MeasureWasStarted: Boolean = False;

implementation

{$R *.dfm}

procedure TfrmMain.btnDacOutputApplyClick(Sender: TObject);
var
  lParams: TOngoingMeasureParameters;
  lText: String;
  lDacOutput: Double;
begin
  lDacOutput := StrToFloat(edDacOutput.Text);
  if Measuring then
    begin
      lParams := TOngoingMeasureParameters.Create;
      try
        lParams.NeedUpdateDacOutput := True;
        lParams.DacOutput := lDacOutput;
        if not AdcManager.SetMeasureParameters(lParams, lText) then
          begin
            ShowMessage(lText);
            Exit;
          end;
      finally
        lParams.Free;
      end;
    end
  else
    begin
      if not CheckDacOutputCorrectness(lDacOutput) then
        begin
          ShowMessage('Некорректное значение выходного напряжения');
          Exit;
        end;
    end;

  FCurrentDacOutput := lDacOutput;
  SetDacOutputControlsDefaultState
end;

procedure TfrmMain.btnDacOutputCancelClick(Sender: TObject);
begin
  FControlsUpdating := True;
  edDacOutput.Text := FloatToStr(FCurrentDacOutput);
  FControlsUpdating := False;
  SetDacOutputControlsDefaultState;
end;

procedure TfrmMain.btnDeleteResonanceClick(Sender: TObject);
begin
  if FResonances.Count = 0 then
    Exit;
  FResonances[FResonances.Count - 1].Free;
  FResonances.Delete(FResonances.Count - 1);
  edResonancesCount.Text := IntToStr(FResonances.Count);
  cbResonances.Items.Delete(cbResonances.Items.Count - 1);
end;

procedure TfrmMain.btnStartClick(Sender: TObject);
var
  lParams: TStartMeasureParameters;
  lText: String;
  lFrame: TfrmResonance;
begin
  lParams := TStartMeasureParameters.Create;
  try
    lParams.FourierAnalysis := rbFourierTransform.Checked;
    lParams.DataStep := 1024 * StrToInt(frmSettings.edDataStep.Text);
    lParams.BlocksToReadCount := StrToInt(frmSettings.edBlocksToReadCount.Text);
    lParams.SleepBetweenSetFreqAndDoSampling := StrToInt(frmSettings.edSleepBetweenSetFreqAndDoSampling.Text);
    lParams.DacOutput := StrToFloat(edDacOutput.Text);
    case frmSettings.cmRangeIn.ItemIndex of
      0: lParams.InputSignalChannelRange := air300mV;
      1: lParams.InputSignalChannelRange := air1000mV;
      2: lParams.InputSignalChannelRange := air3000mV;
      else lParams.InputSignalChannelRange := air3000mV;
    end;
    case frmSettings.cmRangeOut.ItemIndex of
      0: lParams.OutputSignalChannelRange := air300mV;
      1: lParams.OutputSignalChannelRange := air1000mV;
      2: lParams.OutputSignalChannelRange := air3000mV;
      else lParams.OutputSignalChannelRange := air3000mV;
    end;
    lParams.Series := chSeries.Checked;
    for lFrame in FResonances do
      lParams.AddResonance(
          StrToFloat(lFrame.edFreq.Text),
          StrToFloat(lFrame.edMinus.Text),
          StrToFloat(lFrame.edPlus.Text),
          StrToInt(lFrame.edSteps.Text),
          StrToInt(lFrame.edDelay.Text),
          lFrame.chWatch.Checked,
          lFrame.seAmplitudeN.Value, lFrame.sePhaseN.Value, lFrame.sePhaseDN.Value);

    if not AdcManager.StartMeasure(lParams, lText) then
      ShowMessage(lText)
    else
      ProcessMeasureStart(lParams);
  finally
    lParams.Free;
  end;
end;

procedure TfrmMain.btnStopClick(Sender: TObject);
var
  lText: String;
begin
  if not AdcManager.StopMeasure(lText) then
    ShowMessage(lText)
  else
    ProcessMeasureStop;
end;

procedure TfrmMain.imgPlotMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  LAmpl, LFreq, LPhase, LPhaseD: Double;
begin
  if AdcManager <> nil then
    begin
      LAmpl := AdcManager.MeasurementResult.ReducedImageToMagnitudeValue(FDisplayingResonance, Y);
      LFreq := AdcManager.MeasurementResult.ReducedImageToFrequencyValue(FDisplayingResonance, X);
      if FPhaseOnCurrentPlot then
        begin
          LPhase := AdcManager.MeasurementResult.ReducedImageToPhaseValue(FDisplayingResonance, Y);
          LPhaseD := AdcManager.MeasurementResult.ReducedImageToPhaseDerivativeValue(FDisplayingResonance, Y);
          stbBottom.SimpleText := FloatToStr(LFreq) +  ' Гц; ' + FloatToStr(LAmpl) + '; ' + FloatToStr(TwoPortNetwork.GetResistance(LAmpl)) + ' Ом; ' +
              FloatToStr(LPhase) + ' град.; ' + FloatToStr(LPhaseD) + ' град./Гц';
        end
      else
        stbBottom.SimpleText := FloatToStr(LFreq) +  ' Гц; ' + FloatToStr(LAmpl) + '; ' + FloatToStr(TwoPortNetwork.GetResistance(LAmpl)) + ' Ом';
    end;
end;

procedure TfrmMain.cbResonancesChange(Sender: TObject);
begin
  if FControlsUpdating then Exit;
  SetDisplayedResonance(cbResonances.ItemIndex);
end;

procedure TfrmMain.chExcelClick(Sender: TObject);
begin
  AdcManager.MeasurementResult.NeedSaveToExcel := chExcel.Checked;
end;

procedure TfrmMain.edDacOutputChange(Sender: TObject);
begin
  if FControlsUpdating then Exit;
  if Measuring then
    begin
      edDacOutput.Color := CL_CHANGED_EDIT;
      btnDacOutputApply.Show;
      btnDacOutputCancel.Show;
    end;
end;

procedure TfrmMain.actRefreshPlotExecute(Sender: TObject);
begin
  UpdatePlot(FDisplayingResonance);
end;

procedure TfrmMain.actShowSettingsExecute(Sender: TObject);
begin
  frmSettings.Show;
end;

procedure TfrmMain.btnAddResonanceClick(Sender: TObject);
var
  LFrame: TfrmResonance;
begin
  LFrame := TfrmResonance.Create(sbResonances);
  LFrame.Name := 'frmResonance' + IntToStr(FResonances.Count + 1);
  LFrame.Top := - sbResonances.VertScrollBar.Position;
  LFrame.Left := LFrame.Width * FResonances.Count - sbResonances.HorzScrollBar.Position;
  LFrame.Parent := sbResonances;
  LFrame.ResonanceIndex := FResonances.Count;
  FResonances.Add(LFrame);
  edResonancesCount.Text := IntToStr(FResonances.Count);
  cbResonances.Items.Add(IntToStr(FResonances.Count));
  if FResonances.Count > 1 then
    chSeries.Checked := True;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FControlsUpdating := True;

  AdcManager := TAdcManager.Create(Handle);
  FResonances := TList<TfrmResonance>.Create;

  FCurrentDacOutput := 0.25;
  edDacOutput.Text := FloatToStr(FCurrentDacOutput);

  FControlsUpdating := False;
  FLastResonance := -1;
  FMeasuringResonance := -1;
  FDisplayingResonance := -1;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  FResonances.Free;
  AdcManager.Free;
end;

procedure TfrmMain.UpdateControls(const AResonance: Integer);
var
  LResonanceParameters: TResonanceParameters;
  LResonanceWatchingData: TResonanceWatchingData;
  LFrame: TfrmResonance;
begin
  if (AResonance < 0) or (AResonance >= FResonances.Count) then Exit;
  LFrame := FResonances[AResonance];

  LResonanceParameters := AdcManager.MeasurementResult.GetResonanceParameters(AResonance);
  LResonanceWatchingData := AdcManager.MeasurementResult.GetFrequencyRange(AResonance);

  LFrame.UpdateControls(LResonanceParameters, LResonanceWatchingData);
end;

procedure TfrmMain.DrawPoint(const APoint: TPoint);
begin
  imgPlot.Canvas.Ellipse(APoint.X - 3, APoint.Y - 3, APoint.X + 3, APoint.Y + 3);
end;

procedure TfrmMain.UpdatePlot(const AResonance: Integer);
var
  LMagnitude, LMagnitudeSmooth, LPhase, LPhaseSmooth, LPhaseDerivative, LPhaseDerivativeSmooth: TReducedImagePlot;
  LMagnitudeResonance, LPhaseResonance: TPoint;
  LPhaseDefined: Boolean;
begin
  AdcManager.MeasurementResult.GetReducedImagePlots(imgPlot.Height, imgPlot.Width, 20, 20, AResonance,
      LPhaseDefined, LMagnitude, LMagnitudeSmooth, LPhase, LPhaseSmooth, LPhaseDerivative, LPhaseDerivativeSmooth, LMagnitudeResonance, LPhaseResonance);

  if imgPlot.Picture.Graphic <> nil then
    begin
      imgPlot.Picture.Graphic.Width := imgPlot.Width;
      imgPlot.Picture.Graphic.Height := imgPlot.Height;
    end;
  imgPlot.Canvas.Brush.Color := CL_PLOT_BACKGROUND;
  imgPlot.Canvas.FillRect(imgPlot.ClientRect);

  if LMagnitudeSmooth = nil then
    begin
      imgPlot.Canvas.Pen.Color := CL_MAGNITUDE_LINE;
      imgPlot.Canvas.Polyline(LMagnitude);
    end
  else
    begin
      imgPlot.Canvas.Pen.Color := CL_MAGNITUDE_PALE_LINE;
      imgPlot.Canvas.Polyline(LMagnitude);
      imgPlot.Canvas.Pen.Color := CL_MAGNITUDE_LINE;
      imgPlot.Canvas.Polyline(LMagnitudeSmooth);
    end;
  DrawPoint(LMagnitudeResonance);

  FPhaseOnCurrentPlot := LPhaseDefined;
  if LPhaseDefined then
    begin
      if LPhaseSmooth = nil then
        begin
          imgPlot.Canvas.Pen.Color := CL_PHASE_LINE;
          imgPlot.Canvas.Polyline(LPhase);
        end
      else
        begin
          imgPlot.Canvas.Pen.Color := CL_PHASE_PALE_LINE;
          imgPlot.Canvas.Polyline(LPhase);
          imgPlot.Canvas.Pen.Color := CL_PHASE_LINE;
          imgPlot.Canvas.Polyline(LPhaseSmooth);
        end;

      if LPhaseDerivativeSmooth = nil then
        begin
          imgPlot.Canvas.Pen.Color := CL_PHASE_DERIVATIVE_LINE;
          imgPlot.Canvas.Polyline(LPhaseDerivative);
        end
      else
        begin
          imgPlot.Canvas.Pen.Color := CL_PHASE_DERIVATIVE_PALE_LINE;
          imgPlot.Canvas.Polyline(LPhaseDerivative);
          imgPlot.Canvas.Pen.Color := CL_PHASE_DERIVATIVE_LINE;
          imgPlot.Canvas.Polyline(LPhaseDerivativeSmooth);
        end;
      DrawPoint(LPhaseResonance);
    end;
end;

procedure TfrmMain.SetDacOutputControlsDefaultState;
begin
  edDacOutput.Color := clWindow;
  btnDacOutputApply.Hide;
  btnDacOutputCancel.Hide;
end;

procedure TfrmMain.SetControlsEnabled(const AMeasuring: Boolean);
begin
  btnStart.Enabled := not AMeasuring;
  btnStop.Enabled := AMeasuring;
  rbStandartDeviation.Enabled := not AMeasuring;
  rbFourierTransform.Enabled := not AMeasuring;
  chSeries.Enabled := not AMeasuring;
  btnDeleteResonance.Enabled := not AMeasuring;
  btnAddResonance.Enabled := not AMeasuring;
  frmSettings.edBlocksToReadCount.Enabled := not AMeasuring;
  frmSettings.edDataStep.Enabled := not AMeasuring;
  frmSettings.edSleepBetweenSetFreqAndDoSampling.Enabled := not AMeasuring;
end;

procedure TfrmMain.TimerExcelSavingTimer(Sender: TObject);
var
  LNeedTryAgain: Boolean;
  LErrorDescription: String;
begin
  try
    if AdcManager.MeasurementResult.AddDataToExcel(LNeedTryAgain, LErrorDescription) then
      TimerExcelSaving.Enabled := False
    else if not LNeedTryAgain then
      begin
        TimerExcelSaving.Enabled := False;
        MessageDlg('Не удалось сохранить данные в Excel: ' + LErrorDescription, mtError, [mbOK], 0);
      end;
  except
    on E: Exception do
      begin
        TimerExcelSaving.Enabled := False;
        raise;
      end;
  end;
end;

procedure TfrmMain.SetDisplayedResonance(const AResonance: Integer);
begin
  FDisplayingResonance := AResonance;
  UpdatePlot(AResonance);
  SetResonanceFramesColors;
  FControlsUpdating := True;
  cbResonances.ItemIndex := FDisplayingResonance;
  FControlsUpdating := False;
end;

procedure TfrmMain.ResetResonanceFramesColors;
var
  LFrame: TfrmResonance;
begin
  for LFrame in FResonances do
    begin
      LFrame.Color := clBtnFace;
    end;
end;

procedure TfrmMain.SetResonanceFramesColors;
var
  LFrame: TfrmResonance;
begin
  ResetResonanceFramesColors;

  if (FMeasuringResonance <> FDisplayingResonance) then
    begin
      if (FMeasuringResonance >= 0) and (FMeasuringResonance < FResonances.Count) then
        begin
          LFrame := FResonances[FMeasuringResonance];
          LFrame.Color := CL_RESONANCE_FRAME_MEASURING;
        end;
      if (FDisplayingResonance >= 0) and (FDisplayingResonance < FResonances.Count) then
        begin
          LFrame := FResonances[FDisplayingResonance];
          LFrame.Color := CL_RESONANCE_FRAME_VIEWED;
        end;
    end
  else
    begin
      if (FMeasuringResonance >= 0) and (FMeasuringResonance < FResonances.Count) then
        begin
          LFrame := FResonances[FMeasuringResonance];
          LFrame.Color := CL_RESONANCE_FRAME_VIEWED_MEASURING;
        end;
    end;

  for LFrame in FResonances do
    begin
      LFrame.Refresh;
      LFrame.chWatch.Refresh;
    end;
end;

procedure TfrmMain.ProcessMeasureStart(AParams: TStartMeasureParameters);
var
  i, cnt: Integer;
  LFrame: TfrmResonance;
  LResonance: TResonanceMeasurementParameters;
begin
  MeasureWasStarted := True;
  Measuring := True;
  TimerExcelSaving.Enabled := False;
  FCurrentDacOutput := AParams.DacOutput;
  SetDacOutputControlsDefaultState;
  if AParams.Resonances.Count < FResonances.Count then
    cnt := AParams.Resonances.Count
  else
    cnt := FResonances.Count;
  for i := 0 to cnt - 1 do
    begin
      LResonance := AParams.Resonances[i];
      LFrame := FResonances[i];
      LFrame.ProcessMeasureStart(LResonance);
    end;
  imgPlot.Canvas.FillRect(imgPlot.ClientRect);
  SetControlsEnabled(True);
end;

procedure TfrmMain.ProcessMeasureStop;
begin
  Measuring := False;
  SetControlsEnabled(False);
end;

procedure TfrmMain.SaveToExcel;
var
  LNeedTryAgain: Boolean;
  LErrorDescription: String;
begin
  if TimerExcelSaving.Enabled then
    Exit;
  if not AdcManager.MeasurementResult.AddDataToExcel(LNeedTryAgain, LErrorDescription) then
    begin
      if LNeedTryAgain then
        TimerExcelSaving.Enabled := True
      else
        begin
          chExcel.Checked := False;
          MessageDlg('Не удалось сохранить данные в Excel: ' + LErrorDescription, mtError, [mbOK], 0);
        end;
    end;
end;

procedure TfrmMain.HandleErrorMessage(var AMessage: TMessage);
var
  LErrorMessage: TErrorMessage;
begin
  ProcessMeasureStop;
  LErrorMessage := AdcManager.PopErrorMessage;
  if LErrorMessage <> nil then
    begin
      MessageDlg(LErrorMessage.MessageText, mtError, [mbOK], 0);
      LErrorMessage.Free;
    end;
end;

procedure TfrmMain.HandleMeasureCompletedMessage(var AMessage: TMessage);
begin
  ProcessMeasureStop;
  FMeasuringResonance := 0;
  UpdateControls(0);
  SetDisplayedResonance(0);
  ShowMessage('Измерение завершено!');
  SaveToExcel;
end;

procedure TfrmMain.HandleIterationCompletedMessage(var AMessage: TMessage);
begin
  FLastResonance := Integer(AMessage.WParam);
  UpdateControls(FLastResonance);
  SetDisplayedResonance(FLastResonance);
  SaveToExcel;
end;

procedure TfrmMain.HandleMeasurementStateUpdated(var AMessage: TMessage);
var
  LState: TMeasurementState;
begin
  LState := TMeasurementState(AMessage.LParam);
  try
    ggProgress.Progress := LState.MeasureProgressPrecent;
    ggBufferFilling.Progress := LState.MaxOfBufferFillingPercent;
    if LState.InputChannelOverflow then
      shInputChannelOverflow.Brush.Color := clRed
    else
      shInputChannelOverflow.Brush.Color := clWhite;
    if LState.OutputChannelOverflow then
      shOutputChannelOverflow.Brush.Color := clRed
    else
      shOutputChannelOverflow.Brush.Color := clWhite;
    if FMeasuringResonance <> LState.CurrentResonance then
      begin
        FMeasuringResonance := LState.CurrentResonance;
        if Measuring then
          SetResonanceFramesColors;
      end;
  finally
    LState.Free;
  end;
end;

procedure TfrmMain.UpdateForResonance(const AResonance: Integer);
begin
  SetDisplayedResonance(AResonance);
  UpdateControls(AResonance);
end;

end.
