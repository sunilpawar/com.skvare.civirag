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
