#!/bin/bash

# Script to systematically replace print() statements with proper logging

echo "Fixing print statements in production code..."

# Define a function to add logging import if not present
add_logging_import() {
    local file="$1"
    if ! grep -q "import.*logging_service.dart" "$file"; then
        # Find the last import statement and add logging service import after it
        local last_import_line=$(grep -n "^import" "$file" | tail -1 | cut -d: -f1)
        if [ ! -z "$last_import_line" ]; then
            sed -i "${last_import_line}a\\
import '../../core/services/logging_service.dart';" "$file" 2>/dev/null || \
            sed -i "${last_import_line}a\\
import '../../../core/services/logging_service.dart';" "$file" 2>/dev/null || \
            sed -i "${last_import_line}a\\
import '../../../../core/services/logging_service.dart';" "$file" 2>/dev/null || \
            echo "Could not determine correct path for logging service in $file"
        fi
    fi
}

# Process each file with print statements
for file in $(find /Users/rayding/galway/what_we_have_for_lunch/lib -name "*.dart" -exec grep -l "print(" {} \;); do
    echo "Processing $file..."
    
    # Add logging import
    add_logging_import "$file"
    
    # Replace print statements based on context
    # Error contexts
    sed -i "s/print('Failed to \([^']*\): \$e');/LoggingService().error('Failed to \1', tag: 'System', error: e);/g" "$file"
    sed -i "s/print('Error \([^']*\): \$e');/LoggingService().error('Error \1', tag: 'System', error: e);/g" "$file"
    sed -i "s/print('\([^']*\) failed: \$e');/LoggingService().error('\1 failed', tag: 'System', error: e);/g" "$file"
    sed -i "s/print('\([^']*\) error: \$e');/LoggingService().error('\1 error', tag: 'System', error: e);/g" "$file"
    
    # Warning contexts
    sed -i "s/print('Warning: \([^']*\)');/LoggingService().warning('\1', tag: 'System');/g" "$file"
    sed -i "s/print('CRITICAL \([^']*\)');/LoggingService().critical('\1', tag: 'Security');/g" "$file"
    
    # Info contexts
    sed -i "s/print('\([^']*\) initialized');/LoggingService().info('\1 initialized', tag: 'System');/g" "$file"
    sed -i "s/print('\([^']*\) updated');/LoggingService().info('\1 updated', tag: 'System');/g" "$file"
    sed -i "s/print('\([^']*\) completed');/LoggingService().info('\1 completed', tag: 'System');/g" "$file"
    
    # Generic print statements
    sed -i "s/print('\([^']*\)');/LoggingService().info('\1', tag: 'System');/g" "$file"
    
    echo "Processed $file"
done

echo "Print statement replacement completed!"