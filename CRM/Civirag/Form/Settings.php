<?php

use CRM_Civirag_ExtensionUtil as E;

/**
 * Form controller class
 *
 * @see https://docs.civicrm.org/dev/en/latest/framework/quickform/
 */
class CRM_Civirag_Form_Settings extends CRM_Core_Form {

  public function buildQuickForm() {
    $this->addElement('checkbox', 'civirag_enabled', E::ts('Enable RAG Integration'));

    $this->addElement('text', 'civirag_backend_url', E::ts('RAG Backend URL'), [
      'size' => 50,
      'placeholder' => 'http://localhost:8000'
    ]);

    $this->addElement('text', 'civirag_api_key', E::ts('API Key'), [
      'size' => 50,
      'placeholder' => 'Your secure API key'
    ]);

    $this->addElement('select', 'civirag_sync_interval', E::ts('Sync Interval'), [
      '300' => '5 minutes',
      '900' => '15 minutes',
      '3600' => '1 hour',
      '14400' => '4 hours',
      '86400' => '24 hours',
    ]);

    $this->addButtons([
      ['type' => 'submit', 'name' => E::ts('Save'), 'isDefault' => TRUE],
      ['type' => 'cancel', 'name' => E::ts('Cancel')],
    ]);

    // Set defaults
    $defaults = [
      'civirag_enabled' => Civi::settings()->get('civirag_enabled') ?? 1,
      'civirag_backend_url' => Civi::settings()->get('civirag_backend_url') ?? 'http://localhost:8000',
      'civirag_api_key' => Civi::settings()->get('civirag_api_key') ?? '',
      'civirag_sync_interval' => Civi::settings()->get('civirag_sync_interval') ?? 3600,
    ];
    $this->setDefaults($defaults);
  }

  public function postProcess() {
    $values = $this->exportValues();

    Civi::settings()->set('civirag_enabled', !empty($values['civirag_enabled']));
    Civi::settings()->set('civirag_backend_url', $values['civirag_backend_url']);
    Civi::settings()->set('civirag_api_key', $values['civirag_api_key']);
    Civi::settings()->set('civirag_sync_interval', $values['civirag_sync_interval']);

    CRM_Core_Session::setStatus(E::ts('RAG settings saved successfully.'), E::ts('Settings'), 'success');
  }
}
