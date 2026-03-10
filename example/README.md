# Igloo Dio Logger - Example

This example demonstrates the various features of the Igloo Dio Logger package.

## Running the Example

1. Make sure you have Flutter installed
2. Navigate to the example directory:
   ```bash
   cd example
   ```

3. Get dependencies:
   ```bash
   flutter pub get
   ```

4. Run the example:
   ```bash
   dart main.dart
   ```

## What You'll See

The example demonstrates:

1. **GET Request with Query Params** - Shows how query parameters are formatted
2. **POST Request with Body** - Displays JSON body with syntax highlighting
3. **404 Error Response** - Shows error handling with appropriate emoji
4. **Endpoint Filtering** - Demonstrates include/exclude filtering

## Expected Output

You should see colorful, formatted HTTP logs in your console with:
- 🎨 ANSI colors for different elements
- 😊 Status-specific emojis (✅, 🔍, 💥, etc.)
- 📊 Request duration and size metrics
- 🎯 JSON syntax highlighting
- 📝 Formatted query parameters

## Customizing

Feel free to modify the `main.dart` file to experiment with different:
- Logger configurations
- Endpoint filters
- API endpoints
- Request types

Enjoy exploring the logger! 🚀
