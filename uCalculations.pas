unit uCalculations;

interface

uses
  Winapi.Windows, System.SysUtils,
  uAdcCommonTypes, uComplex;

type

  TStandartDeviationResult = record
    InputAverage: Double;
    OutputAverage: Double;
    Magnitude: Double;
  end;

  TFourierTransformResult = record
    Magnitude: Double;
    Phase: Double;
  end;

function CalculateStandartDeviation(const AInputSignal: TInputSignal; const AOutputSignalChannelRange, AInputSignalChannelRange: TAdcInputRange): TStandartDeviationResult;
function CalculateFourierTransform(const AInputSignal: TInputSignal; const AOutputSignalChannelRange, AInputSignalChannelRange: TAdcInputRange; const AFrequencyHz, ASamplingFrequencyHz: Double): TFourierTransformResult;

implementation

function AdcDataToVoltage(const AAdcData: Double; const AAdcInputRange: TAdcInputRange): Double; inline;
begin
  case AAdcInputRange of
    air3000mV: Result := 3.0 * AAdcData / 8000;
    air1000mV: Result := 1.0 * AAdcData / 8000;
    air300mV: Result := 0.3 * AAdcData / 8000;
    else raise Exception.Create('AdcDataToVoltage wrong value');
  end;
end;

function AdcInputRangeMultiplier(const AAdcInputRange: TAdcInputRange): Integer; inline;
begin
  case AAdcInputRange of
    air3000mV: Result := 30;
    air1000mV: Result := 10;
    air300mV: Result := 3;
    else raise Exception.Create('AdcInputRangeMultiplier wrong value');
  end;
end;

function CalculateStandartDeviation(const AInputSignal: TInputSignal; const AOutputSignalChannelRange, AInputSignalChannelRange: TAdcInputRange): TStandartDeviationResult;
 var
  i, j: Integer;
  LSamplesCount: Integer;
  LSumIn, LSumOut: Int64;
  LShiftIn, LShiftOut: SHORT;
begin
  LSamplesCount := 0;
  for i := 0 to Length(AInputSignal) - 1 do
    Inc(LSamplesCount, Length(AInputSignal[i]));

  LSumIn := 0;
  LSumOut := 0;
  for i := 0 to Length(AInputSignal) - 1 do
    for j := 0 to Length(AInputSignal[i]) - 1 do
      begin
        if Odd(j) then
          Inc(LSumOut, AInputSignal[i, j])
        else
          Inc(LSumIn, AInputSignal[i, j]);
      end;
  LShiftIn := Round(LSumIn / (LSamplesCount / 2));
  LShiftOut := Round(LSumOut / (LSamplesCount / 2));

  LSumIn := 0;
  LSumOut := 0;
  for i := 0 to Length(AInputSignal) - 1 do
    for j := 0 to Length(AInputSignal[i]) - 1 do
      begin
        if Odd(j) then
          Inc(LSumOut, Abs(AInputSignal[i, j] - LShiftOut))
        else
          Inc(LSumIn, Abs(AInputSignal[i, j] - LShiftIn));
      end;

  Result.InputAverage := AdcDataToVoltage(LSumIn / (LSamplesCount / 2), AInputSignalChannelRange) * pi / 2.0;
  Result.OutputAverage := AdcDataToVoltage(LSumOut / (LSamplesCount / 2), AOutputSignalChannelRange) * pi / 2.0;
  Result.Magnitude := (AdcInputRangeMultiplier(AOutputSignalChannelRange) * LSumOut) / (AdcInputRangeMultiplier(AInputSignalChannelRange) * LSumIn);
end;

function CalculateFourierTransform(const AInputSignal: TInputSignal; const AOutputSignalChannelRange, AInputSignalChannelRange: TAdcInputRange;
    const AFrequencyHz, ASamplingFrequencyHz: Double): TFourierTransformResult;
var
  i, j, k: Integer;
  LSampleIndex, LSamplesCount: Integer;
  LFreq: Integer;
  LConvolutionIn, LConvolutionOut: array [0..2] of TComplex;
  LBaseConst: array [0..2] of Double;
  LBase: Double;
  LInMultiplier, LOutMultiplier: Integer;
  LMagnitude, LMagnitudeIn, LMagnitudeOut: Double;
  LInFreqIndex, LOutFreqIndex: Integer;
begin
  LSamplesCount := 0;
  for i := 0 to Length(AInputSignal) - 1 do
    Inc(LSamplesCount, Length(AInputSignal[i]));
  LSamplesCount := LSamplesCount div 2;

  LFreq := Round(AFrequencyHz * LSamplesCount / ASamplingFrequencyHz) - 1;
  LInMultiplier := AdcInputRangeMultiplier(AInputSignalChannelRange);
  LOutMultiplier := AdcInputRangeMultiplier(AOutputSignalChannelRange);

  for k := 0 to 2 do
    begin
      LConvolutionIn[k] := CompN(0, 0);
      LConvolutionOut[k] := CompN(0, 0);
      LBaseConst[k] := -2.0 * pi * (LFreq + k) / LSamplesCount;
    end;

  for i := 0 to Length(AInputSignal) - 1 do
    for j := 0 to Length(AInputSignal[i]) - 1 do
      begin
        LSampleIndex := (i * Length(AInputSignal[i]) + j) div 2;
        for k := 0 to 2 do
          begin
            LBase := LBaseConst[k] * LSampleIndex;
            if Odd(j) then
              LConvolutionOut[k] := Slozh(LConvolutionOut[k], Umnozh(CompN(LOutMultiplier * AInputSignal[i, j], 0), ExpI(LBase)))
            else
              LConvolutionIn[k] := Slozh(LConvolutionIn[k], Umnozh(CompN(LInMultiplier * AInputSignal[i, j], 0), ExpI(LBase)));
          end;
      end;

  for k := 0 to 2 do
    begin
      LConvolutionOut[k] := Umnozh(LConvolutionOut[k], ExpI(-pi * (LFreq + k) / LSamplesCount));
    end;

  LMagnitudeIn := ModCN(LConvolutionIn[0]);
  LMagnitudeOut := ModCN(LConvolutionOut[0]);
  LInFreqIndex := 0;
  LOutFreqIndex := 0;
  for k := 1 to 2 do
    begin
      LMagnitude := ModCN(LConvolutionIn[k]);
      if LMagnitude > LMagnitudeIn then
        begin
          LMagnitudeIn := LMagnitude;
          LInFreqIndex := k;
        end;
      LMagnitude := ModCN(LConvolutionOut[k]);
      if LMagnitude > LMagnitudeOut then
        begin
          LMagnitudeOut := LMagnitude;
          LOutFreqIndex := k;
        end;
    end;
  Result.Magnitude := LMagnitudeOut / LMagnitudeIn;
  Result.Phase := 180.0 * (ArgCN(LConvolutionOut[LOutFreqIndex]) - ArgCN(LConvolutionIn[LInFreqIndex])) / pi;
  if Result.Phase > 90.0 then
    Result.Phase := Result.Phase - 180.0
  else if Result.Phase < -90.0 then
    Result.Phase := Result.Phase + 180.0;
end;

end.
