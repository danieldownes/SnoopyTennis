VERSION 5.00
Begin VB.UserControl URLLink 
   BackColor       =   &H00FFFFFF&
   ClientHeight    =   3600
   ClientLeft      =   0
   ClientTop       =   0
   ClientWidth     =   4800
   MousePointer    =   10  'Up Arrow
   ScaleHeight     =   3600
   ScaleWidth      =   4800
   Begin VB.Label lblURL 
      BackColor       =   &H00FFFFFF&
      Caption         =   "Label1"
      BeginProperty Font 
         Name            =   "MS Sans Serif"
         Size            =   8.25
         Charset         =   0
         Weight          =   400
         Underline       =   -1  'True
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   &H00FF0000&
      Height          =   615
      Left            =   120
      MousePointer    =   1  'Arrow
      TabIndex        =   0
      Top             =   120
      Width           =   1575
   End
End
Attribute VB_Name = "URLLink"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
'URLLink - Simply URL control demo program
'Copyright (c) 1997 SoftCircuits Programming (R)
'Redistributed by Permission.
'
'This Visual Basic 5.0 example program demonstrates how to
'automatically load a user's web browser and point it to a particular
'web site. The URL can also be a data file that has an extension that
'has been registered by an application on your system. The appropriate
'application is automatically loaded with the specified data file or
'URL.
'
'The code is implemented as a simple control. The text (which can be
'different from the actual URL) is displayed with an underline and the
'mouse pointer changes to a hand when it is over the text. The URL
'property specifies the URL or data file that is loaded when the text
'is clicked. If the ShowToolTip property is true, a tooltip with the
'underlying URL is displayed when the mousepointer is parked over the
'text. The only event, GoToURL, gives you a chance to change the URL
'or cancel altogether after the text is clicked.
'
'This program may be distributed on the condition that it is
'distributed in full and unchanged, and that no fee is charged for
'such distribution with the exception of reasonable shipping and media
'charged. In addition, the code in this program may be incorporated
'into your own programs and the resulting programs may be distributed
'without payment of royalties.
'
'This example program was provided by:
' SoftCircuits Programming
' http://www.softcircuits.com
' P.O. Box 16262
' Irvine, CA 92623
Option Explicit

Private Const DEF_TEXT = "Ex-D Software Development(TM)"
Private Const DEF_URL = "http://v9.users.btopenworld.com/ex-d/"
Private Const DEF_SHOWTOOLTIP = False

Private m_sURL As String
Private m_bShowToolTip As Boolean

Event GoToURL(URL As String, Cancel As Boolean)

Private Declare Function ShellExecute Lib "shell32.dll" Alias "ShellExecuteA" (ByVal hwnd As Long, ByVal lpOperation As String, ByVal lpFile As String, ByVal lpParameters As String, ByVal lpDirectory As String, ByVal nShowCmd As Long) As Long
Private Const SW_NORMAL = 1

Public Property Get Text() As String
Attribute Text.VB_Description = "Text displayed in control"
Attribute Text.VB_ProcData.VB_Invoke_Property = ";Text"
Attribute Text.VB_UserMemId = -517
    Text = lblURL.Caption
End Property

Public Property Let Text(sText As String)
    lblURL.Caption = sText
    lblURL.Move 0, 0, UserControl.TextWidth(sText), _
        UserControl.TextHeight(sText)
    PropertyChanged "Text"
End Property

Public Property Get URL() As String
Attribute URL.VB_Description = "URL loaded when mouse is clicked over text. May also be a data file that has an extension registered by an application on your system."
Attribute URL.VB_ProcData.VB_Invoke_Property = ";Behavior"
Attribute URL.VB_MemberFlags = "200"
    URL = m_sURL
End Property

Public Property Let URL(sURL As String)
    m_sURL = sURL
    SetToolTip
    PropertyChanged "URL"
End Property

Public Property Get ShowToolTip() As Boolean
Attribute ShowToolTip.VB_Description = "Determines if the URL is displayed in a tooltip when the mouse is parked over the text"
Attribute ShowToolTip.VB_ProcData.VB_Invoke_Property = ";Behavior"
    ShowToolTip = m_bShowToolTip
End Property

Public Property Let ShowToolTip(bShowToolTip As Boolean)
    m_bShowToolTip = bShowToolTip
    SetToolTip
    PropertyChanged "ShowToolTip"
End Property

Private Sub SetToolTip()
    If m_bShowToolTip Then
        lblURL.ToolTipText = m_sURL
    Else
        lblURL.ToolTipText = ""
    End If
End Sub

'Load the URL in response to mousedown
Private Sub lblURL_MouseDown(Button As Integer, Shift As Integer, X As Single, Y As Single)
    Dim bCancel As Boolean
    Dim sURL As String

    If Button And vbLeftButton Then
        'Give user a chance to modify or cancel URL jump
        sURL = m_sURL
        RaiseEvent GoToURL(sURL, bCancel)
        If bCancel Then Exit Sub
        On Error GoTo LinkError
        Screen.MousePointer = vbHourglass
        ShellExecute hwnd, "open", sURL, vbNullString, vbNullString, SW_NORMAL
    End If
EndMouseDown:
    Screen.MousePointer = vbDefault
    Exit Sub
LinkError:
    MsgBox "Unable to load '" & sURL & "' : " & _
        Err.Description & " (Error " & CStr(Err.Number) & ")"
    Resume EndMouseDown
End Sub

'Initialize control properties on first use
Private Sub UserControl_InitProperties()
    Text = DEF_TEXT
    m_sURL = DEF_URL
    ShowToolTip = DEF_SHOWTOOLTIP
End Sub

'Load control properties
Private Sub UserControl_ReadProperties(PropBag As PropertyBag)
    On Error GoTo ReadPropErr
    Text = PropBag.ReadProperty("Text", DEF_TEXT)
    m_sURL = PropBag.ReadProperty("URL", DEF_URL)
    ShowToolTip = PropBag.ReadProperty("ShowToolTip", DEF_SHOWTOOLTIP)
EndReadProp:
    Exit Sub
ReadPropErr:
    'Use default property settings
    UserControl_InitProperties
    Resume EndReadProp
End Sub

'Save control properties
Private Sub UserControl_WriteProperties(PropBag As PropertyBag)
    PropBag.WriteProperty "Text", Text, DEF_TEXT
    PropBag.WriteProperty "URL", m_sURL, DEF_URL
    PropBag.WriteProperty "ShowToolTip", ShowToolTip, DEF_SHOWTOOLTIP
End Sub
