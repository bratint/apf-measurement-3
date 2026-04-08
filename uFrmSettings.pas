unit uFrmSettings;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  uAdc, uAdcCommonTypes;

type
  TfrmSettings = class(TForm)
    cmRangeIn: TComboBox;
    cmRangeOut: TComboBox;
    btnSetAdcRanges: TButton;
    edDataStep: TEdit;
    Label1: TLabel;
    edSleepBetweenSetFreqAndDoSampling: TEdit;
    lblSleepBetweenSetFreqAndDoSampling: TLabel;
    edBlocksToReadCount: TEdit;
    lblDataStepConst: TLabel;
    lblAdcRange: TLabel;
    lblMultiple: TLabel;
    procedure btnSetAdcRangesClick(Sender: TObject);
  private
  public
  end;

var
  frmSettings: TfrmSettings;

implementation

{$R *.dfm}

uses
  uFrmMain;

procedure TfrmSettings.btnSetAdcRangesClick(Sender: TObject);
var
  lParams: TOngoingMeasureParameters;
  lText: String;
begin
  lParams := TOngoingMeasureParameters.Create;
  try
    lParams.NeedUpdateChannelsRange := True;
    case cmRangeIn.ItemIndex of
      0: lParams.InputSignalChannelRange := air300mV;
      1: lParams.InputSignalChannelRange := air1000mV;
      2: lParams.InputSignalChannelRange := air3000mV;
      else lParams.NeedUpdateChannelsRange := False;
    end;
    case cmRangeOut.ItemIndex of
      0: lParams.OutputSignalChannelRange := air300mV;
      1: lParams.OutputSignalChannelRange := air1000mV;
      2: lParams.OutputSignalChannelRange := air3000mV;
      else lParams.NeedUpdateChannelsRange := False;
    end;
    if not AdcManager.SetMeasureParameters(lParams, lText) then
      ShowMessage(lText);
  finally
    lParams.Free;
  end;
end;

end.
