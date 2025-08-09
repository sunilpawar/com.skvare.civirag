<?php
use CRM_Civirag_ExtensionUtil as E;

class CRM_Civirag_Page_Search extends CRM_Core_Page {

  public function run() {
    $query = CRM_Utils_Request::retrieve('q', 'String');
    $results = [];

    if ($query) {
      $results = CRM_Civirag_BAO_RagSync::search($query);
    }

    $this->assign('query', $query);
    $this->assign('results', $results);

    parent::run();
  }
}
