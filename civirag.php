<?php

require_once 'civirag.civix.php';

use CRM_Civirag_ExtensionUtil as E;

/**
 * Implements hook_civicrm_config().
 *
 * @link https://docs.civicrm.org/dev/en/latest/hooks/hook_civicrm_config/
 */
function civirag_civicrm_config(&$config): void {
  _civirag_civix_civicrm_config($config);
}

/**
 * Implements hook_civicrm_install().
 *
 * @link https://docs.civicrm.org/dev/en/latest/hooks/hook_civicrm_install
 */
function civirag_civicrm_install(): void {
  _civirag_civix_civicrm_install();
}

/**
 * Implements hook_civicrm_enable().
 *
 * @link https://docs.civicrm.org/dev/en/latest/hooks/hook_civicrm_enable
 */
function civirag_civicrm_enable(): void {
  _civirag_civix_civicrm_enable();
}

/**
 * Implements hook_civicrm_navigationMenu().
 */
function civirag_civicrm_navigationMenu(&$menu) {
  _civirag_civix_insert_navigation_menu($menu, 'Administer/System Settings', [
    'label' => E::ts('RAG Settings'),
    'name' => 'rag_settings',
    'url' => 'civicrm/admin/rag/settings',
    'permission' => 'administer CiviCRM',
  ]);
  _civirag_civix_navigationMenu($menu);
}

/**
 * Implements hook_civicrm_post().
 * Triggers RAG sync when CiviCRM data changes.
 */
function civirag_civicrm_post($op, $objectName, $objectId, &$objectRef) {
  // Entities to sync with RAG
  $syncEntities = ['Contact', 'Activity', 'Case', 'Event', 'Grant', 'Membership'];

  if (in_array($objectName, $syncEntities) && in_array($op, ['create', 'edit', 'delete'])) {
    CRM_Civirag_BAO_RagSync::queueEntitySync($objectName, $objectId, $op);
  }
}

