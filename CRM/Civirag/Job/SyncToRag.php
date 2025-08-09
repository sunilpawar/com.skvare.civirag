<?php

class CRM_Civirag_Job_SyncToRag {

  public static function run($params) {
    $processedCount = 0;
    $queue = CRM_Queue_Service::singleton()->create([
      'type' => 'Sql',
      'name' => 'rag_sync',
      'reset' => FALSE,
    ]);

    // Process up to 100 items per run
    for ($i = 0; $i < 100; $i++) {
      $item = $queue->claimItem();
      if (!$item) {
        break;
      }

      try {
        $result = $item->runItem();
        if ($result === CRM_Queue_Task::TASK_SUCCESS) {
          $queue->deleteItem($item);
          $processedCount++;
        }
        else {
          $queue->releaseItem($item);
        }
      }
      catch (Exception $e) {
        $queue->releaseItem($item);
        CRM_Core_Error::debug_log_message("RAG sync job error: " . $e->getMessage());
      }
    }

    return civicrm_api3_create_success([
      'message' => "Processed $processedCount RAG sync items",
      'processed_count' => $processedCount,
    ]);
  }
}
