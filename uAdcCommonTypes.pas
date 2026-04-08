unit uAdcCommonTypes;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.DateUtils, System.Generics.Collections, System.SyncObjs,
  System.Variants, ComObj;

const
  DDS_REF_FREQ: Double = 56000000.0; // опорная частота генератора, Гц
  DDS_WORD_SIZE = 4294967296; // 2^32

type

  TAdcInputRange = (air3000mV, air1000mV, air300mV); // диапазоны входных напряжений

  TResonanceMeasurementParameters = class // параметры измерения резонанса
  public
    ResonantFrequency: Double; // частота резонанса
    MinusResonantFrequency: Double; // сдвиг вниз от частоты резонанса
    PlusResonantFrequency: Double; // сдвиг вверх от частоты резонанса
    Steps: Integer; // число шагов по частоте
    Delay: Integer; // задержка перед началом измерения, мс
    NeedWatch: Boolean; // признак необходимости корректировать параметры в соответствии с частотой резонанса
    MagnitudeMovingAveragePointsCount, PhaseMovingAveragePointsCount, PhaseDerivativeMovingAveragePointsCount: Integer; // число точек для сглаживания
  end;

  TStartMeasureParameters = class // набор параметров, устанавливаемых при старте процесса измерения
  private
    FResonances: TObjectList<TResonanceMeasurementParameters>;
  public
    InputSignalChannelRange: TAdcInputRange; // диапазон напряжений канала АЦП, на который подаётся сигнал со входа четырёхполюсника
    OutputSignalChannelRange: TAdcInputRange; // диапазон напряжений канала АЦП, на который подаётся сигнал с выхода четырёхполюсника
    DataStep: DWORD; // размер выборки данных с АЦП
    BlocksToReadCount: Byte; // количество выборок, осуществляемых за одно измерение
    SleepBetweenSetFreqAndDoSampling: Integer; // задержка между установкой частоты и началом измерения
    DacOutput: Double; // выходное напряжение ЦАП, являющееся множителем амплитуды на выходе генератора
    FourierAnalysis: Boolean; // метод обработки
    Series: Boolean; // непрерывная серия измерений
    constructor Create;
    destructor Destroy; override;
    procedure AddResonance(const AResonantFrequencyHz, AMinusFrequencyHz, APlusFrequencyHz: Double; const ASteps, ADelay: Integer; const ANeedWatch: Boolean; const AMagnitudePointsCount, APhasePointsCount, APhaseDerivativePointsCount: Integer);
    property Resonances: TObjectList<TResonanceMeasurementParameters> read FResonances;
  end;

  TOngoingMeasureParameters = class // набор параметров, устанавливаемых в процессе измерения
  public
    InputSignalChannelRange: TAdcInputRange; // диапазон напряжений канала АЦП, на который подаётся сигнал со входа четырёхполюсника
    OutputSignalChannelRange: TAdcInputRange; // диапазон напряжений канала АЦП, на который подаётся сигнал с выхода четырёхполюсника
    NeedUpdateChannelsRange: Boolean;
    DacOutput: Double; // выходное напряжение ЦАП, являющееся множителем амплитуды на выходе генератора
    NeedUpdateDacOutput: Boolean;
  end;

  TInputSignal = array of array of SHORT; // массив отсчётов, получаемый в результате измерения
  PInputSignal = ^TInputSignal;

  TDoubleArray = array of Double; // массив чисел с плавающей точкой

  TDoubleArrayStats = record // статистические данные по массиву чисел с плавающей точкой
    MaxValue: Double;
    MaxValueIndex: Integer;
    MinValue: Double;
    MinValueIndex: Integer;
    AvgValue: Double;
    procedure Calculate(const AArray: TDoubleArray);
  end;

  TReducedImagePlot = array of TPoint; // массив координат для построения графика

  TReducedImageData = record // данные для масштабирования
    Shift: Double;
    Scale: Double;
    procedure CalculateY(const AImageHeight, ATopBorder, ABottomBorder: Integer; const AStats: TDoubleArrayStats); // вычислить коэффициенты масштабирования для величины, соответствующей оси Y (амплитуда, сопротивление, фаза)
    procedure CalculateX(const AImageWidth: Integer; const AArray: TDoubleArray); // вычислить коэффициенты масштабирования для величины, соответствующей оси X (частота)
    function ValueToPx(const AValue: Double): Integer; inline; // преобразовать исходную величину в координаты
    function PxToValue(const AValue: Integer): Double; inline; // преобразовать координаты в исходную величину
  end;

  TResonanceParameters = record // характеристики измеренного резонанса
    MeanInputVoltage: Double;
    ResonantFrequency: Double;
    ResonantMagnitude: Double;
    ResonantResistance: Double;
    FourierAnalysis: Boolean;
    MaxPhaseDerivativeFrequency: Double;
    MaxPhaseDerivative: Double;
    QualityFactor: Double;
  end;

  TResonanceWatchingData = record // данные для слежения за резонансом
    ResonantFrequency: Double;
    MinusFrequency, PlusFrequency: Double;
    Steps: Integer;
    NeedWatch: Boolean;
    Delay: Integer; // задержка перед началом измерения, мс
    NeedUseManualRange: Boolean; // служебный флаг для обновления данных по запросу
  end;

  TResonanceMeasurementResult = class // результат измерения резонанса
  private
    FFrequencyReducedImageData: TReducedImageData; // данные для масштабирования частоты
    FMagnitudeReducedImageData: TReducedImageData; // данные для масштабирования амплитуды
    FPhaseReducedImageData: TReducedImageData; // данные для масштабирования фазы
    FPhaseDerivativeReducedImageData: TReducedImageData; // данные для масштабирования производной фазы
    procedure UpdateReducedImageData(const AImageHeight, AImageWidth, ATopBorder, ABottomBorder: Integer); // пересчитать данные для масштабирования
    procedure FillReducedArray(const ASourceXArray, ASourceYArray: TDoubleArray; AXReducedData, AYReducedData: TReducedImageData; const AImageWidth: Integer; out AReducedArray: TReducedImagePlot); // построить массив для графика
    function GetReducedPoint(const ASourceX, ASourceY: Double; AXReducedData, AYReducedData: TReducedImageData): TPoint; // получить координаты точки
    procedure FillSmoothedArray(const ASourceXArray, ASourceYArray: TDoubleArray; const APointsCount: Integer; out ASmoothedXArray, ASmoothedYArray: TDoubleArray); // построить сглаженный массив
    procedure CalculatePhaseDerivative; // вычислить производную фазы
    procedure UpdateResonanceParameters; // пересчитать параметры резонанса
  public
    ArraysLength: Integer; // длина массивов
    FourierAnalysis: Boolean; // метод обработки. если false, то фаза недоступна
    StartTime, StopTime: TDateTime; // время начала и конца измерения

    FrequencyHz: TDoubleArray; // частота

    InputAverage: TDoubleArray; // напряжение на входе четырёхполюсника
    InputAverageStats: TDoubleArrayStats;

    OutputAverage: TDoubleArray; // напряжение на выходе четырёхполюсника
    OutputAverageStats: TDoubleArrayStats;

    Magnitude: TDoubleArray; // амплитуда (отношение выхода ко входу)
    MagnitudeStats: TDoubleArrayStats;
    MagnitudeSmooth: TDoubleArray;
    MagnitudeSmoothFreq: TDoubleArray;
    MagnitudeSmoothStats: TDoubleArrayStats;

    Phase: TDoubleArray; // фаза (доступна только в режиме преобразования Фурье)
    PhaseStats: TDoubleArrayStats;
    PhaseSmooth: TDoubleArray;
    PhaseSmoothFreq: TDoubleArray;
    PhaseSmoothStats: TDoubleArrayStats;

    PhaseDerivative: TDoubleArray; // производная фазы (доступна только в режиме преобразования Фурье)
    PhaseDerivativeFreq: TDoubleArray;
    PhaseDerivativeStats: TDoubleArrayStats;
    PhaseDerivativeSmooth: TDoubleArray;
    PhaseDerivativeSmoothFreq: TDoubleArray;
    PhaseDerivativeSmoothStats: TDoubleArrayStats;

    MagnitudeMovingAveragePointsCount, PhaseMovingAveragePointsCount, PhaseDerivativeMovingAveragePointsCount: Integer; // число точек для сглаживания
    ResonanceParameters: TResonanceParameters; // параметры резонанса
    ResonanceWatchingData: TResonanceWatchingData; // данные для слежения за резонансом

    InputSignalChannelRange: TAdcInputRange; // диапазон напряжения на канале, на который подаётся сигнал со входа четырёхполюсника
    OutputSignalChannelRange: TAdcInputRange; // диапазон напряжения на канале, на который подаётся сигнал с выхода четырёхполюсника

    ResonanceNumber: Integer; // номер резонанса
    destructor Destroy; override;
    procedure Initialize(const ANumber, ALength: Integer; const AFourierAnalysis: Boolean; const AOutputSignalChannelRange, AInputSignalChannelRange: TAdcInputRange); overload; // инициализация объекта;
    procedure Initialize(const ANumber: Integer; AParameters: TResonanceMeasurementParameters; const AFourierAnalysis: Boolean; const AOutputSignalChannelRange, AInputSignalChannelRange: TAdcInputRange); overload; // инициализация объекта;
    procedure AssignFrom(const ASource: TResonanceMeasurementResult; const AFromMeasure: Boolean); // установить значения объекта в соответствии с исходным объектом

    procedure GetReducedImagePlots(const AImageHeight, AImageWidth, ATopBorder, ABottomBorder: Integer;
        out APhaseDefined: Boolean; out AMagnitude, AMagnitudeSmooth, APhase, APhaseSmooth, APhaseDerivative, APhaseDerivativeSmooth: TReducedImagePlot;
        out AMagnitudeResonance, APhaseResonance: TPoint); // получить графики
    function ReducedImageToFrequencyValue(const ALeft: Integer): Double; // преобразовать координату в частоту
    function ReducedImageToMagnitudeValue(const ATop: Integer): Double; // преобразовать координату в амплитуду
    function ReducedImageToPhaseValue(const ATop: Integer): Double; // преобразовать координату в фазу
    function ReducedImageToPhaseDerivativeValue(const ATop: Integer): Double; // преобразовать координату в производную фазы
  end;

  TFileSaver = class
  private const
    FILE_FORMAT_VERSION: Integer = 1;
  private
    FCriticalSection: TCriticalSection;
    FFolderPath: String;
    FFileStream: TFileStream;
    FNeedSave: Boolean;
    FResonancesCount: Integer;
    FResonancesCursors: array of Int64;
    procedure Lock; inline;
    procedure Unlock; inline;
  public
    constructor Create(const AFolderPath: String);
    destructor Destroy; override;

    procedure Initialize(const AFileName: String; const AResonancesCount: Integer);
    procedure AddNewResult(const AResonanceIndex: Integer; ASource: TResonanceMeasurementResult);
    procedure UpdateLastResult(const AResonanceIndex: Integer; ASource: TResonanceMeasurementResult);
  end;

  TExcelSaver = class
  private const
    DEFAULT_COLUMN_WIDTH = 15;
  private
    FCriticalSection: TCriticalSection;
    FFolderPath, FFileName: String;
    FExcelApplication: Variant;
    FExcelBook: Variant;
    FExcelSheet: Variant;
    FChartObjects: array of Variant;
    FCharts: array of Variant;
    FCanSave: Boolean;
    FSeries: Boolean;
    FFourierAnalysis: Boolean;
    FResonancesCount: Integer;
    FResonancesCursors: array of Int64;
    procedure Lock; inline;
    procedure Unlock; inline;
    function GetCellCoordinates(const ARow, ACol: Integer): String; inline;
  public
    constructor Create(const AFolderPath: String);
    destructor Destroy; override;

    procedure Initialize(const AFileName: String; const AResonancesCount: Integer; const ASeries, AFourierAnalysis: Boolean; const AStartTime: TDateTime);
    procedure AddNewResult(const AResonanceIndex: Integer; ASource: TResonanceMeasurementResult);
    procedure UpdateLastResult(const AResonanceIndex: Integer; ASource: TResonanceMeasurementResult);
  end;

  TMeasurementResult = class // результат измерения
  private
    FCriticalSection: TCriticalSection;
    FInitialized: Boolean;
    FResonances: TObjectList<TResonanceMeasurementResult>;
    FSeries: Boolean;
    FHasData: Boolean;
    FStartOfMeasurement: TDateTime;

    FNeedSaveToExcel: Boolean;
    FNeedInitializeExcelSaver: Boolean;
    FExcelSaver: TExcelSaver;
    FSaveToExcelQueue: TObjectList<TResonanceMeasurementResult>;

    procedure Lock; inline;
    procedure Unlock; inline;
    procedure SetNeedSaveToExcel(const AValue: Boolean);
  public
    constructor Create(const AFolderPath: String);
    destructor Destroy; override;

    procedure Initialize(AParameters: TStartMeasureParameters; const AOutputSignalChannelRange, AInputSignalChannelRange: TAdcInputRange); // потокобезопасная инициализация объекта
    procedure AssignResonanceResult(const AResonanceIndex: Integer; ASource: TResonanceMeasurementResult); // потокобезопасная установка значений объекта в соответствии с исходным объектом

    // методы, предназначенные для вызова из формы
    function GetResonanceParameters(const AResonanceIndex: Integer): TResonanceParameters; // потокобезопасное получение измеренных параметров резонанса
    function GetFrequencyRange(const AResonanceIndex: Integer): TResonanceWatchingData; // потокобезопасное получение диапазона измеряемых частот
    procedure SetFrequencyRange(const AResonanceIndex: Integer; const AResonantFrequencyHz, AMinusFrequencyHz, APlusFrequencyHz: Double; const ASteps, ADelay: Integer; const ANeedWatch: Boolean); // потокобезопасная установка диапазона измеряемых частот
    procedure SetMovingAverageParams(const AResonanceIndex, AMagnitudePointsCount, APhasePointsCount, APhaseDerivativePointsCount: Integer); // потокобезопасная установка параметров сглаживания
    procedure GetReducedImagePlots(const AImageHeight, AImageWidth, ATopBorder, ABottomBorder, AResonanceIndex: Integer;
        out APhaseDefined: Boolean; out AMagnitude, AMagnitudeSmooth, APhase, APhaseSmooth, APhaseDerivative, APhaseDerivativeSmooth: TReducedImagePlot; out AMagnitudeResonance, APhaseResonance: TPoint); // потокобезопасное получение графиков
    function ReducedImageToFrequencyValue(const AResonanceIndex, ALeft: Integer): Double; // потокобезопасное преобразование координаты в частоту
    function ReducedImageToMagnitudeValue(const AResonanceIndex, ATop: Integer): Double; // потокобезопасное преобразованик координаты в амплитуду
    function ReducedImageToPhaseValue(const AResonanceIndex, ATop: Integer): Double; // потокобезопасное преобразованик координаты в фазу
    function ReducedImageToPhaseDerivativeValue(const AResonanceIndex, ATop: Integer): Double; // потокобезопасное преобразованик координаты в производную фазы

    function AddDataToExcel(out ANeedTryAgain: Boolean; out AErrorDescription: String): Boolean;
    procedure UpdateLastResultInExcel(const AResonanceIndex: Integer);

    property NeedSaveToExcel: Boolean read FNeedSaveToExcel write SetNeedSaveToExcel;
  end;

  TMeasurementState = class // состояние процесса измерения
  public
    InputChannelOverflow, OutputChannelOverflow: Boolean;
    BufferOverrun: Boolean;
    MaxOfBufferFillingPercent: Integer;
    MeasureProgressPrecent: Integer;
    CurrentResonance: Integer;
  end;

  TTwoPortNetwork = class // параметры четырёхполюсника
  private
    FR1, FR2, FR3, FR4, FR5, FR6: Double;
    FCharacteristicResistance, FTransferCoefficient: Double;
    procedure SetResistances(const AR1, AR2, AR3, AR4, AR5, AR6: Double);
  public
    constructor Create;
    function GetResistance(const AMagnitude: Double): Double; inline;
  end;

function MaxPhaseDerivativeMovingAveragePointsCount(const APhaseArrayLength, APhaseMovingAveragePointsCount: Integer): Integer;
function CheckFrequencyRangeCorrectness(const AResonantFrequencyHz, AMinusFrequencyHz, APlusFrequencyHz: Double; const ASteps: Integer; out AFailReason: String): Boolean;
function CheckDelayCorrectness(const ADelay: Integer; out AFailReason: String): Boolean;
function CheckDacOutputCorrectness(const ADacOutput: Double): Boolean;
function GetFileNameOfDateTime(const ADateTime: TDateTime): String;
function FrequencyHzToTurningWord(const AFreqHz: Double): Cardinal;
function TurningWordToFrequencyHz(const ATurningWord: Cardinal): Double;

var
  TwoPortNetwork: TTwoPortNetwork;

implementation

{}

function MaxPhaseDerivativeMovingAveragePointsCount(const APhaseArrayLength, APhaseMovingAveragePointsCount: Integer): Integer;
var
  LSmoothArrayLength, LDerivativeArrayLength: Integer;
begin
  if APhaseArrayLength < 1 then
    raise Exception.Create('MaxPhaseDerivativeMovingAveragePointsCount wrong phase array length');
  if (APhaseMovingAveragePointsCount < 1) or (APhaseMovingAveragePointsCount > APhaseArrayLength) then
    raise Exception.Create('MaxPhaseDerivativeMovingAveragePointsCount wrong phase moving average points count');

  LSmoothArrayLength := APhaseArrayLength - APhaseMovingAveragePointsCount + 1;
  LDerivativeArrayLength := LSmoothArrayLength - 2;
  Result := LDerivativeArrayLength;
end;

function CheckFrequencyRangeCorrectness(const AResonantFrequencyHz, AMinusFrequencyHz, APlusFrequencyHz: Double; const ASteps: Integer; out AFailReason: String): Boolean;
var
  LStartFrequencyHz, LStopFrequencyHz: Double;
begin
  Result := False;

  LStartFrequencyHz := AResonantFrequencyHz - AMinusFrequencyHz;
  LStopFrequencyHz := AResonantFrequencyHz + APlusFrequencyHz;

  if (LStartFrequencyHz < 0.0) or (LStartFrequencyHz > DDS_REF_FREQ) then
    begin
      AFailReason := 'Некорректное значение начальной частоты';
      Exit;
    end;

  if (LStopFrequencyHz < 0.0) or (LStopFrequencyHz > DDS_REF_FREQ) then
    begin
      AFailReason := 'Некорректное значение конечной частоты';
      Exit;
    end;

  if ASteps <= 1 then
    begin
      AFailReason := 'Некорректное количество шагов';
      Exit;
    end;

  Result := True;
end;

function CheckDelayCorrectness(const ADelay: Integer; out AFailReason: String): Boolean;
begin
  Result := False;

  if (ADelay < 0) or (ADelay > 60000000) then
    begin
      AFailReason := 'Некорректное значение задержки';
      Exit;
    end;

  Result := True;
end;

function CheckDacOutputCorrectness(const ADacOutput: Double): Boolean;
begin
  Result := (ADacOutput >= 0) and (ADacOutput <= 1.25);
end;

function WordToTwoSignedString(const AWord: Word): String;
begin
  if AWord < 10 then
    Result := '0' + IntToStr(AWord)
  else
    Result := IntToStr(AWord);
end;

function GetFileNameOfDateTime(const ADateTime: TDateTime): String;
var
  LYear, LMonth, LDay, LHour, LMinute, LSecond, LMilliSecond: Word;
begin
  DecodeDateTime(ADateTime, LYear, LMonth, LDay, LHour, LMinute, LSecond, LMilliSecond);
  Result := IntToStr(LYear) + '_' + WordToTwoSignedString(LMonth) + '_' + WordToTwoSignedString(LDay) + '_' + WordToTwoSignedString(LHour) + '_' + WordToTwoSignedString(LMinute) + '_' + WordToTwoSignedString(LSecond);
end;

function FrequencyHzToTurningWord(const AFreqHz: Double): Cardinal;
var
  LValue: Int64;
begin
  LValue := Round((DDS_WORD_SIZE / DDS_REF_FREQ) * AFreqHz);
  if LValue < 0 then
    Result := 0
  else if LValue > (DDS_WORD_SIZE - 1) then
    Result := DDS_WORD_SIZE - 1
  else
    Result := LValue;
end;

function TurningWordToFrequencyHz(const ATurningWord: Cardinal): Double;
begin
  Result := ATurningWord * DDS_REF_FREQ / DDS_WORD_SIZE;
end;

{ TStartMeasureParameters }

constructor TStartMeasureParameters.Create;
begin
  FResonances := TObjectList<TResonanceMeasurementParameters>.Create;
  DataStep := 1024 * 1024;
  BlocksToReadCount := 1;
  SleepBetweenSetFreqAndDoSampling := 100;
end;

destructor TStartMeasureParameters.Destroy;
begin
  FResonances.Free;
  inherited Destroy;
end;

procedure TStartMeasureParameters.AddResonance(const AResonantFrequencyHz, AMinusFrequencyHz, APlusFrequencyHz: Double; const ASteps, ADelay: Integer; const ANeedWatch: Boolean; const AMagnitudePointsCount, APhasePointsCount, APhaseDerivativePointsCount: Integer);
var
  LResonance: TResonanceMeasurementParameters;
begin
  LResonance := TResonanceMeasurementParameters.Create;
  LResonance.ResonantFrequency := AResonantFrequencyHz;
  LResonance.MinusResonantFrequency := AMinusFrequencyHz;
  LResonance.PlusResonantFrequency := APlusFrequencyHz;
  LResonance.Steps := ASteps;
  LResonance.Delay := ADelay;
  LResonance.NeedWatch := ANeedWatch;
  LResonance.MagnitudeMovingAveragePointsCount := AMagnitudePointsCount;
  LResonance.PhaseMovingAveragePointsCount := APhasePointsCount;
  LResonance.PhaseDerivativeMovingAveragePointsCount := APhaseDerivativePointsCount;
  FResonances.Add(LResonance);
end;

{ TDoubleArrayStats }

procedure TDoubleArrayStats.Calculate(const AArray: TDoubleArray);
var
  i: Integer;
  LSum: Double;
begin
  if Length(AArray) = 0 then
    begin
      Self := Default(TDoubleArrayStats);
      Exit;
    end;

  MaxValue := AArray[0];
  MaxValueIndex := 0;
  MinValue := AArray[0];
  MinValueIndex := 0;
  LSum := AArray[0];
  for i := 1 to Length(AArray) - 1 do
    begin
      if AArray[i] > MaxValue then
        begin
          MaxValue := AArray[i];
          MaxValueIndex := i;
        end;
      if AArray[i] < MinValue then
        begin
          MinValue := AArray[i];
          MinValueIndex := i;
        end;
      LSum := LSum + AArray[i];
    end;
  AvgValue := LSum / Length(AArray);
end;

{ TReducedImageData }

procedure TReducedImageData.CalculateY(const AImageHeight, ATopBorder, ABottomBorder: Integer; const AStats: TDoubleArrayStats);
begin
  if (AStats.MinValue <> AStats.MaxValue) and ((AImageHeight - ATopBorder - ABottomBorder) > 0) then
    Scale := (AStats.MinValue - AStats.MaxValue) / (AImageHeight - ATopBorder - ABottomBorder)
  else
    Scale := 1;
  Shift := AStats.MaxValue - Scale * ATopBorder;
end;

procedure TReducedImageData.CalculateX(const AImageWidth: Integer; const AArray: TDoubleArray);
var
  LMin, LMax: Double;
begin
  LMax := AArray[Length(AArray) - 1];
  LMin := AArray[0];
  if (LMax <> LMin) and (AImageWidth <> 0) then
    Scale := (LMax - LMin) / AImageWidth
  else
    Scale := 1;
  Shift := LMin;
end;

function TReducedImageData.ValueToPx(const AValue: Double): Integer;
begin
  Result := Round((AValue - Shift) / Scale);
end;

function TReducedImageData.PxToValue(const AValue: Integer): Double;
begin
  Result := Scale * AValue + Shift;
end;

{ TResonanceMeasurementResult }

procedure TResonanceMeasurementResult.UpdateReducedImageData(const AImageHeight, AImageWidth, ATopBorder, ABottomBorder: Integer);
begin
  FFrequencyReducedImageData.CalculateX(AImageWidth, FrequencyHz);
  FMagnitudeReducedImageData.CalculateY(AImageHeight, ATopBorder, ABottomBorder, MagnitudeSmoothStats);
  FPhaseReducedImageData.CalculateY(AImageHeight, ATopBorder, ABottomBorder, PhaseSmoothStats);
  FPhaseDerivativeReducedImageData.CalculateY(AImageHeight, ATopBorder, ABottomBorder, PhaseDerivativeSmoothStats);
end;

procedure TResonanceMeasurementResult.FillReducedArray(const ASourceXArray, ASourceYArray: TDoubleArray; AXReducedData, AYReducedData: TReducedImageData; const AImageWidth: Integer; out AReducedArray: TReducedImagePlot);
var
  i, j, cnt: Integer;
  LXValue, LYValue: Integer;
  LXScale: Double;
begin
  if Length(ASourceXArray) <> Length(ASourceYArray) then
    raise Exception.Create('TResonanceMeasurementResult.FillReducedArray: длины массивов не совпадают');
  cnt := Length(ASourceXArray);
  if AImageWidth < cnt then
    begin
      SetLength(AReducedArray, 2 * AImageWidth);

      LXScale := AImageWidth / cnt;

      for j := 0 to AImageWidth - 1 do
        begin
          i := Round(j / LXScale);
          if i < 0 then i := 0;
          if i >= cnt then i := cnt - 1;

          LXValue := AXReducedData.ValueToPx(ASourceXArray[i]);
          AReducedArray[2 * j].X := LXValue;
          AReducedArray[2 * j + 1].X := LXValue;

          LYValue := AYReducedData.ValueToPx(ASourceYArray[i]);
          AReducedArray[2 * j].Y := LYValue;
          AReducedArray[2 * j + 1].Y := LYValue;
        end;

      for i := 0 to cnt - 1 do
        begin
          j := Round(i * LXScale);
          if j < 0 then j := 0;
          if j >= AImageWidth then j := AImageWidth - 1;

          LYValue := AYReducedData.ValueToPx(ASourceYArray[i]);
          if AReducedArray[2 * j].Y > LYValue then
            AReducedArray[2 * j].Y := LYValue;
          if AReducedArray[2 * j + 1].Y < LYValue then
            AReducedArray[2 * j + 1].Y := LYValue;
        end;
    end

  else
    begin
      SetLength(AReducedArray, cnt);
      for i := 0 to cnt - 1 do
        begin
          AReducedArray[i].X := AXReducedData.ValueToPx(ASourceXArray[i]);
          AReducedArray[i].Y := AYReducedData.ValueToPx(ASourceYArray[i]);
        end;
    end;
end;

function TResonanceMeasurementResult.GetReducedPoint(const ASourceX, ASourceY: Double; AXReducedData, AYReducedData: TReducedImageData): TPoint;
begin
  Result.X := AXReducedData.ValueToPx(ASourceX);
  Result.Y := AYReducedData.ValueToPx(ASourceY);
end;

procedure TResonanceMeasurementResult.FillSmoothedArray(const ASourceXArray, ASourceYArray: TDoubleArray; const APointsCount: Integer; out ASmoothedXArray, ASmoothedYArray: TDoubleArray);
var
  LSourceArrayLength, LSmoothArrayLength, i, j: Integer;
  LXSum, LYSum: Double;
begin
  LSourceArrayLength := Length(ASourceYArray);
  LSmoothArrayLength := LSourceArrayLength - APointsCount + 1;
  if (LSmoothArrayLength <= 0) or (LSmoothArrayLength > LSourceArrayLength) then
    raise Exception.Create('TResonanceMeasurementResult.FillSmoothedArray wrong points count');
  if APointsCount = 1 then
    begin
      ASmoothedXArray := ASourceXArray;
      ASmoothedYArray := ASourceYArray;
    end
  else
    begin
      SetLength(ASmoothedXArray, LSmoothArrayLength);
      SetLength(ASmoothedYArray, LSmoothArrayLength);
      for i := 0 to LSmoothArrayLength - 1 do
        begin
          LXSum := 0;
          LYSum := 0;
          for j := 0 to APointsCount - 1 do
            begin
              LXSum := LXSum + ASourceXArray[i + j];
              LYSum := LYSum + ASourceYArray[i + j];
            end;
          ASmoothedXArray[i] := LXSum / APointsCount;
          ASmoothedYArray[i] := LYSum / APointsCount;
        end;
    end;
end;

procedure TResonanceMeasurementResult.CalculatePhaseDerivative;
var
  LSourceArrayLength, LDerivativeArrayLength, i: Integer;
begin
  LSourceArrayLength := Length(PhaseSmooth);
  LDerivativeArrayLength := LSourceArrayLength - 2;
  if LDerivativeArrayLength < 0 then LDerivativeArrayLength := 0;
  SetLength(PhaseDerivative, LDerivativeArrayLength);
  SetLength(PhaseDerivativeFreq, LDerivativeArrayLength);
  for i := 0 to LDerivativeArrayLength - 1 do
    begin
      PhaseDerivativeFreq[i] := PhaseSmoothFreq[i + 1];
      PhaseDerivative[i] := - (pi / 180) * (PhaseSmooth[i + 2] - PhaseSmooth[i]) / (PhaseSmoothFreq[i + 2] - PhaseSmoothFreq[i]);
    end;
end;

procedure TResonanceMeasurementResult.UpdateResonanceParameters;
begin
  // пересчитать статистические данные исходных массивов
  InputAverageStats.Calculate(InputAverage);
  OutputAverageStats.Calculate(OutputAverage);
  MagnitudeStats.Calculate(Magnitude);
  if FourierAnalysis then
    PhaseStats.Calculate(Phase)
  else
    PhaseStats := Default(TDoubleArrayStats);

  // построить сглаженные массивы
  FillSmoothedArray(FrequencyHz, Magnitude, MagnitudeMovingAveragePointsCount, MagnitudeSmoothFreq, MagnitudeSmooth);
  if FourierAnalysis then
    FillSmoothedArray(FrequencyHz, Phase, PhaseMovingAveragePointsCount, PhaseSmoothFreq, PhaseSmooth)
  else
    begin
      PhaseSmoothFreq := nil;
      PhaseSmooth := nil;
    end;

  // пересчитать статистические данные сглаженных массивов
  MagnitudeSmoothStats.Calculate(MagnitudeSmooth);
  if FourierAnalysis then
    PhaseSmoothStats.Calculate(PhaseSmooth)
  else
    PhaseSmoothStats := Default(TDoubleArrayStats);

  if FourierAnalysis then
    begin
      // вычислить и сгладить производную сглаженной фазы
      CalculatePhaseDerivative;
      FillSmoothedArray(PhaseDerivativeFreq, PhaseDerivative, PhaseDerivativeMovingAveragePointsCount, PhaseDerivativeSmoothFreq, PhaseDerivativeSmooth);
      PhaseDerivativeStats.Calculate(PhaseDerivative);
      PhaseDerivativeSmoothStats.Calculate(PhaseDerivativeSmooth);
    end
  else
    begin
      PhaseDerivative := nil;
      PhaseDerivativeFreq := nil;
      PhaseDerivativeStats := Default(TDoubleArrayStats);
      PhaseDerivativeSmooth := nil;
      PhaseDerivativeSmoothFreq := nil;
      PhaseDerivativeSmoothStats := Default(TDoubleArrayStats);
    end;

  // вычислить параметры резонанса
  ResonanceParameters.MeanInputVoltage := InputAverageStats.AvgValue;
  ResonanceParameters.ResonantFrequency := MagnitudeSmoothFreq[MagnitudeSmoothStats.MaxValueIndex];
  ResonanceParameters.ResonantMagnitude := MagnitudeSmoothStats.MaxValue;
  ResonanceParameters.ResonantResistance := TwoPortNetwork.GetResistance(MagnitudeSmoothStats.MaxValue);
  ResonanceParameters.FourierAnalysis := FourierAnalysis;
  if FourierAnalysis then
    begin
      ResonanceParameters.MaxPhaseDerivativeFrequency := PhaseDerivativeSmoothFreq[PhaseDerivativeSmoothStats.MaxValueIndex];
      ResonanceParameters.MaxPhaseDerivative := PhaseDerivativeSmoothStats.MaxValue;
      ResonanceParameters.QualityFactor := PhaseDerivativeSmoothFreq[PhaseDerivativeSmoothStats.MaxValueIndex] * PhaseDerivativeSmoothStats.MaxValue / 2.0
    end
  else
    begin
      ResonanceParameters.MaxPhaseDerivativeFrequency := 0;
      ResonanceParameters.MaxPhaseDerivative := 0;
      ResonanceParameters.QualityFactor := 0;
    end;

  // обновить резонансную частоту в данных для слежения
  if ResonanceWatchingData.NeedWatch and not ResonanceWatchingData.NeedUseManualRange then
    ResonanceWatchingData.ResonantFrequency := ResonanceParameters.ResonantFrequency;
end;

destructor TResonanceMeasurementResult.Destroy;
begin
  Finalize(FrequencyHz);
  Finalize(InputAverage);
  Finalize(OutputAverage);
  Finalize(Magnitude);
  Finalize(MagnitudeSmooth);
  Finalize(MagnitudeSmoothFreq);
  Finalize(Phase);
  Finalize(PhaseSmooth);
  Finalize(PhaseSmoothFreq);
  Finalize(PhaseDerivative);
  Finalize(PhaseDerivativeFreq);
  Finalize(PhaseDerivativeSmooth);
  Finalize(PhaseDerivativeSmoothFreq);
  inherited Destroy;
end;

procedure TResonanceMeasurementResult.Initialize(const ANumber, ALength: Integer; const AFourierAnalysis: Boolean; const AOutputSignalChannelRange, AInputSignalChannelRange: TAdcInputRange);
begin
  ArraysLength := ALength;
  FourierAnalysis := AFourierAnalysis;

  SetLength(FrequencyHz, ArraysLength);
  FillChar(FrequencyHz[0], ArraysLength * SizeOf(Double), 0);

  SetLength(InputAverage, ArraysLength);
  FillChar(InputAverage[0], ArraysLength * SizeOf(Double), 0);

  SetLength(OutputAverage, ArraysLength);
  FillChar(OutputAverage[0], ArraysLength * SizeOf(Double), 0);

  SetLength(Magnitude, ArraysLength);
  FillChar(Magnitude[0], ArraysLength * SizeOf(Double), 0);

  MagnitudeSmooth := nil;
  MagnitudeSmoothFreq := nil;

  SetLength(Phase, ArraysLength);
  FillChar(Phase[0], ArraysLength * SizeOf(Double), 0);

  PhaseSmooth := nil;
  PhaseSmoothFreq := nil;
  PhaseDerivative := nil;
  PhaseDerivativeFreq := nil;
  PhaseDerivativeSmooth := nil;
  PhaseDerivativeSmoothFreq := nil;

  OutputSignalChannelRange := AOutputSignalChannelRange;
  InputSignalChannelRange := AInputSignalChannelRange;

  ResonanceNumber := ANumber;
end;

procedure TResonanceMeasurementResult.Initialize(const ANumber: Integer; AParameters: TResonanceMeasurementParameters; const AFourierAnalysis: Boolean; const AOutputSignalChannelRange, AInputSignalChannelRange: TAdcInputRange);
begin
  Initialize(ANumber, AParameters.Steps + 1, AFourierAnalysis, AOutputSignalChannelRange, AInputSignalChannelRange);
  ResonanceWatchingData.ResonantFrequency := AParameters.ResonantFrequency;
  ResonanceWatchingData.MinusFrequency := AParameters.MinusResonantFrequency;
  ResonanceWatchingData.PlusFrequency := AParameters.PlusResonantFrequency;
  ResonanceWatchingData.Steps := AParameters.Steps;
  ResonanceWatchingData.NeedWatch := AParameters.NeedWatch;
  ResonanceWatchingData.Delay := AParameters.Delay;
  MagnitudeMovingAveragePointsCount := AParameters.MagnitudeMovingAveragePointsCount;
  PhaseMovingAveragePointsCount := AParameters.PhaseMovingAveragePointsCount;
  PhaseDerivativeMovingAveragePointsCount := AParameters.PhaseDerivativeMovingAveragePointsCount;
end;

procedure TResonanceMeasurementResult.AssignFrom(const ASource: TResonanceMeasurementResult; const AFromMeasure: Boolean);
begin
  ArraysLength := ASource.ArraysLength;
  FourierAnalysis := ASource.FourierAnalysis;
  StartTime := ASource.StartTime;
  StopTime := ASource.StopTime;

  SetLength(FrequencyHz, ArraysLength);
  Move(ASource.FrequencyHz[0], FrequencyHz[0], ArraysLength * SizeOf(Double));

  SetLength(InputAverage, ArraysLength);
  Move(ASource.InputAverage[0], InputAverage[0], ArraysLength * SizeOf(Double));

  SetLength(OutputAverage, ArraysLength);
  Move(ASource.OutputAverage[0], OutputAverage[0], ArraysLength * SizeOf(Double));

  SetLength(Magnitude, ArraysLength);
  Move(ASource.Magnitude[0], Magnitude[0], ArraysLength * SizeOf(Double));

  SetLength(Phase, ArraysLength);
  Move(ASource.Phase[0], Phase[0], ArraysLength * SizeOf(Double));

  if AFromMeasure then
    begin
      UpdateResonanceParameters;
      ResonanceWatchingData.NeedUseManualRange := False;
    end
  else
    begin
      SetLength(MagnitudeSmooth, Length(ASource.MagnitudeSmooth));
      Move(ASource.MagnitudeSmooth[0], MagnitudeSmooth[0], Length(ASource.MagnitudeSmooth) * SizeOf(Double));

      SetLength(MagnitudeSmoothFreq, Length(ASource.MagnitudeSmoothFreq));
      Move(ASource.MagnitudeSmoothFreq[0], MagnitudeSmoothFreq[0], Length(ASource.MagnitudeSmoothFreq) * SizeOf(Double));

      SetLength(PhaseSmooth, Length(ASource.PhaseSmooth));
      Move(ASource.PhaseSmooth[0], PhaseSmooth[0], Length(ASource.PhaseSmooth) * SizeOf(Double));

      SetLength(PhaseSmoothFreq, Length(ASource.PhaseSmoothFreq));
      Move(ASource.PhaseSmoothFreq[0], PhaseSmoothFreq[0], Length(ASource.PhaseSmoothFreq) * SizeOf(Double));

      SetLength(PhaseDerivative, Length(ASource.PhaseDerivative));
      Move(ASource.PhaseDerivative[0], PhaseDerivative[0], Length(ASource.PhaseDerivative) * SizeOf(Double));

      SetLength(PhaseDerivativeFreq, Length(ASource.PhaseDerivativeFreq));
      Move(ASource.PhaseDerivativeFreq[0], PhaseDerivativeFreq[0], Length(ASource.PhaseDerivativeFreq) * SizeOf(Double));

      SetLength(PhaseDerivativeSmooth, Length(ASource.PhaseDerivativeSmooth));
      Move(ASource.PhaseDerivativeSmooth[0], PhaseDerivativeSmooth[0], Length(ASource.PhaseDerivativeSmooth) * SizeOf(Double));

      SetLength(PhaseDerivativeSmoothFreq, Length(ASource.PhaseDerivativeSmoothFreq));
      Move(ASource.PhaseDerivativeSmoothFreq[0], PhaseDerivativeSmoothFreq[0], Length(ASource.PhaseDerivativeSmoothFreq) * SizeOf(Double));

      InputAverageStats := ASource.InputAverageStats;
      OutputAverageStats := ASource.OutputAverageStats;
      MagnitudeStats := ASource.MagnitudeStats;
      MagnitudeSmoothStats := ASource.MagnitudeSmoothStats;
      PhaseStats := ASource.PhaseStats;
      PhaseSmoothStats := ASource.PhaseSmoothStats;
      PhaseDerivativeStats := ASource.PhaseDerivativeStats;
      PhaseDerivativeSmoothStats := ASource.PhaseDerivativeSmoothStats;

      MagnitudeMovingAveragePointsCount := ASource.MagnitudeMovingAveragePointsCount;
      PhaseMovingAveragePointsCount := ASource.PhaseMovingAveragePointsCount;
      PhaseDerivativeMovingAveragePointsCount := ASource.PhaseDerivativeMovingAveragePointsCount;

      ResonanceParameters := ASource.ResonanceParameters;
      ResonanceWatchingData := ASource.ResonanceWatchingData;
    end;

  InputSignalChannelRange := ASource.InputSignalChannelRange;
  OutputSignalChannelRange := ASource.OutputSignalChannelRange;

  ResonanceNumber := ASource.ResonanceNumber;
end;

procedure TResonanceMeasurementResult.GetReducedImagePlots(const AImageHeight, AImageWidth, ATopBorder, ABottomBorder: Integer;
    out APhaseDefined: Boolean; out AMagnitude, AMagnitudeSmooth, APhase, APhaseSmooth, APhaseDerivative, APhaseDerivativeSmooth: TReducedImagePlot;
    out AMagnitudeResonance, APhaseResonance: TPoint);
begin
  AMagnitude := nil;
  AMagnitudeSmooth := nil;
  APhase := nil;
  APhaseSmooth := nil;
  APhaseDerivative := nil;
  APhaseDerivativeSmooth := nil;
  AMagnitudeResonance := Default(TPoint);
  APhaseResonance := Default(TPoint);
  APhaseDefined := FourierAnalysis;

  UpdateReducedImageData(AImageHeight, AImageWidth, ATopBorder, ABottomBorder);

  FillReducedArray(FrequencyHz, Magnitude, FFrequencyReducedImageData, FMagnitudeReducedImageData, AImageWidth, AMagnitude);
  FillReducedArray(MagnitudeSmoothFreq, MagnitudeSmooth, FFrequencyReducedImageData, FMagnitudeReducedImageData, AImageWidth, AMagnitudeSmooth);
  AMagnitudeResonance := GetReducedPoint(ResonanceParameters.ResonantFrequency, ResonanceParameters.ResonantMagnitude, FFrequencyReducedImageData, FMagnitudeReducedImageData);
  if FourierAnalysis then
    begin
      FillReducedArray(FrequencyHz, Phase, FFrequencyReducedImageData, FPhaseReducedImageData, AImageWidth, APhase);
      FillReducedArray(PhaseSmoothFreq, PhaseSmooth, FFrequencyReducedImageData, FPhaseReducedImageData, AImageWidth, APhaseSmooth);
      FillReducedArray(PhaseDerivativeFreq, PhaseDerivative, FFrequencyReducedImageData, FPhaseDerivativeReducedImageData, AImageWidth, APhaseDerivative);
      FillReducedArray(PhaseDerivativeSmoothFreq, PhaseDerivativeSmooth, FFrequencyReducedImageData, FPhaseDerivativeReducedImageData, AImageWidth, APhaseDerivativeSmooth);
      APhaseResonance := GetReducedPoint(ResonanceParameters.MaxPhaseDerivativeFrequency, ResonanceParameters.MaxPhaseDerivative, FFrequencyReducedImageData, FPhaseDerivativeReducedImageData);
    end;
end;

function TResonanceMeasurementResult.ReducedImageToFrequencyValue(const ALeft: Integer): Double;
begin
  Result := FFrequencyReducedImageData.PxToValue(ALeft);
end;

function TResonanceMeasurementResult.ReducedImageToMagnitudeValue(const ATop: Integer): Double;
begin
  Result := FMagnitudeReducedImageData.PxToValue(ATop);
end;

function TResonanceMeasurementResult.ReducedImageToPhaseValue(const ATop: Integer): Double;
begin
  Result := FPhaseReducedImageData.PxToValue(ATop);
end;

function TResonanceMeasurementResult.ReducedImageToPhaseDerivativeValue(const ATop: Integer): Double;
begin
  Result := FPhaseDerivativeReducedImageData.PxToValue(ATop);
end;

{ TFileSaver }

procedure TFileSaver.Lock;
begin
  FCriticalSection.Enter;
end;

procedure TFileSaver.Unlock;
begin
  FCriticalSection.Leave;
end;

constructor TFileSaver.Create(const AFolderPath: String);
begin
  FCriticalSection := TCriticalSection.Create;
  FFolderPath := AFolderPath;
  if not ForceDirectories(FFolderPath) then
    raise Exception.Create('Каталог для сохранения недоступен: "' + SysErrorMessage(GetLastError) + '"');
end;

destructor TFileSaver.Destroy;
begin
  FCriticalSection.Free;
  FFileStream.Free;
  Finalize(FResonancesCursors);
  inherited Destroy;
end;

procedure TFileSaver.Initialize(const AFileName: String; const AResonancesCount: Integer);
var
  i: Integer;
begin
  Lock;
  try
    FNeedSave := False;

    FreeAndNil(FFileStream);
    if FileExists(FFolderPath + AFileName) then
      raise Exception.Create('Файл существует: ' + AFileName);
    FFileStream := TFileStream.Create(FFolderPath + AFileName, fmCreate or fmShareDenyWrite);
    FFileStream.Seek(0, soBeginning);
    FFileStream.Write(FILE_FORMAT_VERSION, SizeOf(FILE_FORMAT_VERSION));

    FResonancesCount := AResonancesCount;
    SetLength(FResonancesCursors, FResonancesCount);
    for i := 0 to FResonancesCount - 1 do
      FResonancesCursors[i] := 1;

    FNeedSave := True;
  finally
    Unlock;
  end;
end;

procedure TFileSaver.AddNewResult(const AResonanceIndex: Integer; ASource: TResonanceMeasurementResult);
begin
  Lock;
  try
    if not FNeedSave then
      Exit;
    if (AResonanceIndex < 0) or (AResonanceIndex >= FResonancesCount) then
      Exit;
    FFileStream.Seek(0, soEnd);

    // записать частотные характеристики
    FFileStream.Write(ASource.ArraysLength, SizeOf(Integer));
    FFileStream.Write(ASource.FourierAnalysis, SizeOf(Boolean));
    FFileStream.Write(ASource.FrequencyHz[0], SizeOf(Double) * ASource.ArraysLength);
    FFileStream.Write(ASource.InputAverage[0], SizeOf(Double) * ASource.ArraysLength);
    FFileStream.Write(ASource.OutputAverage[0], SizeOf(Double) * ASource.ArraysLength);
    FFileStream.Write(ASource.Magnitude[0], SizeOf(Double) * ASource.ArraysLength);
    if ASource.FourierAnalysis then
      FFileStream.Write(ASource.Phase[0], SizeOf(Double) * ASource.ArraysLength);

    FResonancesCursors[AResonanceIndex] := FFileStream.Position;

    // записать характеристики резонанса
    FFileStream.Write(ASource.MagnitudeMovingAveragePointsCount, SizeOf(Integer));
    FFileStream.Write(ASource.PhaseMovingAveragePointsCount, SizeOf(Integer));
    FFileStream.Write(ASource.PhaseDerivativeMovingAveragePointsCount, SizeOf(Integer));
    FFileStream.Write(ASource.ResonanceParameters, SizeOf(TResonanceParameters));
  finally
    Unlock;
  end;
end;

procedure TFileSaver.UpdateLastResult(const AResonanceIndex: Integer; ASource: TResonanceMeasurementResult);
begin
  Lock;
  try
    if not FNeedSave then
      Exit;
    if (AResonanceIndex < 0) or (AResonanceIndex >= FResonancesCount) then
      Exit;
    if FResonancesCursors[AResonanceIndex] = 0 then
      Exit;

    FFileStream.Seek(FResonancesCursors[AResonanceIndex], soBeginning);

    // записать характеристики резонанса
    FFileStream.Write(ASource.MagnitudeMovingAveragePointsCount, SizeOf(Integer));
    FFileStream.Write(ASource.PhaseMovingAveragePointsCount, SizeOf(Integer));
    FFileStream.Write(ASource.PhaseDerivativeMovingAveragePointsCount, SizeOf(Integer));
    FFileStream.Write(ASource.ResonanceParameters, SizeOf(TResonanceParameters));
  finally
    Unlock;
  end;
end;

{ TExcelSaver }

procedure TExcelSaver.Lock;
begin
  FCriticalSection.Enter;
end;

procedure TExcelSaver.Unlock;
begin
  FCriticalSection.Leave;
end;

function TExcelSaver.GetCellCoordinates(const ARow, ACol: Integer): String;
begin
  Result := 'R' + IntToStr(ARow) + 'C' + IntToStr(ACol);
end;

constructor TExcelSaver.Create(const AFolderPath: String);
begin
  FCriticalSection := TCriticalSection.Create;
  FFolderPath := AFolderPath;
  if not ForceDirectories(FFolderPath) then
    raise Exception.Create('Каталог для сохранения недоступен: "' + SysErrorMessage(GetLastError) + '"');
end;

destructor TExcelSaver.Destroy;
var
  i: Integer;
begin
  for i := 0 to Length(FCharts) - 1 do
    FCharts[i] := Unassigned;
  for i := 0 to Length(FChartObjects) - 1 do
    FChartObjects[i] := Unassigned;
  FExcelSheet := Unassigned;
  FExcelBook := Unassigned;
  FExcelApplication := Unassigned;
  FCriticalSection.Free;
  inherited Destroy;
end;

procedure TExcelSaver.Initialize(const AFileName: String; const AResonancesCount: Integer; const ASeries, AFourierAnalysis: Boolean; const AStartTime: TDateTime);
var
  i: Integer;
begin
  Lock;
  try
    FCanSave := False;
    for i := 0 to Length(FCharts) - 1 do
      FCharts[i] := Unassigned;
    for i := 0 to Length(FChartObjects) - 1 do
      FChartObjects[i] := Unassigned;
    FExcelSheet := Unassigned;
    FExcelBook := Unassigned;
    FExcelApplication := Unassigned;

    FFileName := AFileName + '.xlsx';
    if FileExists(FFolderPath + FFileName) then
      begin
        i := 0;
        while True do
          begin
            Inc(i);
            FFileName := AFileName + '_' + IntToStr(i) + '.xlsx';
            if not FileExists(FFolderPath + FFileName) then Break;
          end;
      end;

    FSeries := ASeries;
    FFourierAnalysis := AFourierAnalysis;

    FExcelApplication := CreateOleObject('Excel.Application');
    if VarIsNull(FExcelApplication) or VarIsEmpty(FExcelApplication) then
      raise Exception.Create('Excel недоступен.');
    FExcelApplication.Visible := True;
    FExcelApplication.SheetsInNewWorkbook := 1;
    FExcelBook := FExcelApplication.WorkBooks.Add;
    if VarIsNull(FExcelBook) or VarIsEmpty(FExcelBook) then
      raise Exception.Create('Книга Excel недоступна.');
    FExcelSheet := FExcelBook.WorkSheets[1];
    if VarIsNull(FExcelBook) or VarIsEmpty(FExcelBook) then
      raise Exception.Create('Лист Excel недоступен.');

    FResonancesCount := AResonancesCount;
    SetLength(FResonancesCursors, FResonancesCount);
    for i := 0 to FResonancesCount - 1 do
      FResonancesCursors[i] := 2;

    if FSeries then
      begin
        for i := 0 to FResonancesCount - 1 do
          begin
            FExcelSheet.Cells[1, i * 7 + 1].Value := AStartTime;
            FExcelSheet.Columns[i * 7 + 1].ColumnWidth := DEFAULT_COLUMN_WIDTH;
            FExcelSheet.Cells[1, i * 7 + 2].Value := 'Время';
            FExcelSheet.Columns[i * 7 + 2].ColumnWidth := DEFAULT_COLUMN_WIDTH;
            FExcelSheet.Cells[1, i * 7 + 3].Value := 'Частота резонанса, Гц';
            FExcelSheet.Columns[i * 7 + 3].ColumnWidth := DEFAULT_COLUMN_WIDTH;
            FExcelSheet.Cells[1, i * 7 + 4].Value := 'Сопротивление, Ом';
            FExcelSheet.Columns[i * 7 + 4].ColumnWidth := DEFAULT_COLUMN_WIDTH;
            if FFourierAnalysis then
              begin
                FExcelSheet.Cells[1, i * 7 + 5].Value := 'Добротность';
                FExcelSheet.Columns[i * 7 + 5].ColumnWidth := DEFAULT_COLUMN_WIDTH;
              end;
          end;
        SetLength(FChartObjects, FResonancesCount);
        SetLength(FCharts, FResonancesCount);
        for i := 0 to FResonancesCount - 1 do
          begin
            FChartObjects[i] := FExcelSheet.ChartObjects.Add(
                FExcelSheet.Cells[2, (FResonancesCount - 1) * 7 + 6].Left,
                FExcelSheet.Cells[2, i * 7 + 6].Top + i * 250,
                400, 200);
            FCharts[i] := FChartObjects[i].Chart;
            FCharts[i].ChartType := 75;
            FCharts[i].SeriesCollection.NewSeries;
            FCharts[i].SetElement(100);
          end;
      end
    else
      begin
        FExcelSheet.Cells[1, 1].Value := 'Частота, Гц';
        FExcelSheet.Columns[1].ColumnWidth := DEFAULT_COLUMN_WIDTH;
        FExcelSheet.Cells[1, 2].Value := 'Вход, мВ';
        FExcelSheet.Columns[2].ColumnWidth := DEFAULT_COLUMN_WIDTH;
        FExcelSheet.Cells[1, 3].Value := 'Амплитуда';
        FExcelSheet.Columns[3].ColumnWidth := DEFAULT_COLUMN_WIDTH;
        FExcelSheet.Cells[1, 4].Value := 'Сопротивление, Ом';
        FExcelSheet.Columns[4].ColumnWidth := DEFAULT_COLUMN_WIDTH;
        if FFourierAnalysis then
          begin
            FExcelSheet.Cells[1, 5].Value := 'Фаза';
            FExcelSheet.Columns[5].ColumnWidth := DEFAULT_COLUMN_WIDTH;
            FExcelSheet.Cells[1, 6].Value := 'Вр. нач./кон.';
            FExcelSheet.Columns[6].ColumnWidth := DEFAULT_COLUMN_WIDTH;
          end
        else
          begin
            FExcelSheet.Cells[1, 5].Value := 'Вр. нач./кон.';
            FExcelSheet.Columns[5].ColumnWidth := DEFAULT_COLUMN_WIDTH;
          end;

        SetLength(FChartObjects, 1);
        SetLength(FCharts, 1);
        FChartObjects[0] := FExcelSheet.ChartObjects.Add(
            FExcelSheet.Cells[2, 8].Left,
            FExcelSheet.Cells[2, 8].Top,
            400, 200);
        FCharts[0] := FChartObjects[0].Chart;
        FCharts[0].ChartType := 73;
        FCharts[0].SeriesCollection.NewSeries;
        FCharts[0].SetElement(100);
      end;
    FExcelBook.SaveAs(FFolderPath + FFileName);

    FCanSave := True;
  finally
    Unlock;
  end;
end;

procedure TExcelSaver.AddNewResult(const AResonanceIndex: Integer; ASource: TResonanceMeasurementResult);
var
  LVals: Variant;
  i, j: Integer;
begin
  Lock;
  try
    if not FCanSave then
      Exit;
    if (AResonanceIndex < 0) or (AResonanceIndex >= FResonancesCount) then
      Exit;

    if FSeries then
      begin
        j := FResonancesCursors[AResonanceIndex];

        FExcelSheet.Cells[j, AResonanceIndex * 7 + 2].Value := ASource.StartTime;
        FExcelSheet.Cells[j, AResonanceIndex * 7 + 1].Value :=
            '=(' + GetCellCoordinates(j, AResonanceIndex * 7 + 2) + '-' + GetCellCoordinates(1, AResonanceIndex * 7 + 1) + ')*24*60';
        FExcelSheet.Cells[j, AResonanceIndex * 7 + 3].Value := ASource.ResonanceParameters.ResonantFrequency;
        FExcelSheet.Cells[j, AResonanceIndex * 7 + 4].Value := ASource.ResonanceParameters.ResonantResistance;
        if FFourierAnalysis then
          FExcelSheet.Cells[j, AResonanceIndex * 7 + 5].Value := ASource.ResonanceParameters.QualityFactor;

        FCharts[AResonanceIndex].SeriesCollection[1].XValues := '=' + FExcelSheet.Name + '!' +
            GetCellCoordinates(2, AResonanceIndex * 7 + 1) + ':' + GetCellCoordinates(j, AResonanceIndex * 7 + 1);
        FCharts[AResonanceIndex].SeriesCollection[1].Values := '=' + FExcelSheet.Name + '!' +
            GetCellCoordinates(2, AResonanceIndex * 7 + 3) + ':' + GetCellCoordinates(j, AResonanceIndex * 7 + 3);

        Inc(FResonancesCursors[AResonanceIndex]);
      end
    else
      begin
        if FFourierAnalysis then
          LVals := VarArrayCreate([0, ASource.ArraysLength - 1, 0, 4], varVariant)
        else
          LVals := VarArrayCreate([0, ASource.ArraysLength - 1, 0, 3], varVariant);
        for i := 0 to ASource.ArraysLength - 1 do
          begin
            LVals[i, 0] := ASource.FrequencyHz[i];
            LVals[i, 1] := 1000 * ASource.InputAverage[i];
            LVals[i, 2] := ASource.Magnitude[i];
            LVals[i, 3] := TwoPortNetwork.GetResistance(ASource.Magnitude[i]);
            if FFourierAnalysis then
              LVals[i, 4] := ASource.Phase[i];
          end;
        if FFourierAnalysis then
          begin
            FExcelSheet.Range[FExcelSheet.Cells[2, 1], FExcelSheet.Cells[ASource.ArraysLength + 1, 5]].Value := LVals;
            FExcelSheet.Cells[2, 6].Value := ASource.StartTime;
            FExcelSheet.Cells[3, 6].Value := ASource.StopTime;
          end
        else
          begin
            FExcelSheet.Range[FExcelSheet.Cells[2, 1], FExcelSheet.Cells[ASource.ArraysLength + 1, 4]].Value := LVals;
            FExcelSheet.Cells[2, 5].Value := ASource.StartTime;
            FExcelSheet.Cells[3, 5].Value := ASource.StopTime;
          end;
        LVals := Unassigned;

        FCharts[0].SeriesCollection[1].XValues := '=' + FExcelSheet.Name + '!R2C1:R' + IntToStr(ASource.ArraysLength + 1) + 'C1';
        FCharts[0].SeriesCollection[1].Values := '=' + FExcelSheet.Name + '!R2C3:R' + IntToStr(ASource.ArraysLength + 1) + 'C3';
        FCharts[0].Axes(1).MinimumScale := ASource.FrequencyHz[0];
        FCharts[0].Axes(1).MaximumScale := ASource.FrequencyHz[ASource.ArraysLength - 1];
      end;
    FExcelBook.Save;
  finally
    Unlock;
  end;
end;

procedure TExcelSaver.UpdateLastResult(const AResonanceIndex: Integer; ASource: TResonanceMeasurementResult);
var
  j: Integer;
begin
  Lock;
  try
    if not FCanSave then
      Exit;
    if (AResonanceIndex < 0) or (AResonanceIndex >= FResonancesCount) then
      Exit;
    if FResonancesCursors[AResonanceIndex] = 1 then
      Exit;

    j := FResonancesCursors[AResonanceIndex];
    if FSeries then
      begin
        FExcelSheet.Cells[j, AResonanceIndex * 7 + 1].Value := ASource.StartTime;
        FExcelSheet.Cells[j, AResonanceIndex * 7 + 2].Value := ASource.ResonanceParameters.ResonantFrequency;
        FExcelSheet.Cells[j, AResonanceIndex * 7 + 3].Value := ASource.ResonanceParameters.ResonantResistance;
        if FFourierAnalysis then
          FExcelSheet.Cells[j, AResonanceIndex * 7 + 4].Value := ASource.ResonanceParameters.QualityFactor;
      end;
    FExcelBook.Save;
  finally
    Unlock;
  end;
end;

{ TMeasurementResult }

procedure TMeasurementResult.Lock;
begin
  FCriticalSection.Enter;
end;

procedure TMeasurementResult.Unlock;
begin
  FCriticalSection.Leave;
end;

procedure TMeasurementResult.SetNeedSaveToExcel(const AValue: Boolean);
var
  LNeedTryAgain: Boolean;
  LErrorDescription: String;
begin
  Lock;
  try
    if AValue <> FNeedSaveToExcel then
      begin
        FNeedSaveToExcel := AValue;
        if AValue then
          if not FSeries and FHasData then
            if not AddDataToExcel(LNeedTryAgain, LErrorDescription) then
              raise Exception.Create('Не удалось сохранить данные в Excel: ' + LErrorDescription);
      end;
  finally
    Unlock;
  end;
end;

constructor TMeasurementResult.Create(const AFolderPath: String);
begin
  FCriticalSection := TCriticalSection.Create;
  FResonances := TObjectList<TResonanceMeasurementResult>.Create;
  FExcelSaver := TExcelSaver.Create(AFolderPath);
  FSaveToExcelQueue := TObjectList<TResonanceMeasurementResult>.Create;
end;

destructor TMeasurementResult.Destroy;
begin
  FSaveToExcelQueue.Free;
  FExcelSaver.Free;
  FResonances.Free;
  FCriticalSection.Free;
  inherited Destroy;
end;

procedure TMeasurementResult.Initialize(AParameters: TStartMeasureParameters; const AOutputSignalChannelRange, AInputSignalChannelRange: TAdcInputRange);
var
  i: Integer;
  LItem: TResonanceMeasurementResult;
begin
  Lock;
  try
    FStartOfMeasurement := Now;
    FResonances.Clear;
    for i := 0 to AParameters.Resonances.Count - 1 do
      begin
        LItem := TResonanceMeasurementResult.Create;
        LItem.Initialize(i, AParameters.Resonances[i], AParameters.FourierAnalysis, AOutputSignalChannelRange, AInputSignalChannelRange);
        FResonances.Add(LItem);
      end;
    FSeries := AParameters.Series;
    FNeedInitializeExcelSaver := True;
    FSaveToExcelQueue.Clear;
    FHasData := False;
    FInitialized := True;
  finally
    Unlock;
  end;
end;

procedure TMeasurementResult.AssignResonanceResult(const AResonanceIndex: Integer; ASource: TResonanceMeasurementResult);
var
  LItem, LQueuedItem: TResonanceMeasurementResult;
begin
  Lock;
  try
    if (AResonanceIndex < 0) or (AResonanceIndex >= FResonances.Count) then
      raise Exception.Create('TMeasurementResult.AssignResonanceResult index out of range');
    LItem := FResonances[AResonanceIndex];
    LItem.AssignFrom(ASource, True);
    if FNeedSaveToExcel then
      begin
        LQueuedItem := TResonanceMeasurementResult.Create;
        LQueuedItem.AssignFrom(LItem, False);
        FSaveToExcelQueue.Add(LQueuedItem);
      end;
    FHasData := True;
  finally
    Unlock;
  end;
end;

function TMeasurementResult.GetResonanceParameters(const AResonanceIndex: Integer): TResonanceParameters;
begin
  Lock;
  try
    if (AResonanceIndex < 0) or (AResonanceIndex >= FResonances.Count) then
      raise Exception.Create('TMeasurementResult.AssignResonanceResult index out of range');
    Result := FResonances[AResonanceIndex].ResonanceParameters;
  finally
    Unlock;
  end;
end;

function TMeasurementResult.GetFrequencyRange(const AResonanceIndex: Integer): TResonanceWatchingData;
begin
  Lock;
  try
    if (AResonanceIndex < 0) or (AResonanceIndex >= FResonances.Count) then
      raise Exception.Create('TMeasurementResult.AssignResonanceResult index out of range');
    Result := FResonances[AResonanceIndex].ResonanceWatchingData;
  finally
    Unlock;
  end;
end;

procedure TMeasurementResult.SetFrequencyRange(const AResonanceIndex: Integer; const AResonantFrequencyHz, AMinusFrequencyHz, APlusFrequencyHz: Double; const ASteps, ADelay: Integer; const ANeedWatch: Boolean);
var
  LFailReason: String;
  LNotUseManualRange: Boolean;
begin
  Lock;
  try
    if not FInitialized then
      Exit;
    if (AResonanceIndex < 0) or (AResonanceIndex >= FResonances.Count) then
      raise Exception.Create('TMeasurementResult.SetMovingAverageParams index out of range');

    if not CheckFrequencyRangeCorrectness(AResonantFrequencyHz, AMinusFrequencyHz, APlusFrequencyHz, ASteps, LFailReason) then
      raise Exception.Create(LFailReason);

    if not CheckDelayCorrectness(ADelay, LFailReason) then
      raise Exception.Create(LFailReason);

    LNotUseManualRange := (not FResonances[AResonanceIndex].ResonanceWatchingData.NeedWatch and ANeedWatch) and (FResonances[AResonanceIndex].ResonanceWatchingData.ResonantFrequency = AResonantFrequencyHz);
    FResonances[AResonanceIndex].ResonanceWatchingData.ResonantFrequency := AResonantFrequencyHz;
    FResonances[AResonanceIndex].ResonanceWatchingData.MinusFrequency := AMinusFrequencyHz;
    FResonances[AResonanceIndex].ResonanceWatchingData.PlusFrequency := APlusFrequencyHz;
    FResonances[AResonanceIndex].ResonanceWatchingData.Steps := ASteps;
    FResonances[AResonanceIndex].ResonanceWatchingData.NeedWatch := ANeedWatch;
    FResonances[AResonanceIndex].ResonanceWatchingData.NeedUseManualRange := not LNotUseManualRange;
    FResonances[AResonanceIndex].ResonanceWatchingData.Delay := ADelay;
  finally
    Unlock;
  end;
end;

procedure TMeasurementResult.SetMovingAverageParams(const AResonanceIndex, AMagnitudePointsCount, APhasePointsCount, APhaseDerivativePointsCount: Integer);
begin
  Lock;
  try
    if not FInitialized then
      Exit;
    if (AResonanceIndex < 0) or (AResonanceIndex >= FResonances.Count) then
      raise Exception.Create('TMeasurementResult.SetMovingAverageParams index out of range');
    if (AMagnitudePointsCount < 1) or (AMagnitudePointsCount > FResonances[AResonanceIndex].ArraysLength) then
      raise Exception.Create('Wrong magnitude points count');
    if (APhasePointsCount < 1) or (APhasePointsCount > FResonances[AResonanceIndex].ArraysLength) then
      raise Exception.Create('Wrong phase points count');
    if (APhaseDerivativePointsCount < 1) or (APhaseDerivativePointsCount > MaxPhaseDerivativeMovingAveragePointsCount(FResonances[AResonanceIndex].ArraysLength, APhasePointsCount)) then
      raise Exception.Create('Wrong phase derivative points count');

    FResonances[AResonanceIndex].MagnitudeMovingAveragePointsCount := AMagnitudePointsCount;
    FResonances[AResonanceIndex].PhaseMovingAveragePointsCount := APhasePointsCount;
    FResonances[AResonanceIndex].PhaseDerivativeMovingAveragePointsCount := APhaseDerivativePointsCount;
    FResonances[AResonanceIndex].UpdateResonanceParameters;
  finally
    Unlock;
  end;
end;

procedure TMeasurementResult.GetReducedImagePlots(const AImageHeight, AImageWidth, ATopBorder, ABottomBorder, AResonanceIndex: Integer;
    out APhaseDefined: Boolean; out AMagnitude, AMagnitudeSmooth, APhase, APhaseSmooth, APhaseDerivative, APhaseDerivativeSmooth: TReducedImagePlot;
    out AMagnitudeResonance, APhaseResonance: TPoint);
begin
  AMagnitude := nil;
  AMagnitudeSmooth := nil;
  APhase := nil;
  APhaseSmooth := nil;
  APhaseDerivative := nil;
  APhaseDerivativeSmooth := nil;
  AMagnitudeResonance := Default(TPoint);

  Lock;
  try
    if not FInitialized then
      Exit;
    if (AResonanceIndex < 0) or (AResonanceIndex >= FResonances.Count) then
      raise Exception.Create('TMeasurementResult.GetReducedArraysForImage index out of range');
    FResonances[AResonanceIndex].GetReducedImagePlots(AImageHeight, AImageWidth, ATopBorder, ABottomBorder,
        APhaseDefined, AMagnitude, AMagnitudeSmooth, APhase, APhaseSmooth, APhaseDerivative, APhaseDerivativeSmooth, AMagnitudeResonance, APhaseResonance);
  finally
    Unlock;
  end;
end;

function TMeasurementResult.ReducedImageToFrequencyValue(const AResonanceIndex, ALeft: Integer): Double;
begin
  Result := 0;
  Lock;
  try
    if not FInitialized then
      Exit;
    if (AResonanceIndex < 0) or (AResonanceIndex >= FResonances.Count) then
      Exit;
    Result := FResonances[AResonanceIndex].ReducedImageToFrequencyValue(ALeft);
  finally
    Unlock;
  end;
end;

function TMeasurementResult.ReducedImageToMagnitudeValue(const AResonanceIndex, ATop: Integer): Double;
begin
  Result := 0;
  Lock;
  try
    if not FInitialized then
      Exit;
    if (AResonanceIndex < 0) or (AResonanceIndex >= FResonances.Count) then
      Exit;
    Result := FResonances[AResonanceIndex].ReducedImageToMagnitudeValue(ATop);
  finally
    Unlock;
  end;
end;

function TMeasurementResult.ReducedImageToPhaseValue(const AResonanceIndex, ATop: Integer): Double;
begin
  Result := 0;
  Lock;
  try
    if not FInitialized then
      Exit;
    if (AResonanceIndex < 0) or (AResonanceIndex >= FResonances.Count) then
      Exit;
    Result := FResonances[AResonanceIndex].ReducedImageToPhaseValue(ATop);
  finally
    Unlock;
  end;
end;

function TMeasurementResult.ReducedImageToPhaseDerivativeValue(const AResonanceIndex, ATop: Integer): Double;
begin
  Result := 0;
  Lock;
  try
    if not FInitialized then
      Exit;
    if (AResonanceIndex < 0) or (AResonanceIndex >= FResonances.Count) then
      Exit;
    Result := FResonances[AResonanceIndex].ReducedImageToPhaseDerivativeValue(ATop);
  finally
    Unlock;
  end;
end;

function TMeasurementResult.AddDataToExcel(out ANeedTryAgain: Boolean; out AErrorDescription: String): Boolean;
var
  LFourierAnalysis: Boolean;
  LResonance: TResonanceMeasurementResult;
begin
  Result := False;
  ANeedTryAgain := False;
  AErrorDescription := '';

  Lock;
  try
    try
      if not FNeedSaveToExcel then
        Exit(True);
      if FNeedInitializeExcelSaver then
        begin
          LFourierAnalysis := False;
          for LResonance in FResonances do
            if LResonance.FourierAnalysis then
              begin
                LFourierAnalysis := True;
                Break;
              end;
          FExcelSaver.Initialize(GetFileNameOfDateTime(FStartOfMeasurement), FResonances.Count, FSeries, LFourierAnalysis, FStartOfMeasurement);
          FNeedInitializeExcelSaver := False;
        end;
      if FSeries then
        begin
          while FSaveToExcelQueue.Count > 0 do
            begin
              LResonance := FSaveToExcelQueue[0];
              FExcelSaver.AddNewResult(LResonance.ResonanceNumber, LResonance);
              FSaveToExcelQueue.Delete(0);
            end;
        end
      else
        begin
          FExcelSaver.AddNewResult(0, FResonances[0]);
        end;
      Result := True;
    except
      on E: EOleSysError do
        begin
          AErrorDescription := E.Message;
          ANeedTryAgain := (EOleSysError(E).ErrorCode = -2147418111) or (EOleSysError(E).ErrorCode = -2146777998);
          if not ANeedTryAgain then
            FNeedInitializeExcelSaver := True;
        end;
      on E: Exception do
        begin
          FNeedInitializeExcelSaver := True;
          raise;
        end;
    end;
  finally
    Unlock;
  end;
end;

procedure TMeasurementResult.UpdateLastResultInExcel(const AResonanceIndex: Integer);
var
  i: Integer;
  LQueuedItem: TResonanceMeasurementResult;
begin
  Lock;
  try
    if FHasData and FNeedSaveToExcel and not FNeedInitializeExcelSaver then
      begin
        for i := FSaveToExcelQueue.Count - 1 downto 0 do
          begin
            LQueuedItem := FSaveToExcelQueue[i];
            if LQueuedItem.ResonanceNumber = AResonanceIndex then
              begin
                LQueuedItem.AssignFrom(FResonances[AResonanceIndex], False);
                Exit;
              end;
          end;
        FExcelSaver.UpdateLastResult(AResonanceIndex, FResonances[AResonanceIndex]);
      end;
  finally
    Unlock;
  end;
end;

{ TTwoPortNetwork }

procedure TTwoPortNetwork.SetResistances(const AR1, AR2, AR3, AR4, AR5, AR6: Double);
var
  LA2, LA4: Double;
begin
  FR1 := AR1;
  FR2 := AR2;
  FR3 := AR3;
  FR4 := AR4;
  FR5 := AR5;
  FR6 := AR6;
  LA2 := 1.0 / FR2 + 1.0 / FR3;
  LA4 := 1.0 / FR4 + 1.0 / (FR5 + FR6);
  FCharacteristicResistance := 1.0 / LA2 + 1.0 / LA4;
  FTransferCoefficient := FR5 / (FR5 + FR6) / (FR3 * LA2 * LA4);
end;

constructor TTwoPortNetwork.Create;
begin
  SetResistances(60.45, 259.1, 213, 257.1, 60.89, 213);
end;

function TTwoPortNetwork.GetResistance(const AMagnitude: Double): Double;
begin
  if AMagnitude = 0 then
    Result := 0
  else
    Result := FTransferCoefficient / AMagnitude - FCharacteristicResistance;
end;

initialization
  TwoPortNetwork := TTwoPortNetwork.Create;

finalization
  FreeAndNil(TwoPortNetwork);

end.
