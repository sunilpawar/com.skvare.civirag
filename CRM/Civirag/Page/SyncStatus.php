<?php
use CRM_Civirag_ExtensionUtil as E;

/**
 * RAG Sync Status Page
 * Provides detailed view of synchronization status and queue management
 */
class CRM_Civirag_Page_SyncStatus extends CRM_Core_Page {

  public function run() {
    // Set page title
    CRM_Utils_System::setTitle(E::ts('RAG Synchronization Status'));

    // Get queue status
    $queueStatus = $this->getQueueStatus();
    $this->assign('queueStatus', $queueStatus);

    // Get configuration
    $config = CRM_Civirag_BAO_RagSync::getConfig();
    $this->assign('config', $config);

    // Get recent sync activity
    $recentActivity = $this->getRecentSyncActivity();
    $this->assign('recentActivity', $recentActivity);

    // Get entity statistics
    $entityStats = $this->getEntityStatistics();
    $this->assign('entityStats', $entityStats);

    // Check if initial sync is needed
    $needsInitialSync = $this->checkInitialSyncNeeded();
    $this->assign('needsInitialSync', $needsInitialSync);

    parent::run();
  }

  /**
   * Get queue status information
   */
  private function getQueueStatus() {
    try {
      $result = civicrm_api3('RagSync', 'queuestatus');
      return $result['values'];
    }
    catch (Exception $e) {
      return [
        'status' => 'error',
        'status_message' => 'Unable to get queue status: ' . $e->getMessage(),
        'queue_size' => 0,
        'pending_items' => 0,
        'processing_items' => 0,
      ];
    }
  }

  /**
   * Get recent sync activity from logs
   */
  private function getRecentSyncActivity() {
    $activity = [];

    try {
      // Get recent queue items (last 24 hours)
      $dao = CRM_Core_DAO::executeQuery("
        SELECT
          qi.data,
          qi.submit_time,
          qi.release_time,
          qi.run_count
        FROM civicrm_queue_item qi
        WHERE qi.queue_name = 'rag_sync'
          AND qi.submit_time >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
        ORDER BY qi.submit_time DESC
        LIMIT 50
      ");

      while ($dao->fetch()) {
        $taskData = unserialize($dao->data);
        $activity[] = [
          'submit_time' => $dao->submit_time,
          'release_time' => $dao->release_time,
          'run_count' => $dao->run_count,
          'entity_type' => $taskData->arguments[0] ?? 'Unknown',
          'entity_id' => $taskData->arguments[1] ?? 'Unknown',
          'operation' => $taskData->arguments[2] ?? 'Unknown',
          'status' => $dao->release_time ?
            ($dao->run_count > 0 ? 'completed' : 'processing') : 'pending'
        ];
      }
    }
    catch (Exception $e) {
      CRM_Core_Error::debug_log_message("Error getting recent sync activity: " . $e->getMessage());
    }

    return $activity;
  }

  /**
   * Get statistics by entity type
   */
  private function getEntityStatistics() {
    $stats = [];
    $entities = ['Contact', 'Activity', 'Case', 'Event', 'Grant', 'Membership'];

    foreach ($entities as $entity) {
      try {
        $count = civicrm_api3($entity, 'getcount');
        $stats[$entity] = [
          'total_records' => $count,
          'last_synced' => $this->getLastSyncedTime($entity),
        ];
      }
      catch (Exception $e) {
        $stats[$entity] = [
          'total_records' => 0,
          'last_synced' => NULL,
          'error' => $e->getMessage()
        ];
      }
    }

    return $stats;
  }

  /**
   * Check if initial sync is needed
   */
  private function checkInitialSyncNeeded() {
    // Check if there are any records in the database but no sync activity
    $hasData = FALSE;
    $hasSyncActivity = FALSE;

    try {
      $contactCount = civicrm_api3('Contact', 'getcount');
      $hasData = $contactCount > 0;

      // Check if there's any sync activity in the queue or completed
      $queueCount = CRM_Core_DAO::singleValueQuery("
        SELECT COUNT(*) FROM civicrm_queue_item WHERE queue_name = 'rag_sync'
      ");
      $hasSyncActivity = $queueCount > 0;

    }
    catch (Exception $e) {
      // If we can't determine, assume sync is needed
      return TRUE;
    }

    return $hasData && !$hasSyncActivity;
  }

  /**
   * Get last synced time for an entity type
   */
  private function getLastSyncedTime($entityType) {
    try {
      $lastSync = CRM_Core_DAO::singleValueQuery("
        SELECT MAX(submit_time)
        FROM civicrm_queue_item
        WHERE queue_name = 'rag_sync'
          AND data LIKE %1
      ", [
        1 => ["%{$entityType}%", 'String']
      ]);

      return $lastSync;
    }
    catch (Exception $e) {
      return NULL;
    }
  }
}
