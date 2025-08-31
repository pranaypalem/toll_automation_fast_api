Attribute VB_Name = "Module1"

' Helper function to find column position by header name
' Returns 0 if header not found
Function FindColumnByHeader(ws As Worksheet, headerName As String) As Integer
    Dim lastCol As Integer
    Dim i As Integer
    
    lastCol = ws.Cells(1, ws.Columns.Count).End(xlToLeft).Column
    
    For i = 1 To lastCol
        If Trim(UCase(ws.Cells(1, i).Value)) = Trim(UCase(headerName)) Then
            FindColumnByHeader = i
            Exit Function
        End If
    Next i
    
    FindColumnByHeader = 0
End Function

' Helper function to get dynamic data range based on actual data
Function GetDataRange(ws As Worksheet) As Range
    Dim lastRow As Long
    Dim lastCol As Integer
    
    lastRow = ws.Cells(ws.Rows.Count, 1).End(xlUp).Row
    lastCol = ws.Cells(1, ws.Columns.Count).End(xlToLeft).Column
    
    Set GetDataRange = ws.Range(ws.Cells(1, 1), ws.Cells(lastRow, lastCol))
End Function

' Resets the project by deleting all worksheets except Dashboard
' Used to clean the workbook before importing new data
Sub resProject()

    Dim xWs As Worksheet
    Application.ScreenUpdating = False
    Application.DisplayAlerts = False
    
    ' Loop through all worksheets and delete everything except Dashboard
    For Each xWs In Application.ActiveWorkbook.Worksheets
        If xWs.Name <> "Dashboard" Then
            xWs.Delete
        End If
    Next
        
    Application.DisplayAlerts = True
    Application.ScreenUpdating = True

End Sub

' Imports data from an external Excel file selected by the user
' Creates a new "Data" sheet with the imported data
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
    
    ' Copy the sheet to this workbook
    shtToCopy.Copy Before:=ThisWorkbook.Sheets(1)
    
    ' Activate the original workbook and rename the imported sheet
    Set wbDest = ThisWorkbook
    wbDest.Activate
    ActiveSheet.Name = "Data"
    
    ' Close the source workbook without saving changes
    wbSource.Close False
    
End Sub

' Arranges worksheets in the correct order: Dashboard, Toll Process, Data, Filtered Data
' Also sets the Toll Process sheet tab color to green
Sub ArrangeSheets()
    Dim dashboardSheet As Worksheet
    Dim dataSheet As Worksheet
    Dim fltrSheet As Worksheet
    Dim TollSheet As Worksheet
    
    ' Get references to all sheets (use error handling in case they don't exist)
    On Error Resume Next
    Set dashboardSheet = ThisWorkbook.Sheets("Dashboard")
    Set dataSheet = ThisWorkbook.Sheets("Data")
    Set fltrSheet = ThisWorkbook.Sheets("Filtered Data")
    Set TollSheet = ThisWorkbook.Sheets("Toll Process")
    On Error GoTo 0
    
    ' Reorder sheets in the desired sequence
    If Not dashboardSheet Is Nothing Then
        dashboardSheet.Move Before:=ThisWorkbook.Sheets(1)
    End If
    
    If Not TollSheet Is Nothing Then
        TollSheet.Move After:=dashboardSheet
        TollSheet.Tab.Color = RGB(112, 173, 71) ' Set tab color to green
    End If
    
    If Not dataSheet Is Nothing Then
        dataSheet.Move After:=TollSheet
    End If
    
    If Not fltrSheet Is Nothing Then
        fltrSheet.Move After:=dataSheet
    End If
    
End Sub

' Filters the imported data to show only debit transactions with amounts > 0
' Creates a new "Filtered Data" sheet with the filtered results
Sub filteredData()

    Dim dataRange As Range
    Dim ws As Worksheet
    Dim amountCol As Integer
    Dim transactionTypeCol As Integer
    Dim dateCol As Integer
    
    Set ws = Worksheets("Data")
    
    ' Find column positions by header names
    amountCol = FindColumnByHeader(ws, "AMOUNT IN RS")
    transactionTypeCol = FindColumnByHeader(ws, "TRANSACTIONTYPE")
    dateCol = FindColumnByHeader(ws, "TRANSACTION_DATE")
    
    ' Check if required headers were found
    If amountCol = 0 Or transactionTypeCol = 0 Or dateCol = 0 Then
        MsgBox "Error: Required columns not found. Expected headers:" & vbCrLf & _
               "- AMOUNT IN RS" & vbCrLf & _
               "- TRANSACTIONTYPE" & vbCrLf & _
               "- TRANSACTION_DATE", vbCritical, "Header Detection Error"
        Exit Sub
    End If
    
    ' Get dynamic data range
    Set dataRange = GetDataRange(ws)
    
    ' Clear any existing filters
    If ws.AutoFilterMode Then
        ws.AutoFilterMode = False
    End If
    
    ' Since all data in NewData.xlsx is valid (all amounts > 0 and all are "Debit"), 
    ' just copy all data directly without filtering
    dataRange.Copy
    
    ' Create new sheet and paste
    Sheets.Add.Name = "Filtered Data"
    Worksheets("Filtered Data").Range("A1").PasteSpecial xlPasteValues
    Application.CutCopyMode = False
    
    ' Format the new sheet dynamically
    With Worksheets("Filtered Data")
        .Range("A1").CurrentRegion.EntireColumn.AutoFit
        .Range("A1").CurrentRegion.Borders.LineStyle = xlContinuous
        
        ' Find the last column and row for dynamic formatting
        Dim lastCol As Integer
        Dim lastRow As Long
        lastCol = .Cells(1, .Columns.Count).End(xlToLeft).Column
        lastRow = .Cells(.Rows.Count, 1).End(xlUp).Row
        
        ' Format header row dynamically
        .Range(.Cells(1, 1), .Cells(1, lastCol)).Interior.Color = RGB(217, 225, 242)
        
        ' Format date column dynamically (find TRANSACTION_DATE column)
        Dim newDateCol As Integer
        newDateCol = FindColumnByHeader(Worksheets("Filtered Data"), "TRANSACTION_DATE")
        If newDateCol > 0 Then
            .Range(.Cells(1, newDateCol), .Cells(lastRow, newDateCol)).NumberFormat = "dd/mm/yyyy"
        End If
    End With
    ActiveWindow.DisplayGridlines = False
    
    ' Clear clipboard
    Application.CutCopyMode = False
    
End Sub

' Formats the filtered data by grouping up to 8 entries per day
' Combines transaction IDs and sums amounts for same-day transactions
Sub formatData()
    
    Dim ws As Worksheet
    Dim lastRow As Long
    Dim i As Integer
    Dim currentDate As String
    Dim sameDataEntries As Integer
    Dim startRow As Integer
    
    ' Find required columns dynamically
    Dim txnIDCol As Integer
    Dim amountCol As Integer
    Dim dateCol As Integer
    
    Set ws = Worksheets("Filtered Data")
    ws.Activate
    
    ' Find column positions by header names
    txnIDCol = FindColumnByHeader(ws, "TRANSACTIONID")
    amountCol = FindColumnByHeader(ws, "AMOUNT IN RS")
    dateCol = FindColumnByHeader(ws, "TRANSACTION_DATE")
    
    ' Check if required headers were found
    If txnIDCol = 0 Or amountCol = 0 Or dateCol = 0 Then
        MsgBox "Error: Required columns not found in Filtered Data sheet.", vbCritical, "Header Detection Error"
        Exit Sub
    End If
    
    ' Find the last row with data
    lastRow = ws.Cells(ws.Rows.Count, 1).End(xlUp).Row
    
    ' Delete all columns except the 3 main ones, but do it smartly
    ' First, copy the 3 essential columns to temporary location
    Dim tempRange As Range
    Dim newWS As Worksheet
    
    ' Create a temporary array to store essential data
    Dim essentialData As Variant
    ReDim essentialData(1 To lastRow, 1 To 3)
    
    ' Copy essential data
    For i = 1 To lastRow
        essentialData(i, 1) = ws.Cells(i, txnIDCol).Value  ' Transaction ID
        essentialData(i, 2) = ws.Cells(i, amountCol).Value ' Amount
        essentialData(i, 3) = ws.Cells(i, dateCol).Value   ' Date
    Next i
    
    ' Clear the worksheet and rebuild with essential columns + No. Entries
    ws.Cells.Clear
    
    ' Set up new column structure
    ws.Cells(1, 1).Value = "Transaction ID"
    ws.Cells(1, 2).Value = "No. Entries"
    ws.Cells(1, 3).Value = "Amount"
    ws.Cells(1, 4).Value = "Date"
    
    ' Copy essential data back in new structure and convert dates immediately
    For i = 2 To lastRow
        ws.Cells(i, 1).Value = essentialData(i, 1)  ' Transaction ID
        ws.Cells(i, 3).Value = essentialData(i, 2)  ' Amount (skip No. Entries for now)
        
        ' Convert date immediately to ensure uniform format for grouping
        Dim dateVal As Variant
        Dim convertedDate As Date
        Dim dateStr As String
        
        dateVal = essentialData(i, 3)
        dateStr = CStr(dateVal)
        
        ' Convert various date formats to uniform dd/mm/yyyy
        On Error Resume Next
        convertedDate = 0
        
        If IsDate(dateVal) Then
            convertedDate = CDate(dateVal)
        ElseIf IsDate(dateStr) Then
            convertedDate = CDate(dateStr)
        Else
            ' Handle text-based dates like "30-Jul-25"
            dateStr = Replace(dateStr, "-", " ")
            If IsDate(dateStr) Then
                convertedDate = CDate(dateStr)
            End If
        End If
        
        On Error GoTo 0
        
        ' Store converted date
        If convertedDate > 0 Then
            ws.Cells(i, 4).Value = Format(convertedDate, "dd/mm/yyyy")
        Else
            ws.Cells(i, 4).Value = essentialData(i, 3)  ' Keep original if conversion failed
        End If
    Next i
    
    ' Format headers and columns
    ws.Range("A1:D1").Interior.Color = RGB(217, 225, 242)
    ws.Range("C:C").ColumnWidth = 12
    ws.Range("C:C").HorizontalAlignment = xlLeft
    ws.Range("B:B").HorizontalAlignment = xlLeft
    ws.Range("D:D").ColumnWidth = 15  ' Increase Date column width
    ws.Range("D:D").NumberFormat = "dd/mm/yyyy"  ' Set date format immediately
    
    ' Process data to group up to 8 entries per day
    i = 2
    Do While i <= lastRow
        currentDate = ws.Cells(i, 4).Value  ' Date is in column D
        sameDataEntries = 1
        startRow = i
        
        ' Count consecutive entries with the same date
        Do While i + sameDataEntries <= lastRow And ws.Cells(i + sameDataEntries, 4).Value = currentDate
            sameDataEntries = sameDataEntries + 1
        Loop
        
        ' Process groups of up to 8 entries per day
        If sameDataEntries > 1 And sameDataEntries <= 8 Then
            ' Create combined transaction ID string and sum amounts for the group
            Dim combinedTxnIDs As String
            Dim totalAmount As Double
            Dim j As Integer
            
            combinedTxnIDs = ""
            totalAmount = 0
            
            ' Loop through all entries in the same-date group
            For j = 0 To sameDataEntries - 1
                Dim txnID As String
                txnID = ws.Cells(startRow + j, 1).Value
                
                ' Get only last 4 digits of transaction ID
                txnID = Right(txnID, 4)
                
                ' Build combined transaction ID string
                If j = 0 Then
                    combinedTxnIDs = txnID
                Else
                    combinedTxnIDs = combinedTxnIDs & "-" & txnID
                End If
                
                ' Add to total amount
                totalAmount = totalAmount + ws.Cells(startRow + j, 3).Value
            Next j
            
            ' Update the first row with combined data
            ws.Cells(startRow, 1).Value = combinedTxnIDs
            ws.Cells(startRow, 2).Value = sameDataEntries  ' Number of entries
            ws.Cells(startRow, 3).Value = totalAmount      ' Total amount
            
            ' Clear other rows in the group
            For j = 1 To sameDataEntries - 1
                ws.Cells(startRow + j, 1).Value = ""
                ws.Cells(startRow + j, 2).Value = ""
                ws.Cells(startRow + j, 3).Value = ""
            Next j
        End If
        
        ' Properly increment i to avoid infinite loop
        i = i + sameDataEntries
    Loop
    
    ' Apply final formatting to the sheet
    ws.Range("A1").CurrentRegion.EntireColumn.AutoFit
    ws.Range("A1").CurrentRegion.Borders.LineStyle = xlContinuous
    
End Sub

' Converts date format from DD-MMM-YYYY to dd/mm/yyyy in the Date column
' Ensures consistent date formatting throughout the workbook
Sub ConvertDateFormat()
    Dim ws As Worksheet
    Dim lastRow As Long
    Dim dateVal As Variant
    Dim i As Integer
    Dim dateCol As Integer
    
    Set ws = Worksheets("Filtered Data")
    ws.Activate
    
    ' Find Date column dynamically (should be "Date" after formatData)
    dateCol = FindColumnByHeader(ws, "Date")
    
    ' If "Date" not found, try original header name
    If dateCol = 0 Then
        dateCol = FindColumnByHeader(ws, "TRANSACTION_DATE")
    End If
    
    ' Check if date column was found
    If dateCol = 0 Then
        MsgBox "Error: Date column not found.", vbCritical, "Header Detection Error"
        Exit Sub
    End If
    
    ' Find the last row with data
    lastRow = ws.Cells(ws.Rows.Count, 1).End(xlUp).Row
    
    ' Loop through each cell in the Date column
    For i = 2 To lastRow
        If ws.Cells(i, dateCol).Value <> "" Then
            dateVal = ws.Cells(i, dateCol).Value
            
            ' Handle different date formats
            Dim convertedDate As Date
            Dim dateStr As String
            
            ' Convert to string first to handle various formats
            dateStr = CStr(dateVal)
            
            ' Try to parse different date formats
            On Error Resume Next
            
            ' Try standard date conversion first
            If IsDate(dateVal) Then
                convertedDate = CDate(dateVal)
            ElseIf IsDate(dateStr) Then
                convertedDate = CDate(dateStr)
            Else
                ' Handle text-based dates like "30-Jul-25"
                dateStr = Replace(dateStr, "-", " ")
                If IsDate(dateStr) Then
                    convertedDate = CDate(dateStr)
                End If
            End If
            
            On Error GoTo 0
            
            ' Format as dd/mm/yyyy if conversion was successful
            If convertedDate > 0 Then
                ws.Cells(i, dateCol).Value = Format(convertedDate, "dd/mm/yyyy")
            End If
            
            ' Reset for next iteration
            convertedDate = 0
        End If
    Next i
        
    ' Apply consistent date number formatting to the entire column
    ws.Range(ws.Cells(1, dateCol), ws.Cells(lastRow, dateCol)).NumberFormat = "dd/mm/yyyy"
    
    ' Set column width for Date column
    ws.Columns(dateCol).ColumnWidth = 15
    
End Sub


' Applies final filtering to show only processed toll routes with amounts > 0
' Creates the final "Toll Process" sheet with formatted output
Sub finalFilter()

    Dim wsFiltered As Worksheet
    Dim wsToll As Worksheet
    Dim txnIDCol As Integer
    Dim amountCol As Integer
    Dim dateCol As Integer
    Dim lastRow As Long
    
    Set wsFiltered = Worksheets("Filtered Data")
    
    ' Clear any existing filters
    If wsFiltered.AutoFilterMode Then
        wsFiltered.AutoFilterMode = False
    End If
    
    ' Find column positions dynamically
    txnIDCol = FindColumnByHeader(wsFiltered, "Transaction ID")
    amountCol = FindColumnByHeader(wsFiltered, "Amount")
    dateCol = FindColumnByHeader(wsFiltered, "Date")
    
    ' Check if required columns were found
    If txnIDCol = 0 Or amountCol = 0 Or dateCol = 0 Then
        MsgBox "Error: Required columns not found in Filtered Data sheet.", vbCritical, "Header Detection Error"
        Exit Sub
    End If
    
    ' Get data range dynamically
    Dim dataRange As Range
    Set dataRange = GetDataRange(wsFiltered)
    
    ' Apply filters dynamically
    dataRange.AutoFilter field:=txnIDCol, Criteria1:="<>"
    dataRange.AutoFilter field:=amountCol, Criteria1:=">0"
   
    ' Copy the filtered results
    dataRange.Copy
    
    ' Create final output sheet
    Sheets.Add.Name = "Toll Process"
    Set wsToll = Worksheets("Toll Process")
    wsToll.Range("A1").PasteSpecial xlPasteValues
    Application.CutCopyMode = False
    
    ' Delete the "No. Entries" column from Toll Process sheet
    Dim noEntriesCol As Integer
    noEntriesCol = FindColumnByHeader(wsToll, "No. Entries")
    If noEntriesCol > 0 Then
        wsToll.Columns(noEntriesCol).Delete
    End If
    
    ' Find the last row and column for dynamic formatting
    lastRow = wsToll.Cells(wsToll.Rows.Count, 1).End(xlUp).Row
    Dim lastCol As Integer
    lastCol = wsToll.Cells(1, wsToll.Columns.Count).End(xlToLeft).Column
    
    ' Format the final output sheet dynamically
    wsToll.Range("A1").CurrentRegion.EntireColumn.AutoFit
    wsToll.Range("A1").CurrentRegion.Borders.LineStyle = xlContinuous
    wsToll.Range(wsToll.Cells(1, 1), wsToll.Cells(1, lastCol)).Interior.Color = RGB(217, 225, 242)
    ActiveWindow.DisplayGridlines = False
    
    ' Find and format Amount column dynamically
    Dim tollAmountCol As Integer
    tollAmountCol = FindColumnByHeader(wsToll, "Amount")
    If tollAmountCol = 0 Then
        tollAmountCol = FindColumnByHeader(wsToll, "Total Amount")
    End If
    
    If tollAmountCol > 0 Then
        wsToll.Columns(tollAmountCol).ColumnWidth = 12
        wsToll.Columns(tollAmountCol).HorizontalAlignment = xlLeft
    End If
    
    ' Clear filters on the Filtered Data sheet (with error handling)
    On Error Resume Next
    wsFiltered.ShowAllData
    On Error GoTo 0
    If wsFiltered.AutoFilterMode Then
        wsFiltered.AutoFilterMode = False
    End If
    
    ' Rename columns for final output
    wsToll.Cells(1, 1).Value = "Toll Route"
    If tollAmountCol > 0 Then
        wsToll.Cells(1, tollAmountCol).Value = "Total Amount"
    End If
    
    ' Find and format Date column
    Dim tollDateCol As Integer
    tollDateCol = FindColumnByHeader(wsToll, "Date")
    If tollDateCol > 0 Then
        wsToll.Range(wsToll.Cells(1, tollDateCol), wsToll.Cells(lastRow, tollDateCol)).NumberFormat = "dd/mm/yyyy"
    End If
    
    wsToll.Range("A1").Select
    
    ' Protect all sheets with password "om"
    wsToll.Protect "om"
    wsFiltered.Protect "om"
    Worksheets("Data").Protect "om"
    
End Sub


' Main automation routine that runs all processing steps in sequence
' This is the primary subroutine called by the user interface
Sub action()
    
    ' Disable screen updates and alerts for better performance
    Application.ScreenUpdating = False
    Application.DisplayAlerts = False
    
    ' Execute the complete toll data processing workflow
    importData          ' Import data from selected Excel file
    filteredData        ' Filter data for debit transactions > 0
    formatData          ' Group up to 8 entries per day and combine toll routes
    ConvertDateFormat   ' Convert dates to mm/dd/yyyy format
    finalFilter         ' Apply final filters and create output sheet
    ArrangeSheets       ' Organize sheet tabs in proper order
    
    ' Return to Dashboard and re-enable screen updates
    Worksheets("Dashboard").Activate
    Application.ScreenUpdating = True
    Application.DisplayAlerts = True
    
End Sub
