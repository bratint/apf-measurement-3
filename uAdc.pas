unit uAdc;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.SyncObjs, System.Generics.Collections,
  uAdcThread, uAdcCommonTypes;

const
  WM_ADC_ERROR_MESSAGE = WM_USER + 1;
  WM_MEASURE_COMPLETED = WM_USER + 2;
  WM_ITERATION_COMPLETED = WM_USER + 3;
  WM_MEASUREMENT_STATE_UPDATED = WM_USER + 4;

type

  TErrorMessage = class // сообщение об ошибке, которое должно быть выведено
  private
    FMessageText: String;
  public
    constructor Create(const AMessageText: String);
    property MessageText: String read FMessageText;
  end;

  TErrorMessagesQueue = class(TObjectList<TErrorMessage>) // потокобезопасная очередь сообщений об ошибках
  private const
    MAX_QUEUE_LENGTH = 100;
  private
    FCriticalSection: TCriticalSection;
    FTargetHandle: THandle;
    FDisabled: Boolean;
  public
    constructor Create(ATargetHandle: THandle);
    destructor Destroy; override;
    procedure Push(const AMessageText: String);
    function Pop: TErrorMessage;
  end;

  TAdcManager = class // главный класс для взаимодействия с модулем АЦП
  private
    FWorkFolder: String;
    FAdcThread: TADCThread; // поток для работы с АЦП
    FTargetHandle: THandle; // дескриптор главной формы
    FErrorMessagesQueue: TErrorMessagesQueue; // очередь сообщений об ошибках
    FMeasurementResult: TMeasurementResult; // объект с последним результатом измерения
    function SendCommand(ACommandData: TCommandDataAbstract; out AFailReason: String): Boolean; // выполнить команду на поток модуля АЦП
    procedure PushErrorMessage(const AMessageText: String); // добавить новое сообщение об ошибке в конец очереди
    procedure OnMeasureCompleted;
    procedure OnIterationCompleted(const AResonanceIndex: Integer);
    procedure OnUpdateMeasurementState(AState: TMeasurementState);
  public
    constructor Create(ATargetHandle: THandle);
    destructor Destroy; override;
    function StartMeasure(const AMeasureParameters: TStartMeasureParameters; out AFailReason: String): Boolean; // начать процесс измерения
    function StopMeasure(out AFailReason: String): Boolean; // остановить процесс измерения
    function SetMeasureParameters(const AMeasureParameters: TOngoingMeasureParameters; out AFailReason: String): Boolean; // скорректировать параметры в процессе измерения
    function PopErrorMessage: TErrorMessage; // извлечь из очереди первое сообщение об ошибке. форма должна вызывать этот метод при получении сообщения WM_ADC_ERROR_MESSAGE
    property MeasurementResult: TMeasurementResult read FMeasurementResult;
  end;

implementation

{ TErrorMessage }

constructor TErrorMessage.Create(const AMessageText: String);
begin
  FMessageText := AMessageText;
end;

{ TErrorMessagesQueue }

constructor TErrorMessagesQueue.Create(ATargetHandle: THandle);
begin
  inherited Create;
  FTargetHandle := ATargetHandle;
  FCriticalSection := TCriticalSection.Create;
end;

destructor TErrorMessagesQueue.Destroy;
begin
  FCriticalSection.Free;
  inherited Destroy;
end;

procedure TErrorMessagesQueue.Push(const AMessageText: String);
begin
  if FDisabled then
    Exit;
  FCriticalSection.Enter;
  try
    if Count >= MAX_QUEUE_LENGTH then
      begin
        FDisabled := True;
        raise Exception.Create('Error message queue overflow');
      end;
    Add(TErrorMessage.Create(AMessageText));
  finally
    FCriticalSection.Leave;
  end;
  PostMessage(FTargetHandle, WM_ADC_ERROR_MESSAGE, 0, 0);
end;

function TErrorMessagesQueue.Pop: TErrorMessage;
begin
  FCriticalSection.Enter;
  try
    if Count > 0 then
      Result := ExtractAt(0)
    else
      Result := nil;
  finally
    FCriticalSection.Leave;
  end;
end;

{ TAdcManager }

function TAdcManager.SendCommand(ACommandData: TCommandDataAbstract; out AFailReason: String): Boolean;
begin
  FAdcThread.ProcessCommand(ACommandData);
  Result := ACommandData.SuccessResult;
  AFailReason := ACommandData.FailReason;
  if not ACommandData.FreeForbidden then
    ACommandData.Free;
end;

procedure TAdcManager.PushErrorMessage(const AMessageText: String);
begin
  FErrorMessagesQueue.Push(AMessageText);
end;

procedure TAdcManager.OnMeasureCompleted;
begin
  PostMessage(FTargetHandle, WM_MEASURE_COMPLETED, 0, 0);
end;

procedure TAdcManager.OnIterationCompleted(const AResonanceIndex: Integer);
begin
  PostMessage(FTargetHandle, WM_ITERATION_COMPLETED, NativeUInt(AResonanceIndex), 0);
end;

procedure TAdcManager.OnUpdateMeasurementState(AState: TMeasurementState);
begin
  PostMessage(FTargetHandle, WM_MEASUREMENT_STATE_UPDATED, 0, NativeInt(AState));
end;

constructor TAdcManager.Create(ATargetHandle: THandle);
begin
  FWorkFolder := ExtractFilePath(ParamStr(0));
  FTargetHandle := ATargetHandle;
  FErrorMessagesQueue := TErrorMessagesQueue.Create(ATargetHandle);
  FMeasurementResult := TMeasurementResult.Create(FWorkFolder + 'Measurements\');
  FAdcThread := TAdcThread.Create(FMeasurementResult, PushErrorMessage, OnIterationCompleted, OnMeasureCompleted, OnUpdateMeasurementState);
end;

destructor TAdcManager.Destroy;
begin
  FAdcThread.Terminate;
  FAdcThread.WaitFor;
  FAdcThread.Free;
  FMeasurementResult.Free;
  FErrorMessagesQueue.Free;
  inherited Destroy;
end;

function TAdcManager.StartMeasure(const AMeasureParameters: TStartMeasureParameters; out AFailReason: String): Boolean;
var
  LCommandData: TCommandDataStartMeasure;
begin
  LCommandData := TCommandDataStartMeasure.Create(AMeasureParameters);
  Result := SendCommand(LCommandData, AFailReason);
end;

function TAdcManager.StopMeasure(out AFailReason: String): Boolean;
var
  LCommandData: TCommandDataStopMeasure;
begin
  LCommandData := TCommandDataStopMeasure.Create;
  Result := SendCommand(LCommandData, AFailReason);
end;

function TAdcManager.SetMeasureParameters(const AMeasureParameters: TOngoingMeasureParameters; out AFailReason: String): Boolean;
var
  LCommandData: TCommandDataSetMeasureParameters;
begin
  LCommandData := TCommandDataSetMeasureParameters.Create(AMeasureParameters);
  Result := SendCommand(LCommandData, AFailReason);
end;

function TAdcManager.PopErrorMessage: TErrorMessage;
begin
  Result := FErrorMessagesQueue.Pop;
end;

end.
