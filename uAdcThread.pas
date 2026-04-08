unit uAdcThread;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Types, System.Generics.Collections, System.SyncObjs,
  Lusbapi,
  uAdcCommonTypes, uCalculations;

type

  TOnExceptionProcedure = procedure(const AMessageText: String) of object;
  TOnMeasureCompletedProcedure = procedure of object;
  TOnIterationCompletedProcedure = procedure(const AResonanceIndex: Integer) of object;
  TOnMeasurementStateUpdatedProcedure = procedure(AState: TMeasurementState) of object;

  TCommandKind = (ckStartMeasure, ckStopMeasure, ckSetMeasureParameters); // тип команды

  TCommandDataAbstract = class abstract // базовый класс команды, передаваемой из формы потоку
  private
    FCommandKind: TCommandKind; // тип команды
  public
    SuccessResult: Boolean; // признак успешного выполнения команды
    FailReason: String; // описание причины неудачи выполнения команды
    FreeForbidden: Boolean; // если не удалось дождаться обработки команды, объект нельзя освобождать, поскольку поток ещё может к нему обратиться
    function CheckCorrectness: Boolean; virtual; abstract; // метод проверки, что данные в команде заполнены корректно
    property Kind: TCommandKind read FCommandKind;
  end;

  TCommandDataStartMeasure = class(TCommandDataAbstract) // команда начала измерения
  public
    MeasureParameters: TStartMeasureParameters;
    constructor Create(const AMeasureParameters: TStartMeasureParameters);
    function CheckCorrectness: Boolean; override;
  end;

  TCommandDataStopMeasure = class(TCommandDataAbstract) // команда остановки измерения
  public
    constructor Create;
    function CheckCorrectness: Boolean; override;
  end;

  TCommandDataSetMeasureParameters = class(TCommandDataAbstract) // команда установки параметров во время процесса измерения
  public
    MeasureParameters: TOngoingMeasureParameters;
    constructor Create(const AMeasureParameters: TOngoingMeasureParameters);
    function CheckCorrectness: Boolean; override;
  end;

  TCurrentMeasureResonanceParameters = class // параметры резонанса, хранящиеся в списке в текущих параметрах измерения
  private
    FArrayOfFreqWord: array of Cardinal;
    procedure FillFreqArrays;
  public
    StartFrequencyHz: Double; // начальная частота
    StopFrequencyHz: Double; // конечная частота
    MinusResonantFrequency: Double; // сдвиг вниз от частоты резонанса
    PlusResonantFrequency: Double; // сдвиг вверх от частоты резонанса
    Steps: Integer; // число шагов по частоте
    Delay: Integer; // задержка перед началом измерения, мс
    CurrentStep: Integer; // текущий шаг
    NeedWatch: Boolean; // признак того, что надо корректировать параметры в соответствии с измеренной частотой резонанса
    procedure AssignFromResonanceMeasurementParameters(AParameters: TResonanceMeasurementParameters); // установить значения объекта в соответствии с исходным объектом
    procedure AssignFromResonanceWatchingData(AFrequencyRange: TResonanceWatchingData); // установить значения объекта в соответствии с исходным объектом
    function FrequencyWordOfCurrentStep: Cardinal; inline;
    function FrequencyHzOfStep(const AStep: Integer): Double; inline;
  end;

  TCurrentMeasureParameters = class // текущие параметры измерения
  private
    procedure Reset; // сбросить список резонансов
  public
    ChannelsQuantity: Word; // количество активных каналов АЦП
    ChannelsInputRange: array [0..ADC_CHANNELS_QUANTITY_E2010 - 1] of TAdcInputRange; // входные диапазоны каналов АЦП
    NeedUpdateChannelsInputRange: Boolean;
    AdcRate: Double; // частота работы АЦП, кГц
    InterKadrDelay: Double; // межкадровая задержка, мс
    DataStep: DWORD; // размер выборки
    BlocksToReadCount: Byte; // количество выборок, осуществляемых за одно измерение
    SleepBetweenSetFreqAndDoSampling: Integer; // задержка между установкой частоты генератора и началом измерения, мкс
    DacOutput: Double; // напряжение на выходе ЦАП
    NeedUpdateDacOutput: Boolean;
    FourierAnalysis: Boolean; // метод обработки
    Series: Boolean; // серия измерений
    Resonances: TObjectList<TCurrentMeasureResonanceParameters>; // список резонансов
    CurrentResonance: Integer; // индекс текущего резонанса
    constructor Create;
    destructor Destroy; override;
    procedure AssignFromStartMeasureParameters(AParameters: TStartMeasureParameters); // установить параметры в соответствии с данными команды начала измерения
    procedure AssignFromOngoingMeasureParameters(AParameters: TOngoingMeasureParameters); // установить параметры в соответствии с данными команды установки параметров в ходе измерения
    procedure UpdateCurrentResonanceFromMeasurementResult(AMeasurementResult: TMeasurementResult); // установить параметры из объекта с результатами измерения
  end;

  TMeasurementStateContainer = class // обёртка для объекта с информацией о текущем состоянии процесса измерения
  private
    FChannelsOverFlow: Byte;
    FBufferOverrun: Byte;
    FMaxOfBufferFillingPercent: Integer;
    FMeasureProgressPrecent: Integer;
    FCurrentResonance: Integer;

    FOnUpdated: TOnMeasurementStateUpdatedProcedure;
    function CreateMeasurementState: TMeasurementState;
  public
    constructor Create(AOnUpdated: TOnMeasurementStateUpdatedProcedure);
    procedure Update(ANewState: pDATA_STATE_E2010; const AStep, AStepsCount, ACurrentResonance: Integer);
  end;

  TCalculationData = class // данные для вычисляющего потока и полученная в результате вычисления АЧХ
  private
    FCriticalSection: TCriticalSection;
    FWaitCalculationCompleteEvent: TEvent; // событие, сигнализирующее о завершении вычислений
  public
    CurrentReadIndex: Integer; // индекс элемента, обрабатываемого вычисляющим потоком
    Characteristic: TResonanceMeasurementResult; // результат измерения резонанса
    SamplingFrequencyHz: Double; // частота дискретизации по каналу
    constructor Create;
    destructor Destroy; override;
    procedure SafeInitialze(const ASourceParameters: TCurrentMeasureParameters; const ASamplingFrequencyHz: Double); // потокобезопасная инициализация

    procedure Lock;
    procedure Unlock;

    property WaitCalculationCompleteEvent: TEvent read FWaitCalculationCompleteEvent;
  end;

  TAdcDataBuffer = class // буфер, в который пишется очередная выборка данных с АЦП, и из которого она берётся для вычислений
  private const
    WRITE_WAIT_TIMEOUT = 10000;
  private type
    TAdcDataBufferItem = record // элемент буфера
      Buffers: TInputSignal; // выборка, полученная с АЦП
      EventRead, EventWrite: TEvent; // события, блокирующие потоки на чтение и на запись
    end;
  private
    Items: array [0..1] of TAdcDataBufferItem; // массив из двух элементов буфера
    FReadIdx, FWriteIdx: Byte; // индексы элементов на чтение и на запись
  public
    constructor Create;
    destructor Destroy; override;
    procedure SetBufferSize(const ABufferSize: Integer; const ABlocksCount: Byte); // инициализация буферов
    function GetBufferToWriteWithLock: PInputSignal; // получить указатель на буфер для записи
    procedure UnlockAfterWrite; // разблокировать буфер после записи
    function GetBufferToReadWithLock: PInputSignal; // получить указатель на буфер для чтения
    procedure UnlockAfterRead; // разблокировать буфер после чтения
    procedure SetReadEvents; // разблокировать читающий поток для его остановки
    procedure WaitReadComplete; // дождаться, когда читающий поток завершит вычисления.
  end;

  TAdcDataCalculationsThread = class(TThread) // поток для обработки полученных с АЦП данных
  private
    FBuffer: TAdcDataBuffer; // ссылка на буфер
    FCalculationData: TCalculationData; // ссылка на данные для вычисления
    FOnException: TOnExceptionProcedure;
  protected
    procedure Execute; override;
  public
    constructor Create(ABuffer: TAdcDataBuffer; ACalculationData: TCalculationData; AOnException: TOnExceptionProcedure);
  end;

  TAdcThread = class(TThread) // поток для взаимодействия с модулем АЦП
  private const
    COMMAND_WAIT_TIMEOUT = 10000;
    WAIT_CALCULATION_COMPLETED_TIMEOUT = 30000;
  private
    FPModule: ILE2010; // указатель на интерфейс модуля
    FModuleHandle: THandle; // дескриптор устройства

    FInitialized: Boolean; // признак того, что получен указатель на интерфейс модуля и можно обращаться к устройству
    FConnected: Boolean; // признак того, что устройство подключено
    FMeasuring: Boolean; // признак того, что ведётся измерение
    FCalculationsThread: TAdcDataCalculationsThread; // поток для обработки данных, полученных с АЦП
    FBuffer: TAdcDataBuffer; // буфер для данных, поступающих с АЦП

    FIORequestsOverlapped: array of OVERLAPPED; // массив структур для асинхронного запроса. каждый элемент массива используется в соответствующем элементе массива FIORequests
    FIORequests: array of IO_REQUEST_LUSBAPI; // массив структур для получения данных с АЦП
    FAdcPars: ADC_PARS_E2010; // параметры сбора данных с АЦП
    FDataState: DATA_STATE_E2010; // текущее состояние процесса сбора данных

    FQueryPerformanceFrequency: Int64; // частота счётчика производительности
    FSetCommandCriticalSection: TCriticalSection;
    FWaitCommandResultEvent: TEvent;
    FCurrentCommand: TCommandDataAbstract; // ссылка на обрабатываемую команду
    FCurrentMeasureParams: TCurrentMeasureParameters; // данные текущего процесса измерения
    FCalculationData: TCalculationData; // данные для обработки выборки и первичный результат обработки
    FMeasurementResult: TMeasurementResult; // ссылка на общий объект с результатами измерений
    FMeasurementStateContainer: TMeasurementStateContainer; // обёртка для состояния процесса измерения

    FOnException: TOnExceptionProcedure;
    FOnIterationCompleted: TOnIterationCompletedProcedure;
    FOnMeasureCompleted: TOnMeasureCompletedProcedure;

    procedure GetModuleInterface; // получение указателя на интерфейс модуля
    procedure ReleaseModuleInterface; // освобождение интерфейса модуля
    procedure CreateIORequests(const ACount: Byte); // подготовка структур для получения данных с АЦП
    procedure ClearIORequests; // очистка структур для получения данных с АЦП
    procedure StartCalculationsThread; // запуск потока для обработки полученных с АЦП данных
    procedure StopCalculationsThread; // завершение потока для обработки полученных с АЦП данных
    procedure ConnectAdc; // подключение к АЦП, установка параметров работы
    procedure DisconnectAdc; // завершение взаимодействия с виртуальным слотом, к которому подключён модуль
    procedure TryDisconnectAdc; // попытка завершения взаимодействия без генерации ошибок
    procedure SleepMicroSeconds(const AMicroSeconds: Integer); // задержка, мкс
    procedure SetDacOutput(const AChannel0Volts, AChannel1Volts: Double); // установить напряжение на выходе ЦАП
    procedure SetOutputSignalFreq(const ATuningWord: Cardinal); // установить частоту сигнала на выходе генератора
    procedure WaitingForRequestCompleted(const ARequestIndex: Byte); // ожидание окончания асинхронного запроса
    procedure DoInputSignalSampling; // произвести выборку с АЦП
    procedure StartMeasure(ACommandData: TCommandDataStartMeasure); // обработка команды начала измерения
    procedure StopMeasure(ACommandData: TCommandDataStopMeasure); // обработка команды остановки измерения
    procedure SetMeasureParameters(ACommandData: TCommandDataSetMeasureParameters); // обработка команды установки параметров в процессе измерения
    procedure ProcessCurrentCommand; // обработка команды
    procedure DoMeasureStep; // итерация процесса измерения
    procedure ApplyNewMeasureParameters; // применение параметров, полученных в команде в ходе измерения
  protected
    procedure Execute; override;
  public
    constructor Create(AMeasurementResult: TMeasurementResult; AOnException: TOnExceptionProcedure; AOnIterationCompleted: TOnIterationCompletedProcedure; AOnMeasureCompleted: TOnMeasureCompletedProcedure; AOnMeasurementStateUpdated: TOnMeasurementStateUpdatedProcedure);
    destructor Destroy; override;
    procedure ProcessCommand(ACommandData: TCommandDataAbstract); // обработать команду. синхронный метод, следует вызывать из другого потока.
  end;

  EAdcError = class(Exception);

implementation

function ConvertAdcInputRange(const ARange: TAdcInputRange): Shortint;
begin
  case ARange of
    air3000mV: Result := ADC_INPUT_RANGE_3000mV_E2010;
    air1000mV: Result := ADC_INPUT_RANGE_1000mV_E2010;
    air300mV: Result := ADC_INPUT_RANGE_300mV_E2010;
    else raise Exception.Create('Wrong ADC input range');
  end;
end;

{ TCommandDataStartMeasure }

constructor TCommandDataStartMeasure.Create(const AMeasureParameters: TStartMeasureParameters);
begin
  inherited Create;
  FCommandKind := ckStartMeasure;
  MeasureParameters := AMeasureParameters;
end;

function TCommandDataStartMeasure.CheckCorrectness: Boolean;
var
  LResonance: TResonanceMeasurementParameters;
begin
  Result := False;

  if (MeasureParameters.DataStep < 1) or (MeasureParameters.DataStep > 1024 * 1024) then
    begin
      FailReason := 'Некорректное значение количества передаваемых отсчётов';
      Exit;
    end;

  if not CheckDacOutputCorrectness(MeasureParameters.DacOutput) then
    begin
      FailReason := 'Некорректное значение выходного напряжения';
      Exit;
    end;

  if MeasureParameters.Resonances.Count = 0 then
    begin
      FailReason := 'Не задан ни один резонанс';
      Exit;
    end;

  if not MeasureParameters.Series then
    begin
      if MeasureParameters.Resonances.Count > 1 then
        begin
          FailReason := 'Однократное измерение АЧХ возможно только по одному резонансу';
          Exit;
        end;

      if MeasureParameters.Resonances[0].NeedWatch then
        begin
          FailReason := 'Отслеживание резонанса возможно только при серии измерений';
        end;
    end;

  for LResonance in MeasureParameters.Resonances do
    begin
      if not CheckFrequencyRangeCorrectness(LResonance.ResonantFrequency, LResonance.MinusResonantFrequency, LResonance.PlusResonantFrequency, LResonance.Steps, FailReason) then
        Exit;

      if not CheckDelayCorrectness(LResonance.Delay, FailReason) then
        Exit;

      if (LResonance.MagnitudeMovingAveragePointsCount < 1) or (LResonance.MagnitudeMovingAveragePointsCount > LResonance.Steps + 1) then
        begin
          FailReason := 'Некорректное число точек сглаживания по амплитуде';
          Exit;
        end;

      if (LResonance.PhaseMovingAveragePointsCount < 1) or (LResonance.PhaseMovingAveragePointsCount > LResonance.Steps + 1) then
        begin
          FailReason := 'Некорректное число точек сглаживания по фазе';
          Exit;
        end;

      if (LResonance.PhaseDerivativeMovingAveragePointsCount < 1) or (LResonance.PhaseDerivativeMovingAveragePointsCount > MaxPhaseDerivativeMovingAveragePointsCount(LResonance.Steps + 1, LResonance.PhaseMovingAveragePointsCount)) then
        begin
          FailReason := 'Некорректное число точек сглаживания по производной фазы';
          Exit;
        end;
    end;

  Result := True;
end;

{ TCommandDataStopMeasure }

constructor TCommandDataStopMeasure.Create;
begin
  inherited Create;
  FCommandKind := ckStopMeasure;
end;

function TCommandDataStopMeasure.CheckCorrectness: Boolean;
begin
  Result := True;
end;

{ TCommandDataSetMeasureParameters }

constructor TCommandDataSetMeasureParameters.Create(const AMeasureParameters: TOngoingMeasureParameters);
begin
  inherited Create;
  FCommandKind := ckSetMeasureParameters;
  MeasureParameters := AMeasureParameters;
end;

function TCommandDataSetMeasureParameters.CheckCorrectness: Boolean;
begin
  Result := False;

  if MeasureParameters.NeedUpdateDacOutput then
    if not CheckDacOutputCorrectness(MeasureParameters.DacOutput) then
      begin
        FailReason := 'Некорректное значение выходного напряжения';
        Exit;
      end;

  if MeasureParameters.NeedUpdateDacOutput then
    if (MeasureParameters.DacOutput < 0) or (MeasureParameters.DacOutput > 1.25) then
      begin
        FailReason := 'Некорректное значение выходного напряжения';
        Exit;
      end;

  Result := True;
end;

{ TCurrentMeasureResonanceParameters }

procedure TCurrentMeasureResonanceParameters.FillFreqArrays;
var
  LStartFreqWord, LStopFreqWord: Cardinal;
  i: Integer;
  LStepWord: Double;
begin
  LStartFreqWord := FrequencyHzToTurningWord(StartFrequencyHz);
  LStopFreqWord := FrequencyHzToTurningWord(StopFrequencyHz);
  LStepWord := (LStopFreqWord - LStartFreqWord) / Steps;
  SetLength(FArrayOfFreqWord, Steps + 1);
  for i := 0 to Steps do
    FArrayOfFreqWord[i] := Round(LStartFreqWord + LStepWord * i);
end;

procedure TCurrentMeasureResonanceParameters.AssignFromResonanceMeasurementParameters(AParameters: TResonanceMeasurementParameters);
begin
  StartFrequencyHz := AParameters.ResonantFrequency - AParameters.MinusResonantFrequency;
  StopFrequencyHz := AParameters.ResonantFrequency + AParameters.PlusResonantFrequency;
  MinusResonantFrequency := AParameters.MinusResonantFrequency;
  PlusResonantFrequency := AParameters.PlusResonantFrequency;
  Steps := AParameters.Steps;
  Delay := AParameters.Delay;
  CurrentStep := 0;
  NeedWatch := AParameters.NeedWatch;
  FillFreqArrays;
end;

procedure TCurrentMeasureResonanceParameters.AssignFromResonanceWatchingData(AFrequencyRange: TResonanceWatchingData);
begin
  StartFrequencyHz := AFrequencyRange.ResonantFrequency - AFrequencyRange.MinusFrequency;
  StopFrequencyHz := AFrequencyRange.ResonantFrequency + AFrequencyRange.PlusFrequency;
  MinusResonantFrequency := AFrequencyRange.MinusFrequency;
  PlusResonantFrequency := AFrequencyRange.PlusFrequency;
  Steps := AFrequencyRange.Steps;
  Delay := AFrequencyRange.Delay;
  NeedWatch := AFrequencyRange.NeedWatch;

  if StartFrequencyHz < 0 then StartFrequencyHz := 0;
  if StartFrequencyHz > DDS_REF_FREQ then StartFrequencyHz := DDS_REF_FREQ;
  if StopFrequencyHz < 0 then StopFrequencyHz := 0;
  if StopFrequencyHz > DDS_REF_FREQ then StopFrequencyHz := DDS_REF_FREQ;
  if Steps < 2 then Steps := 2;

  FillFreqArrays;
end;

function TCurrentMeasureResonanceParameters.FrequencyWordOfCurrentStep: Cardinal;
begin
  Result := FArrayOfFreqWord[CurrentStep];
end;

function TCurrentMeasureResonanceParameters.FrequencyHzOfStep(const AStep: Integer): Double;
begin
  if (AStep < 0) or (AStep >= Length(FArrayOfFreqWord)) then
    raise Exception.Create('FrequencyOfStep: step out of range');

  Result := TurningWordToFrequencyHz(FArrayOfFreqWord[AStep]);
end;

{ TCurrentMeasureParameters }

procedure TCurrentMeasureParameters.Reset;
begin
  Resonances.Clear;
  CurrentResonance := 0;
end;

constructor TCurrentMeasureParameters.Create;
var
  i: Integer;
begin
  Resonances := TObjectList<TCurrentMeasureResonanceParameters>.Create;
  ChannelsQuantity := 2;
  for i := 0 to Length(ChannelsInputRange) do
    ChannelsInputRange[i] := air3000mV;
  AdcRate := 10000.0;
  InterKadrDelay := 0.0;
  DataStep := 1024 * 1024;
  BlocksToReadCount := 1;
  SleepBetweenSetFreqAndDoSampling := 100;
end;

destructor TCurrentMeasureParameters.Destroy;
begin
  Resonances.Free;
  inherited Destroy;
end;

procedure TCurrentMeasureParameters.AssignFromStartMeasureParameters(AParameters: TStartMeasureParameters);
var
  LSourceResonanceParams: TResonanceMeasurementParameters;
  LTargetResonanceParams: TCurrentMeasureResonanceParameters;
begin
  Reset;

  ChannelsInputRange[0] := aParameters.InputSignalChannelRange;
  ChannelsInputRange[1] := aParameters.OutputSignalChannelRange;
  DataStep := aParameters.DataStep;
  BlocksToReadCount := aParameters.BlocksToReadCount;
  SleepBetweenSetFreqAndDoSampling := aParameters.SleepBetweenSetFreqAndDoSampling;
  DacOutput := aParameters.DacOutput;
  FourierAnalysis := aParameters.FourierAnalysis;
  Series := aParameters.Series;
  for LSourceResonanceParams in aParameters.Resonances do
    begin
      LTargetResonanceParams := TCurrentMeasureResonanceParameters.Create;
      LTargetResonanceParams.AssignFromResonanceMeasurementParameters(LSourceResonanceParams);
      Resonances.Add(LTargetResonanceParams);
    end;
end;

procedure TCurrentMeasureParameters.AssignFromOngoingMeasureParameters(AParameters: TOngoingMeasureParameters);
begin
  if AParameters.NeedUpdateChannelsRange then
    begin
      ChannelsInputRange[0] := aParameters.InputSignalChannelRange;
      ChannelsInputRange[1] := aParameters.OutputSignalChannelRange;
      NeedUpdateChannelsInputRange := True;
    end;
  if AParameters.NeedUpdateDacOutput then
    begin
      DacOutput := aParameters.DacOutput;
      NeedUpdateDacOutput := True;
    end;
end;

procedure TCurrentMeasureParameters.UpdateCurrentResonanceFromMeasurementResult(AMeasurementResult: TMeasurementResult);
var
  LFrequencyRange: TResonanceWatchingData;
begin
  LFrequencyRange := AMeasurementResult.GetFrequencyRange(CurrentResonance);
  Resonances[CurrentResonance].AssignFromResonanceWatchingData(LFrequencyRange);
end;

{ TMeasurementStateContainer }

function TMeasurementStateContainer.CreateMeasurementState: TMeasurementState;
begin
  Result := TMeasurementState.Create;
  Result.InputChannelOverflow := (FChannelsOverFlow and 1) <> 0;
  Result.OutputChannelOverflow := (FChannelsOverFlow and 2) <> 0;
  Result.BufferOverrun := FBufferOverrun <> 0;
  Result.MaxOfBufferFillingPercent := FMaxOfBufferFillingPercent;
  Result.MeasureProgressPrecent := FMeasureProgressPrecent;
  Result.CurrentResonance := FCurrentResonance;
end;

constructor TMeasurementStateContainer.Create(AOnUpdated: TOnMeasurementStateUpdatedProcedure);
begin
  FOnUpdated := AOnUpdated;
end;

procedure TMeasurementStateContainer.Update(ANewState: pDATA_STATE_E2010; const AStep, AStepsCount, ACurrentResonance: Integer);
var
  LStateChanged: Boolean;
  LNewMaxOfBufferFillingPercent, LNewMeasureProgressPrecent: Integer;
begin
  LStateChanged := False;
  if FChannelsOverFlow <> ANewState^.ChannelsOverFlow then
    begin
      FChannelsOverFlow := ANewState^.ChannelsOverFlow;
      LStateChanged := True;
    end;
  if FBufferOverrun <> ANewState^.BufferOverrun then
    begin
      FBufferOverrun := ANewState^.BufferOverrun;
      LStateChanged := True;
    end;
  LNewMaxOfBufferFillingPercent := Round(ANewState^.MaxOfBufferFillingPercent);
  if FMaxOfBufferFillingPercent <> LNewMaxOfBufferFillingPercent then
    begin
      FMaxOfBufferFillingPercent := LNewMaxOfBufferFillingPercent;
      LStateChanged := True;
    end;
  LNewMeasureProgressPrecent := Round(100.0 * AStep / AStepsCount);
  if FMeasureProgressPrecent <> LNewMeasureProgressPrecent then
    begin
      FMeasureProgressPrecent := LNewMeasureProgressPrecent;
      LStateChanged := True;
    end;
  if FCurrentResonance <> ACurrentResonance then
    begin
      FCurrentResonance := ACurrentResonance;
      LStateChanged := True;
    end;

  if LStateChanged then
    if Assigned(FOnUpdated) then
      FOnUpdated(CreateMeasurementState);
end;

{ TCalculationData }

constructor TCalculationData.Create;
begin
  FCriticalSection := TCriticalSection.Create;
  FWaitCalculationCompleteEvent := TEvent.Create;
  Characteristic := TResonanceMeasurementResult.Create;
end;

destructor TCalculationData.Destroy;
begin
  Characteristic.Free;
  FWaitCalculationCompleteEvent.Free;
  FCriticalSection.Free;
  inherited Destroy;
end;

procedure TCalculationData.SafeInitialze(const ASourceParameters: TCurrentMeasureParameters; const ASamplingFrequencyHz: Double);
var
  LResonance: TCurrentMeasureResonanceParameters;
  i: Integer;
begin
  Lock;
  try
    CurrentReadIndex := 0;
    LResonance := ASourceParameters.Resonances[ASourceParameters.CurrentResonance];
    Characteristic.Initialize(ASourceParameters.CurrentResonance, LResonance.Steps + 1, ASourceParameters.FourierAnalysis,
        ASourceParameters.ChannelsInputRange[1], ASourceParameters.ChannelsInputRange[0]);
    for i := 0 to Characteristic.ArraysLength - 1 do
      Characteristic.FrequencyHz[i] := LResonance.FrequencyHzOfStep(i);
    SamplingFrequencyHz := ASamplingFrequencyHz;
    Characteristic.StartTime := Now;
    WaitCalculationCompleteEvent.ResetEvent;
  finally
    Unlock;
  end;
end;

procedure TCalculationData.Lock;
begin
  FCriticalSection.Enter;
end;

procedure TCalculationData.Unlock;
begin
  FCriticalSection.Leave;
end;

{ TAdcDataBuffer }

constructor TAdcDataBuffer.Create;
var
  i: Byte;
begin
  for i := 0 to 1 do
    begin
      Items[i].EventRead := TEvent.Create;
      Items[i].EventWrite := TEvent.Create;
      Items[i].EventRead.ResetEvent;
      Items[i].EventWrite.SetEvent;
    end;
end;

destructor TAdcDataBuffer.Destroy;
var
  i: Byte;
  j: Integer;
begin
  for i := 0 to 1 do
    begin
      Items[i].EventRead.Free;
      Items[i].EventWrite.Free;
      for j := 0 to Length(Items[i].Buffers) - 1 do
        Finalize(Items[i].Buffers[j]);
      Finalize(Items[i].Buffers);
    end;
  inherited Destroy;
end;

procedure TAdcDataBuffer.SetBufferSize(const ABufferSize: Integer; const ABlocksCount: Byte);
var
  i: Byte;
  j: Integer;
begin
  for i := 0 to 1 do
    begin
      SetLength(Items[i].Buffers, ABlocksCount);
      for j := 0 to ABlocksCount - 1 do
        begin
          SetLength(Items[i].Buffers[j], ABufferSize);
          ZeroMemory(Items[i].Buffers[j], ABufferSize * SizeOf(SHORT));
        end;
    end;
end;

function TAdcDataBuffer.GetBufferToWriteWithLock: PInputSignal;
begin
  if Items[FWriteIdx].EventWrite.WaitFor(WRITE_WAIT_TIMEOUT) <> wrSignaled then
    raise Exception.Create('AdcDataBuffer EventWrite wait fail');
  Result := @(Items[FWriteIdx].Buffers);
end;

procedure TAdcDataBuffer.UnlockAfterWrite;
begin
  Items[FWriteIdx].EventWrite.ResetEvent;
  Items[FWriteIdx].EventRead.SetEvent;
  FWriteIdx := FWriteIdx xor 1;
end;

function TAdcDataBuffer.GetBufferToReadWithLock: PInputSignal;
begin
  while True do
    case Items[FReadIdx].EventRead.WaitFor of
      wrSignaled: Break;
      wrTimeout: ;
      else raise Exception.Create('AdcDataBuffer EventRead wait fail');
    end;
  Result := @(Items[FReadIdx].Buffers);
end;

procedure TAdcDataBuffer.UnlockAfterRead;
begin
  Items[FReadIdx].EventRead.ResetEvent;
  Items[FReadIdx].EventWrite.SetEvent;
  FReadIdx := FReadIdx xor 1;
end;

procedure TAdcDataBuffer.SetReadEvents;
var
  i: Byte;
begin
  for i := 0 to 1 do
    Items[i].EventRead.SetEvent;
end;

procedure TAdcDataBuffer.WaitReadComplete;
begin
  if Items[FWriteIdx xor 1].EventWrite.WaitFor(WRITE_WAIT_TIMEOUT) <> wrSignaled then
    raise Exception.Create('AdcDataBuffer EventWrite wait fail');
end;

{ TAdcDataCalculationsThread }

procedure TAdcDataCalculationsThread.Execute;
var
  LBuffers: TInputSignal;
  LStandartDeviationResult: TStandartDeviationResult;
  LFourierTransformResult: TFourierTransformResult;
begin
  try
    while not Terminated do
      begin
        LBuffers := FBuffer.GetBufferToReadWithLock^;
        try
          if Terminated then
            Break;
          FCalculationData.Lock;
          try
            if FCalculationData.CurrentReadIndex >= FCalculationData.Characteristic.ArraysLength then
              raise Exception.Create('Calculation array out of range');

            if FCalculationData.Characteristic.FourierAnalysis then
              begin
                LStandartDeviationResult := CalculateStandartDeviation(LBuffers, FCalculationData.Characteristic.OutputSignalChannelRange, FCalculationData.Characteristic.InputSignalChannelRange);
                with FCalculationData.Characteristic do
                  begin
                    InputAverage[FCalculationData.CurrentReadIndex] := LStandartDeviationResult.InputAverage;
                    OutputAverage[FCalculationData.CurrentReadIndex] := LStandartDeviationResult.OutputAverage;
                  end;
                LFourierTransformResult := CalculateFourierTransform(LBuffers, FCalculationData.Characteristic.OutputSignalChannelRange, FCalculationData.Characteristic.InputSignalChannelRange,
                    FCalculationData.Characteristic.FrequencyHz[FCalculationData.CurrentReadIndex], FCalculationData.SamplingFrequencyHz);
                with FCalculationData.Characteristic do
                  begin
                    Magnitude[FCalculationData.CurrentReadIndex] := LFourierTransformResult.Magnitude;
                    Phase[FCalculationData.CurrentReadIndex] := LFourierTransformResult.Phase;
                  end;
              end

            else
              begin
                LStandartDeviationResult := CalculateStandartDeviation(LBuffers, FCalculationData.Characteristic.OutputSignalChannelRange, FCalculationData.Characteristic.InputSignalChannelRange);
                with FCalculationData.Characteristic do
                  begin
                    InputAverage[FCalculationData.CurrentReadIndex] := LStandartDeviationResult.InputAverage;
                    OutputAverage[FCalculationData.CurrentReadIndex] := LStandartDeviationResult.OutputAverage;
                    Magnitude[FCalculationData.CurrentReadIndex] := LStandartDeviationResult.Magnitude;
                  end;
              end;

            Inc(FCalculationData.CurrentReadIndex);
            if FCalculationData.CurrentReadIndex = FCalculationData.Characteristic.ArraysLength then
              FCalculationData.WaitCalculationCompleteEvent.SetEvent;
          finally
            FCalculationData.Unlock;
          end;
        finally
          FBuffer.UnlockAfterRead;
        end;
      end;
  except
    on E: Exception do
      begin
        if Assigned(FOnException) then
          FOnException('CalculationsThread fatal exception: ' + E.Message);
      end;
  end;
end;

constructor TAdcDataCalculationsThread.Create(ABuffer: TAdcDataBuffer; ACalculationData: TCalculationData; AOnException: TOnExceptionProcedure);
begin
  FBuffer := ABuffer;
  FCalculationData := ACalculationData;
  FOnException := AOnException;
  inherited Create;
end;

{ TADCThread }

procedure TAdcThread.GetModuleInterface;
begin
  // Проверить, что установлена нужная библиотека Lusbapi
  if GetDllVersion() <> CURRENT_VERSION_LUSBAPI then
    raise EAdcError.Create('Библиотека Lusbapi не установлена или имеет неподходящую версию');

  // Получить указатель на интерфейс модуля
  FPModule := CreateLInstance(PAnsiChar('e2010'));
  if FPModule = nil then
    raise EAdcError.Create('Неуспешный вызов метода CreateLInstance');

  FInitialized := True;
end;

procedure TAdcThread.ReleaseModuleInterface;
begin
  FInitialized := False;

  if FPModule <> nil then
    begin
      // Завершить работу с интерфейсом модуля
      FPModule.ReleaseLInstance;
      FPModule := nil;
    end;
end;

procedure TAdcThread.CreateIORequests(const ACount: Byte);
var
  i: Integer;
begin
  ClearIORequests;
  SetLength(FIORequestsOverlapped, ACount);
  SetLength(FIORequests, ACount);
  for i := 0 to ACount - 1 do
    begin
      // инициализация структуры типа OVERLAPPED
      ZeroMemory(@FIORequestsOverlapped[i], SizeOf(OVERLAPPED));
      // создаём событие для асинхронного запроса
      FIORequestsOverlapped[i].hEvent := CreateEvent(nil, False, False, nil);
      // формируем структуру IoReq
      FIORequests[i].Buffer := nil;
      FIORequests[i].NumberOfWordsToPass := FCurrentMeasureParams.DataStep;
      FIORequests[i].NumberOfWordsPassed := 0;
      FIORequests[i].Overlapped := @FIORequestsOverlapped[i];
      FIORequests[i].TimeOut := Round(FCurrentMeasureParams.DataStep / FAdcPars.KadrRate) + 1000;
    end;
end;

procedure TAdcThread.ClearIORequests;
var
  i: Integer;
begin
  for i := 0 to Length(FIORequestsOverlapped) - 1 do
    CloseHandle(FIORequestsOverlapped[i].hEvent);
  SetLength(FIORequestsOverlapped, 0);
  SetLength(FIORequests, 0);
end;

procedure TAdcThread.StartCalculationsThread;
begin
  FCalculationsThread := TAdcDataCalculationsThread.Create(FBuffer, FCalculationData, FOnException);
end;

procedure TAdcThread.StopCalculationsThread;
begin
  FCalculationsThread.Terminate;
  FBuffer.SetReadEvents;
  FCalculationsThread.WaitFor;
  FreeAndNil(FCalculationsThread);
end;

procedure TAdcThread.ConnectAdc;
const
  E2010_MODULE_NAME: AnsiString = 'E20-10';
var
  i, j: Integer;
  LModuleFound: Boolean;
  LModuleName: array [0..6] of AnsiChar;
  LUsbSpeed: Byte;
  LModuleDescription: MODULE_DESCRIPTION_E2010;
begin
  // попробуем обнаружить модуль E20-10 в первых MAX_VIRTUAL_SLOTS_QUANTITY_LUSBAPI виртуальных слотах
  LModuleFound := False;
	for i := 0 to (MAX_VIRTUAL_SLOTS_QUANTITY_LUSBAPI - 1) do
    if FPModule.OpenLDevice(i) then
      begin
        LModuleFound := True;
        Break;
      end;

	// что-нибудь обнаружили?
	if not LModuleFound then
    raise EAdcError.Create('Не удалось обнаружить модуль E20-10 в первых 127 виртуальных слотах!');

	// получим идентификатор устройства
	FModuleHandle := FPModule.GetModuleHandle();

	// прочитаем название модуля в текущем виртуальном слоте
	if not FPModule.GetModuleName(@LModuleName[0]) then
    raise EAdcError.Create('Не могу прочитать название модуля!');

	// проверим, что это модуль E20-10
	for i := 1 to Length(E2010_MODULE_NAME) do
    if E2010_MODULE_NAME[i] <> LModuleName[i - 1] then
      raise EAdcError.Create('Обнаруженный модуль не является E20-10!');

	// попробуем получить скорость работы шины USB
	if not FPModule.GetUsbSpeed(@LUsbSpeed) then
    raise EAdcError.Create('Не могу определить скорость работы шины USB');

	// теперь отобразим скорость работы шины USB
	if LUsbSpeed <> USB20_LUSBAPI then
    raise EAdcError.Create('Режим работы USB отличен от High-Speed Mode (480 Mbit/s)');

	// Образ для ПЛИС возьмём из соответствующего ресурса DLL библиотеки Lusbapi.dll
	if not FPModule.LOAD_MODULE(nil) then
    raise EAdcError.Create('Не могу загрузить модуль E20-10!');

	// проверим загрузку модуля
 	if not FPModule.TEST_MODULE() then
    raise EAdcError.Create('Ошибка в загрузке модуля E20-10!');

	// теперь получим номер версии загруженного драйвера DSP
	if not FPModule.GET_MODULE_DESCRIPTION(@LModuleDescription) then
    raise EAdcError.Create('Не могу получить информацию о модуле!');

  if LModuleDescription.Dac.Active = BOOL(DAC_INACCESSIBLED_E2010) then
    raise EAdcError.Create('ЦАП недоступен!');

	// получим текущие параметры работы ввода данных
	if not FPModule.GET_ADC_PARS(@FAdcPars) then
    raise EAdcError.Create('Не могу получить текущие параметры ввода данных!');

	// установим желаемые параметры ввода данных с модуля E20-10
	if LModuleDescription.Module.Revision = BYTE(REVISIONS_E2010[REVISION_A_E2010]) then
		FAdcPars.IsAdcCorrectionEnabled := False// запретим автоматическую корректировку данных на уровне модуля (для Rev.A)
	else
		begin
			FAdcPars.IsAdcCorrectionEnabled := True; // разрешим автоматическую корректировку данных на уровне модуля (для Rev.B и выше)
			FAdcPars.SynchroPars.StartDelay := 0;
			FAdcPars.SynchroPars.StopAfterNKadrs := 0;
			FAdcPars.SynchroPars.SynchroAdMode := NO_ANALOG_SYNCHRO_E2010;
			FAdcPars.SynchroPars.SynchroAdChannel := $0;
			FAdcPars.SynchroPars.SynchroAdPorog := 0;
			FAdcPars.SynchroPars.IsBlockDataMarkerEnabled := $0;
		end;
	FAdcPars.SynchroPars.StartSource := INT_ADC_START_E2010; // внутренний старт сбора с АЦП
	FAdcPars.SynchroPars.SynhroSource := INT_ADC_CLOCK_E2010; // внутренние тактовые импульсы АЦП
	FAdcPars.OverloadMode := CLIPPING_OVERLOAD_E2010; // обычная фиксация факта перегрузки входных каналов путём ограничения отсчёта АЦП (только для Rev.A)
	FAdcPars.ChannelsQuantity := FCurrentMeasureParams.ChannelsQuantity; // кол-во активных каналов
	for i:=0 to (FAdcPars.ChannelsQuantity - 1) do
    FAdcPars.ControlTable[i] := i;
	FAdcPars.AdcRate := FCurrentMeasureParams.AdcRate; // частота АЦП данных в кГц
  FAdcPars.InterKadrDelay := FCurrentMeasureParams.InterKadrDelay; // межкадровая задержка в мс
	// конфигурим входные каналы
	for i := 0 to (ADC_CHANNELS_QUANTITY_E2010 - 1) do
		begin
			FAdcPars.InputRange[i] := ConvertAdcInputRange(FCurrentMeasureParams.ChannelsInputRange[i]); // входной диапазон
			FAdcPars.InputSwitch[i] := ADC_INPUT_SIGNAL_E2010; // источник входа - сигнал
		end;
	// передаём в структуру параметров работы АЦП корректировочные коэффициенты АЦП
	for i := 0 to (ADC_INPUT_RANGES_QUANTITY_E2010 - 1) do
		for j := 0 to (ADC_CHANNELS_QUANTITY_E2010 - 1) do
      begin
        // корректировка смещения
        FAdcPars.AdcOffsetCoefs[i][j] := LModuleDescription.Adc.OffsetCalibration[j + i * ADC_CHANNELS_QUANTITY_E2010];
        // корректировка масштаба
        FAdcPars.AdcScaleCoefs[i][j] := LModuleDescription.Adc.ScaleCalibration[j + i * ADC_CHANNELS_QUANTITY_E2010];
      end;

	// передадим в модуль требуемые параметры по вводу данных
	if not FPModule.SET_ADC_PARS(@FAdcPars) then
    raise EAdcError.Create('Не могу установить параметры ввода данных!');

  FConnected := True;
end;

procedure TAdcThread.DisconnectAdc;
begin
  if not FPModule.CloseLDevice then
    raise EAdcError.Create('Не удалось завершить доступ к модулю');

  FConnected := False;
end;

procedure TAdcThread.TryDisconnectAdc;
begin
  try
    DisconnectAdc;
  except
    on E: EAdcError do
      begin
        if Assigned(FOnException) then
          FOnException(E.Message);
      end;
  end;
end;

procedure TAdcThread.SleepMicroSeconds(const AMicroSeconds: Integer);
var
  LStart, LStop, LDelta: Int64;
  LExpectedInterval: Integer;
  i: Word;
begin
  QueryPerformanceCounter(LStart);
  LExpectedInterval := Round((AMicroSeconds * FQueryPerformanceFrequency) / 1e6);
  repeat
    i := 0;
    while i < 65535 do
      Inc(i);
    QueryPerformanceCounter(LStop);
    if LStop < LStart then
      LDelta := LStop - (LStart - High(Int64))
    else
      LDelta := LStop - LStart;
  until LDelta >= LExpectedInterval;
end;

procedure TAdcThread.SetDacOutput(const AChannel0Volts, AChannel1Volts: Double);
var
  LDacSample0, LDacSample1: SHORT;
begin
  LDacSample0 := Round(2048 * AChannel0Volts / 5.0);
  if LDacSample0 > 2047 then LDacSample0 := 2047;
  if LDacSample0 < -2048 then LDacSample0 := -2048;
  LDacSample1 := Round(2048 * AChannel1Volts / 5.0);
  if LDacSample1 > 2047 then LDacSample1 := 2047;
  if LDacSample1 < -2048 then LDacSample1 := -2048;
  if not FPModule.DAC_SAMPLE(@LDacSample0, 0) then
    raise EAdcError.Create('DAC_SAMPLE(0, ) failed');
  if not FPModule.DAC_SAMPLE(@LDacSample1, 1) then
    raise EAdcError.Create('DAC_SAMPLE(1, ) failed');
end;

procedure TAdcThread.SetOutputSignalFreq(const ATuningWord: Cardinal);
var
  LTuningWord: Cardinal;
  LTtlOut: Word;
begin
  LTuningWord := ATuningWord;

  FPModule.ENABLE_TTL_OUT(true);
  LTtlOut := 0;

  FPModule.TTL_OUT(1024);
  SleepMicroSeconds(10);
  FPModule.TTL_OUT(0);
  SleepMicroSeconds(10);

  FPModule.TTL_OUT(LTtlOut);
  SleepMicroSeconds(10);
  FPModule.TTL_OUT(LTtlOut + 512);
  SleepMicroSeconds(10);

  LTtlOut := ((LTuningWord and 4278190080) shr 24);
  FPModule.TTL_OUT(LTtlOut);
  SleepMicroSeconds(10);
  FPModule.TTL_OUT(LTtlOut + 512);
  SleepMicroSeconds(10);

  LTuningWord := LTuningWord - ((LTuningWord and 4278190080));
  LTtlOut := ((LTuningWord and 16711680) shr 16);
  FPModule.TTL_OUT(LTtlOut);
  SleepMicroSeconds(10);
  FPModule.TTL_OUT(LTtlOut + 512);
  SleepMicroSeconds(10);

  LTuningWord := LTuningWord - ((LTuningWord and 16711680));
  LTtlOut := ((LTuningWord and 65280) shr 8);
  FPModule.TTL_OUT(LTtlOut);
  SleepMicroSeconds(10);
  FPModule.TTL_OUT(LTtlOut + 512);
  SleepMicroSeconds(10);

  LTuningWord := LTuningWord - ((LTuningWord and 65280));
  LTtlOut := (LTuningWord);
  FPModule.TTL_OUT(LTtlOut);
  SleepMicroSeconds(10);
  FPModule.TTL_OUT(LTtlOut + 512);
  SleepMicroSeconds(10);

  FPModule.TTL_OUT(1024);
  SleepMicroSeconds(10);
  FPModule.TTL_OUT(0);
  SleepMicroSeconds(10);
end;

procedure TAdcThread.WaitingForRequestCompleted(const ARequestIndex: Byte);
var
  LBytesTransferred: DWORD;
begin
  LBytesTransferred := 0;
  if not GetOverlappedResult(FModuleHandle, FIORequestsOverlapped[ARequestIndex], LBytesTransferred, True) then
    if GetLastError = WAIT_TIMEOUT then
      raise EAdcError.Create('WaitingForRequestCompleted timeout')
    else
      raise EAdcError.Create('GetOverlappedResult failed: ' + IntToStr(GetLastError));
end;

procedure TAdcThread.DoInputSignalSampling;
var
  LBuffers: TInputSignal;
  i: Integer;
begin
  // остановим работу АЦП и одновременно сбросим USB-канал чтения данных
  if not FPModule.STOP_ADC() then
    raise EAdcError.Create('STOP_ADC failed');

  // готовим необходимые для сбора данных структуры
  LBuffers := FBuffer.GetBufferToWriteWithLock^;
  try
    FIORequests[0].Buffer := Pointer(LBuffers[0]);

    // заранее закажем первый асинхронный сбор данных в Buffer
    if not FPModule.ReadData(@(FIORequests[0])) then
      raise EAdcError.Create('ReadData failed');

    try
      // а теперь можно запускать сбор данных
      if not FPModule.START_ADC() then
        raise EAdcError.Create('START_ADC failed');

      try
        // цикл сбора данных
        for i := 1 to FCurrentMeasureParams.BlocksToReadCount - 1 do
          begin
            FIORequests[i].Buffer := Pointer(LBuffers[i]);

            // сделаем запрос на очередную порции вводимых данных
            if not FPModule.ReadData(@(FIORequests[i])) then
              raise EAdcError.Create('ReadData failed');
            // ожидание выполнение очередного запроса на сбор данных
            if not WaitForSingleObject(FIORequestsOverlapped[i].hEvent, FIORequests[i].TimeOut) = WAIT_TIMEOUT then
              raise EAdcError.Create('Wait timeout');
            // попробуем получить текущее состояние процесса сбора данных
            if not FPModule.GET_DATA_STATE(@FDataState) then
              raise EAdcError.Create('GET_DATA_STATE failed');
            // теперь можно проверить этот признак переполнения внутреннего буфера модуля
            if (FDataState.BufferOverrun = (1 shl BUFFER_OVERRUN_E2010)) then
              raise EAdcError.Create('Buffer overrun');
          end;
        // ждём окончания операции сбора последней порции данных
        WaitingForRequestCompleted(FCurrentMeasureParams.BlocksToReadCount - 1);
      finally
        // остановим сбор данных c АЦП
        if not FPModule.STOP_ADC() then
          raise EAdcError.Create('STOP_ADC failed');
      end;

      // если нужно - анализируем окончательный признак переполнения внутреннего буфера модуля
      if (FDataState.BufferOverrun <> (1 shl BUFFER_OVERRUN_E2010)) then
        begin
          // попробуем получить окончательное состояние процесса сбора данных
          if not FPModule.GET_DATA_STATE(@FDataState) then
            raise EAdcError.Create('GET_DATA_STATE failed');
          // теперь можно проверить этот признак переполнения внутреннего буфера модуля
          if (FDataState.BufferOverrun = (1 shl BUFFER_OVERRUN_E2010)) then
            raise EAdcError.Create('Buffer overrun');
        end;

    finally
      // если надо, то прервём все незавершённые асинхронные запросы
      if not CancelIo(FModuleHandle) then
        raise EAdcError.Create('CancelIo failed');
    end;

  finally
    FBuffer.UnlockAfterWrite;
  end;
end;

procedure TAdcThread.StartMeasure(ACommandData: TCommandDataStartMeasure);
begin
  if FMeasuring then
    begin
      ACommandData.FailReason := 'Измерение уже идёт';
      Exit;
    end;

  FCurrentMeasureParams.AssignFromStartMeasureParameters(ACommandData.MeasureParameters); // инициализация параметров измерения

  try
    ConnectAdc;
  except
    on E: EAdcError do
      begin
        TryDisconnectAdc;
        ACommandData.FailReason := E.Message;
        Exit;
      end;
  end;

  SetDacOutput(0, FCurrentMeasureParams.DacOutput);
  SetOutputSignalFreq(FCurrentMeasureParams.Resonances[0].FrequencyWordOfCurrentStep);
  FBuffer.WaitReadComplete; // ожидание вычисляющего потока
  FBuffer.SetBufferSize(FCurrentMeasureParams.DataStep, FCurrentMeasureParams.BlocksToReadCount); // инициализация буфера
  FCalculationData.SafeInitialze(FCurrentMeasureParams, 1000.0 * FAdcPars.KadrRate); // инициализация данных для вычисляющего потока
  FMeasurementResult.Initialize(ACommandData.MeasureParameters, FCurrentMeasureParams.ChannelsInputRange[1], FCurrentMeasureParams.ChannelsInputRange[0]); // инициализация общего объекта с результатом измерения
  CreateIORequests(FCurrentMeasureParams.BlocksToReadCount); // подготовка структур для получения данных с АЦП
  FMeasuring := True; // процесс измерения пошёл

  ACommandData.SuccessResult := True;
end;

procedure TAdcThread.StopMeasure(ACommandData: TCommandDataStopMeasure);
begin
  if not FMeasuring then
    begin
      ACommandData.FailReason := 'Измерение не идёт';
      Exit;
    end;

  FMeasuring := False;
  try
    DisconnectAdc;
  except
    on E: EAdcError do
      begin
        ACommandData.FailReason := E.Message;
        Exit;
      end;
  end;

  ACommandData.SuccessResult := True;
end;

procedure TAdcThread.SetMeasureParameters(ACommandData: TCommandDataSetMeasureParameters);
begin
  if not FMeasuring then
    begin
      ACommandData.FailReason := 'Измерение не идёт';
      Exit;
    end;

  FCurrentMeasureParams.AssignFromOngoingMeasureParameters(ACommandData.MeasureParameters); // обновление параметров измерения

  ACommandData.SuccessResult := True;
end;

procedure TAdcThread.ProcessCurrentCommand;
begin
  FSetCommandCriticalSection.Enter;
  try
    if FCurrentCommand <> nil then
      begin
        FCurrentCommand.SuccessResult := False;
        if not FCurrentCommand.CheckCorrectness then
          Exit;
        case FCurrentCommand.Kind of
          ckStartMeasure: StartMeasure(TCommandDataStartMeasure(FCurrentCommand));
          ckStopMeasure: StopMeasure(TCommandDataStopMeasure(FCurrentCommand));
          ckSetMeasureParameters: SetMeasureParameters(TCommandDataSetMeasureParameters(FCurrentCommand));
          else FCurrentCommand.FailReason := 'Неизвестная команда';
        end;
      end;
  finally
    FCurrentCommand := nil;
    FWaitCommandResultEvent.SetEvent;
    FSetCommandCriticalSection.Leave;
  end;
end;

procedure TAdcThread.DoMeasureStep;
var
  LIterationCompleted, LMeasureCompleted: Boolean;
  LCurrentResonance: TCurrentMeasureResonanceParameters;
begin
  try
    LCurrentResonance := FCurrentMeasureParams.Resonances[FCurrentMeasureParams.CurrentResonance];
    SetOutputSignalFreq(LCurrentResonance.FrequencyWordOfCurrentStep); // установка очередной частоты на выходе генератора
    if LCurrentResonance.CurrentStep = 0 then
      SleepMicroSeconds(1000 * LCurrentResonance.Delay + FCurrentMeasureParams.SleepBetweenSetFreqAndDoSampling) // задержка для установления переходного процесса
    else
      SleepMicroSeconds(FCurrentMeasureParams.SleepBetweenSetFreqAndDoSampling); // задержка для установления переходного процесса
    DoInputSignalSampling; // выборка входного сигнала
    FMeasurementStateContainer.Update(@FDataState, LCurrentResonance.CurrentStep, LCurrentResonance.Steps, FCurrentMeasureParams.CurrentResonance); // обновление данных о процессе измерения

    // обработка завершения итерации либо измерения
    LIterationCompleted := False;
    LMeasureCompleted := False;
    if LCurrentResonance.CurrentStep >= LCurrentResonance.Steps then
      if FCurrentMeasureParams.Series then
        LIterationCompleted := True
      else
        LMeasureCompleted := True;

    if LIterationCompleted or LMeasureCompleted then
      begin
        if FCalculationData.WaitCalculationCompleteEvent.WaitFor(WAIT_CALCULATION_COMPLETED_TIMEOUT) <> wrSignaled then // ожидание завершения вычислений
          raise Exception.Create('Wait calculation complete timeout');

        FCalculationData.Lock;
        try
          FCalculationData.Characteristic.StopTime := Now;
          FMeasurementResult.AssignResonanceResult(FCurrentMeasureParams.CurrentResonance, FCalculationData.Characteristic);
        finally
          FCalculationData.Unlock;
        end;

        if LMeasureCompleted then
          begin
            FMeasuring := False;
            if Assigned(FOnMeasureCompleted) then
              FOnMeasureCompleted;
          end
        else if LIterationCompleted then
          begin
            if Assigned(FOnIterationCompleted) then
              FOnIterationCompleted(FCurrentMeasureParams.CurrentResonance);
          end;
      end;

    // обновление данных процесса измерения после очередной итерации
    if not LMeasureCompleted then
      begin
        if LIterationCompleted then
          begin
            LCurrentResonance.CurrentStep := 0;
            Inc(FCurrentMeasureParams.CurrentResonance);
            if FCurrentMeasureParams.CurrentResonance >= FCurrentMeasureParams.Resonances.Count then
              FCurrentMeasureParams.CurrentResonance := 0;
            FCurrentMeasureParams.UpdateCurrentResonanceFromMeasurementResult(FMeasurementResult);
            FCalculationData.SafeInitialze(FCurrentMeasureParams, 1000.0 * FAdcPars.KadrRate);
            ApplyNewMeasureParameters;
          end
        else
          Inc(LCurrentResonance.CurrentStep);
      end;
  except
    on E: EAdcError do
      begin
        FMeasuring := False;
        if Assigned(FOnException) then
          FOnException(E.Message);
      end;
  end;
end;

procedure TAdcThread.ApplyNewMeasureParameters;
var
  i: Integer;
begin
  if FCurrentMeasureParams.NeedUpdateChannelsInputRange then
    begin
      // конфигурим входные каналы
      for i := 0 to (ADC_CHANNELS_QUANTITY_E2010 - 1) do
        FAdcPars.InputRange[i] := ConvertAdcInputRange(FCurrentMeasureParams.ChannelsInputRange[i]); // входной диапазон

      // передадим в модуль требуемые параметры по вводу данных
      if not FPModule.SET_ADC_PARS(@FAdcPars) then
        raise EAdcError.Create('Не могу установить параметры ввода данных!');

      FCurrentMeasureParams.NeedUpdateChannelsInputRange := False;
    end;

  if FCurrentMeasureParams.NeedUpdateDacOutput then
    begin
      SetDacOutput(0, FCurrentMeasureParams.DacOutput);
      FCurrentMeasureParams.NeedUpdateDacOutput := False;
    end;
end;

procedure TAdcThread.Execute;
begin
  try
    QueryPerformanceFrequency(FQueryPerformanceFrequency);
    GetModuleInterface;
    StartCalculationsThread;
    try
      while not Terminated do
        begin
          ProcessCurrentCommand;
          if FMeasuring then
            DoMeasureStep;
          if not FMeasuring then
            begin
              if FConnected then
                DisconnectAdc;
              SleepMicroSeconds(1000);
            end;
        end;
    finally
      if FConnected then
        TryDisconnectAdc;
      StopCalculationsThread;
      ClearIORequests;
      ReleaseModuleInterface;
    end;
  except
    on E: Exception do
      begin
        if Assigned(FOnException) then
          FOnException('AdcThread fatal exception: ' + E.Message);
      end;
  end;
end;

constructor TAdcThread.Create(AMeasurementResult: TMeasurementResult; AOnException: TOnExceptionProcedure; AOnIterationCompleted: TOnIterationCompletedProcedure; AOnMeasureCompleted: TOnMeasureCompletedProcedure; AOnMeasurementStateUpdated: TOnMeasurementStateUpdatedProcedure);
begin
  FMeasurementResult := AMeasurementResult;
  FOnException := AOnException;
  FOnIterationCompleted := AOnIterationCompleted;
  FOnMeasureCompleted := AOnMeasureCompleted;
  FSetCommandCriticalSection := TCriticalSection.Create;
  FWaitCommandResultEvent := TEvent.Create;
  FCurrentMeasureParams := TCurrentMeasureParameters.Create;
  FMeasurementStateContainer := TMeasurementStateContainer.Create(AOnMeasurementStateUpdated);
  FCalculationData := TCalculationData.Create;
  FBuffer := TAdcDataBuffer.Create;
  inherited Create;
end;

destructor TAdcThread.Destroy;
begin
  FBuffer.Free;
  FMeasurementStateContainer.Free;
  FCalculationData.Free;
  FCurrentMeasureParams.Free;
  FWaitCommandResultEvent.Free;
  FSetCommandCriticalSection.Free;
  inherited Destroy;
end;

procedure TAdcThread.ProcessCommand(ACommandData: TCommandDataAbstract);
begin
  if not FInitialized then
    begin
      ACommandData.FailReason := 'Устройство не инициализировано.';
      Exit;
    end;
  FSetCommandCriticalSection.Enter;
  try
    FCurrentCommand := ACommandData;
    FWaitCommandResultEvent.ResetEvent;
  finally
    FSetCommandCriticalSection.Leave;
  end;
  if FWaitCommandResultEvent.WaitFor(COMMAND_WAIT_TIMEOUT) <> wrSignaled then
    begin
      ACommandData.FailReason := 'Не удалось выполнить команду';
      ACommandData.FreeForbidden := True;
    end;
end;

end.
