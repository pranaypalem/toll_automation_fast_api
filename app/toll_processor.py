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
            
            # Try reading with different engines to handle various Excel formats
            df = None
            last_error = None
            
            # First try with openpyxl for .xlsx files
            try:
                logger.info("Attempting to read with openpyxl engine")
                df = pd.read_excel(file_path, engine="openpyxl")
                logger.info("Successfully read with openpyxl")
            except Exception as e:
                last_error = e
                logger.warning(f"openpyxl failed: {str(e)}")
                
                # Try with xlrd for .xls files
                try:
                    logger.info("Attempting to read with xlrd engine")
                    df = pd.read_excel(file_path, engine="xlrd")
                    logger.info("Successfully read with xlrd")
                except Exception as e2:
                    last_error = e2
                    logger.warning(f"xlrd failed: {str(e2)}")
                    
                    # Try with calamine engine as last resort
                    try:
                        logger.info("Attempting to read with calamine engine")
                        df = pd.read_excel(file_path, engine="calamine")
                        logger.info("Successfully read with calamine")
                    except Exception as e3:
                        last_error = e3
                        logger.error(f"All engines failed. Last error: {str(e3)}")
            
            if df is None:
                raise ValueError(f"Could not read Excel file with any engine. Error: {str(last_error)}")

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
