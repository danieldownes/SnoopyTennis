VERSION 5.00
Begin VB.Form frmMain 
   BackColor       =   &H00FFFFFF&
   BorderStyle     =   1  'Fixed Single
   Caption         =   "Snoopy Tennis v2.1"
   ClientHeight    =   3375
   ClientLeft      =   45
   ClientTop       =   360
   ClientWidth     =   6240
   Icon            =   "frmMain.frx":0000
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   MinButton       =   0   'False
   ScaleHeight     =   3375
   ScaleWidth      =   6240
   StartUpPosition =   2  'CenterScreen
   Begin frmSTLoader.URLLink URLLink1 
      Height          =   255
      Left            =   1650
      TabIndex        =   6
      Top             =   2940
      Width           =   2415
      _ExtentX        =   4260
      _ExtentY        =   450
   End
   Begin VB.CommandButton cmdAbout 
      BackColor       =   &H00FFFFFF&
      Caption         =   "About"
      Height          =   375
      Left            =   4485
      Style           =   1  'Graphical
      TabIndex        =   3
      Top             =   2790
      Width           =   1335
   End
   Begin VB.PictureBox Picture1 
      Appearance      =   0  'Flat
      BackColor       =   &H80000005&
      BorderStyle     =   0  'None
      FillColor       =   &H00FFFFFF&
      ForeColor       =   &H00FFFFFF&
      Height          =   1455
      Left            =   -1065
      Picture         =   "frmMain.frx":08CA
      ScaleHeight     =   1455
      ScaleWidth      =   7215
      TabIndex        =   2
      Top             =   -15
      Width           =   7215
   End
   Begin VB.Frame frmMusic 
      BackColor       =   &H00FFFFFF&
      Caption         =   "In-game Music?"
      BeginProperty Font 
         Name            =   "Arial"
         Size            =   9.75
         Charset         =   0
         Weight          =   700
         Underline       =   0   'False
         Italic          =   -1  'True
         Strikethrough   =   0   'False
      EndProperty
      Height          =   1170
      Left            =   3540
      TabIndex        =   1
      Top             =   1485
      Width           =   2295
      Begin VB.OptionButton optNo 
         BackColor       =   &H00FFFFFF&
         Caption         =   "No, (try this if you are having problems)"
         Height          =   450
         Left            =   225
         TabIndex        =   5
         Top             =   645
         Width           =   1815
      End
      Begin VB.OptionButton optYes 
         BackColor       =   &H00FFFFFF&
         Caption         =   "Cool, ok!"
         Height          =   255
         Left            =   225
         TabIndex        =   4
         Top             =   300
         Value           =   -1  'True
         Width           =   1815
      End
   End
   Begin VB.CommandButton cmdPlay 
      BackColor       =   &H00FFFFFF&
      Caption         =   "Play!"
      Default         =   -1  'True
      BeginProperty Font 
         Name            =   "Arial"
         Size            =   9.75
         Charset         =   0
         Weight          =   700
         Underline       =   0   'False
         Italic          =   -1  'True
         Strikethrough   =   0   'False
      EndProperty
      Height          =   1125
      Left            =   720
      Picture         =   "frmMain.frx":D780
      Style           =   1  'Graphical
      TabIndex        =   0
      Top             =   1560
      Width           =   1815
   End
End
Attribute VB_Name = "frmMain"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Private sURL As String

Private Declare Function ShellExecute Lib "shell32.dll" Alias "ShellExecuteA" (ByVal hwnd As Long, ByVal lpOperation As String, ByVal lpFile As String, ByVal lpParameters As String, ByVal lpDirectory As String, ByVal nShowCmd As Long) As Long
Private Const SW_NORMAL = 1

Private Sub cmdPlay_Click()
    
''''''''''''' Write .bat file
    
    Open App.Path & "\play.bat" For Output As #1
    Print #1, "cd " & App.Path
    
    If optYes.Value = True Then
        Print #1, "sbmidi"
        Print #1, "sbsim.com"
        Print #1, "st2-1.exe"
        
    Else
        Print #1, "st2-1-nm.exe"
        
    End If
    
    Close #1
    
    ShellExecute hwnd, "open", App.Path & "\play.bat", vbNullString, vbNullString, SW_NORMAL
    
    End
End Sub
    

Private Sub cmdAbout_Click()
    frmAbout.Show
End Sub



Private Sub Form_Load()

    Me.Show

    ' Handle new versions!
    If dllExVersionCheck.CheckForNew("Snoopy Tennis", "2.1") = 3 Then
        
        dllExVersionCheck.ExVersionCheck
        
    End If
    
End Sub
