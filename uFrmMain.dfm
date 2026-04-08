object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'E20-10'
  ClientHeight = 703
  ClientWidth = 852
  Color = clBtnFace
  Constraints.MinWidth = 400
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object splitMain: TSplitter
    Left = 0
    Top = 337
    Width = 852
    Height = 3
    Cursor = crVSplit
    Align = alTop
    ExplicitWidth = 304
  end
  object stbBottom: TStatusBar
    Left = 0
    Top = 684
    Width = 852
    Height = 19
    Panels = <>
    ParentShowHint = False
    ShowHint = True
    SimplePanel = True
  end
  object sbResonances: TScrollBox
    Left = 0
    Top = 340
    Width = 852
    Height = 344
    Align = alClient
    Constraints.MinHeight = 10
    TabOrder = 1
  end
  object pnTop: TPanel
    Left = 0
    Top = 0
    Width = 852
    Height = 337
    Align = alTop
    Caption = 'pnTop'
    Constraints.MinHeight = 337
    ShowCaption = False
    TabOrder = 2
    object imgPlot: TImage
      Left = 140
      Top = 1
      Width = 711
      Height = 335
      Align = alClient
      OnMouseMove = imgPlotMouseMove
      ExplicitLeft = 280
      ExplicitTop = 112
      ExplicitWidth = 105
      ExplicitHeight = 105
    end
    object pnMain: TPanel
      Left = 1
      Top = 1
      Width = 139
      Height = 335
      Align = alLeft
      Caption = 'pnMain'
      ShowCaption = False
      TabOrder = 0
      object ggProgress: TGauge
        Left = 8
        Top = 40
        Width = 121
        Height = 25
        Progress = 0
      end
      object ggBufferFilling: TGauge
        Left = 8
        Top = 72
        Width = 57
        Height = 25
        Progress = 0
      end
      object shInputChannelOverflow: TShape
        Left = 72
        Top = 72
        Width = 25
        Height = 25
      end
      object shOutputChannelOverflow: TShape
        Left = 104
        Top = 72
        Width = 25
        Height = 25
      end
      object lblDacOutput: TLabel
        Left = 8
        Top = 156
        Width = 122
        Height = 13
        Caption = #1052#1085#1086#1078#1080#1090#1077#1083#1100' '#1072#1084#1087#1083#1080#1090#1091#1076#1099':'
      end
      object lblCalculationKind: TLabel
        Left = 8
        Top = 112
        Width = 101
        Height = 13
        Caption = #1052#1077#1090#1086#1076' '#1074#1099#1095#1080#1089#1083#1077#1085#1080#1103':'
      end
      object lblResonances: TLabel
        Left = 8
        Top = 264
        Width = 58
        Height = 13
        Caption = #1056#1077#1079#1086#1085#1072#1085#1089#1099':'
      end
      object btnStart: TButton
        Left = 8
        Top = 8
        Width = 57
        Height = 25
        Caption = #1055#1091#1089#1082
        TabOrder = 0
        OnClick = btnStartClick
      end
      object btnStop: TButton
        Left = 72
        Top = 8
        Width = 57
        Height = 25
        Caption = #1057#1090#1086#1087
        Enabled = False
        TabOrder = 1
        OnClick = btnStopClick
      end
      object rbStandartDeviation: TRadioButton
        Left = 16
        Top = 128
        Width = 49
        Height = 17
        Caption = #1057#1050#1054
        Checked = True
        TabOrder = 2
        TabStop = True
      end
      object rbFourierTransform: TRadioButton
        Left = 72
        Top = 128
        Width = 49
        Height = 17
        Caption = #1041#1055#1060
        TabOrder = 3
      end
      object edDacOutput: TEdit
        Left = 8
        Top = 176
        Width = 49
        Height = 21
        TabOrder = 4
        Text = '0,25'
        OnChange = edDacOutputChange
      end
      object btnDacOutputApply: TBitBtn
        Left = 60
        Top = 176
        Width = 21
        Height = 21
        Default = True
        Glyph.Data = {
          DE010000424DDE01000000000000760000002800000024000000120000000100
          0400000000006801000000000000000000001000000000000000000000000000
          80000080000000808000800000008000800080800000C0C0C000808080000000
          FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00333333333333
          3333333333333333333333330000333333333333333333333333F33333333333
          00003333344333333333333333388F3333333333000033334224333333333333
          338338F3333333330000333422224333333333333833338F3333333300003342
          222224333333333383333338F3333333000034222A22224333333338F338F333
          8F33333300003222A3A2224333333338F3838F338F33333300003A2A333A2224
          33333338F83338F338F33333000033A33333A222433333338333338F338F3333
          0000333333333A222433333333333338F338F33300003333333333A222433333
          333333338F338F33000033333333333A222433333333333338F338F300003333
          33333333A222433333333333338F338F00003333333333333A22433333333333
          3338F38F000033333333333333A223333333333333338F830000333333333333
          333A333333333333333338330000333333333333333333333333333333333333
          0000}
        ModalResult = 1
        NumGlyphs = 2
        TabOrder = 5
        Visible = False
        OnClick = btnDacOutputApplyClick
      end
      object chExcel: TCheckBox
        Left = 12
        Top = 208
        Width = 69
        Height = 17
        Caption = 'Excel'
        TabOrder = 6
        OnClick = chExcelClick
      end
      object chSeries: TCheckBox
        Left = 12
        Top = 232
        Width = 69
        Height = 17
        Caption = #1057#1077#1088#1080#1103
        TabOrder = 7
      end
      object edResonancesCount: TEdit
        Left = 8
        Top = 280
        Width = 69
        Height = 21
        ReadOnly = True
        TabOrder = 8
        Text = '0'
      end
      object btnDeleteResonance: TButton
        Left = 84
        Top = 280
        Width = 21
        Height = 21
        Caption = '-'
        TabOrder = 9
        OnClick = btnDeleteResonanceClick
      end
      object btnAddResonance: TButton
        Left = 108
        Top = 280
        Width = 21
        Height = 21
        Caption = '+'
        TabOrder = 10
        OnClick = btnAddResonanceClick
      end
      object cbResonances: TComboBox
        Left = 8
        Top = 304
        Width = 121
        Height = 21
        Style = csDropDownList
        TabOrder = 11
        OnChange = cbResonancesChange
      end
      object btnDacOutputCancel: TBitBtn
        Left = 84
        Top = 176
        Width = 21
        Height = 21
        Cancel = True
        Glyph.Data = {
          DE010000424DDE01000000000000760000002800000024000000120000000100
          0400000000006801000000000000000000001000000000000000000000000000
          80000080000000808000800000008000800080800000C0C0C000808080000000
          FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00333333333333
          333333333333333333333333000033338833333333333333333F333333333333
          0000333911833333983333333388F333333F3333000033391118333911833333
          38F38F333F88F33300003339111183911118333338F338F3F8338F3300003333
          911118111118333338F3338F833338F3000033333911111111833333338F3338
          3333F8330000333333911111183333333338F333333F83330000333333311111
          8333333333338F3333383333000033333339111183333333333338F333833333
          00003333339111118333333333333833338F3333000033333911181118333333
          33338333338F333300003333911183911183333333383338F338F33300003333
          9118333911183333338F33838F338F33000033333913333391113333338FF833
          38F338F300003333333333333919333333388333338FFF830000333333333333
          3333333333333333333888330000333333333333333333333333333333333333
          0000}
        ModalResult = 2
        NumGlyphs = 2
        TabOrder = 12
        Visible = False
        OnClick = btnDacOutputCancelClick
      end
    end
  end
  object ActionListMain: TActionList
    Left = 160
    Top = 16
    object actShowSettings: TAction
      Caption = #1053#1072#1089#1090#1088#1086#1081#1082#1080
      ShortCut = 121
      OnExecute = actShowSettingsExecute
    end
    object actRefreshPlot: TAction
      Caption = 'actRefreshPlot'
      ShortCut = 116
      OnExecute = actRefreshPlotExecute
    end
  end
  object TimerExcelSaving: TTimer
    Enabled = False
    OnTimer = TimerExcelSavingTimer
    Left = 160
    Top = 72
  end
end
