Set oWSH = WScript.CreateObject("WScript.Shell")
Set oFSO = CreateObject("Scripting.FileSystemObject")

CurBld = oWSH.RegRead("HKLM\Software\Microsoft\Windows NT\CurrentVersion\CurrentBuild")
If CurBld<22000 Or CurBld>=23000 Then
  MsgBox "Not supported on this build",vbInformation+vbSystemModal,"Notice"
  WScript.Quit
End If

If Not WScript.Arguments.Named.Exists("elevate") Then
  CreateObject("Shell.Application").ShellExecute WScript.FullName, """" & WScript.ScriptFullName & """ /elevate", "", "runas", 1
  WScript.Quit
End If

MyFolder = oFSO.GetParentFolderName(WScript.ScriptFullName)
RegShellValue = "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\Shell"
SystemRoot = oWSH.ExpandEnvironmentStrings("%SYSTEMROOT%")
Z = VBCRLF
Q = Chr(34)
B1 = vbInformation + vbOKCancel + vbSystemModal

Response = MsgBox("Click Yes for Windows 10 Explorer" & Z & Z & "Click No for Windows 11 Explorer",vbYesNoCancel+vbSystemModal,"Select your preferred Explorer version")

Sub RestartExplorer
  oWSH.Run "Powershell.exe -ExecutionPolicy Bypass -Command Stop-Process -Force -Processname explorer",0,True
  WScript.Sleep 1000
  oWSH.Run Q & MyFolder & Q
End Sub

If Response = vbYes Then
  Set oExec = oWSH.Exec("fsutil hardlink list " & SystemRoot & "\explorer.exe")
  Do While Not oExec.StdOut.AtEndOfStream
    StdOut = Trim(oExec.StdOut.ReadLine)
    If InStr(1,StdOut,"winsxs",1)>0 Then Exit Do
  Loop
  StdOut = Trim(Replace(StdOut, "\windows\WinSxS", SystemRoot & "\WinSxS"))
  If oFSO.FileExists(StdOut) Then
    oWSH.RegWrite RegShellValue, StdOut, "REG_SZ"
    Response = MsgBox("The following file is now set as the shell:" & Z & Z & StdOut & Z & Z & "Click OK to restart Explorer now",B1,"Notice")
    If Response = vbOK Then RestartExplorer
  Else
    MsgBox "File not found:" & Z & Z & StdOut,vbSystemModal,"Error"
  End If
End If

If Response = vbNo Then
  oWSH.RegWrite RegShellValue, "Explorer.exe", "REG_SZ"
  Response = MsgBox("The shell is now set to Explorer.exe" & Z & Z & "Click OK to restart Explorer now",B1,"Notice")
  If Response = vbOK Then RestartExplorer
End If
