#!/bin/bash
# ===========================================================================
# WC3 Database Import Example Data Script
# ===========================================================================
# This script imports the example items into the database
# ===========================================================================

echo ""
echo "============================================================"
echo "WC3 PotS Database - Import Example Data"
echo "============================================================"
echo ""

# Check if Python is available
if ! command -v python &> /dev/null; then
    if ! command -v python3 &> /dev/null; then
        echo "ERROR: Python is not installed"
        exit 1
    fi
    PYTHON=python3
else
    PYTHON=python
fi

echo "[1/2] Checking if example_items.json exists..."
if [ ! -f "example_items.json" ]; then
    echo "ERROR: example_items.json not found"
    echo "Please ensure you are in the WC3_Database directory"
    exit 1
fi
echo "✓ Found example_items.json"
echo ""

echo "[2/2] Importing example data..."
$PYTHON wc3_importer.py example_items.json --format json

if [ $? -eq 0 ]; then
    echo ""
    echo "============================================================"
    echo "Import completed successfully!"
    echo "============================================================"
    echo ""
    echo "You can now:"
    echo "  - View items: psql -U postgres -d wc3_pots -c 'SELECT * FROM v_items_complete;'"
    echo "  - Export to JASS: python wc3_exporter.py --output Items.j --format jass"
    echo "  - Query database: psql -U postgres -d wc3_pots"
    echo ""
else
    echo ""
    echo "ERROR: Import failed"
    echo "Please check the error messages above"
    exit 1
fi
