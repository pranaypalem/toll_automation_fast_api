Attribute VB_Name = "Module1"

Sub resProject()

    Dim xWs As Worksheet
    Application.ScreenUpdating = False
    Application.DisplayAlerts = False
    For Each xWs In Application.ActiveWorkbook.Worksheets
        If xWs.Name <> "Dashboard" Then
            xWs.Delete
        End If
    Next
        
    Application.DisplayAlerts = True
    Application.ScreenUpdating = True

End Sub

Sub importData()

    Dim wbSource As Workbook
    Dim wbDest As Workbook
    Dim shtToCopy As Worksheet
    Dim shtDest As Worksheet
    Dim fd As Office.FileDialog
    
    ' Display the open file dialog box to select the source workbook
    Set fd = Application.FileDialog(msoFileDialogFilePicker)
    fd.Title = "Select source workbook"
    fd.ButtonName = "Open"
    fd.InitialFileName = Application.DefaultFilePath & "\"
    fd.Filters.Clear
    fd.Filters.Add "Excel workbooks", "*.xlsx; *.xlsm; *.xls"
    fd.Show
    
    ' If the user didn't select a file, exit the macro
    If fd.SelectedItems.Count = 0 Then
        Exit Sub
    End If
    
    ' Open the source workbook and select the sheet to copy
    Set wbSource = Workbooks.Open(fd.SelectedItems(1))
    Set shtToCopy = wbSource.ActiveSheet
    
    ' Copy the sheet
    shtToCopy.Copy Before:=ThisWorkbook.Sheets(1)
    
    ' Activate the original workbook
    Set wbDest = ThisWorkbook
    wbDest.Activate
    
    ActiveSheet.Name = "Data"
    
    ' Close the source workbook without saving changes
    wbSource.Close False
    
End Sub

Sub ArrangeSheets()
    Dim dashboardSheet As Worksheet
    Dim dataSheet As Worksheet
    Dim fltrSheet As Worksheet
    Dim TollSheet As Worksheet
    
    
    On Error Resume Next
    Set dashboardSheet = ThisWorkbook.Sheets("Dashboard")
    Set dataSheet = ThisWorkbook.Sheets("Data")
    Set fltrSheet = ThisWorkbook.Sheets("Filtered Data")
    Set TollSheet = ThisWorkbook.Sheets("Toll Process")
    
    On Error GoTo 0
    
    ' Reorder sheets
    If Not dashboardSheet Is Nothing Then
        dashboardSheet.Move Before:=ThisWorkbook.Sheets(1)
    End If
    
    If Not dataSheet Is Nothing Then
        dataSheet.Move After:=dashboardSheet
    End If
    
    If Not fltrSheet Is Nothing Then
        fltrSheet.Move After:=dataSheet
    End If
    
    If Not TollSheet Is Nothing Then
        TollSheet.Move After:=dashboardSheet
        TollSheet.Tab.Color = RGB(112, 173, 71) ' Set tab color to green
    End If
    
End Sub

Sub filteredData()

     If Worksheets("Data").AutoFilterMode Then
        Worksheets("Data").AutoFilterMode = False
    End If
    
    ' Filter for NewData.xlsx format - filter by AMOUNT IN RS > 0 and TRANSACTIONTYPE = "Debit"
    Worksheets("Data").Range("A1").AutoFilter field:=2, Criteria1:=">0"
    Worksheets("Data").Range("A1").AutoFilter field:=7, Criteria1:="Debit"
   
    Worksheets("Data").Range("A1").CurrentRegion.Copy
    
    Sheets.Add.Name = "Filtered Data"
    Worksheets("Filtered Data").Range("A1").PasteSpecial xlPasteValues
    
    'Formatting for new data structure
    Worksheets("Filtered Data").Range("A1").CurrentRegion.EntireColumn.AutoFit
    Worksheets("Filtered Data").Range("A1").CurrentRegion.Borders.LineStyle = xlContinuous
    Worksheets("Filtered Data").Range("A1:I1").Interior.Color = RGB(217, 225, 242)
    Worksheets("Filtered Data").Range("C1:C10000").NumberFormat = "mm/dd/yyyy"
    ActiveWindow.DisplayGridlines = False
    
    Worksheets("Data").ShowAllData
    If Worksheets("Data").AutoFilterMode Then
        Worksheets("Data").AutoFilterMode = False
    End If
    
End Sub

Sub formatData()
    
    Dim cell As Range
    Dim lastRow As Integer
    Dim i As Integer
    Dim currentDate As String
    Dim sameDataEntries As Integer
    Dim startRow As Integer
    
    lastRow = Range("A10000").End(xlUp).Row
    
    Worksheets("Filtered Data").Activate
    
    ' Keep only first 3 columns (TRANSACTIONID, AMOUNT IN RS, TRANSACTION_DATE) plus VEHICLETRANSACTIONAT for toll info
    Range("D:D").Delete  ' Delete TRANSACTION_TIME
    Range("D:D").Delete  ' Delete VEHICLENO
    Range("E:I").Delete  ' Delete remaining columns except VEHICLETRANSACTIONAT
    
    ' Rename columns for consistency
    Range("A1").Value = "Transaction ID"
    Range("B1").Value = "Amount"
    Range("C1").Value = "Date"
    Range("D1").Value = "Toll Location"
    Range("A1:D1").Interior.Color = RGB(217, 225, 242)
    
    ' Process data to group up to 8 entries per day
    i = 2
    Do While i <= lastRow
        currentDate = Range("C" & i).Value
        sameDataEntries = 1
        startRow = i
        
        ' Count consecutive entries with same date
        Do While i + sameDataEntries <= lastRow And Range("C" & (i + sameDataEntries)).Value = currentDate
            sameDataEntries = sameDataEntries + 1
        Loop
        
        ' Process groups of up to 8 entries per day
        If sameDataEntries > 1 And sameDataEntries <= 8 Then
            ' Create combined toll route and sum amounts for the group
            Dim tollRoute As String
            Dim totalAmount As Double
            Dim j As Integer
            
            tollRoute = ""
            totalAmount = 0
            
            For j = 0 To sameDataEntries - 2
                Dim tollLocation As String
                tollLocation = Range("D" & (startRow + j)).Value
                
                ' Extract toll plaza name from location string
                If InStr(tollLocation, "Toll Plaza") > 0 Then
                    tollLocation = Mid(tollLocation, InStr(tollLocation, "-") + 1)
                    tollLocation = Left(tollLocation, InStr(tollLocation, " Toll Plaza") - 1)
                    tollLocation = Right(tollLocation, 4) ' Get last 4 characters as identifier
                End If
                
                If j = 0 Then
                    tollRoute = tollLocation
                Else
                    tollRoute = tollRoute & "-" & tollLocation
                End If
                
                totalAmount = totalAmount + Range("B" & (startRow + j)).Value
            Next j
            
            ' Update the first row with combined data
            Range("A" & startRow).Value = tollRoute
            Range("B" & startRow).Value = totalAmount
            
            ' Clear other rows in the group
            For j = 1 To sameDataEntries - 2
                Range("A" & (startRow + j)).Value = ""
                Range("B" & (startRow + j)).Value = ""
            Next j
        End If
        
        i = i + sameDataEntries - 1
    Loop
    
    ' Delete the toll location column as it's no longer needed
    Range("D:D").Delete
    
    ' Format the sheet
    Worksheets("Filtered Data").Range("A1").CurrentRegion.EntireColumn.AutoFit
    Worksheets("Filtered Data").Range("A1").CurrentRegion.Borders.LineStyle = xlContinuous
    
End Sub

Sub ConvertDateFormat()
    Dim lastRow As Long
    Dim dateVal As Variant
    Dim i As Integer
    
    Worksheets("Filtered Data").Activate
    
    ' Find the last row in Column C (Date column)
    lastRow = Cells(Rows.Count, 3).End(xlUp).Row
    
    ' Loop through each cell in Column C (Date column)
    For i = 2 To lastRow
        If Cells(i, 3).Value <> "" Then
            ' Convert date format from DD-MMM-YYYY to mm/dd/yyyy
            dateVal = Cells(i, 3).Value
            If IsDate(dateVal) Then
                dateVal = Format(CDate(dateVal), "mm/dd/yyyy")
                Cells(i, 3).Value = dateVal
            End If
        End If
    Next i
        
    Worksheets("Filtered Data").Range("C1:C10000").NumberFormat = "mm/dd/yyyy"
    
End Sub


Sub finalFilter()

     If Worksheets("Filtered Data").AutoFilterMode Then
        Worksheets("Filtered Data").AutoFilterMode = False
    End If
    
    ' Filter for rows with Transaction ID and Amount > 0
    Worksheets("Filtered Data").Range("A1").AutoFilter field:=1, Criteria1:="<>"
    Worksheets("Filtered Data").Range("A1").AutoFilter field:=2, Criteria1:=">0"
   
    Worksheets("Filtered Data").Range("A1").CurrentRegion.Copy
    
    Sheets.Add.Name = "Toll Process"
    Worksheets("Toll Process").Range("A1").PasteSpecial xlPasteValues
    
    'Formatting
    Worksheets("Toll Process").Range("A1").CurrentRegion.EntireColumn.AutoFit
    Worksheets("Toll Process").Range("A1").CurrentRegion.Borders.LineStyle = xlContinuous
    Worksheets("Toll Process").Range("A1:C1").Interior.Color = RGB(217, 225, 242)
    ActiveWindow.DisplayGridlines = False
    
    Worksheets("Filtered Data").ShowAllData
    If Worksheets("Filtered Data").AutoFilterMode Then
        Worksheets("Filtered Data").AutoFilterMode = False
    End If
    
    ' Rename columns for final output
    Worksheets("Toll Process").Range("A1").Value = "Toll Route"
    Worksheets("Toll Process").Range("B1").Value = "Total Amount"
    Worksheets("Toll Process").Range("C1").Value = "Date"
    
    Worksheets("Toll Process").Range("C1:C10000").NumberFormat = "mm/dd/yyyy"
    
    Worksheets("Toll Process").Range("A1").Select
    
    Worksheets("Toll Process").Protect "om"
    Worksheets("Filtered Data").Protect "om"
    Worksheets("Data").Protect "om"
    
End Sub


Sub action()
    
    Application.ScreenUpdating = False
    Application.DisplayAlerts = False
    
    importData
    filteredData
    formatData
    ConvertDateFormat
    finalFilter
    ArrangeSheets
    
    
    Worksheets("Dashboard").Activate

    Application.ScreenUpdating = True
    Application.DisplayAlerts = True
End Sub
