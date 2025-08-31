Attribute VB_Name = "Module1"

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

    Dim lastRow As Long
    Dim dataRange As Range
    Dim ws As Worksheet
    
    Set ws = Worksheets("Data")
    
    ' Find the actual data range
    lastRow = ws.Cells(ws.Rows.Count, 1).End(xlUp).Row
    Set dataRange = ws.Range("A1:I" & lastRow)
    
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
    
    ' Format the new sheet
    With Worksheets("Filtered Data")
        .Range("A1").CurrentRegion.EntireColumn.AutoFit
        .Range("A1").CurrentRegion.Borders.LineStyle = xlContinuous
        .Range("A1:I1").Interior.Color = RGB(217, 225, 242)
        .Range("C1:C10000").NumberFormat = "mm/dd/yyyy"
    End With
    ActiveWindow.DisplayGridlines = False
    
    ' Clear clipboard
    Application.CutCopyMode = False
    
End Sub

' Formats the filtered data by grouping up to 8 entries per day
' Combines transaction IDs and sums amounts for same-day transactions
Sub formatData()
    
    Dim cell As Range
    Dim lastRow As Integer
    Dim i As Integer
    Dim currentDate As String
    Dim sameDataEntries As Integer
    Dim startRow As Integer
    
    ' Find the last row with data
    lastRow = Range("A10000").End(xlUp).Row
    
    Worksheets("Filtered Data").Activate
    
    ' Keep only the first 3 columns: TRANSACTIONID, AMOUNT IN RS, TRANSACTION_DATE
    Range("D:I").Delete  ' Delete all columns after the first 3
    
    ' Insert a new column B for "No. Entries"
    Range("B:B").Insert Shift:=xlShiftRight
    
    ' Rename columns for clarity
    Range("A1").Value = "Transaction ID"
    Range("B1").Value = "No. Entries"
    Range("C1").Value = "Amount"
    Range("D1").Value = "Date"
    Range("A1:D1").Interior.Color = RGB(217, 225, 242)
    
    ' Format Amount column (now column C) and No. Entries column (column B)
    Range("C:C").ColumnWidth = 12
    Range("C:C").HorizontalAlignment = xlLeft
    Range("B:B").HorizontalAlignment = xlLeft
    
    ' Process data to group up to 8 entries per day
    i = 2
    Do While i <= lastRow
        currentDate = Range("D" & i).Value  ' Date is now in column D
        sameDataEntries = 1
        startRow = i
        
        ' Count consecutive entries with the same date
        Do While i + sameDataEntries <= lastRow And Range("D" & (i + sameDataEntries)).Value = currentDate
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
                txnID = Range("A" & (startRow + j)).Value
                
                ' Get only last 4 digits of transaction ID
                txnID = Right(txnID, 4)
                
                ' Build combined transaction ID string
                If j = 0 Then
                    combinedTxnIDs = txnID
                Else
                    combinedTxnIDs = combinedTxnIDs & "-" & txnID
                End If
                
                ' Add to total amount (Amount is now in column C)
                totalAmount = totalAmount + Range("C" & (startRow + j)).Value
            Next j
            
            ' Update the first row with combined data
            Range("A" & startRow).Value = combinedTxnIDs
            Range("B" & startRow).Value = sameDataEntries  ' Number of entries
            Range("C" & startRow).Value = totalAmount      ' Total amount
            
            ' Clear other rows in the group
            For j = 1 To sameDataEntries - 1
                Range("A" & (startRow + j)).Value = ""
                Range("B" & (startRow + j)).Value = ""
                Range("C" & (startRow + j)).Value = ""
            Next j
        End If
        
        ' Properly increment i to avoid infinite loop
        i = i + sameDataEntries
    Loop
    
    ' Apply final formatting to the sheet
    Worksheets("Filtered Data").Range("A1").CurrentRegion.EntireColumn.AutoFit
    Worksheets("Filtered Data").Range("A1").CurrentRegion.Borders.LineStyle = xlContinuous
    
End Sub

' Converts date format from DD-MMM-YYYY to dd/mm/yyyy in the Date column
' Ensures consistent date formatting throughout the workbook
Sub ConvertDateFormat()
    Dim lastRow As Long
    Dim dateVal As Variant
    Dim i As Integer
    
    Worksheets("Filtered Data").Activate
    
    ' Find the last row in Column D (Date column)
    lastRow = Cells(Rows.Count, 4).End(xlUp).Row
    
    ' Loop through each cell in Column D (Date column)
    For i = 2 To lastRow
        If Cells(i, 4).Value <> "" Then
            ' Convert date format from DD-MMM-YYYY to dd/mm/yyyy
            dateVal = Cells(i, 4).Value
            If IsDate(dateVal) Then
                dateVal = Format(CDate(dateVal), "dd/mm/yyyy")
                Cells(i, 4).Value = dateVal
            End If
        End If
    Next i
        
    ' Apply consistent date number formatting to the entire column
    Worksheets("Filtered Data").Range("D1:D10000").NumberFormat = "dd/mm/yyyy"
    
End Sub


' Applies final filtering to show only processed toll routes with amounts > 0
' Creates the final "Toll Process" sheet with formatted output
Sub finalFilter()

    ' Clear any existing filters on the Filtered Data sheet
    If Worksheets("Filtered Data").AutoFilterMode Then
        Worksheets("Filtered Data").AutoFilterMode = False
    End If
    
    ' Apply filters to show only rows with:
    ' - Non-empty Transaction ID (column 1)
    ' - Amount > 0 (column 3, since Amount is now in column C)
    Worksheets("Filtered Data").Range("A1").AutoFilter field:=1, Criteria1:="<>"
    Worksheets("Filtered Data").Range("A1").AutoFilter field:=3, Criteria1:=">0"
   
    ' Copy the filtered results
    Worksheets("Filtered Data").Range("A1").CurrentRegion.Copy
    
    ' Create final output sheet
    Sheets.Add.Name = "Toll Process"
    Worksheets("Toll Process").Range("A1").PasteSpecial xlPasteValues
    
    ' Delete the "No. Entries" column (column B) from Toll Process sheet
    Worksheets("Toll Process").Range("B:B").Delete
    
    ' Format the final output sheet
    Worksheets("Toll Process").Range("A1").CurrentRegion.EntireColumn.AutoFit
    Worksheets("Toll Process").Range("A1").CurrentRegion.Borders.LineStyle = xlContinuous
    Worksheets("Toll Process").Range("A1:C1").Interior.Color = RGB(217, 225, 242)
    ActiveWindow.DisplayGridlines = False
    
    ' Format Amount column in Toll Process sheet (now column B after deleting No. Entries)
    Worksheets("Toll Process").Range("B:B").ColumnWidth = 12
    Worksheets("Toll Process").Range("B:B").HorizontalAlignment = xlLeft
    
    ' Clear filters on the Filtered Data sheet (with error handling)
    On Error Resume Next
    Worksheets("Filtered Data").ShowAllData
    On Error GoTo 0
    If Worksheets("Filtered Data").AutoFilterMode Then
        Worksheets("Filtered Data").AutoFilterMode = False
    End If
    
    ' Rename columns for final output (after deleting No. Entries column)
    Worksheets("Toll Process").Range("A1").Value = "Toll Route"
    Worksheets("Toll Process").Range("B1").Value = "Total Amount"
    Worksheets("Toll Process").Range("C1").Value = "Date"
    
    ' Apply date formatting and select the first cell
    Worksheets("Toll Process").Range("C1:C10000").NumberFormat = "dd/mm/yyyy"
    Worksheets("Toll Process").Range("A1").Select
    
    ' Protect all sheets with password "om"
    Worksheets("Toll Process").Protect "om"
    Worksheets("Filtered Data").Protect "om"
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
