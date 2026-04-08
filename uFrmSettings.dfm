object frmSettings: TfrmSettings
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = #1053#1072#1089#1090#1088#1086#1081#1082#1080
  ClientHeight = 121
  ClientWidth = 249
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 104
    Top = 8
    Width = 86
    Height = 13
    Caption = #1056#1072#1079#1084#1077#1088' '#1074#1099#1073#1086#1088#1082#1080':'
  end
  object lblSleepBetweenSetFreqAndDoSampling: TLabel
    Left = 104
    Top = 56
    Width = 137
    Height = 26
    Caption = #1047#1072#1076#1077#1088#1078#1082#1072' '#1087#1086#1089#1083#1077' '#1091#1089#1090#1072#1085#1086#1074#1082#1080' '#1095#1072#1089#1090#1086#1090#1099', '#1084#1082#1089':'
    WordWrap = True
  end
  object lblDataStepConst: TLabel
    Left = 192
    Top = 28
    Width = 33
    Height = 13
    Caption = 'x 1024'
  end
  object lblAdcRange: TLabel
    Left = 8
    Top = 8
    Width = 71
    Height = 26
    Caption = #1044#1080#1072#1087#1072#1079#1086#1085' '#1082#1072#1085#1072#1083#1086#1074' '#1040#1062#1055':'
    WordWrap = True
  end
  object lblMultiple: TLabel
    Left = 134
    Top = 28
    Width = 6
    Height = 13
    Caption = 'x'
  end
  object cmRangeIn: TComboBox
    Left = 8
    Top = 40
    Width = 73
    Height = 21
    Style = csDropDownList
    ItemIndex = 1
    TabOrder = 0
    Text = '1000 '#1084#1042
    Items.Strings = (
      '300 '#1084#1042
      '1000 '#1084#1042
      '3000 '#1084#1042)
  end
  object cmRangeOut: TComboBox
    Left = 8
    Top = 64
    Width = 73
    Height = 21
    Style = csDropDownList
    ItemIndex = 0
    TabOrder = 1
    Text = '300 '#1084#1042
    Items.Strings = (
      '300 '#1084#1042
      '1000 '#1084#1042
      '3000 '#1084#1042)
  end
  object btnSetAdcRanges: TButton
    Left = 8
    Top = 88
    Width = 75
    Height = 25
    Caption = #1055#1088#1080#1084#1077#1085#1080#1090#1100
    TabOrder = 2
    OnClick = btnSetAdcRangesClick
  end
  object edDataStep: TEdit
    Left = 144
    Top = 24
    Width = 41
    Height = 21
    TabOrder = 3
    Text = '1024'
  end
  object edSleepBetweenSetFreqAndDoSampling: TEdit
    Left = 104
    Top = 88
    Width = 65
    Height = 21
    TabOrder = 4
    Text = '10000'
  end
  object edBlocksToReadCount: TEdit
    Left = 104
    Top = 24
    Width = 25
    Height = 21
    TabOrder = 5
    Text = '1'
  end
end
