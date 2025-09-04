import logging
from datetime import datetime

import pandas as pd

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class TollProcessor:
    """
    Python implementation of the VBA toll automation logic
    Processes toll transaction data following the same workflow as the original VBA code
    """

    def __init__(self) -> None:
        self.required_columns = [
            "AMOUNT IN RS",
            "TRANSACTIONTYPE",
            "TRANSACTION_DATE",
            "TRANSACTIONID",
        ]

    def process_excel_file(self, file_path: str) -> pd.DataFrame:
        """
        Main processing function that mimics the VBA action() subroutine
        Processes the Excel file through all transformation steps
        """
        try:
            logger.info(f"Starting processing of file: {file_path}")

            # Step 1: Import data (equivalent to importData())
            df = self._import_data(file_path)
            logger.info(f"Imported {len(df)} rows of data")

            # Step 2: Filter data (equivalent to filteredData())
            filtered_df = self._filter_data(df)
            logger.info(f"Filtered to {len(filtered_df)} rows")

            # Step 3: Format data (equivalent to formatData())
            formatted_df = self._format_data(filtered_df)
            logger.info(f"Formatted to {len(formatted_df)} rows")

            # Step 4: Convert date format (equivalent to ConvertDateFormat())
            date_converted_df = self._convert_date_format(formatted_df)

            # Step 5: Apply final filter (equivalent to finalFilter())
            final_df = self._final_filter(date_converted_df)
            logger.info(f"Final output contains {len(final_df)} rows")

            return final_df

        except Exception as e:
            logger.error(f"Error processing file {file_path}: {str(e)}")
            raise

    def _import_data(self, file_path: str) -> pd.DataFrame:
        """
        Import data from Excel file (equivalent to VBA importData())
        """
        import os
        
        try:
            # Verify file exists and has content
            if not os.path.exists(file_path):
                raise ValueError(f"File not found: {file_path}")
            
            file_size = os.path.getsize(file_path)
            if file_size == 0:
                raise ValueError("File is empty")
                
            logger.info(f"Reading file: {file_path} (size: {file_size} bytes)")
            
            # Detect actual file format by reading file headers
            actual_format = self._detect_file_format(file_path)
            file_ext = file_path.lower().split('.')[-1]
            logger.info(f"File extension: {file_ext}, Detected format: {actual_format}")
            
            # Warn if extension doesn't match detected format
            if actual_format and actual_format != file_ext:
                logger.warning(f"File extension '{file_ext}' doesn't match detected format '{actual_format}'. File may have incorrect extension.")
            
            df = None
            last_error = None
            engines_to_try = []
            
            # Determine engines to try based on detected format and extension
            if actual_format == 'xlsx' or file_ext in ['xlsx', 'xlsm']:
                engines_to_try = ['openpyxl', 'xlrd']
            elif actual_format == 'xls' or file_ext == 'xls':
                engines_to_try = ['xlrd', 'openpyxl']
            elif actual_format == 'csv':
                # File detected as CSV, skip Excel engines
                engines_to_try = []
            else:
                # If detection failed, try both engines
                engines_to_try = ['openpyxl', 'xlrd']
            
            # Try engines in order of preference
            for engine in engines_to_try:
                try:
                    logger.info(f"Attempting to read file with {engine} engine")
                    df = pd.read_excel(file_path, engine=engine)
                    logger.info(f"Successfully read with {engine}")
                    break
                except Exception as e:
                    last_error = e
                    logger.warning(f"{engine} failed: {str(e)}")
                    continue
            
            # Try reading as CSV if detected as CSV or if Excel engines failed for .xls files
            if df is None and (actual_format == 'csv' or file_ext == 'xls'):
                try:
                    logger.info("Attempting to read as CSV format")
                    df = pd.read_csv(file_path, encoding='utf-8')
                    logger.info("Successfully read as CSV format")
                except UnicodeDecodeError:
                    try:
                        # Try different encoding
                        logger.info("UTF-8 failed, trying latin-1 encoding")
                        df = pd.read_csv(file_path, encoding='latin-1')
                        logger.info("Successfully read as CSV with latin-1 encoding")
                    except Exception as e:
                        logger.warning(f"CSV read with latin-1 failed: {str(e)}")
                        # Try tab-separated values
                        try:
                            logger.info("Trying tab-separated format")
                            df = pd.read_csv(file_path, sep='\t', encoding='utf-8')
                            logger.info("Successfully read as TSV format")
                        except Exception as e2:
                            logger.warning(f"TSV read failed: {str(e2)}")
                except Exception as e:
                    logger.warning(f"CSV read failed: {str(e)}")
            
            if df is None:
                # Provide more helpful error message
                error_msg = f"Could not read file with any supported format (Excel engines or CSV). "
                if actual_format and actual_format != file_ext:
                    error_msg += f"The file appears to be in '{actual_format}' format but has a '{file_ext}' extension. "
                    error_msg += "The file may be corrupted, have an incorrect file extension, or be in an unsupported format. "
                    error_msg += "Please ensure the file is a valid Excel file (.xlsx, .xls) or try saving it in a different format. "
                error_msg += f"Last error: {str(last_error)}"
                raise ValueError(error_msg)

            logger.info(f"Excel file loaded successfully with {len(df)} rows and {len(df.columns)} columns")
            
            # Clean column names (remove extra spaces, standardize case)
            df.columns = df.columns.str.strip().str.upper()

            # Validate required columns exist
            missing_cols = [
                col for col in self.required_columns if col not in df.columns
            ]
            if missing_cols:
                available_cols = list(df.columns)
                raise ValueError(f"Missing required columns: {missing_cols}. Available columns: {available_cols}")

            return df

        except Exception as e:
            logger.error(f"Error importing Excel file: {str(e)}")
            raise ValueError(f"Error importing Excel file: {str(e)}")

    def _detect_file_format(self, file_path: str) -> str:
        """
        Detect actual file format by reading file headers/magic bytes
        Returns 'xlsx', 'xls', or None if unknown
        """
        try:
            with open(file_path, 'rb') as f:
                # Read first few bytes to check file signature
                header = f.read(8)
                
                # ZIP signature (used by .xlsx, .xlsm) - starts with 'PK'
                if header.startswith(b'PK'):
                    return 'xlsx'
                
                # Old Excel binary format (.xls) - starts with specific signatures
                # Microsoft Office documents often start with D0CF11E0 (OLE compound document)
                if header.startswith(b'\xd0\xcf\x11\xe0'):
                    return 'xls'
                
                # Additional signatures for Excel files
                if header.startswith(b'\x09\x08'):  # Some .xls files
                    return 'xls'
                    
                # Check for XML-based files (sometimes .xls files are actually XML)
                if header.startswith(b'<?xml') or header.startswith(b'<html') or header.startswith(b'<HTML'):
                    # This might be an HTML/XML file with wrong extension
                    logger.warning("File appears to be HTML/XML format, not Excel")
                    return 'xml'
                
                # Check for CSV-like content (text files saved as .xls)
                try:
                    # Try to decode as text to check if it looks like CSV
                    text_content = header.decode('utf-8', errors='ignore')
                    if ',' in text_content or '\t' in text_content:
                        logger.info("File appears to contain delimited text (CSV/TSV)")
                        return 'csv'
                except Exception:
                    pass
                
                logger.info(f"Unknown file signature: {header}")
                return None
                
        except Exception as e:
            logger.warning(f"Could not detect file format: {str(e)}")
            return None

    def _filter_data(self, df: pd.DataFrame) -> pd.DataFrame:
        """
        Filter data for debit transactions > 0 (equivalent to VBA filteredData())
        Based on VBA analysis, all data in NewData.xlsx is valid, so we'll filter
        appropriately
        """
        try:
            # Create copy to avoid modifying original
            filtered_df = df.copy()

            # Filter for debit transactions with amount > 0
            if "TRANSACTIONTYPE" in filtered_df.columns:
                filtered_df = filtered_df[
                    filtered_df["TRANSACTIONTYPE"].str.upper() == "DEBIT"
                ]

            if "AMOUNT IN RS" in filtered_df.columns:
                # Convert to numeric, handling any string values
                filtered_df["AMOUNT IN RS"] = pd.to_numeric(
                    filtered_df["AMOUNT IN RS"], errors="coerce"
                )
                filtered_df = filtered_df[filtered_df["AMOUNT IN RS"] > 0]

            # Remove rows with null values in critical columns
            filtered_df = filtered_df.dropna(
                subset=["TRANSACTIONID", "TRANSACTION_DATE"]
            )

            return filtered_df

        except Exception as e:
            raise ValueError(f"Error filtering data: {str(e)}")

    def _format_data(self, df: pd.DataFrame) -> pd.DataFrame:
        """
        Format data by grouping up to 8 entries per day (equivalent to VBA formatData())
        Combines transaction IDs and sums amounts for same-day transactions
        """
        try:
            # Extract essential columns and convert dates first
            essential_df = df[
                ["TRANSACTIONID", "AMOUNT IN RS", "TRANSACTION_DATE"]
            ].copy()

            # Convert dates to consistent format for grouping
            essential_df["TRANSACTION_DATE"] = self._standardize_dates(
                essential_df["TRANSACTION_DATE"]
            )

            # Sort by date to group consecutive entries
            essential_df = essential_df.sort_values("TRANSACTION_DATE")

            # Process groups of up to 8 entries per day
            formatted_rows = []

            # Group by date
            for date_val, group in essential_df.groupby("TRANSACTION_DATE"):
                group_list = group.to_dict("records")

                # If group has more than 8 entries, split into chunks
                for i in range(0, len(group_list), 8):
                    chunk = group_list[i : i + 8]

                    if len(chunk) > 1:
                        # Combine transaction IDs (last 4 digits)
                        combined_txn_ids = "-".join(
                            [str(row["TRANSACTIONID"])[-4:] for row in chunk]
                        )
                        total_amount = sum(row["AMOUNT IN RS"] for row in chunk)
                        num_entries = len(chunk)

                        formatted_rows.append(
                            {
                                "Transaction ID": combined_txn_ids,
                                "No. Entries": num_entries,
                                "Amount": total_amount,
                                "Date": date_val,
                            }
                        )
                    else:
                        # Single entry - use last 4 digits of transaction ID
                        row = chunk[0]
                        formatted_rows.append(
                            {
                                "Transaction ID": str(row["TRANSACTIONID"])[-4:],
                                "No. Entries": 1,
                                "Amount": row["AMOUNT IN RS"],
                                "Date": date_val,
                            }
                        )

            return pd.DataFrame(formatted_rows)

        except Exception as e:
            raise ValueError(f"Error formatting data: {str(e)}")

    def _convert_date_format(self, df: pd.DataFrame) -> pd.DataFrame:
        """
        Convert date format to dd/mm/yyyy (equivalent to VBA ConvertDateFormat())
        """
        try:
            result_df = df.copy()

            if "Date" in result_df.columns:
                result_df["Date"] = self._standardize_dates(result_df["Date"])

            return result_df

        except Exception as e:
            raise ValueError(f"Error converting date format: {str(e)}")

    def _final_filter(self, df: pd.DataFrame) -> pd.DataFrame:
        """
        Apply final filtering (equivalent to VBA finalFilter())
        Remove 'No. Entries' column and create final output structure
        """
        try:
            # Create final output with renamed columns
            final_df = df.copy()

            # Filter out empty transaction IDs and zero amounts
            final_df = final_df[
                (final_df["Transaction ID"].notna())
                & (final_df["Transaction ID"] != "")
                & (final_df["Amount"] > 0)
            ]

            # Remove 'No. Entries' column for final output
            if "No. Entries" in final_df.columns:
                final_df = final_df.drop("No. Entries", axis=1)

            # Rename columns for final output (matching VBA output)
            final_df = final_df.rename(
                columns={
                    "Transaction ID": "Toll Route",
                    "Amount": "Total Amount",
                    "Date": "Date",
                }
            )

            # Reorder columns
            final_df = final_df[["Toll Route", "Total Amount", "Date"]]

            return final_df

        except Exception as e:
            raise ValueError(f"Error applying final filter: {str(e)}")

    def _standardize_dates(self, date_series: pd.Series) -> pd.Series:
        """
        Standardize date formats to dd/mm/yyyy
        Handles various input formats like the VBA code
        """
        standardized_dates = []

        for date_val in date_series:
            try:
                if pd.isna(date_val):
                    standardized_dates.append("")
                    continue

                # Convert to string first
                date_str = str(date_val)

                # Try different parsing approaches
                parsed_date = None

                # Try pandas to_datetime with various formats
                try:
                    parsed_date = pd.to_datetime(date_val, dayfirst=True)
                except Exception:
                    try:
                        # Handle format like "30-Jul-25"
                        date_str_modified = date_str.replace("-", " ")
                        parsed_date = pd.to_datetime(date_str_modified, dayfirst=True)
                    except Exception:
                        # Try other common formats
                        for fmt in [
                            "%d/%m/%Y",
                            "%d-%m-%Y",
                            "%Y-%m-%d",
                            "%d/%m/%y",
                            "%d-%m-%y",
                        ]:
                            try:
                                parsed_date = datetime.strptime(date_str, fmt)
                                break
                            except Exception:
                                continue

                if parsed_date is not None:
                    # Format as dd/mm/yyyy
                    standardized_dates.append(parsed_date.strftime("%d/%m/%Y"))
                else:
                    # Keep original if parsing failed
                    standardized_dates.append(date_str)

            except Exception:
                # Keep original value if all parsing attempts fail
                standardized_dates.append(str(date_val))

        return pd.Series(standardized_dates)
