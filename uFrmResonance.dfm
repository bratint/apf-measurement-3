object frmResonance: TfrmResonance
  Left = 0
  Top = 0
  Width = 157
  Height = 402
  Color = clBtnFace
  ParentBackground = False
  ParentColor = False
  TabOrder = 0
  object pnMain: TPanel
    Left = 0
    Top = 0
    Width = 157
    Height = 402
    Align = alClient
    Caption = 'pnMain'
    ShowCaption = False
    TabOrder = 0
    object lblFreq: TLabel
      Left = 8
      Top = 36
      Width = 27
      Height = 13
      Caption = 'f, '#1043#1094':'
    end
    object lblMinus: TLabel
      Left = 8
      Top = 60
      Width = 4
      Height = 13
      Caption = '-'
    end
    object lblPlus: TLabel
      Left = 76
      Top = 60
      Width = 8
      Height = 13
      Caption = '+'
    end
    object lblSteps: TLabel
      Left = 8
      Top = 88
      Width = 29
      Height = 13
      Caption = #1096#1072#1075#1080':'
    end
    object shWatch: TShape
      Left = 5
      Top = 6
      Width = 19
      Height = 20
      Brush.Style = bsClear
      Pen.Color = 43775
      Pen.Width = 2
      Visible = False
    end
    object lblDelay: TLabel
      Left = 8
      Top = 112
      Width = 72
      Height = 13
      Caption = #1079#1072#1076#1077#1088#1078#1082#1072', '#1084#1089':'
    end
    object chWatch: TCheckBox
      Left = 8
      Top = 8
      Width = 137
      Height = 17
      Caption = #1057#1083#1077#1076#1080#1090#1100' '#1079#1072' '#1088#1077#1079#1086#1085#1072#1085#1089#1086#1084
      TabOrder = 0
      OnClick = chWatchClick
    end
    object edFreq: TEdit
      Left = 40
      Top = 32
      Width = 105
      Height = 21
      TabOrder = 1
      OnChange = edFreqChange
    end
    object edMinus: TEdit
      Left = 16
      Top = 56
      Width = 57
      Height = 21
      TabOrder = 2
      OnChange = edMinusChange
    end
    object edPlus: TEdit
      Left = 88
      Top = 56
      Width = 57
      Height = 21
      TabOrder = 3
      OnChange = edPlusChange
    end
    object btnFreqApply: TBitBtn
      Left = 104
      Top = 84
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
      TabOrder = 6
      Visible = False
      OnClick = btnFreqApplyClick
    end
    object btnFreqCancel: TBitBtn
      Left = 128
      Top = 84
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
      TabOrder = 7
      Visible = False
      OnClick = btnFreqCancelClick
    end
    object edSteps: TEdit
      Left = 40
      Top = 84
      Width = 57
      Height = 21
      TabOrder = 4
      Text = '100'
      OnChange = edStepsChange
    end
    object edDelay: TEdit
      Left = 88
      Top = 108
      Width = 57
      Height = 21
      TabOrder = 5
      Text = '500'
      OnChange = edDelayChange
    end
    object pnMagnitudePhaseSmooth: TPanel
      Left = 5
      Top = 136
      Width = 149
      Height = 205
      BevelInner = bvRaised
      BevelOuter = bvLowered
      Caption = 'pnMagnitudePhaseSmooth'
      ShowCaption = False
      TabOrder = 8
      object lblAmplitude: TLabel
        Left = 4
        Top = 4
        Width = 60
        Height = 13
        Caption = #1040#1084#1087#1083#1080#1090#1091#1076#1072':'
      end
      object lblAmplitudeN: TLabel
        Left = 4
        Top = 28
        Width = 10
        Height = 13
        Caption = 'n:'
      end
      object lblFreqAmplitude: TLabel
        Left = 4
        Top = 54
        Width = 31
        Height = 13
        Caption = 'fr, '#1043#1094':'
      end
      object lblFreqPhase: TLabel
        Left = 4
        Top = 156
        Width = 31
        Height = 13
        Caption = 'fr, '#1043#1094':'
      end
      object lblPhase: TLabel
        Left = 4
        Top = 106
        Width = 101
        Height = 13
        Caption = #1055#1088#1086#1080#1079#1074#1086#1076#1085#1072#1103' '#1092#1072#1079#1099':'
      end
      object lblPhaseN: TLabel
        Left = 4
        Top = 128
        Width = 10
        Height = 13
        Caption = 'n:'
      end
      object lblQuality: TLabel
        Left = 4
        Top = 180
        Width = 12
        Height = 13
        Caption = 'Q:'
      end
      object lblResistance: TLabel
        Left = 4
        Top = 78
        Width = 32
        Height = 13
        Caption = 'R, '#1054#1084':'
      end
      object seAmplitudeN: TSpinEdit
        Left = 20
        Top = 24
        Width = 57
        Height = 22
        MaxValue = 65535
        MinValue = 1
        TabOrder = 0
        Value = 1
        OnChange = seAmplitudeNChange
      end
      object sePhaseDN: TSpinEdit
        Left = 84
        Top = 124
        Width = 57
        Height = 22
        MaxValue = 65535
        MinValue = 1
        TabOrder = 1
        Value = 1
        OnChange = sePhaseDNChange
      end
      object sePhaseN: TSpinEdit
        Left = 20
        Top = 124
        Width = 57
        Height = 22
        MaxValue = 65535
        MinValue = 1
        TabOrder = 2
        Value = 1
        OnChange = sePhaseNChange
      end
      object btnNApply: TBitBtn
        Left = 99
        Top = 24
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
        TabOrder = 3
        Visible = False
        OnClick = btnNApplyClick
      end
      object btnNCancel: TBitBtn
        Left = 122
        Top = 24
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
        TabOrder = 4
        Visible = False
        OnClick = btnNCancelClick
      end
      object edFreqAmplitude: TEdit
        Left = 36
        Top = 50
        Width = 105
        Height = 21
        ParentShowHint = False
        ReadOnly = True
        ShowHint = False
        TabOrder = 5
      end
      object edFreqPhase: TEdit
        Left = 36
        Top = 152
        Width = 105
        Height = 21
        ParentShowHint = False
        ReadOnly = True
        ShowHint = False
        TabOrder = 6
      end
      object edQuality: TEdit
        Left = 36
        Top = 176
        Width = 105
        Height = 21
        ParentShowHint = False
        ReadOnly = True
        ShowHint = False
        TabOrder = 7
      end
      object edResistance: TEdit
        Left = 36
        Top = 74
        Width = 105
        Height = 21
        ParentShowHint = False
        ReadOnly = True
        ShowHint = False
        TabOrder = 8
      end
    end
    object pnFrequencySmooth: TPanel
      Left = 5
      Top = 344
      Width = 149
      Height = 54
      BevelInner = bvRaised
      BevelOuter = bvLowered
      Caption = 'pnMagnitudePhaseSmooth'
      ShowCaption = False
      TabOrder = 9
      object lblFreqSmooth: TLabel
        Left = 4
        Top = 4
        Width = 46
        Height = 13
        Caption = #1063#1072#1089#1090#1086#1090#1072':'
      end
      object lblFreqN: TLabel
        Left = 4
        Top = 28
        Width = 10
        Height = 13
        Caption = 'n:'
      end
      object seFreqN: TSpinEdit
        Left = 20
        Top = 24
        Width = 57
        Height = 22
        MaxValue = 65535
        MinValue = 1
        TabOrder = 0
        Value = 1
        OnChange = seFreqNChange
      end
      object btnFreqNApply: TBitBtn
        Left = 99
        Top = 24
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
        TabOrder = 1
        Visible = False
        OnClick = btnFreqNApplyClick
      end
      object btnFreqNCancel: TBitBtn
        Left = 122
        Top = 24
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
        TabOrder = 2
        Visible = False
        OnClick = btnFreqNCancelClick
      end
    end
  end
end
