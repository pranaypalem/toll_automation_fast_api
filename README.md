# Toll Automation VBA

A VBA-based Excel automation tool for processing toll transaction data and generating formatted reports.

## Overview

This automation processes toll transaction data from Excel files and creates organized reports with filtered and formatted data. It's designed to streamline toll expense tracking and reporting.

## Features

- **Data Import**: Import toll transaction data from Excel files
- **Smart Filtering**: Filter debit transactions with amounts greater than 0
- **Data Formatting**: Group up to 8 entries per day and combine toll routes
- **Date Standardization**: Convert dates to mm/dd/yyyy format
- **Automated Reporting**: Generate final filtered output with proper formatting
- **Sheet Organization**: Organize worksheets in logical order with color-coded tabs

## Files

- `Automation Toll Statement.xlsm` - Main Excel workbook with VBA automation
- `Module1.bas` - VBA source code for the automation
- `NewData.xlsx` - Sample new data file for testing
- `OldData.xls` - Sample old data file for testing

## Usage

1. Open `Automation Toll Statement.xlsm`
2. Run the `action()` macro to start the complete workflow
3. Select your toll transaction data file when prompted
4. The automation will process the data and create formatted reports

## Workflow

The automation follows this sequence:
1. Import data from selected Excel file
2. Filter for debit transactions > 0
3. Format and group data by date
4. Standardize date formats
5. Apply final filters and create output
6. Organize sheets and return to Dashboard