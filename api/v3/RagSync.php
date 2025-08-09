<?php

/**
 * RagSync.queuestatus API
 * Gets status information about the RAG synchronization queue
 */
function civicrm_api3_rag_sync_queuestatus($params) {
  try {
    // Get queue instance
    $queue = CRM_Queue_Service::singleton()->create([
      'type' => 'Sql',
      'name' => 'rag_sync',
      'reset' => FALSE,
    ]);

    // Get basic queue statistics
    $queueSize = $queue->numberOfItems();

    // Get additional queue information
    $queueInfo = [];

    // Get last processed job info from database
    $dao = CRM_Core_DAO::executeQuery("
      SELECT
        COUNT(*) as total_processed,
        MAX(release_time) as last_processed_time,
        COUNT(CASE WHEN release_time IS NULL THEN 1 END) as pending_items,
        COUNT(CASE WHEN release_time IS NOT NULL THEN 1 END) as processing_items
      FROM civicrm_queue_item
      WHERE queue_name = 'rag_sync'
    ");

    if ($dao->fetch()) {
      $queueInfo = [
        'queue_size' => $queueSize,
        'pending_items' => (int)$dao->pending_items,
        'processing_items' => (int)$dao->processing_items,
        'total_in_queue' => (int)($dao->pending_items + $dao->processing_items),
        'last_processed' => $dao->last_processed_time ?
          date('Y-m-d H:i:s', strtotime($dao->last_processed_time)) : NULL,
      ];
    }
    else {
      $queueInfo = [
        'queue_size' => $queueSize,
        'pending_items' => $queueSize,
        'processing_items' => 0,
        'total_in_queue' => $queueSize,
        'last_processed' => NULL,
      ];
    }

    // Get some failed items if any
    $failedItems = [];
    $failedDao = CRM_Core_DAO::executeQuery("
      SELECT data, release_time
      FROM civicrm_queue_item
      WHERE queue_name = 'rag_sync'
        AND release_time IS NOT NULL
        AND release_time < DATE_SUB(NOW(), INTERVAL 1 HOUR)
      ORDER BY release_time DESC
      LIMIT 5
    ");

    while ($failedDao->fetch()) {
      $taskData = unserialize($failedDao->data);
      $failedItems[] = [
        'stuck_since' => $failedDao->release_time,
        'task_info' => isset($taskData->arguments) ?
          "Sync {$taskData->arguments[0]} #{$taskData->arguments[1]}" : 'Unknown task'
      ];
    }

    // Check if RAG is enabled
    $config = CRM_Civirag_BAO_RagSync::getConfig();

    // Get last job run information
    $lastJobRun = CRM_Core_DAO::singleValueQuery("
      SELECT MAX(last_run)
      FROM civicrm_job
      WHERE api_entity = 'Job'
        AND api_action = 'rag_sync'
        AND is_active = 1
    ");

    // Prepare status summary
    $status = 'healthy';
    $statusMessage = 'Queue is operating normally';

    if (!$config['enabled']) {
      $status = 'disabled';
      $statusMessage = 'RAG integration is disabled';
    }
    elseif ($queueInfo['total_in_queue'] > 1000) {
      $status = 'warning';
      $statusMessage = 'Large queue backlog detected';
    }
    elseif (count($failedItems) > 0) {
      $status = 'warning';
      $statusMessage = 'Some items may be stuck in queue';
    }
    elseif (!$lastJobRun || strtotime($lastJobRun) < strtotime('-2 hours')) {
      $status = 'warning';
      $statusMessage = 'Queue processor may not be running regularly';
    }

    $result = array_merge($queueInfo, [
      'status' => $status,
      'status_message' => $statusMessage,
      'rag_enabled' => $config['enabled'],
      'backend_url' => $config['backend_url'],
      'sync_interval' => $config['sync_interval'],
      'last_job_run' => $lastJobRun,
      'failed_items' => $failedItems,
      'recommendations' => _getRagQueueRecommendations($queueInfo, $config, $lastJobRun)
    ]);

    return civicrm_api3_create_success($result);

  }
  catch (Exception $e) {
    CRM_Core_Error::debug_log_message("RAG queue status error: " . $e->getMessage());
    return civicrm_api3_create_error('Failed to get queue status: ' . $e->getMessage());
  }
}

/**
 * Get recommendations based on queue status
 */
function _getRagQueueRecommendations($queueInfo, $config, $lastJobRun) {
  $recommendations = [];

  if (!$config['enabled']) {
    $recommendations[] = 'Enable RAG integration in settings to start processing queue';
  }

  if ($queueInfo['total_in_queue'] > 1000) {
    $recommendations[] = 'Consider reducing sync interval or increasing job frequency to clear backlog';
  }

  if ($queueInfo['total_in_queue'] > 100) {
    $recommendations[] = 'Monitor queue processing to ensure items are being processed regularly';
  }

  if (!$lastJobRun || strtotime($lastJobRun) < strtotime('-2 hours')) {
    $recommendations[] = 'Check that the RAG sync scheduled job is enabled and running';
  }

  if (empty($config['backend_url']) || empty($config['api_key'])) {
    $recommendations[] = 'Complete RAG backend configuration (URL and API key)';
  }

  if (empty($recommendations)) {
    $recommendations[] = 'Queue is healthy - no action needed';
  }

  return $recommendations;
}

/**
 * RagSync.queuestatus API specification
 */
function _civicrm_api3_rag_sync_queuestatus_spec(&$spec) {
  // No parameters required for this operation
}

/**
 * RagSync.performinitialsync API
 * Alternative endpoint for initial sync (matches what's called in template)
 */
function civicrm_api3_rag_sync_performinitialsync($params) {
  // Delegate to the RagSearch version
  return civicrm_api3_rag_search_performinitialsync($params);
}

/**
 * RagSync.performinitialsync API specification
 */
function _civicrm_api3_rag_sync_performinitialsync_spec(&$spec) {
  // No parameters required for this operation
}

/**
 * RagSync.processqueue API
 * Manually process queue items (useful for debugging)
 */
function civicrm_api3_rag_sync_processqueue($params) {
  $limit = $params['limit'] ?? 10;

  try {
    $result = CRM_Civirag_Job_SyncToRag::run(['limit' => $limit]);
    return $result;
  }
  catch (Exception $e) {
    CRM_Core_Error::debug_log_message("RAG manual queue processing error: " . $e->getMessage());
    return civicrm_api3_create_error('Queue processing failed: ' . $e->getMessage());
  }
}

function _civicrm_api3_rag_sync_processqueue_spec(&$spec) {
  $spec['limit'] = [
    'title' => 'Processing Limit',
    'description' => 'Maximum number of queue items to process',
    'type' => CRM_Utils_Type::T_INT,
    'api.default' => 10,
  ];
}

/**
 * RagSync.clearqueue API
 * Clear all items from the RAG sync queue (use with caution)
 */
function civicrm_api3_rag_sync_clearqueue($params) {
  $confirm = $params['confirm'] ?? FALSE;

  if (!$confirm) {
    return civicrm_api3_create_error('This action will delete all queued items. Set confirm=1 to proceed.');
  }

  try {
    $queue = CRM_Queue_Service::singleton()->create([
      'type' => 'Sql',
      'name' => 'rag_sync',
      'reset' => FALSE,
    ]);

    // Count items before clearing
    $itemCount = $queue->numberOfItems();

    // Clear the queue by deleting all items
    CRM_Core_DAO::executeQuery("DELETE FROM civicrm_queue_item WHERE queue_name = 'rag_sync'");

    return civicrm_api3_create_success([
      'status' => 'success',
      'message' => "Cleared $itemCount items from RAG sync queue",
      'cleared_items' => $itemCount
    ]);

  }
  catch (Exception $e) {
    CRM_Core_Error::debug_log_message("RAG clear queue error: " . $e->getMessage());
    return civicrm_api3_create_error('Failed to clear queue: ' . $e->getMessage());
  }
}

function _civicrm_api3_rag_sync_clearqueue_spec(&$spec) {
  $spec['confirm'] = [
    'title' => 'Confirm Action',
    'description' => 'Set to 1 to confirm queue clearing',
    'type' => CRM_Utils_Type::T_BOOLEAN,
    'api.required' => 1,
  ];
}

