{* CiviRAG Settings Form Template *}

<div class="crm-block crm-form-block crm-civirag-settings-form-block">

  {* Page header *}
  <div class="crm-submit-buttons">
    {include file="CRM/common/formButtons.tpl" location="top"}
  </div>

  {* Introduction text *}
  <div class="crm-section crm-civirag-intro">
    <div class="content">
      <p class="description">
        {ts}Configure the RAG (Retrieval-Augmented Generation) integration settings for CiviCRM.
          This enables AI-powered natural language search across your CiviCRM data.{/ts}
      </p>
    </div>
  </div>

  {* Enable RAG Integration *}
  <div class="crm-section">
    <div class="label">{$form.civirag_enabled.label}</div>
    <div class="content">
      {$form.civirag_enabled.html}
      <div class="description">
        {ts}Enable or disable the RAG integration. When disabled, no data will be synced and search will be unavailable.{/ts}
      </div>
    </div>
    <div class="clear"></div>
  </div>

  {* RAG Backend URL *}
  <div class="crm-section">
    <div class="label">{$form.civirag_backend_url.label} <span class="crm-marker">*</span></div>
    <div class="content">
      {$form.civirag_backend_url.html}
      <div class="description">
        {ts}The base URL of your RAG backend service (e.g., http://localhost:8000 or https://your-rag-service.com){/ts}
      </div>
    </div>
    <div class="clear"></div>
  </div>

  {* API Key *}
  <div class="crm-section">
    <div class="label">{$form.civirag_api_key.label} <span class="crm-marker">*</span></div>
    <div class="content">
      {$form.civirag_api_key.html}
      <div class="description">
        {ts}Secure API key for authenticating with the RAG backend service. Keep this confidential.{/ts}
      </div>
    </div>
    <div class="clear"></div>
  </div>

  {* Sync Interval *}
  <div class="crm-section">
    <div class="label">{$form.civirag_sync_interval.label}</div>
    <div class="content">
      {$form.civirag_sync_interval.html}
      <div class="description">
        {ts}How frequently the sync queue should be processed. More frequent syncing provides faster updates but uses more resources.{/ts}
      </div>
    </div>
    <div class="clear"></div>
  </div>

  {* Connection Test Section *}
  <div class="crm-section crm-civirag-test-section">
    <div class="label">{ts}Connection Test{/ts}</div>
    <div class="content">
      <a href="#" id="civirag-test-connection" class="button" style="margin-right: 10px;">
        <span><i class="crm-i fa-plug" aria-hidden="true"></i> {ts}Test Connection{/ts}</span>
      </a>
      <div id="civirag-test-result" style="margin-top: 10px;"></div>
      <div class="description">
        {ts}Test the connection to your RAG backend service to verify configuration.{/ts}
      </div>
    </div>
    <div class="clear"></div>
  </div>

  {* Initial Sync Section *}
  <div class="crm-section crm-civirag-sync-section">
    <div class="label">{ts}Data Synchronization{/ts}</div>
    <div class="content">
      <a href="#" id="civirag-initial-sync" class="button" style="margin-right: 10px;">
        <span><i class="crm-i fa-refresh" aria-hidden="true"></i> {ts}Perform Initial Sync{/ts}</span>
      </a>
      <div id="civirag-sync-result" style="margin-top: 10px;"></div>
      <div class="description">
        {ts}Queue all existing CiviCRM data for synchronization with the RAG backend. Use this after initial setup or major configuration changes.{/ts}
      </div>
    </div>
    <div class="clear"></div>
  </div>

  {* Queue Status Section *}
  <div class="crm-section crm-civirag-status-section">
    <div class="label">{ts}Queue Status{/ts}</div>
    <div class="content">
      <div id="civirag-queue-status">
        <a href="#" id="civirag-check-queue" class="button">
          <span><i class="crm-i fa-list" aria-hidden="true"></i> {ts}Check Queue Status{/ts}</span>
        </a>
      </div>
      <div id="civirag-queue-result" style="margin-top: 10px;"></div>
      <div class="description">
        {ts}Check the current status of the RAG synchronization queue.{/ts}
      </div>
    </div>
    <div class="clear"></div>
  </div>

  {* Help Section *}
  <div class="crm-section crm-civirag-help-section">
    <div class="label">{ts}Help & Documentation{/ts}</div>
    <div class="content">
      <div class="description">
        <ul>
          <li><strong>{ts}Search Interface:{/ts}</strong> <a href="{crmURL p='civicrm/rag/search'}">{ts}Access the RAG search interface{/ts}</a></li>
          <li><strong>{ts}Supported Entities:{/ts}</strong> {ts}Contacts, Activities, Cases, Events, Grants, Memberships{/ts}</li>
          <li><strong>{ts}Custom Fields:{/ts}</strong> {ts}All active custom fields are automatically included in synchronization{/ts}</li>
          <li><strong>{ts}Troubleshooting:{/ts}</strong> {ts}Check CiviCRM error logs for detailed sync and search error messages{/ts}</li>
        </ul>
      </div>
    </div>
    <div class="clear"></div>
  </div>

  {* Form buttons *}
  <div class="crm-submit-buttons">
    {include file="CRM/common/formButtons.tpl" location="bottom"}
  </div>

</div>

{* JavaScript for AJAX functionality *}
<script type="text/javascript">
  {literal}
  CRM.$(function($) {

    // Test connection functionality
    $('#civirag-test-connection').click(function(e) {
      e.preventDefault();

      var $button = $(this);
      var $result = $('#civirag-test-result');

      // Show loading state
      $button.prop('disabled', true).find('span').html('<i class="crm-i fa-spinner fa-spin"></i> {/literal}{ts escape='js'}Testing Connection...{/ts}{literal}');
      $result.empty();

      // Get current form values
      var backendUrl = $('input[name="civirag_backend_url"]').val();
      var apiKey = $('input[name="civirag_api_key"]').val();

      if (!backendUrl || !apiKey) {
        $result.html('<div class="crm-error">{/literal}{ts escape='js'}Please enter both Backend URL and API Key before testing.{/ts}{literal}</div>');
        $button.prop('disabled', false).find('span').html('<i class="crm-i fa-plug"></i> {/literal}{ts escape='js'}Test Connection{/ts}{literal}');
        return;
      }

      // Make AJAX call to test connection
      CRM.api3('RagSearch', 'testconnection', {
        'backend_url': backendUrl,
        'api_key': apiKey
      })
        .done(function(result) {
          if (result.is_error) {
            $result.html('<div class="crm-error"><i class="crm-i fa-times"></i> {/literal}{ts escape='js'}Connection failed:{/ts}{literal} ' + result.error_message + '</div>');
          } else {
            $result.html('<div class="crm-ok"><i class="crm-i fa-check"></i> {/literal}{ts escape='js'}Connection successful! Backend is reachable.{/ts}{literal}</div>');
          }
        })
        .fail(function() {
          $result.html('<div class="crm-error"><i class="crm-i fa-times"></i> {/literal}{ts escape='js'}Connection test failed. Please check your settings.{/ts}{literal}</div>');
        })
        .always(function() {
          $button.prop('disabled', false).find('span').html('<i class="crm-i fa-plug"></i> {/literal}{ts escape='js'}Test Connection{/ts}{literal}');
        });
    });

    // Initial sync functionality
    $('#civirag-initial-sync').click(function(e) {
      e.preventDefault();

      var $button = $(this);
      var $result = $('#civirag-sync-result');

      // Confirm action
      if (!confirm('{/literal}{ts escape='js'}This will queue all CiviCRM data for synchronization. This may take some time. Continue?{/ts}{literal}')) {
        return;
      }

      // Show loading state
      $button.prop('disabled', true).find('span').html('<i class="crm-i fa-spinner fa-spin"></i> {/literal}{ts escape='js'}Starting Sync...{/ts}{literal}');
      $result.empty();

      // Make AJAX call to start initial sync
      CRM.api3('RagSync', 'performinitialsync', {})
        .done(function(result) {
          if (result.is_error) {
            $result.html('<div class="crm-error"><i class="crm-i fa-times"></i> {/literal}{ts escape='js'}Sync failed:{/ts}{literal} ' + result.error_message + '</div>');
          } else {
            $result.html('<div class="crm-ok"><i class="crm-i fa-check"></i> {/literal}{ts escape='js'}Initial sync queued successfully! Data will be processed in the background.{/ts}{literal}</div>');
          }
        })
        .fail(function() {
          $result.html('<div class="crm-error"><i class="crm-i fa-times"></i> {/literal}{ts escape='js'}Failed to start initial sync. Please try again.{/ts}{literal}</div>');
        })
        .always(function() {
          $button.prop('disabled', false).find('span').html('<i class="crm-i fa-refresh"></i> {/literal}{ts escape='js'}Perform Initial Sync{/ts}{literal}');
        });
    });

    // Queue status functionality
    $('#civirag-check-queue').click(function(e) {
      e.preventDefault();

      var $button = $(this);
      var $result = $('#civirag-queue-result');

      // Show loading state
      $button.prop('disabled', true).find('span').html('<i class="crm-i fa-spinner fa-spin"></i> {/literal}{ts escape='js'}Checking...{/ts}{literal}');
      $result.empty();

      // Make AJAX call to check queue status
      CRM.api3('RagSync', 'queuestatus', {})
        .done(function(result) {
          if (result.is_error) {
            $result.html('<div class="crm-error"><i class="crm-i fa-times"></i> {/literal}{ts escape='js'}Error checking queue:{/ts}{literal} ' + result.error_message + '</div>');
          } else {
            var data = result.values;
            var statusHtml = '<div class="crm-info">' +
              '<strong>{/literal}{ts escape='js'}Queue Status:{/ts}{literal}</strong><br/>' +
              '{/literal}{ts escape='js'}Items in queue:{/ts}{literal} ' + (data.queue_size || 0) + '<br/>' +
              '{/literal}{ts escape='js'}Last processed:{/ts}{literal} ' + (data.last_processed || '{/literal}{ts escape='js'}Never{/ts}{literal}') +
              '</div>';
            $result.html(statusHtml);
          }
        })
        .fail(function() {
          $result.html('<div class="crm-error"><i class="crm-i fa-times"></i> {/literal}{ts escape='js'}Failed to check queue status.{/ts}{literal}</div>');
        })
        .always(function() {
          $button.prop('disabled', false).find('span').html('<i class="crm-i fa-list"></i> {/literal}{ts escape='js'}Check Queue Status{/ts}{literal}');
        });
    });

    // Form validation
    $('form').submit(function() {
      var backendUrl = $('input[name="civirag_backend_url"]').val();
      var apiKey = $('input[name="civirag_api_key"]').val();
      var enabled = $('input[name="civirag_enabled"]').is(':checked');

      if (enabled && (!backendUrl || !apiKey)) {
        CRM.alert('{/literal}{ts escape='js'}Backend URL and API Key are required when RAG integration is enabled.{/ts}{literal}', '{/literal}{ts escape='js'}Configuration Error{/ts}{literal}', 'error');
        return false;
      }

      return true;
    });

    // Auto-check queue status on page load
    setTimeout(function() {
      $('#civirag-check-queue').trigger('click');
    }, 1000);

  });
  {/literal}
</script>

{* Custom CSS for better styling *}
<style type="text/css">
  {literal}
  .crm-civirag-settings-form-block .crm-section {
    margin-bottom: 20px;
  }

  .crm-civirag-settings-form-block .description {
    color: #666;
    font-style: italic;
    margin-top: 5px;
    font-size: 0.9em;
  }

  .crm-civirag-intro {
    background: #f8f9fa;
    border: 1px solid #dee2e6;
    border-radius: 4px;
    padding: 15px;
    margin-bottom: 25px;
  }

  .crm-civirag-intro .description {
    margin: 0;
    font-style: normal;
    color: #495057;
  }

  .crm-civirag-test-section,
  .crm-civirag-sync-section,
  .crm-civirag-status-section {
    border-top: 1px solid #e9ecef;
    padding-top: 20px;
  }

  .crm-civirag-help-section {
    background: #e8f4fd;
    border: 1px solid #bee5eb;
    border-radius: 4px;
    padding: 15px;
    margin-top: 25px;
  }

  .crm-civirag-help-section ul {
    margin: 10px 0 0 20px;
  }

  .crm-civirag-help-section li {
    margin-bottom: 8px;
  }

  #civirag-test-result .crm-ok,
  #civirag-sync-result .crm-ok,
  #civirag-queue-result .crm-info {
    background: #d4edda;
    border: 1px solid #c3e6cb;
    color: #155724;
    padding: 10px;
    border-radius: 4px;
  }

  #civirag-test-result .crm-error,
  #civirag-sync-result .crm-error,
  #civirag-queue-result .crm-error {
    background: #f8d7da;
    border: 1px solid #f5c6cb;
    color: #721c24;
    padding: 10px;
    border-radius: 4px;
  }

  .button {
    background: #0073aa;
    border: 1px solid #0073aa;
    color: white;
    padding: 8px 15px;
    text-decoration: none;
    border-radius: 3px;
    display: inline-block;
  }

  .button:hover {
    background: #005a87;
    border-color: #005a87;
    color: white;
    text-decoration: none;
  }

  .button:disabled {
    background: #ccc;
    border-color: #ccc;
    cursor: not-allowed;
  }
  {/literal}
</style>
