# Supabase Integration Setup Guide

## Backend Configuration

Your Flutter admin app is now configured to communicate with your Supabase project.

### Project Details
- **Project URL**: https://lnssskyfwshwextaecdx.supabase.co
- **REST API Base URL**: https://lnssskyfwshwextaecdx.supabase.co/rest/v1

### Getting Your API Key

1. Go to your Supabase project dashboard
2. Navigate to **Settings** → **API**
3. Copy your **`anon` (public) key** from the "Project API keys" section
4. This is a safe public key used for client-side authentication

### Configuration Steps

1. **Update API Key in Config**
   - Open: `lib/config/supabase_config.dart`
   - Replace `YOUR_SUPABASE_ANON_KEY` with your actual anon key:
   ```dart
   static const String apiKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'; // Your actual key
   ```

2. **Verify Dependencies**
   - The `http` package is already in `pubspec.yaml`
   - Run: `flutter pub get`

3. **Test Connection**
   - Run the app and navigate to Fleet Management
   - The app will attempt to fetch buses from Supabase
   - Check debug console for any connection errors

### API Endpoints

The app uses the following Supabase REST API endpoints:

**Buses:**
- `GET /rest/v1/buses` - List all buses
- `POST /rest/v1/buses` - Create bus
- `PATCH /rest/v1/buses?id=eq.{id}` - Update bus
- `DELETE /rest/v1/buses?id=eq.{id}` - Delete bus

**Students:**
- `GET /rest/v1/students` - List students
- `POST /rest/v1/students` - Create student
- `PATCH /rest/v1/students?id=eq.{id}` - Update student
- `DELETE /rest/v1/students?id=eq.{id}` - Delete student

**Stops:**
- `GET /rest/v1/stops` - List boarding stops

**Relationships:**
- `GET /rest/v1/students?select=*,payments(*)` - Students with payments
- `GET /rest/v1/daily_manifests?allocated_bus_id=eq.{busId}&select=*,students(*,payments(*))` - Bus students with payments

### Row Level Security (RLS)

For production, consider enabling RLS policies:
1. In Supabase, go to **Authentication** → **Policies**
2. Create policies to restrict read/write access
3. Update headers if using custom authentication

### Environment Variables (Optional)

For better security, consider storing the API key in environment variables instead of hardcoding:

```dart
// lib/config/supabase_config.dart
class SupabaseConfig {
  static const String projectUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://lnssskyfwshwextaecdx.supabase.co');
  static const String apiKey = String.fromEnvironment('SUPABASE_KEY', defaultValue: 'YOUR_SUPABASE_ANON_KEY');
  // ...
}
```

Run with:
```bash
flutter run --dart-define=SUPABASE_URL=https://... --dart-define=SUPABASE_KEY=...
```

### Troubleshooting

**Issue**: 401 Unauthorized
- **Solution**: Verify your API key is correct in `supabase_config.dart`

**Issue**: 404 Not Found
- **Solution**: Check table names match exactly (lowercase, plural)

**Issue**: CORS errors
- **Solution**: Supabase should handle CORS automatically for anon key

**Issue**: Empty results
- **Solution**: Verify tables exist in Supabase and contain data

### Support
For issues, check:
- Supabase dashboard logs
- Flutter debug console output
- Your network connection
