# CiviRAG - CiviCRM RAG Integration Extension

This extension integrates Retrieval-Augmented Generation (RAG) capabilities with CiviCRM, enabling AI-powered natural language search and intelligent data retrieval across your CiviCRM database. By connecting to an external RAG backend, users can ask questions in plain English and get contextual answers based on their CiviCRM data.

This is an [extension for CiviCRM](https://docs.civicrm.org/sysadmin/en/latest/customize/extensions/), licensed under [AGPL-3.0](LICENSE.txt).

## Features

- **Natural Language Search**: Ask questions about your CiviCRM data in plain English
- **Real-time Data Sync**: Automatically syncs CiviCRM data changes to the RAG backend
- **Multi-entity Support**: Searches across Contacts, Activities, Cases, Events, Grants, and Memberships
- **Custom Field Integration**: Includes custom fields in the searchable data
- **Queue-based Synchronization**: Reliable background processing for data updates
- **API Integration**: RESTful API endpoints for programmatic access
- **Configurable Settings**: Easy administration through CiviCRM's interface

## Supported Entities

The extension automatically syncs and makes searchable the following CiviCRM entities:
- **Contacts** (including custom fields, organization details, contact information)
- **Activities** (subjects, details, types, dates, statuses)
- **Cases** (case types, subjects, statuses, dates)
- **Events**
- **Grants**
- **Memberships**

## Prerequisites

Before installing this extension, you'll need:

1. **CiviCRM 6.6+** - Compatible with CiviCRM version 6.6 and above
2. **RAG Backend Service** - An external RAG backend API service that can:
  - Accept data synchronization requests
  - Process natural language search queries
  - Return structured search results with AI-generated answers
3. **Queue Processing** - Ensure CiviCRM's queue processing is configured (for data synchronization)

## Installation

1. Download and extract the extension to your CiviCRM extensions directory
2. Navigate to **Administer > System Settings > Extensions**
3. Find "CiviCRM RAG Integration" and click **Install**

## Configuration

### 1. Basic Setup

Navigate to **Administer > System Settings > RAG Settings** to configure:

- **Enable RAG Integration**: Toggle to enable/disable the extension
- **RAG Backend URL**: The endpoint URL of your RAG backend service (e.g., `http://localhost:8000`)
- **API Key**: Authentication key for secure communication with the RAG backend
- **Sync Interval**: How frequently to process the synchronization queue (5 minutes to 24 hours)

### 2. Initial Data Sync

After configuration, perform an initial sync of your existing data:

```php
// Via API
civicrm_api3('RagSync', 'performinitialsync');

// Or programmatically
CRM_Civirag_BAO_RagSync::performInitialSync();
```

This will queue all existing records for synchronization with the RAG backend.

### 3. Queue Processing

Ensure your CiviCRM scheduled jobs include the RAG sync job:
- **Job Name**: `civirag_sync_job`
- **API Entity**: `Job`
- **API Action**: `rag_sync`
- **Frequency**: Every 5-15 minutes (based on your sync interval setting)

## Usage

### Web Interface Search

1. Navigate to **civicrm/rag/search** in your CiviCRM installation
2. Enter a natural language question in the search box, such as:
  - "Show me all contacts from New York who donated last month"
  - "What activities were completed for the Johnson case?"
  - "Find all upcoming events in Chicago"
3. View AI-generated answers along with relevant source records

### API Usage

Use the RAG Search API for programmatic access:

```php
// Search via API
$result = civicrm_api3('RagSearch', 'search', [
  'query' => 'Find all contacts with email addresses containing gmail',
  'limit' => 20
]);

if (!$result['is_error']) {
  $answer = $result['values']['answer'];
  $sources = $result['values']['sources'];
}
```

### Example Queries

The extension can handle various types of natural language queries:

- **Contact searches**: "Find all individual contacts in California"
- **Activity queries**: "Show me all meetings scheduled for next week"
- **Case management**: "What cases are currently open and assigned to Sarah?"
- **Event information**: "List all fundraising events in 2024"
- **Grant tracking**: "Show me grants that were approved last quarter"
- **Membership status**: "Find all expired memberships from organizations"

## How It Works

### Data Synchronization

1. **Real-time Updates**: When CiviCRM data changes (create, edit, delete), the extension automatically queues sync jobs
2. **Queue Processing**: Background jobs process the queue and send data to the RAG backend
3. **Data Extraction**: The extension extracts relevant searchable content from each entity, including custom fields
4. **API Communication**: Data is sent to the RAG backend via secure HTTP requests

### Search Process

1. **Query Input**: User enters a natural language question
2. **RAG Backend Processing**: The backend uses AI to understand the query and search indexed data
3. **Result Generation**: AI generates a contextual answer and identifies relevant source records
4. **Response Display**: Results are presented with both the AI answer and supporting CiviCRM records

## Technical Details

### Key Classes

- **`CRM_Civirag_BAO_RagSync`**: Core functionality for data extraction and synchronization
- **`CRM_Civirag_Form_Settings`**: Administrative configuration interface
- **`CRM_Civirag_Job_SyncToRag`**: Background job for processing sync queue

### Hooks Used

- **`hook_civicrm_post`**: Triggers automatic synchronization when data changes
- **`hook_civicrm_navigationMenu`**: Adds administration menu items

## Troubleshooting

### Common Issues

1. **Search returns no results**
  - Verify RAG backend is running and accessible
  - Check API key configuration
  - Ensure initial sync has completed

2. **Data not syncing**
  - Verify queue processing is running
  - Check CiviCRM error logs for sync failures
  - Confirm RAG backend is accepting requests

3. **Performance issues**
  - Adjust sync interval to reduce frequency
  - Monitor queue size and processing times
  - Optimize RAG backend performance

### Debug Information

Enable debug logging in CiviCRM to see detailed sync and search operations:

```php
// Check queue status
$queue = CRM_Queue_Service::singleton()->create([
  'type' => 'Sql',
  'name' => 'rag_sync',
]);
$queueSize = $queue->numberOfItems();
```

## Security Considerations

- **API Key Protection**: Store API keys securely and rotate regularly
- **Data Privacy**: Ensure RAG backend complies with data protection requirements
- **Access Control**: RAG search respects CiviCRM's permission system
- **HTTPS**: Use encrypted connections for RAG backend communication

## Development

### RAG Backend Requirements

Your RAG backend service should implement these endpoints:

- **POST /sync**: Accept entity synchronization data
- **POST /search**: Process search queries and return results

Expected request/response formats are documented in the `CRM_Civirag_BAO_RagSync` class.

### Extending the Extension

To add support for additional entities:

1. Add entity name to `$syncEntities` array in `civirag_civicrm_post()`
2. Implement data extraction logic in `extractEntityData()` method
3. Update search configuration to include new entities

## Support

For issues, feature requests, or contributions:

- **Documentation**: [CiviCRM Extensions Guide](https://docs.civicrm.org/dev/en/latest/extensions/)
- **Issues**: Report bugs through your preferred issue tracking system
- **Community**: Join CiviCRM community forums for general support

## License

This extension is licensed under [AGPL-3.0](LICENSE.txt). See the license file for complete terms and conditions.

## Changelog

### Version 1.0 (Alpha)
- Initial release
- Basic RAG integration functionality
- Support for core CiviCRM entities
- Configuration interface
- API endpoints
- Queue-based synchronization
