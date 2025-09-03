#!/usr/bin/env python3
"""
Test script to validate the TollProcessor implementation
Tests the core functionality without running the FastAPI server
"""

import sys
import os
sys.path.append('app')

from toll_processor import TollProcessor
import pandas as pd

def test_toll_processor():
    """Test the toll processor with sample data"""
    
    print("Testing TollProcessor...")
    
    # Initialize processor
    processor = TollProcessor()
    
    # Test file path
    test_file = "uploads/test_data.xlsx"
    
    if not os.path.exists(test_file):
        print(f"Error: Test file {test_file} not found!")
        return False
    
    try:
        # Process the file
        print(f"Processing file: {test_file}")
        result_df = processor.process_excel_file(test_file)
        
        # Display results
        print(f"\nProcessing completed successfully!")
        print(f"Result contains {len(result_df)} rows")
        print(f"Columns: {list(result_df.columns)}")
        
        print("\nFirst few rows:")
        print(result_df.head())
        
        print("\nData types:")
        print(result_df.dtypes)
        
        print(f"\nTotal amount sum: {result_df['Total Amount'].sum()}")
        
        # Save test output
        output_file = "outputs/test_output.csv"
        result_df.to_csv(output_file, index=False)
        print(f"\nTest output saved to: {output_file}")
        
        return True
        
    except Exception as e:
        print(f"Error during processing: {str(e)}")
        return False

if __name__ == "__main__":
    success = test_toll_processor()
    if success:
        print("\n[SUCCESS] Test completed successfully!")
    else:
        print("\n[FAILED] Test failed!")
        sys.exit(1)