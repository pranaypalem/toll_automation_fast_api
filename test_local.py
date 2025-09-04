#!/usr/bin/env python3
"""
Local test script to debug Excel file processing
"""
import os
import sys
from app.toll_processor import TollProcessor

def test_excel_file(file_path):
    """Test processing an Excel file locally"""
    print(f"Testing Excel file: {file_path}")
    
    # Check if file exists
    if not os.path.exists(file_path):
        print(f"ERROR: File not found: {file_path}")
        return False
    
    print(f"SUCCESS: File found, size: {os.path.getsize(file_path)} bytes")
    
    try:
        # Create processor and test
        processor = TollProcessor()
        print("Starting processing...")
        
        processed_data = processor.process_excel_file(file_path)
        
        print("Processing successful!")
        print(f"Results: {len(processed_data)} rows processed")
        print("\nSample output:")
        print(processed_data.head())
        
        # Save output locally
        output_path = "test_output.csv"
        processed_data.to_csv(output_path, index=False)
        print(f"Saved to: {output_path}")
        
        return True
        
    except Exception as e:
        print(f"ERROR processing file: {str(e)}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    # Test with the specific file
    test_file = r"C:\Users\Owner\Desktop\NewData_Copy.xlsx"
    
    print("Local Excel Processing Test")
    print("=" * 50)
    
    success = test_excel_file(test_file)
    
    if success:
        print("\nLocal test successful! File processing works.")
        print("The issue might be specific to the Lambda/cloud environment.")
    else:
        print("\nLocal test failed. Need to fix the processing logic.")