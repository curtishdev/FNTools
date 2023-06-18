/*     
     FNTools Aim Assist
     New colors, working
     [UNDETECT] 2023
     Developed by curtishDEV
     -=2023=-
     All rights reserved (C) 
     CurtishDEV (C) 2018 - 2023 
*/

﻿/*

IniRead, HPCoords, %A_ScriptDir%\Config.ini, HPAlerts, HPCoords
IniRead, BPCoords, %A_ScriptDir%\Config.ini, BattlePass, BPCoords
IniRead, BPCoords, %A_ScriptDir%\Config.ini, BattlePass, Rewards
IniRead, BPCoords, %A_ScriptDir%\Config.ini, BattlePass, ClaimPage
IniRead, BPCoords, %A_ScriptDir%\Config.ini, BattlePass, Claim
IniRead, Slot, %A_ScriptDir%\Config.ini, HP, Slot
*/

UseGDIP(Params*) { ; Loads and initializes the Gdiplus.dll at load-time
   Static GdipObject := ""
        , GdipModule := ""
        , GdipToken  := ""
   Static OnLoad := UseGDIP()
   If (GdipModule = "") {
      If !DllCall("LoadLibrary", "Str", "Gdiplus.dll", "UPtr")
         UseGDIP_Error("The Gdiplus.dll could not be loaded!`n`nThe program will exit!")
      If !DllCall("GetModuleHandleEx", "UInt", 0x00000001, "Str", "Gdiplus.dll", "PtrP", GdipModule, "UInt")
         UseGDIP_Error("The Gdiplus.dll could not be loaded!`n`nThe program will exit!")
      VarSetCapacity(SI, 24, 0), NumPut(1, SI, 0, "UInt") ; size of 64-bit structure
      If DllCall("Gdiplus.dll\GdiplusStartup", "PtrP", GdipToken, "Ptr", &SI, "Ptr", 0)
         UseGDIP_Error("GDI+ could not be startet!`n`nThe program will exit!")
      GdipObject := {Base: {__Delete: Func("UseGDIP").Bind(GdipModule, GdipToken)}}
   }
   Else If (Params[1] = GdipModule) && (Params[2] = GdipToken)
      DllCall("Gdiplus.dll\GdiplusShutdown", "Ptr", GdipToken)
}
UseGDIP_Error(ErrorMsg) {
   MsgBox, 262160, UseGDIP, %ErrorMsg%
   ExitApp
}


Class ImageButton {

   Static DefGuiColor  := ""        ; default GUI color                             (read/write)
   Static DefTxtColor := "Black"    ; default caption color                         (read/write)
   Static LastError := ""           ; will contain the last error message, if any   (readonly)

   Static BitMaps := []
   Static GDIPDll := 0
   Static GDIPToken := 0
   Static MaxOptions := 8

   Static HTML := {BLACK: 0x000000, GRAY: 0x808080, SILVER: 0xC0C0C0, WHITE: 0xFFFFFF, MAROON: 0x800000
                 , PURPLE: 0x800080, FUCHSIA: 0xFF00FF, RED: 0xFF0000, GREEN: 0x008000, OLIVE: 0x808000
                 , YELLOW: 0xFFFF00, LIME: 0x00FF00, NAVY: 0x000080, TEAL: 0x008080, AQUA: 0x00FFFF, BLUE: 0x0000FF}

   Static ClassInit := ImageButton.InitClass()

   __New(P*) {
      Return False
   }
   
   InitClass() {
      GuiColor := DllCall("User32.dll\GetSysColor", "Int", 15, "UInt") ; COLOR_3DFACE is used by AHK as default
      This.DefGuiColor := ((GuiColor >> 16) & 0xFF) | (GuiColor & 0x00FF00) | ((GuiColor & 0xFF) << 16)
      Return True
   }
   BitmapOrIcon(O2, O3) {
      Return (This.IsInt(O2) && (O3 = "HICON")) || (DllCall("GetObjectType", "Ptr", O2, "UInt") = 7) || FileExist(O2)
   }
   FreeBitmaps() {
      For I, HBITMAP In This.BitMaps
         DllCall("Gdi32.dll\DeleteObject", "Ptr", HBITMAP)
      This.BitMaps := []
   }
   GetARGB(RGB) {
      ARGB := This.HTML.HasKey(RGB) ? This.HTML[RGB] : RGB
      Return (ARGB & 0xFF000000) = 0 ? 0xFF000000 | ARGB : ARGB
   }
   IsInt(Val) {
      If Val Is Integer
         Return True
      Return False
   }
   PathAddRectangle(Path, X, Y, W, H) {
      Return DllCall("Gdiplus.dll\GdipAddPathRectangle", "Ptr", Path, "Float", X, "Float", Y, "Float", W, "Float", H)
   }
   PathAddRoundedRect(Path, X1, Y1, X2, Y2, R) {
      D := (R * 2), X2 -= D, Y2 -= D
      DllCall("Gdiplus.dll\GdipAddPathArc"
            , "Ptr", Path, "Float", X1, "Float", Y1, "Float", D, "Float", D, "Float", 180, "Float", 90)
      DllCall("Gdiplus.dll\GdipAddPathArc"
            , "Ptr", Path, "Float", X2, "Float", Y1, "Float", D, "Float", D, "Float", 270, "Float", 90)
      DllCall("Gdiplus.dll\GdipAddPathArc"
            , "Ptr", Path, "Float", X2, "Float", Y2, "Float", D, "Float", D, "Float", 0, "Float", 90)
      DllCall("Gdiplus.dll\GdipAddPathArc"
            , "Ptr", Path, "Float", X1, "Float", Y2, "Float", D, "Float", D, "Float", 90, "Float", 90)
      Return DllCall("Gdiplus.dll\GdipClosePathFigure", "Ptr", Path)
   }
   SetRect(ByRef Rect, X1, Y1, X2, Y2) {
      VarSetCapacity(Rect, 16, 0)
      NumPut(X1, Rect, 0, "Int"), NumPut(Y1, Rect, 4, "Int")
      NumPut(X2, Rect, 8, "Int"), NumPut(Y2, Rect, 12, "Int")
      Return True
   }
   SetRectF(ByRef Rect, X, Y, W, H) {
      VarSetCapacity(Rect, 16, 0)
      NumPut(X, Rect, 0, "Float"), NumPut(Y, Rect, 4, "Float")
      NumPut(W, Rect, 8, "Float"), NumPut(H, Rect, 12, "Float")
      Return True
   }
   SetError(Msg) {
      If (This.Bitmap)
         DllCall("Gdiplus.dll\GdipDisposeImage", "Ptr", This.Bitmap)
      If (This.Graphics)
         DllCall("Gdiplus.dll\GdipDeleteGraphics", "Ptr", This.Graphics)
      If (This.Font)
         DllCall("Gdiplus.dll\GdipDeleteFont", "Ptr", This.Font)
      This.Delete("Bitmap")
      This.Delete("Graphics")
      This.Delete("Font")
      This.FreeBitmaps()
      This.LastError := Msg
      Return False
   }
   Create(HWND, Options*) {
      Static BCM_GETIMAGELIST := 0x1603, BCM_SETIMAGELIST := 0x1602
           , BS_CHECKBOX := 0x02, BS_RADIOBUTTON := 0x04, BS_GROUPBOX := 0x07, BS_AUTORADIOBUTTON := 0x09
           , BS_LEFT := 0x0100, BS_RIGHT := 0x0200, BS_CENTER := 0x0300, BS_TOP := 0x0400, BS_BOTTOM := 0x0800
           , BS_VCENTER := 0x0C00, BS_BITMAP := 0x0080
           , BUTTON_IMAGELIST_ALIGN_LEFT := 0, BUTTON_IMAGELIST_ALIGN_RIGHT := 1, BUTTON_IMAGELIST_ALIGN_CENTER := 4
           , ILC_COLOR32 := 0x20
           , OBJ_BITMAP := 7
           , RCBUTTONS := BS_CHECKBOX | BS_RADIOBUTTON | BS_AUTORADIOBUTTON
           , SA_LEFT := 0x00, SA_CENTER := 0x01, SA_RIGHT := 0x02
           , WM_GETFONT := 0x31
      This.LastError := ""
      HBITMAP := HFORMAT := PBITMAP := PBRUSH := PFONT := PPATH := 0
      If !DllCall("User32.dll\IsWindow", "Ptr", HWND)
         Return This.SetError("Invalid parameter HWND!")
      If !(IsObject(Options)) || (Options.MinIndex() <> 1) || (Options.MaxIndex() > This.MaxOptions)
         Return This.SetError("Invalid parameter Options!")
      WinGetClass, BtnClass, ahk_id %HWND%
      ControlGet, BtnStyle, Style, , , ahk_id %HWND%
      If (BtnClass != "Button") || ((BtnStyle & 0xF ^ BS_GROUPBOX) = 0) || ((BtnStyle & RCBUTTONS) > 1)
         Return This.SetError("The control must be a pushbutton!")
      HFONT := DllCall("User32.dll\SendMessage", "Ptr", HWND, "UInt", WM_GETFONT, "Ptr", 0, "Ptr", 0, "Ptr")
      DC := DllCall("User32.dll\GetDC", "Ptr", HWND, "Ptr")
      DllCall("Gdi32.dll\SelectObject", "Ptr", DC, "Ptr", HFONT)
      DllCall("Gdiplus.dll\GdipCreateFontFromDC", "Ptr", DC, "PtrP", PFONT)
      DllCall("User32.dll\ReleaseDC", "Ptr", HWND, "Ptr", DC)
      If !(This.Font := PFONT)
         Return This.SetError("Couldn't get button's font!")
      VarSetCapacity(RECT, 16, 0)
      If !DllCall("User32.dll\GetWindowRect", "Ptr", HWND, "Ptr", &RECT)
         Return This.SetError("Couldn't get button's rectangle!")
      BtnW := NumGet(RECT,  8, "Int") - NumGet(RECT, 0, "Int")
      BtnH := NumGet(RECT, 12, "Int") - NumGet(RECT, 4, "Int")
      ControlGetText, BtnCaption, , ahk_id %HWND%
      If (ErrorLevel)
         Return This.SetError("Couldn't get button's caption!")
      DllCall("Gdiplus.dll\GdipCreateBitmapFromScan0", "Int", BtnW, "Int", BtnH, "Int", 0
            , "UInt", 0x26200A, "Ptr", 0, "PtrP", PBITMAP)
      If !(This.Bitmap := PBITMAP)
         Return This.SetError("Couldn't create the GDI+ bitmap!")
      PGRAPHICS := 0
      DllCall("Gdiplus.dll\GdipGetImageGraphicsContext", "Ptr", PBITMAP, "PtrP", PGRAPHICS)
      If !(This.Graphics := PGRAPHICS)
         Return This.SetError("Couldn't get the the GDI+ bitmap's graphics!")
      DllCall("Gdiplus.dll\GdipSetSmoothingMode", "Ptr", PGRAPHICS, "UInt", 4)
      DllCall("Gdiplus.dll\GdipSetInterpolationMode", "Ptr", PGRAPHICS, "Int", 7)
      DllCall("Gdiplus.dll\GdipSetCompositingQuality", "Ptr", PGRAPHICS, "UInt", 4)
      DllCall("Gdiplus.dll\GdipSetRenderingOrigin", "Ptr", PGRAPHICS, "Int", 0, "Int", 0)
      DllCall("Gdiplus.dll\GdipSetPixelOffsetMode", "Ptr", PGRAPHICS, "UInt", 4)
      This.BitMaps := []
      For Idx, Opt In Options {
         If !IsObject(Opt)
            Continue
         BkgColor1 := BkgColor2 := TxtColor := Mode := Rounded := GuiColor := Image := ""
         Loop, % This.MaxOptions {
            If (Opt[A_Index] = "")
               Opt[A_Index] := Options[1, A_Index]
         }
         Mode := SubStr(Opt[1], 1 ,1)
         If !InStr("0123456789", Mode)
            Return This.SetError("Invalid value for Mode in Options[" . Idx . "]!")
         If (Mode = 0) && This.BitmapOrIcon(Opt[2], Opt[3])
            Image := Opt[2]
         Else {
            If !This.IsInt(Opt[2]) && !This.HTML.HasKey(Opt[2])
               Return This.SetError("Invalid value for StartColor in Options[" . Idx . "]!")
            BkgColor1 := This.GetARGB(Opt[2])
            If (Opt[3] = "")
               Opt[3] := Opt[2]
            If !This.IsInt(Opt[3]) && !This.HTML.HasKey(Opt[3])
               Return This.SetError("Invalid value for TargetColor in Options[" . Idx . "]!")
            BkgColor2 := This.GetARGB(Opt[3])
         }
         If (Opt[4] = "")
            Opt[4] := This.DefTxtColor
         If !This.IsInt(Opt[4]) && !This.HTML.HasKey(Opt[4])
            Return This.SetError("Invalid value for TxtColor in Options[" . Idx . "]!")
         TxtColor := This.GetARGB(Opt[4])
         Rounded := Opt[5]
         If (Rounded = "H")
            Rounded := BtnH * 0.5
         If (Rounded = "W")
            Rounded := BtnW * 0.5
         If ((Rounded + 0) = "")
            Rounded := 0
         If (Opt[6] = "")
            Opt[6] := This.DefGuiColor
         If !This.IsInt(Opt[6]) && !This.HTML.HasKey(Opt[6])
            Return This.SetError("Invalid value for GuiColor in Options[" . Idx . "]!")
         GuiColor := This.GetARGB(Opt[6])
         BorderColor := ""
         If (Opt[7] <> "") {
            If !This.IsInt(Opt[7]) && !This.HTML.HasKey(Opt[7])
               Return This.SetError("Invalid value for BorderColor in Options[" . Idx . "]!")
            BorderColor := 0xFF000000 | This.GetARGB(Opt[7]) ; BorderColor must be always opaque
         }
         BorderWidth := Opt[8] ? Opt[8] : 1
         DllCall("Gdiplus.dll\GdipGraphicsClear", "Ptr", PGRAPHICS, "UInt", GuiColor)
         If (Image = "") { ; Create a BitMap based on the specified colors
            PathX := PathY := 0, PathW := BtnW, PathH := BtnH
            DllCall("Gdiplus.dll\GdipCreatePath", "UInt", 0, "PtrP", PPATH)
            If (Rounded < 1) ; the path is a rectangular rectangle
               This.PathAddRectangle(PPATH, PathX, PathY, PathW, PathH)
            Else ; the path is a rounded rectangle
               This.PathAddRoundedRect(PPATH, PathX, PathY, PathW, PathH, Rounded)
            If (BorderColor <> "") && (BorderWidth > 0) && (Mode <> 7) {
               DllCall("Gdiplus.dll\GdipCreateSolidFill", "UInt", BorderColor, "PtrP", PBRUSH)
               DllCall("Gdiplus.dll\GdipFillPath", "Ptr", PGRAPHICS, "Ptr", PBRUSH, "Ptr", PPATH)
               DllCall("Gdiplus.dll\GdipDeleteBrush", "Ptr", PBRUSH)
               DllCall("Gdiplus.dll\GdipResetPath", "Ptr", PPATH)
               PathX := PathY := BorderWidth, PathW -= BorderWidth, PathH -= BorderWidth, Rounded -= BorderWidth
               If (Rounded < 1) ; the path is a rectangular rectangle
                  This.PathAddRectangle(PPATH, PathX, PathY, PathW - PathX, PathH - PathY)
               Else ; the path is a rounded rectangle
                  This.PathAddRoundedRect(PPATH, PathX, PathY, PathW, PathH, Rounded)
               BkgColor1 := 0xFF000000 | BkgColor1
               BkgColor2 := 0xFF000000 | BkgColor2               
            }
            PathW -= PathX
            PathH -= PathY
            PBRUSH := 0
            If (Mode = 0) { ; the background is unicolored
               DllCall("Gdiplus.dll\GdipCreateSolidFill", "UInt", BkgColor1, "PtrP", PBRUSH)
               DllCall("Gdiplus.dll\GdipFillPath", "Ptr", PGRAPHICS, "Ptr", PBRUSH, "Ptr", PPATH)
            }
            Else If (Mode = 1) || (Mode = 2) { ; the background is bicolored
               This.SetRectF(RECTF, PathX, PathY, PathW, PathH)
               DllCall("Gdiplus.dll\GdipCreateLineBrushFromRect", "Ptr", &RECTF
                     , "UInt", BkgColor1, "UInt", BkgColor2, "Int", Mode & 1, "Int", 3, "PtrP", PBRUSH)
               DllCall("Gdiplus.dll\GdipSetLineGammaCorrection", "Ptr", PBRUSH, "Int", 1)
               This.SetRect(COLORS, BkgColor1, BkgColor1, BkgColor2, BkgColor2) ; sorry for function misuse
               This.SetRectF(POSITIONS, 0, 0.5, 0.5, 1) ; sorry for function misuse
               DllCall("Gdiplus.dll\GdipSetLinePresetBlend", "Ptr", PBRUSH
                     , "Ptr", &COLORS, "Ptr", &POSITIONS, "Int", 4)
               DllCall("Gdiplus.dll\GdipFillPath", "Ptr", PGRAPHICS, "Ptr", PBRUSH, "Ptr", PPATH)
            }
            Else If (Mode >= 3) && (Mode <= 6) { ; the background is a gradient
               W := Mode = 6 ? PathW / 2 : PathW  ; horizontal
               H := Mode = 5 ? PathH / 2 : PathH  ; vertical
               This.SetRectF(RECTF, PathX, PathY, W, H)
               DllCall("Gdiplus.dll\GdipCreateLineBrushFromRect", "Ptr", &RECTF
                     , "UInt", BkgColor1, "UInt", BkgColor2, "Int", Mode & 1, "Int", 3, "PtrP", PBRUSH)
               DllCall("Gdiplus.dll\GdipSetLineGammaCorrection", "Ptr", PBRUSH, "Int", 1)
               DllCall("Gdiplus.dll\GdipFillPath", "Ptr", PGRAPHICS, "Ptr", PBRUSH, "Ptr", PPATH)
            }
            Else { ; raised mode
               DllCall("Gdiplus.dll\GdipCreatePathGradientFromPath", "Ptr", PPATH, "PtrP", PBRUSH)
               DllCall("Gdiplus.dll\GdipSetPathGradientGammaCorrection", "Ptr", PBRUSH, "UInt", 1)
               VarSetCapacity(ColorArray, 4, 0)
               NumPut(BkgColor1, ColorArray, 0, "UInt")
               DllCall("Gdiplus.dll\GdipSetPathGradientSurroundColorsWithCount", "Ptr", PBRUSH, "Ptr", &ColorArray
                   , "IntP", 1)
               DllCall("Gdiplus.dll\GdipSetPathGradientCenterColor", "Ptr", PBRUSH, "UInt", BkgColor2)
               FS := (BtnH < BtnW ? BtnH : BtnW) / 3
               XScale := (BtnW - FS) / BtnW
               YScale := (BtnH - FS) / BtnH
               DllCall("Gdiplus.dll\GdipSetPathGradientFocusScales", "Ptr", PBRUSH, "Float", XScale, "Float", YScale)
               DllCall("Gdiplus.dll\GdipFillPath", "Ptr", PGRAPHICS, "Ptr", PBRUSH, "Ptr", PPATH)
            }
            DllCall("Gdiplus.dll\GdipDeleteBrush", "Ptr", PBRUSH)
            DllCall("Gdiplus.dll\GdipDeletePath", "Ptr", PPATH)
         } Else { ; Create a bitmap from HBITMAP or file
            If This.IsInt(Image)
               If (Opt[3] = "HICON")
                  DllCall("Gdiplus.dll\GdipCreateBitmapFromHICON", "Ptr", Image, "PtrP", PBM)
               Else
                  DllCall("Gdiplus.dll\GdipCreateBitmapFromHBITMAP", "Ptr", Image, "Ptr", 0, "PtrP", PBM)
            Else
               DllCall("Gdiplus.dll\GdipCreateBitmapFromFile", "WStr", Image, "PtrP", PBM)
            DllCall("Gdiplus.dll\GdipDrawImageRectI", "Ptr", PGRAPHICS, "Ptr", PBM, "Int", 0, "Int", 0
                  , "Int", BtnW, "Int", BtnH)
            DllCall("Gdiplus.dll\GdipDisposeImage", "Ptr", PBM)
         }
         If (BtnCaption <> "") {
            DllCall("Gdiplus.dll\GdipStringFormatGetGenericTypographic", "PtrP", HFORMAT)
            DllCall("Gdiplus.dll\GdipCreateSolidFill", "UInt", TxtColor, "PtrP", PBRUSH)
            HALIGN := (BtnStyle & BS_CENTER) = BS_CENTER ? SA_CENTER
                    : (BtnStyle & BS_CENTER) = BS_RIGHT  ? SA_RIGHT
                    : (BtnStyle & BS_CENTER) = BS_Left   ? SA_LEFT
                    : SA_CENTER
            DllCall("Gdiplus.dll\GdipSetStringFormatAlign", "Ptr", HFORMAT, "Int", HALIGN)
            VALIGN := (BtnStyle & BS_VCENTER) = BS_TOP ? 0
                    : (BtnStyle & BS_VCENTER) = BS_BOTTOM ? 2
                    : 1
            DllCall("Gdiplus.dll\GdipSetStringFormatLineAlign", "Ptr", HFORMAT, "Int", VALIGN)
            DllCall("Gdiplus.dll\GdipSetTextRenderingHint", "Ptr", PGRAPHICS, "Int", 0)
            VarSetCapacity(RECT, 16, 0)
            NumPut(BtnW, RECT,  8, "Float")
            NumPut(BtnH, RECT, 12, "Float")
            DllCall("Gdiplus.dll\GdipDrawString", "Ptr", PGRAPHICS, "WStr", BtnCaption, "Int", -1
                  , "Ptr", PFONT, "Ptr", &RECT, "Ptr", HFORMAT, "Ptr", PBRUSH)
         }
         DllCall("Gdiplus.dll\GdipCreateHBITMAPFromBitmap", "Ptr", PBITMAP, "PtrP", HBITMAP, "UInt", 0X00FFFFFF)
         This.BitMaps[Idx] := HBITMAP
         DllCall("Gdiplus.dll\GdipDeleteBrush", "Ptr", PBRUSH)
         DllCall("Gdiplus.dll\GdipDeleteStringFormat", "Ptr", HFORMAT)
      }
      DllCall("Gdiplus.dll\GdipDisposeImage", "Ptr", PBITMAP)
      DllCall("Gdiplus.dll\GdipDeleteGraphics", "Ptr", PGRAPHICS)
      DllCall("Gdiplus.dll\GdipDeleteFont", "Ptr", PFONT)
      This.Delete("Bitmap")
      This.Delete("Graphics")
      This.Delete("Font")
      HIL := DllCall("Comctl32.dll\ImageList_Create"
                   , "UInt", BtnW, "UInt", BtnH, "UInt", ILC_COLOR32, "Int", 6, "Int", 0, "Ptr")
      Loop, % (This.BitMaps.MaxIndex() > 1 ? 6 : 1) {
         HBITMAP := This.BitMaps.HasKey(A_Index) ? This.BitMaps[A_Index] : This.BitMaps.1
         DllCall("Comctl32.dll\ImageList_Add", "Ptr", HIL, "Ptr", HBITMAP, "Ptr", 0)
      }
      VarSetCapacity(BIL, 20 + A_PtrSize, 0)
      DllCall("User32.dll\SendMessage", "Ptr", HWND, "UInt", BCM_GETIMAGELIST, "Ptr", 0, "Ptr", &BIL)
      IL := NumGet(BIL, "UPtr")
      VarSetCapacity(BIL, 20 + A_PtrSize, 0)
      NumPut(HIL, BIL, 0, "Ptr")
      Numput(BUTTON_IMAGELIST_ALIGN_CENTER, BIL, A_PtrSize + 16, "UInt")
      ControlSetText, , , ahk_id %HWND%
      Control, Style, +%BS_BITMAP%, , ahk_id %HWND%
      If(IL)
         IL_Destroy(IL)
      DllCall("User32.dll\SendMessage", "Ptr", HWND, "UInt", BCM_SETIMAGELIST, "Ptr", 0, "Ptr", 0)
      DllCall("User32.dll\SendMessage", "Ptr", HWND, "UInt", BCM_SETIMAGELIST, "Ptr", 0, "Ptr", &BIL)
      This.FreeBitmaps()
      Return True
   }
   SetGuiColor(GuiColor) {
      If !(GuiColor + 0) && !This.HTML.HasKey(GuiColor)
         Return False
      This.DefGuiColor := (This.HTML.HasKey(GuiColor) ? This.HTML[GuiColor] : GuiColor) & 0xFFFFFF
      Return True
   }
   SetTxtColor(TxtColor) {
      If !(TxtColor + 0) && !This.HTML.HasKey(TxtColor)
         Return False
      This.DefTxtColor := (This.HTML.HasKey(TxtColor) ? This.HTML[TxtColor] : TxtColor) & 0xFFFFFF
      Return True
   }
}

; ====================================MAIN CODE=====================================================================================

F1::

URLDownloadToFile, https://github.com//FNTools/raw/main/FNTools.jpg, %a_temp%/FNTools.jpg

#NoEnv
SetBatchLines, -1
GUI -Caption +ToolWindow
WinSet, Region, 50-0 W840 H349 R40-40, WinTitle 
Gui, Show, W840 H349
Gui, Add, Picture, x0 y0 w840 h349 , %a_temp%/FNTools.jpg

Gui, Font, s15 Aerial Black, FNTools

Gui, Add, Button, x10  y10 w200 h40 gHPAlerts hWndhBtn63, % "HP Alert"
IBBtnStyles := [ [0, 0x6632ba, , , 0, , 0x33195d, 2]      ; Цвет Внутри/Рамка
			   , [0, 0x5c2da7, , , 0, , 0x33195d, 2]      ; Ожидание Клика
			   , [0, 0x522895, , , 0, , 0x6632ba, 2]      ; При Нажатии
			   , [0, 0x472382, , , 0, , 0x6632ba, 2] ]
ImageButton.Create(hBtn63, IBBtnStyles*)

Gui, Add, Button, x10  y55 w200 h40 gBattlePass hWndhBtn63, % "BP Climer"
IBBtnStyles := [ [0, 0x6632ba, , , 0, , 0x33195d, 2]      ; Цвет Внутри/Рамка
			   , [0, 0x5c2da7, , , 0, , 0x33195d, 2]      ; Ожидание Клика
			   , [0, 0x522895, , , 0, , 0x6632ba, 2]      ; При Нажатии
			   , [0, 0x472382, , , 0, , 0x6632ba, 2] ]
ImageButton.Create(hBtn63, IBBtnStyles*)

Gui, Add, Button, x10  y100 w200 h40 gSettings hWndhBtn63, % "Settings"
IBBtnStyles := [ [0, 0x6632ba, , , 0, , 0x33195d, 2]      ; Цвет Внутри/Рамка
			   , [0, 0x5c2da7, , , 0, , 0x33195d, 2]      ; Ожидание Клика
			   , [0, 0x522895, , , 0, , 0x6632ba, 2]      ; При Нажатии
			   , [0, 0x472382, , , 0, , 0x6632ba, 2] ]
ImageButton.Create(hBtn63, IBBtnStyles*)

Gui, Show,, FNTools

return

HPAlerts:
Gui, Destroy
MsgBox, 0x40, FNTools, Определение урона запущено!, 5
Sleep, 3000
Cfg=%A_ScriptDir%\FNToolsSettings\Settings.ini
FileGetSize,size,%Cfg%,
If(Size=0)
{
	MsgBox, 0x30, FNTools, Заполните конфигурацию!, 5
}

Else
{
Loop
{
if WinActive("ahk_exe FortniteClient-Win64-Shipping.exe")
{
    PixelGetColor, hp, 388,961, RGB
    if(hp == 0x9CEF67)

    {  
       Continue
    }

    Else

    {
        PixelGetColor, players, 1489, 284, RGB
        if (players == 0xFFFFFF)
        {
           MsgBox, 4, FNTools, У вас мало HP!`nХотите запиться?, 5
           IfMsgBox Yes
           {
             Send, %Slot%
             Sleep, 1
             Click
           }
           Sleep, 10000
        }
    

    Else
    
    PixelGetColor, inv, 1087, 268, RGB
     if (inv == 0xDDDA90)
     {
      ;MsgBox, 0x30, FNTools, Вы в инвентаре!, 5
      Sleep, 10000
      Continue
     }
    
    Else

        PixelGetColor, exitgame, 37, 989, RGB
        if (exitgame == 0xFC8376)
        {
          ;MsgBox, 0x30, FNTools, Вы покидаете матч!, 5
          Sleep, 10000
          Continue
        }
      
    Else
      
        PixelGetColor, lobby, 111, 47, RGB
        if (lobby == 0xFFFFFF)
        {
          MsgBox, 0x30, FNTools, Вы в лобби!, 5
          Sleep, 10000
          Continue
        }
      

    Else

        MsgBox, 0x30, FNTools, Вы не в матче!`nЗайдите в матч!, 5
        Sleep, 10000
        Continue

    }
}

    Else

        MsgBox, 0x30, FNTools, Вы не в Fortnite!`nЗайдите в игру!, 5
        Sleep, 10000
        Continue

}
}

BattlePass:
{
Gui, Destroy
MsgBox, 0x40, FNTools, Получение наград запущено!, 5
Cfg=%A_ScriptDir%\FNToolsSettings\Settings.ini
FileGetSize,size,%Cfg%,
If(Size=0)
{
	MsgBox, 0x30, FNTools, Заполните конфигурацию!, 5
}
Else
{
SendEvent, {Click,%BPCoords%,1}
SendEvent, {Click,%Rewards%,1}
SendEvent, {Click,%ClaimPage%,1}
SendEvent, {Click,%Claim%,1}
ExitApp
}
}

Settings:
Gui, Destroy
Gui,2: -Caption +ToolWindow
WinSet, Region, 50-0 W840 H349 R40-40, WinTitle 
Gui,2: Show, W840 H349
Gui,2: Add, Picture, x0 y0 w840 h349 , %a_temp%/FNTools.jpg
Gui,2: Font, s15 Aerial Black, FNTools
Gui,2: Add, Button, x10  y10 w200 h40 gHPCoords hWndhBtn63, % "HP Settings"
IBBtnStyles := [ [0, 0x6632ba, , , 0, , 0x33195d, 2]      ; Цвет Внутри/Рамка
			   , [0, 0x5c2da7, , , 0, , 0x33195d, 2]      ; Ожидание Клика
			   , [0, 0x522895, , , 0, , 0x6632ba, 2]      ; При Нажатии
			   , [0, 0x472382, , , 0, , 0x6632ba, 2] ]
ImageButton.Create(hBtn63, IBBtnStyles*)

Gui,2: Add, Button, x10  y55 w200 h40 gBPCoords hWndhBtn63, % "BP Settings"
IBBtnStyles := [ [0, 0x6632ba, , , 0, , 0x33195d, 2]      ; Цвет Внутри/Рамка
			   , [0, 0x5c2da7, , , 0, , 0x33195d, 2]      ; Ожидание Клика
			   , [0, 0x522895, , , 0, , 0x6632ba, 2]      ; При Нажатии
			   , [0, 0x472382, , , 0, , 0x6632ba, 2] ]
ImageButton.Create(hBtn63, IBBtnStyles*)

Gui,2: Show,, FNTools Settings

HPCoords:
{
FileCreateDir, %A_ScriptDir%\FNToolsSettings
IniRead, HPCoords, %A_ScriptDir%\FNToolsSettings\Settings.ini, HPAlerts, HPCoords
Gui 3: Add, Text, x10 ,Укажите координаты зеленой шкалы HP:
Gui 3: Add, Edit, w200 h40 vHPCoords,
Gui 3: Add, Button, x10 w80 gInitializeHPCoords, Сохранить
Gui 3: Show, w300 h100, Координаты HP
return

InitializeHPCoords:
{
Gui 3: Submit
IniWrite, %HPCoords%, %A_ScriptDir%\FNToolsSettings\Settings.ini, HPAlerts, HPCoords
IniRead, HPCoords, %A_ScriptDir%\FNToolsSettings\Settings.ini, HPAlerts, HPCoords
msgbox, 0x40, FNTools, Вы указали координаты: %HPCoords%
return
}
}


BPCoords:
{
FileCreateDir, %A_ScriptDir%\FNToolsSettings
IniRead, BPCoords, %A_ScriptDir%\FNToolsSettings\Settings.ini, BattlePass, BPCoords
Gui 4: Add, Text, x10 ,Укажите координаты BP вкладки в лобби:
Gui 4: Add, Edit, w200 h40 vBPCoords,
Gui 4: Add, Button, x10 w80 gInitializeBPCoords, Сохранить
Gui 4: Show, w300 h100, Координаты BP
return

InitializeBPCoords:
{
Gui 4: Submit
IniWrite, %BPCoords%, %A_ScriptDir%\FNToolsSettings\Settings.ini, BattlePass, BPCoords
IniRead, BPCoords, %A_ScriptDir%\FNToolsSettings\Settings.ini, BattlePass, BPCoords
msgbox, 0x40, FNTools, Вы указали координаты: %BPCoords%
return
}
}

2GuiContextMenu:
Return

3GuiContextMenu:
Return

4GuiContextMenu:
Return

GuiClose:
GuiEscape:
ExitApp

F2::ExitApp
F3::Pause
