import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'core'))
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'parsers'))

from wc3_w3t_exporter import WC3W3TExporter

print(f'FIELD_MAP has {len(WC3W3TExporter.FIELD_MAP)} fields')
print('\nAll field mappings:')
for k in sorted(WC3W3TExporter.FIELD_MAP.keys()):
    field_code, field_type = WC3W3TExporter.FIELD_MAP[k]
    print(f'  {k:30} -> {field_code} (type {field_type})')
