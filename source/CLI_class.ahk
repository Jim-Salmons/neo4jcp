class cli {
    __New(sCmd, sDir="") {
      DllCall("CreatePipe","Ptr*",hStdInRd,"Ptr*",hStdInWr,"Uint",0,"Uint",0)
      DllCall("CreatePipe","Ptr*",hStdOutRd,"Ptr*",hStdOutWr,"Uint",0,"Uint",0)
      DllCall("SetHandleInformation","Ptr",hStdInRd,"Uint",1,"Uint",1)
      DllCall("SetHandleInformation","Ptr",hStdOutWr,"Uint",1,"Uint",1)
      if (A_PtrSize=4) {
         VarSetCapacity(pi, 16, 0)
         sisize:=VarSetCapacity(si,68,0)
         NumPut(sisize, si,  0, "UInt"), NumPut(0x100, si, 44, "UInt"),NumPut(hStdInRd , si, 56, "Ptr"),NumPut(hStdOutWr, si, 60, "Ptr"),NumPut(hStdOutWr, si, 64, "Ptr")
         }
      else if (A_PtrSize=8) {
         VarSetCapacity(pi, 24, 0)
         sisize:=VarSetCapacity(si,96,0)
         NumPut(sisize, si,  0, "UInt"),NumPut(0x100, si, 60, "UInt"),NumPut(hStdInRd , si, 80, "Ptr"),NumPut(hStdOutWr, si, 88, "Ptr"), NumPut(hStdOutWr, si, 96, "Ptr")
         }
      DllCall("CreateProcess", "Uint", 0, "Ptr", &sCmd, "Uint", 0, "Uint", 0, "Int", True, "Uint", 0x08000000, "Uint", 0, "Ptr", sDir ? &sDir : 0, "Ptr", &si, "Ptr", &pi)
      DllCall("CloseHandle","Ptr",NumGet(pi,0))
      DllCall("CloseHandle","Ptr",NumGet(pi,A_PtrSize))
      DllCall("CloseHandle","Ptr",hStdOutWr)
      DllCall("CloseHandle","Ptr",hStdInRd)
         ; Create an object.
      this.hStdInWr:= hStdInWr, this.hStdOutRd:= hStdOutRd
       }
    __Delete() {
        this.close()
    }
    close() {
       hStdInWr:=this.hStdInWr
       hStdOutRd:=this.hStdOutRd
       DllCall("CloseHandle","Ptr",hStdInWr)
       DllCall("CloseHandle","Ptr",hStdOutRd)
      }
   stdin(sInput="",codepage="")  {
       hStdInWr:=this.hStdInWr
       if (codepage="")
            codepage:=A_FileEncoding
         If   sInput <>
         FileOpen(hStdInWr, "h", codepage).Write(sInput)
      }
   stdout(chars="",codepage="") {
       hStdOutRd:=this.hStdOutRd
       if (codepage="")
            codepage:=A_FileEncoding
       fout:=FileOpen(hStdOutRd, "h", codepage)
       if (IsObject(fout) and fout.AtEOF=0)
         return fout.Read()
      return ""
      }
}

;The example using the code to comunicate with commandline apps...

/*
 * FileEncoding, CP850
 * netsh:= new cli("netsh.exe")
 * msgbox % "hStdInWr=" netsh.hStdInWr "`thStdOutRd=" netsh.thStdOutRd
 * sleep 300
 * netsh.stdin("firewall`r`n")
 * sleep 100
 * netsh.stdin("show config`r`n")
 * sleep 1000
 * out:=netsh.stdout()
 * msgbox,, FIREWALL CONFIGURATION:, %out%
 * netsh.stdin("bye`r`n")
 * netsh.close() 
 */
