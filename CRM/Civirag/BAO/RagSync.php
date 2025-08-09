<?php

class CRM_Civirag_BAO_RagSync extends CRM_Core_DAO {

  /**
   * Queue entity for RAG synchronization
   */
  public static function queueEntitySync($entityName, $entityId, $operation) {
    $config = self::getConfig();
    if (!$config['enabled']) {
      return;
    }

    // Add to sync queue
    $queue = CRM_Queue_Service::singleton()->create([
      'type' => 'Sql',
      'name' => 'rag_sync',
      'reset' => FALSE,
    ]);

    $task = new CRM_Queue_Task(
      ['CRM_Civirag_BAO_RagSync', 'syncEntityToRag'],
      [$entityName, $entityId, $operation],
      "Sync $entityName $entityId to RAG"
    );

    $queue->createItem($task);
  }

  /**
   * Sync specific entity to RAG backend
   */
  public static function syncEntityToRag($ctx, $entityName, $entityId, $operation) {
    $config = self::getConfig();

    try {
      $data = self::extractEntityData($entityName, $entityId);

      $payload = [
        'entity_type' => $entityName,
        'entity_id' => $entityId,
        'operation' => $operation,
        'data' => $data,
        'timestamp' => date('c')
      ];

      $response = self::callRagBackend('/sync', $payload);

      if ($response['status'] !== 'success') {
        throw new Exception("RAG sync failed: " . $response['message']);
      }

      return CRM_Queue_Task::TASK_SUCCESS;

    }
    catch (Exception $e) {
      CRM_Core_Error::debug_log_message("RAG sync error for $entityName $entityId: " . $e->getMessage());
      return CRM_Queue_Task::TASK_FAIL;
    }
  }

  /**
   * Extract searchable data from CiviCRM entity
   */
  private static function extractEntityData($entityName, $entityId) {
    $data = [];

    switch ($entityName) {
      case 'Contact':
        $contact = civicrm_api3('Contact', 'getsingle', ['id' => $entityId]);
        $data = [
          'id' => $contact['id'],
          'display_name' => $contact['display_name'] ?? '',
          'first_name' => $contact['first_name'] ?? '',
          'last_name' => $contact['last_name'] ?? '',
          'email' => $contact['email'] ?? '',
          'phone' => $contact['phone'] ?? '',
          'organization_name' => $contact['organization_name'] ?? '',
          'job_title' => $contact['job_title'] ?? '',
          'contact_type' => $contact['contact_type'] ?? '',
          'contact_sub_type' => $contact['contact_sub_type'] ?? '',
        ];

        // Add custom fields
        $customFields = self::getCustomFieldsForEntity('Contact', $entityId);
        $data = array_merge($data, $customFields);
        break;

      case 'Activity':
        $activity = civicrm_api3('Activity', 'getsingle', ['id' => $entityId]);
        $data = [
          'id' => $activity['id'],
          'activity_type' => $activity['activity_type_id'] ?? '',
          'subject' => $activity['subject'] ?? '',
          'details' => strip_tags($activity['details'] ?? ''),
          'activity_date_time' => $activity['activity_date_time'] ?? '',
          'status' => $activity['status_id'] ?? '',
        ];
        break;

      case 'Case':
        $case = civicrm_api3('Case', 'getsingle', ['id' => $entityId]);
        $data = [
          'id' => $case['id'],
          'case_type' => $case['case_type_id'] ?? '',
          'subject' => $case['subject'] ?? '',
          'status' => $case['status_id'] ?? '',
          'start_date' => $case['start_date'] ?? '',
          'end_date' => $case['end_date'] ?? '',
        ];
        break;

      default:
        // Generic entity extraction
        try {
          $entity = civicrm_api3($entityName, 'getsingle', ['id' => $entityId]);
          $data = $entity;
        }
        catch (Exception $e) {
          CRM_Core_Error::debug_log_message("Could not extract $entityName $entityId: " . $e->getMessage());
        }
    }

    return $data;
  }

  /**
   * Get custom fields for entity
   */
  private static function getCustomFieldsForEntity($entityName, $entityId) {
    $customFields = [];

    try {
      $customGroups = civicrm_api3('CustomGroup', 'get', [
        'extends' => $entityName,
        'is_active' => 1,
      ]);

      foreach ($customGroups['values'] as $group) {
        $fields = civicrm_api3('CustomField', 'get', [
          'custom_group_id' => $group['id'],
          'is_active' => 1,
        ]);

        foreach ($fields['values'] as $field) {
          $customFieldName = 'custom_' . $field['id'];
          try {
            $value = civicrm_api3('CustomValue', 'get', [
              'entity_id' => $entityId,
              'custom_field_id' => $field['id'],
            ]);

            if (!empty($value['values'])) {
              $customFields[$field['label']] = $value['values'][0]['latest'] ?? '';
            }
          }
          catch (Exception $e) {
            // Skip if custom field value not found
          }
        }
      }
    }
    catch (Exception $e) {
      CRM_Core_Error::debug_log_message("Error getting custom fields: " . $e->getMessage());
    }

    return $customFields;
  }

  /**
   * Perform initial sync of all CiviCRM data
   */
  public static function performInitialSync() {
    $config = self::getConfig();
    if (!$config['enabled']) {
      return;
    }

    $entities = ['Contact', 'Activity', 'Case', 'Event', 'Grant', 'Membership'];

    foreach ($entities as $entity) {
      try {
        $results = civicrm_api3($entity, 'get', [
          'sequential' => 1,
          'options' => ['limit' => 0], // Get all records
        ]);

        foreach ($results['values'] as $record) {
          self::queueEntitySync($entity, $record['id'], 'create');
        }

        CRM_Core_Session::setStatus(
          "Queued {$results['count']} $entity records for RAG sync",
          'RAG Sync',
          'success'
        );

      }
      catch (Exception $e) {
        CRM_Core_Error::debug_log_message("Initial sync error for $entity: " . $e->getMessage());
      }
    }
  }

  /**
   * Call RAG backend API
   */
  private static function callRagBackend($endpoint, $data = []) {
    $config = self::getConfig();
    $url = rtrim($config['backend_url'], '/') . $endpoint;

    $ch = curl_init();
    curl_setopt_array($ch, [
      CURLOPT_URL => $url,
      CURLOPT_RETURNTRANSFER => TRUE,
      CURLOPT_POST => TRUE,
      CURLOPT_POSTFIELDS => json_encode($data),
      CURLOPT_HTTPHEADER => [
        'Content-Type: application/json',
        'X-API-Key: ' . $config['api_key']
      ],
      CURLOPT_TIMEOUT => 30,
    ]);

    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    if ($httpCode !== 200) {
      throw new Exception("RAG API call failed with HTTP $httpCode");
    }

    return json_decode($response, TRUE);
  }

  /**
   * Get extension configuration
   */
  private static function getConfig() {
    return [
      'enabled' => Civi::settings()->get('civirag_enabled') ?? TRUE,
      'backend_url' => Civi::settings()->get('civirag_backend_url') ?? 'http://localhost:8000',
      'api_key' => Civi::settings()->get('civirag_api_key') ?? 'changeme',
      'sync_interval' => Civi::settings()->get('civirag_sync_interval') ?? 3600, // 1 hour
    ];
  }

  /**
   * Search CiviCRM data using RAG
   */
  public static function search($query, $limit = 10) {
    $config = self::getConfig();

    if (!$config['enabled']) {
      return ['error' => 'RAG is disabled'];
    }

    try {
      $response = self::callRagBackend('/search', [
        'query' => $query,
        'limit' => $limit,
        'include_entities' => ['Contact', 'Activity', 'Case'],
      ]);

      return $response;

    }
    catch (Exception $e) {
      CRM_Core_Error::debug_log_message("RAG search error: " . $e->getMessage());
      return ['error' => 'Search failed: ' . $e->getMessage()];
    }
  }
}
