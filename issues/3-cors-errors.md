# Issue #3: CORS Errors

**Category**: Security / Browser

**Severity**: High - Blocks all API access

## Problem

Cross-Origin Resource Sharing (CORS) errors when trying to access Tercen API from Flutter web app.

Browser blocks requests with errors like:
```
Access to fetch at 'https://tercen.com/api/...' from origin 'https://tercen.com'
has been blocked by CORS policy: No 'Access-Control-Allow-Origin' header is present.
```

## Impact

- Cannot access Tercen API
- Manual HTTP requests fail
- Authentication doesn't work
- File downloads blocked

## Root Cause

Tercen platform has strict CORS requirements:
- Requires specific headers
- Token must be sent correctly
- Origin must match deployment URL

Manual HTTP calls don't set these headers correctly.

## Solution

**ALWAYS use `sci_tercen_client` package** - handles CORS automatically.

### ❌ WRONG: Manual HTTP calls

```dart
// DON'T DO THIS - will cause CORS errors
import 'package:http/http.dart' as http;

final response = await http.get(
  Uri.parse('https://tercen.com/api/files/$fileId'),
  headers: {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  },
);
// ✗ CORS error: blocked by browser
```

### ✅ CORRECT: Use sci_tercen_client

```dart
// DO THIS - CORS handled automatically
import 'package:sci_tercen_client/sci_service_factory_web.dart';

final factory = await createServiceFactoryForWebApp();
final fileService = factory.fileService;
final file = await fileService.get(fileId);
// ✓ Works - CORS headers set correctly
```

## Why sci_tercen_client Works

The official client:
- Uses correct base URLs
- Sets required CORS headers automatically
- Handles token injection properly
- Uses HttpAuthClient decorator pattern
- Tested with Tercen platform

## Development vs Production

### Development (localhost)

CORS restrictions are more lenient:
- Can test with mock data
- Can use localStorage tokens
- Browser allows cross-origin requests in dev mode

### Production (Tercen deployment)

CORS strictly enforced:
- Must use sci_tercen_client
- Token from URL parameters
- Origin must match Tercen domain

## Authentication Pattern

```dart
// Web app authentication with CORS handling
import 'package:sci_tercen_client/sci_service_factory_web.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Creates factory with CORS-compliant HTTP client
  final tercenFactory = await createServiceFactoryForWebApp();

  // All services from factory handle CORS automatically
  final fileService = tercenFactory.fileService;
  final workflowService = tercenFactory.workflowService;
  final documentService = tercenFactory.documentService;

  runApp(MyApp());
}
```

## Debugging CORS Issues

### Check Browser Console

Look for CORS errors:
```
❌ CORS policy: No 'Access-Control-Allow-Origin' header
❌ CORS policy: Response to preflight request doesn't pass access control check
❌ CORS policy: Request header field authorization is not allowed
```

### Verify Using sci_tercen_client

```dart
// If you see CORS errors, check:
import 'package:sci_tercen_client/...'; // ✓ Using official client

// NOT:
import 'package:http/http.dart' as http; // ✗ Manual HTTP calls
```

### Check Network Tab

In browser DevTools → Network tab:
- Look for failed requests (red)
- Check request headers
- Verify Authorization header present
- Check response headers for Access-Control-*

## Common Scenarios

### Scenario 1: File Download

```dart
// ❌ WRONG - CORS error
final response = await http.get(Uri.parse('https://tercen.com/api/files/$id'));

// ✅ CORRECT - CORS handled
final stream = _factory.fileService.download(id);
```

### Scenario 2: API Query

```dart
// ❌ WRONG - CORS error
final response = await http.post(
  Uri.parse('https://tercen.com/api/query'),
  body: jsonEncode(query),
);

// ✅ CORRECT - CORS handled
final results = await _factory.tableService.select(query);
```

### Scenario 3: Authentication

```dart
// ❌ WRONG - CORS error
final response = await http.post(
  Uri.parse('https://tercen.com/api/auth/login'),
  body: {'username': user, 'password': pass},
);

// ✅ CORRECT - CORS handled
final factory = await createServiceFactoryForWebApp();
// Authentication handled automatically
```

## Preflight Requests

CORS uses "preflight" OPTIONS requests:
- Browser sends OPTIONS before actual request
- Checks if server allows cross-origin request
- sci_tercen_client handles preflight automatically

You don't need to handle preflight - it's automatic.

## Required Headers (Handled by sci_tercen_client)

```
Access-Control-Allow-Origin: <origin>
Access-Control-Allow-Methods: GET, POST, PUT, DELETE
Access-Control-Allow-Headers: Authorization, Content-Type
Access-Control-Allow-Credentials: true
```

**You don't set these** - sci_tercen_client does it for you.

## When CORS Errors Persist

If using sci_tercen_client and still seeing CORS errors:

1. **Check token validity**
   ```dart
   // Verify token exists
   print('Token: ${localStorage.getItem('tercen.token')}');
   ```

2. **Check serviceUri**
   ```dart
   // Verify serviceUri matches environment
   print('ServiceUri: ${localStorage.getItem('tercen.serviceUri')}');
   ```

3. **Check deployment mode**
   ```dart
   // Verify URL parsing is correct
   print('URL: ${Uri.base}');
   ```

4. **Check Tercen server status**
   - Server may be down
   - Network connectivity issues

## Testing

```dart
void main() {
  test('Uses sci_tercen_client, not manual HTTP', () {
    final service = TercenImageService(factory);

    // Verify no direct http imports in implementation
    expect(service.toString(), isNot(contains('http.get')));
    expect(service.toString(), isNot(contains('http.post')));
  });
}
```

## See Also

- [Pattern: Authentication](../patterns/authentication.md)
- [Pattern: File Streaming](../patterns/file-streaming.md)
- [Issue #5: Tercen-Required File Structure](5-tercen-file-structure.md)
- [Skill 2: Tercen Real Implementation](../skills/2-tercen-real.md)
