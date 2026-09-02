# API Configuration and Deployment Guide

This guide covers the production-ready API configuration system for the "What We Have for Lunch" Flutter application, including Google Places API and Gemini AI integration with comprehensive security and cost controls.

## Overview

The application uses two main APIs:
- **Google Places API**: Restaurant discovery and location services
- **Gemini AI API**: AI-powered restaurant recommendations

Both APIs are configured with production-ready security measures, cost controls, and monitoring capabilities.

## Environment Configuration

### Environment Files

The application supports environment-specific configurations through `.env` files:

- `.env.example` - Template with all available configuration options
- `.env.development` - Development environment (safe defaults, demo keys)
- `.env.staging` - Staging environment (moderate limits, real keys)
- `.env.production` - Production environment (full limits, secure keys) - **CREATE THIS**

### Required Environment Variables

#### Google Places API
```bash
# Core configuration
GOOGLE_PLACES_API_KEY=your_actual_api_key_here
GOOGLE_PLACES_MAX_REQUESTS_PER_MINUTE=60
GOOGLE_PLACES_DAILY_QUOTA_LIMIT=10000

# Optional: Domain restrictions (set in Google Cloud Console)
GOOGLE_PLACES_RESTRICT_DOMAINS=yourdomain.com,*.yourdomain.com
```

#### Gemini AI API
```bash
# Core configuration  
GEMINI_API_KEY=your_actual_api_key_here
GEMINI_MODEL=gemini-1.5-flash
GEMINI_TEMPERATURE=0.7
GEMINI_MAX_TOKENS=1000
GEMINI_DAILY_COST_LIMIT=5.0
GEMINI_MAX_REQUESTS_PER_MINUTE=10
GEMINI_ENABLE_CACHING=true
GEMINI_CACHE_TTL_HOURS=24
```

#### Security Configuration
```bash
# Environment and features
APP_ENVIRONMENT=production
ENABLE_AI_FEATURES=true
ENABLE_PLACES_API=true
ENABLE_DEBUG_LOGGING=false

# App restrictions
ALLOWED_BUNDLE_IDS=com.yourcompany.whatwehaveforlunch
ALLOWED_PACKAGE_NAMES=com.yourcompany.whatwehaveforlunch

# Encryption (generate with: openssl rand -hex 32)
API_ENCRYPTION_KEY=your_32_character_hex_encryption_key_here
```

#### Monitoring and Alerts
```bash
# Monitoring
ENABLE_USAGE_MONITORING=true
ENABLE_COST_ALERTS=true
COST_ALERT_THRESHOLD=80
REQUEST_ALERT_THRESHOLD=90

# Optional: Webhook for alerts
ALERT_WEBHOOK_URL=https://yourmonitoring.service/webhooks/api-alerts

# Fallback configuration
ENABLE_FALLBACK_MODE=true
API_TIMEOUT_SECONDS=30
FALLBACK_DATA_SOURCE=local_cache
```

## API Key Setup

### Google Places API

1. **Create Google Cloud Project**
   ```bash
   # Using gcloud CLI
   gcloud projects create your-project-id
   gcloud config set project your-project-id
   ```

2. **Enable Required APIs**
   ```bash
   gcloud services enable places-backend.googleapis.com
   gcloud services enable maps-backend.googleapis.com
   ```

3. **Create API Key**
   ```bash
   gcloud alpha services api-keys create --display-name="WhatWeHaveForLunch-Production"
   ```

4. **Configure API Key Restrictions**
   - **Application Restrictions**: 
     - Android: Add your package name and SHA-1 fingerprint
     - iOS: Add your bundle identifier
     - Web: Add your domain(s)
   
   - **API Restrictions**: Limit to:
     - Places API
     - Maps SDK for Android
     - Maps SDK for iOS

5. **Set Usage Quotas** (Cost Control)
   - Navigate to Google Cloud Console > APIs & Services > Quotas
   - Set daily quotas for each API to prevent unexpected costs
   - Recommended limits:
     - Places API (Nearby Search): 1,000 requests/day
     - Places API (Details): 500 requests/day
     - Places API (Text Search): 200 requests/day

### Gemini AI API

1. **Get API Key**
   - Visit [Google AI Studio](https://aistudio.google.com/app/apikey)
   - Create a new API key
   - Copy the key securely

2. **Configure Usage Limits**
   The application automatically enforces:
   - $5/user/day cost limit (configurable)
   - 10 requests/minute per user (configurable)
   - Request caching to reduce costs

## Security Implementation

### API Key Protection

1. **Environment Variables**: API keys are loaded from environment variables, never hardcoded
2. **Validation**: Keys are validated at startup with proper error handling
3. **Encryption**: Sensitive data is encrypted using the `API_ENCRYPTION_KEY`
4. **Restrictions**: API keys are restricted to specific bundle IDs/domains

### Production Security Checklist

- [ ] API keys are set via environment variables
- [ ] API key restrictions are properly configured in Google Cloud Console
- [ ] Encryption key is generated securely (32 random hex characters)
- [ ] Debug logging is disabled in production
- [ ] Bundle ID/package name restrictions are set
- [ ] SSL/TLS is enforced for all API communications

## Cost Management

### Budget Controls

The application implements multiple layers of cost control:

1. **Daily Cost Limits**
   - Gemini AI: $5/user/day (configurable)
   - Google Places: Quota-based limiting

2. **Request Rate Limiting**
   - Gemini AI: 10 requests/minute per user
   - Google Places: 60 requests/minute total

3. **Intelligent Caching**
   - Gemini responses cached for 24 hours (configurable)
   - Places API results cached for 24 hours
   - Cache invalidation based on location changes

4. **Fallback Mechanisms**
   - Automatic fallback to cached data when APIs are unavailable
   - Sample data fallback for development/testing

### Cost Monitoring

The application provides comprehensive cost monitoring:

- Real-time usage tracking
- Daily cost calculations  
- Alert thresholds (80% of daily limits by default)
- Webhook notifications for cost/quota issues
- Detailed usage analytics and reporting

## Deployment Configurations

### Development Environment

```bash
# Use .env.development file
APP_ENVIRONMENT=development
# Uses demo keys and lower limits
# Fallback enabled with sample data
# Debug logging enabled
```

### Staging Environment

```bash
# Use .env.staging file  
APP_ENVIRONMENT=staging
# Uses real API keys with moderate limits
# Monitoring enabled with alerts
# Debug logging disabled
```

### Production Environment

```bash
# Create .env.production file
APP_ENVIRONMENT=production
# Uses production API keys with full limits
# All security measures enabled
# Debug logging disabled
# Comprehensive monitoring and alerting
```

## Monitoring and Alerting

### Built-in Monitoring

The `ApiMonitoringService` provides:

- Request/response tracking
- Cost calculation and tracking
- Error rate monitoring
- Rate limit hit detection
- Performance metrics (response times)

### Alert Conditions

Alerts are triggered when:
- Daily cost exceeds 80% of limit (configurable)
- Request rate exceeds 90% of limit (configurable) 
- API errors exceed normal thresholds
- Rate limits are hit repeatedly
- API keys are invalid or expired

### Custom Alert Handlers

```dart
// Add custom alert handling
final monitoringService = ApiMonitoringService(database);
monitoringService.addAlertHandler((event) {
  // Custom alert logic (email, SMS, etc.)
  print('API Alert: ${event.type} for ${event.service}');
});
```

## Testing API Configuration

### Validation on Startup

The application validates configuration on startup:

```dart
// In main.dart or app initialization
final configValidation = ApiConfig.validateConfiguration();
if (!configValidation['valid']) {
  print('Configuration issues: ${configValidation['issues']}');
  // Handle configuration errors
}
```

### Configuration Summary

Get current configuration summary:

```dart
final summary = ApiConfig.getConfigSummary();
print('Environment: ${summary['environment']}');
print('APIs configured: ${summary['apis']}');
```

### Monitoring Dashboard

Get comprehensive monitoring data:

```dart
final monitoringService = ApiMonitoringService(database);
final summary = await monitoringService.getMonitoringSummary();
// Use summary for dashboard/reporting
```

## Troubleshooting

### Common Issues

1. **API Key Invalid Error**
   - Verify API key is correct and not expired
   - Check API key restrictions in Google Cloud Console
   - Ensure environment variable is set correctly

2. **Rate Limit Exceeded**
   - Check current usage in monitoring dashboard
   - Adjust rate limits in configuration
   - Implement backoff/retry logic

3. **High Costs**
   - Review cost monitoring dashboard
   - Adjust daily cost limits
   - Enable more aggressive caching
   - Optimize API usage patterns

4. **Fallback Mode Activated**
   - Check API key validity
   - Verify network connectivity
   - Review API service status
   - Check quota limits in Google Cloud Console

### Debug Mode

Enable debug logging for troubleshooting:

```bash
# In development only
ENABLE_DEBUG_LOGGING=true
APP_ENVIRONMENT=development
```

This will provide detailed logs of API requests, responses, and configuration validation.

## Support and Maintenance

### Regular Maintenance Tasks

1. **Monthly**: Review cost usage and optimize
2. **Weekly**: Check error rates and API health
3. **Daily**: Monitor alert notifications
4. **As needed**: Update API keys before expiration

### Performance Optimization

1. **Cache Optimization**: Tune cache TTL based on usage patterns
2. **Request Batching**: Combine multiple API calls where possible
3. **Intelligent Prefetching**: Cache popular restaurant data
4. **Geographic Optimization**: Adjust search radius based on user patterns

### Scaling Considerations

As your application grows:

1. **Increase Quotas**: Adjust Google Cloud quotas
2. **Implement CDN**: Cache static content
3. **Database Optimization**: Optimize local caching
4. **Load Balancing**: Distribute API load across regions

This comprehensive API configuration system ensures your Flutter application is production-ready with proper security, cost controls, and monitoring capabilities.