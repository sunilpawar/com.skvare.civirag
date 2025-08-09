<?php

function civicrm_api3_rag_search_search($params) {
  $query = $params['query'] ?? '';
  $limit = $params['limit'] ?? 10;

  if (empty($query)) {
    return civicrm_api3_create_error('Query parameter is required');
  }

  $results = CRM_Civirag_BAO_RagSync::search($query, $limit);

  if (isset($results['error'])) {
    return civicrm_api3_create_error($results['error']);
  }

  return civicrm_api3_create_success($results);
}

function _civicrm_api3_rag_search_search_spec(&$spec) {
  $spec['query'] = [
    'title' => 'Search Query',
    'description' => 'Natural language search query',
    'type' => CRM_Utils_Type::T_STRING,
    'api.required' => 1,
  ];
  $spec['limit'] = [
    'title' => 'Result Limit',
    'description' => 'Maximum number of results to return',
    'type' => CRM_Utils_Type::T_INT,
    'api.default' => 10,
  ];
}


/**
 * RagSearch.testconnection API
 * Tests connection to RAG backend service
 */
function civicrm_api3_rag_search_testconnection($params) {
  $backendUrl = $params['backend_url'] ?? '';
  $apiKey = $params['api_key'] ?? '';

  if (empty($backendUrl)) {
    return civicrm_api3_create_error('Backend URL is required');
  }

  if (empty($apiKey)) {
    return civicrm_api3_create_error('API Key is required');
  }

  try {
    // Validate URL format
    if (!filter_var($backendUrl, FILTER_VALIDATE_URL)) {
      return civicrm_api3_create_error('Invalid backend URL format');
    }

    // Prepare test endpoint
    $testUrl = rtrim($backendUrl, '/') . '/health';

    // Test connection with cURL
    $ch = curl_init();
    curl_setopt_array($ch, [
      CURLOPT_URL => $testUrl,
      CURLOPT_RETURNTRANSFER => TRUE,
      CURLOPT_TIMEOUT => 10,
      CURLOPT_CONNECTTIMEOUT => 5,
      CURLOPT_HTTPHEADER => [
        'Content-Type: application/json',
        'X-API-Key: ' . $apiKey,
        'User-Agent: CiviCRM-RAG-Extension/1.0'
      ],
      CURLOPT_SSL_VERIFYPEER => FALSE, // For development - should be TRUE in production
      CURLOPT_FOLLOWLOCATION => TRUE,
      CURLOPT_MAXREDIRS => 3,
    ]);

    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error = curl_error($ch);
    $info = curl_getinfo($ch);
    curl_close($ch);

    // Handle cURL errors
    if ($response === FALSE || !empty($error)) {
      return civicrm_api3_create_error("Connection failed: $error");
    }

    // Check HTTP status codes
    if ($httpCode >= 200 && $httpCode < 300) {
      // Success - try to decode response
      $data = json_decode($response, TRUE);

      return civicrm_api3_create_success([
        'status' => 'success',
        'message' => 'Connection successful',
        'http_code' => $httpCode,
        'response_time' => round($info['total_time'] * 1000, 2) . 'ms',
        'backend_info' => $data ?? ['raw_response' => $response]
      ]);

    }
    elseif ($httpCode === 401 || $httpCode === 403) {
      return civicrm_api3_create_error("Authentication failed (HTTP $httpCode). Please check your API key.");

    }
    elseif ($httpCode === 404) {
      return civicrm_api3_create_error("Backend endpoint not found (HTTP $httpCode). Please check your backend URL.");

    }
    elseif ($httpCode >= 500) {
      return civicrm_api3_create_error("Backend server error (HTTP $httpCode). The RAG service may be experiencing issues.");

    }
    else {
      return civicrm_api3_create_error("Unexpected response (HTTP $httpCode). Please check your configuration.");
    }

  }
  catch (Exception $e) {
    CRM_Core_Error::debug_log_message("RAG connection test error: " . $e->getMessage());
    return civicrm_api3_create_error('Connection test failed: ' . $e->getMessage());
  }
}

/**
 * RagSearch.testconnection API specification
 */
function _civicrm_api3_rag_search_testconnection_spec(&$spec) {
  $spec['backend_url'] = [
    'title' => 'Backend URL',
    'description' => 'RAG backend service URL to test',
    'type' => CRM_Utils_Type::T_STRING,
    'api.required' => 1,
  ];
  $spec['api_key'] = [
    'title' => 'API Key',
    'description' => 'API key for authentication',
    'type' => CRM_Utils_Type::T_STRING,
    'api.required' => 1,
  ];
}

/**
 * RagSearch.performinitialsync API
 * Triggers initial synchronization of all CiviCRM data
 */
function civicrm_api3_rag_search_performinitialsync($params) {
  try {
    // Check if RAG is enabled
    $config = CRM_Civirag_BAO_RagSync::getConfig();
    if (!$config['enabled']) {
      return civicrm_api3_create_error('RAG integration is currently disabled. Please enable it in settings first.');
    }

    // Perform initial sync
    CRM_Civirag_BAO_RagSync::performInitialSync();

    // Get queue statistics
    $queue = CRM_Queue_Service::singleton()->create([
      'type' => 'Sql',
      'name' => 'rag_sync',
      'reset' => FALSE,
    ]);

    $queueSize = $queue->numberOfItems();

    return civicrm_api3_create_success([
      'status' => 'success',
      'message' => 'Initial synchronization queued successfully',
      'queued_items' => $queueSize,
      'note' => 'Data will be processed in the background. Check queue status to monitor progress.'
    ]);

  }
  catch (Exception $e) {
    CRM_Core_Error::debug_log_message("RAG initial sync error: " . $e->getMessage());
    return civicrm_api3_create_error('Initial sync failed: ' . $e->getMessage());
  }
}

/**
 * RagSearch.performinitialsync API specification
 */
function _civicrm_api3_rag_search_performinitialsync_spec(&$spec) {
  // No parameters required for this operation
}
