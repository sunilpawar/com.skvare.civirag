{* RAG Sync Status Page Template *}

<div class="crm-block crm-content-block crm-civirag-sync-status">

  {* Page Header *}
  <div class="crm-submit-buttons">
    <a href="{crmURL p='civicrm/admin/rag/settings'}" class="button">
      <span><i class="crm-i fa-cog" aria-hidden="true"></i> {ts}RAG Settings{/ts}</span>
    </a>
    <a href="{crmURL p='civicrm/rag/search'}" class="button">
      <span><i class="crm-i fa-search" aria-hidden="true"></i> {ts}RAG Search{/ts}</span>
    </a>
  </div>

  {* Configuration Status *}
  <div class="crm-accordion-wrapper crm-accordion-open">
    <div class="crm-accordion-header">
      <i class="crm-i fa-info-circle" aria-hidden="true"></i> {ts}Configuration Status{/ts}
    </div>
    <div class="crm-accordion-body">
      <table class="crm-info-panel">
        <tr>
          <td class="label">{ts}RAG Integration{/ts}</td>
          <td>
            {if $config.enabled}
              <span class="crm-status-enabled"><i class="crm-i fa-check"></i> {ts}Enabled{/ts}</span>
            {else}
              <span class="crm-status-disabled"><i class="crm-i fa-times"></i> {ts}Disabled{/ts}</span>
            {/if}
          </td>
        </tr>
        <tr>
          <td class="label">{ts}Backend URL{/ts}</td>
          <td>
            {if $config.backend_url}
              <code>{$config.backend_url}</code>
            {else}
              <span class="crm-status-warning">{ts}Not configured{/ts}</span>
            {/if}
          </td>
        </tr>
        <tr>
          <td class="label">{ts}API Key{/ts}</td>
          <td>
            {if $config.api_key}
              <span class="crm-status-enabled"><i class="crm-i fa-key"></i> {ts}Configured{/ts}</span>
            {else}
              <span class="crm-status-warning">{ts}Not configured{/ts}</span>
            {/if}
          </td>
        </tr>
        <tr>
          <td class="label">{ts}Sync Interval{/ts}</td>
          <td>
            {if $config.sync_interval == 300}{ts}5 minutes{/ts}
            {elseif $config.sync_interval == 900}{ts}15 minutes{/ts}
            {elseif $config.sync_interval == 3600}{ts}1 hour{/ts}
            {elseif $config.sync_interval == 14400}{ts}4 hours{/ts}
            {elseif $config.sync_interval == 86400}{ts}24 hours{/ts}
            {else}{$config.sync_interval} {ts}seconds{/ts}{/if}
          </td>
        </tr>
      </table>
    </div>
  </div>

  {* Queue Status *}
  <div class="crm-accordion-wrapper crm-accordion-open">
    <div class="crm-accordion-header">
      <i class="crm-i fa-list" aria-hidden="true"></i> {ts}Queue Status{/ts}
      <span class="crm-status-indicator crm-status-{$queueStatus.status}">
        {$queueStatus.status|upper}
      </span>
    </div>
    <div class="crm-accordion-body">
      <div class="crm-status-message crm-status-{$queueStatus.status}">
        <i class="crm-i fa-{if $queueStatus.status == 'healthy'}check{elseif $queueStatus.status == 'warning'}exclamation-triangle{else}times{/if}"></i>
        {$queueStatus.status_message}
      </div>

      <table class="crm-info-panel">
        <tr>
          <td class="label">{ts}Total Items in Queue{/ts}</td>
          <td><strong>{$queueStatus.total_in_queue|default:0}</strong></td>
        </tr>
        <tr>
          <td class="label">{ts}Pending Items{/ts}</td>
          <td>{$queueStatus.pending_items|default:0}</td>
        </tr>
        <tr>
          <td class="label">{ts}Processing Items{/ts}</td>
          <td>{$queueStatus.processing_items|default:0}</td>
        </tr>
        <tr>
          <td class="label">{ts}Last Processed{/ts}</td>
          <td>
            {if $queueStatus.last_processed}
              {$queueStatus.last_processed|date_format:"%Y-%m-%d %H:%M:%S"}
            {else}
              {ts}Never{/ts}
            {/if}
          </td>
        </tr>
        <tr>
          <td class="label">{ts}Last Job Run{/ts}</td>
          <td>
            {if $queueStatus.last_job_run}
              {$queueStatus.last_job_run|date_format:"%Y-%m-%d %H:%M:%S"}
            {else}
              {ts}Never{/ts}
            {/if}
          </td>
        </tr>
      </table>

      {* Action Buttons *}
      <div class="crm-submit-buttons">
        <a href="#" id="refresh-status" class="button">
          <span><i class="crm-i fa-refresh"></i> {ts}Refresh Status{/ts}</span>
        </a>
        <a href="#" id="process-queue" class="button">
          <span><i class="crm-i fa-play"></i> {ts}Process Queue Now{/ts}</span>
        </a>
        {if $needsInitialSync}
          <a href="#" id="initial-sync" class="button">
            <span><i class="crm-i fa-sync"></i> {ts}Perform Initial Sync{/ts}</span>
          </a>
        {/if}
      </div>

      {* Recommendations *}
      {if $queueStatus.recommendations}
        <div class="crm-recommendations">
          <h4>{ts}Recommendations{/ts}</h4>
          <ul>
            {foreach from=$queueStatus.recommendations item=recommendation}
              <li>{$recommendation}</li>
            {/foreach}
          </ul>
        </div>
      {/if}
    </div>
  </div>

  {* Entity Statistics *}
  <div class="crm-accordion-wrapper crm-accordion-open">
    <div class="crm-accordion-header">
      <i class="crm-i fa-bar-chart" aria-hidden="true"></i> {ts}Entity Statistics{/ts}
    </div>
    <div class="crm-accordion-body">
      <table class="display">
        <thead>
        <tr>
          <th>{ts}Entity Type{/ts}</th>
          <th>{ts}Total Records{/ts}</th>
          <th>{ts}Last Synced{/ts}</th>
          <th>{ts}Status{/ts}</th>
        </tr>
        </thead>
        <tbody>
        {foreach from=$entityStats key=entityType item=stats}
          <tr>
            <td><strong>{$entityType}</strong></td>
            <td>{$stats.total_records|number_format}</td>
            <td>
              {if $stats.last_synced}
                {$stats.last_synced|date_format:"%Y-%m-%d %H:%M"}
              {else}
                <span class="crm-status-warning">{ts}Never{/ts}</span>
              {/if}
            </td>
            <td>
              {if $stats.error}
                <span class="crm-status-error"><i class="crm-i fa-times"></i> {ts}Error{/ts}</span>
              {elseif $stats.last_synced}
                <span class="crm-status-enabled"><i class="crm-i fa-check"></i> {ts}Synced{/ts}</span>
              {else}
                <span class="crm-status-warning"><i class="crm-i fa-clock-o"></i> {ts}Pending{/ts}</span>
              {/if}
            </td>
          </tr>
        {/foreach}
        </tbody>
      </table>
    </div>
  </div>

  {* Recent Activity *}
  {if $recentActivity}
    <div class="crm-accordion-wrapper">
      <div class="crm-accordion-header">
        <i class="crm-i fa-history" aria-hidden="true"></i> {ts}Recent Sync Activity{/ts}
        <span class="crm-activity-count">({$recentActivity|@count} {ts}items in last 24 hours{/ts})</span>
      </div>
      <div class="crm-accordion-body">
        <table class="display">
          <thead>
          <tr>
            <th>{ts}Time{/ts}</th>
            <th>{ts}Entity{/ts}</th>
            <th>{ts}Operation{/ts}</th>
            <th>{ts}Status{/ts}</th>
            <th>{ts}Attempts{/ts}</th>
          </tr>
          </thead>
          <tbody>
          {foreach from=$recentActivity item=activity}
            <tr class="crm-activity-{$activity.status}">
              <td>{$activity.submit_time|date_format:"%m/%d %H:%M"}</td>
              <td>{$activity.entity_type} #{$activity.entity_id}</td>
              <td>
                <span class="crm-operation-{$activity.operation}">{$activity.operation|capitalize}</span>
              </td>
              <td>
                {if $activity.status == 'completed'}
                  <span class="crm-status-enabled"><i class="crm-i fa-check"></i> {ts}Completed{/ts}</span>
                {elseif $activity.status == 'processing'}
                  <span class="crm-status-warning"><i class="crm-i fa-spinner"></i> {ts}Processing{/ts}</span>
                {else}
                  <span class="crm-status-pending"><i class="crm-i fa-clock-o"></i> {ts}Pending{/ts}</span>
                {/if}
              </td>
              <td>{$activity.run_count}</td>
            </tr>
          {/foreach}
          </tbody>
        </table>
      </div>
    </div>
  {/if}

  {* Failed Items Warning *}
  {if $queueStatus.failed_items}
    <div class="crm-accordion-wrapper">
      <div class="crm-accordion-header crm-accordion-header-warning">
        <i class="crm-i fa-exclamation-triangle" aria-hidden="true"></i> {ts}Stuck Items{/ts}
        <span class="crm-failed-count">({$queueStatus.failed_items|@count} {ts}items{/ts})</span>
      </div>
      <div class="crm-accordion-body">
        <p class="description">
          {ts}The following items appear to be stuck in the queue and may need attention:{/ts}
        </p>
        <table class="display">
          <thead>
          <tr>
            <th>{ts}Task{/ts}</th>
            <th>{ts}Stuck Since{/ts}</th>
          </tr>
          </thead>
          <tbody>
          {foreach from=$queueStatus.failed_items item=failed}
            <tr>
              <td>{$failed.task_info}</td>
              <td>{$failed.stuck_since|date_format:"%Y-%m-%d %H:%M:%S"}</td>
            </tr>
          {/foreach}
          </tbody>
        </table>
        <div class="crm-submit-buttons">
          <a href="#" id="clear-stuck" class="button button-danger">
            <span><i class="crm-i fa-trash"></i> {ts}Clear Stuck Items{/ts}</span>
          </a>
        </div>
      </div>
    </div>
  {/if}

</div>

{* JavaScript for AJAX functionality *}
<script type="text/javascript">
  {literal}
  CRM.$(function($) {

    // Refresh status
    $('#refresh-status').click(function(e) {
      e.preventDefault();
      location.reload();
    });

    // Process queue manually
    $('#process-queue').click(function(e) {
      e.preventDefault();
      var $button = $(this);

      $button.prop('disabled', true).find('span').html('<i class="crm-i fa-spinner fa-spin"></i> {/literal}{ts escape='js'}Processing...{/ts}{literal}');

      CRM.api3('RagSync', 'processqueue', { limit: 10 })
        .done(function(result) {
          if (result.is_error) {
            CRM.alert(result.error_message, '{/literal}{ts escape='js'}Error{/ts}{literal}', 'error');
          } else {
            CRM.alert('{/literal}{ts escape='js'}Processed queue items successfully{/ts}{literal}', '{/literal}{ts escape='js'}Success{/ts}{literal}', 'success');
            setTimeout(function() { location.reload(); }, 1000);
          }
        })
        .fail(function() {
          CRM.alert('{/literal}{ts escape='js'}Failed to process queue{/ts}{literal}', '{/literal}{ts escape='js'}Error{/ts}{literal}', 'error');
        })
        .always(function() {
          $button.prop('disabled', false).find('span').html('<i class="crm-i fa-play"></i> {/literal}{ts escape='js'}Process Queue Now{/ts}{literal}');
        });
    });

    // Initial sync
    $('#initial-sync').click(function(e) {
      e.preventDefault();
      var $button = $(this);

      if (!confirm('{/literal}{ts escape='js'}This will queue all CiviCRM data for synchronization. Continue?{/ts}{literal}')) {
        return;
      }

      $button.prop('disabled', true).find('span').html('<i class="crm-i fa-spinner fa-spin"></i> {/literal}{ts escape='js'}Starting Sync...{/ts}{literal}');

      CRM.api3('RagSync', 'performinitialsync', {})
        .done(function(result) {
          if (result.is_error) {
            CRM.alert(result.error_message, '{/literal}{ts escape='js'}Error{/ts}{literal}', 'error');
          } else {
            CRM.alert('{/literal}{ts escape='js'}Initial sync queued successfully{/ts}{literal}', '{/literal}{ts escape='js'}Success{/ts}{literal}', 'success');
            setTimeout(function() { location.reload(); }, 1000);
          }
        })
        .fail(function() {
          CRM.alert('{/literal}{ts escape='js'}Failed to start initial sync{/ts}{literal}', '{/literal}{ts escape='js'}Error{/ts}{literal}', 'error');
        })
        .always(function() {
          $button.prop('disabled', false).find('span').html('<i class="crm-i fa-sync"></i> {/literal}{ts escape='js'}Perform Initial Sync{/ts}{literal}');
        });
    });

    // Clear stuck items
    $('#clear-stuck').click(function(e) {
      e.preventDefault();
      var $button = $(this);

      if (!confirm('{/literal}{ts escape='js'}This will remove stuck items from the queue. They will need to be re-queued manually. Continue?{/ts}{literal}')) {
        return;
      }

      $button.prop('disabled', true).find('span').html('<i class="crm-i fa-spinner fa-spin"></i> {/literal}{ts escape='js'}Clearing...{/ts}{literal}');

      CRM.api3('RagSync', 'clearqueue', { confirm: 1 })
        .done(function(result) {
          if (result.is_error) {
            CRM.alert(result.error_message, '{/literal}{ts escape='js'}Error{/ts}{literal}', 'error');
          } else {
            CRM.alert('{/literal}{ts escape='js'}Queue cleared successfully{/ts}{literal}', '{/literal}{ts escape='js'}Success{/ts}{literal}', 'success');
            setTimeout(function() { location.reload(); }, 1000);
          }
        })
        .fail(function() {
          CRM.alert('{/literal}{ts escape='js'}Failed to clear queue{/ts}{literal}', '{/literal}{ts escape='js'}Error{/ts}{literal}', 'error');
        })
        .always(function() {
          $button.prop('disabled', false).find('span').html('<i class="crm-i fa-trash"></i> {/literal}{ts escape='js'}Clear Stuck Items{/ts}{literal}');
        });
    });

    // Auto-refresh every 30 seconds
    setInterval(function() {
      $('#refresh-status').trigger('click');
    }, 30000);

  });
  {/literal}
</script>

{* Custom CSS *}
<style type="text/css">
  {literal}
  .crm-civirag-sync-status .crm-status-warning {
    color: #ffc107;
    font-weight: bold;
  }

  .crm-civirag-sync-status .crm-status-pending {
    color: #6c757d;
  }

  .crm-civirag-sync-status .crm-status-indicator {
    float: right;
    padding: 2px 8px;
    border-radius: 3px;
    font-size: 0.8em;
    font-weight: bold;
  }

  .crm-civirag-sync-status .crm-status-indicator.crm-status-healthy {
    background: #d4edda;
    color: #155724;
    border: 1px solid #c3e6cb;
  }

  .crm-civirag-sync-status .crm-status-indicator.crm-status-warning {
    background: #fff3cd;
    color: #856404;
    border: 1px solid #ffeaa7;
  }

  .crm-civirag-sync-status .crm-status-indicator.crm-status-error,
  .crm-civirag-sync-status .crm-status-indicator.crm-status-disabled {
    background: #f8d7da;
    color: #721c24;
    border: 1px solid #f5c6cb;
  }

  .crm-civirag-sync-status .crm-status-message {
    padding: 10px;
    margin: 10px 0;
    border-radius: 4px;
    border: 1px solid;
  }

  .crm-civirag-sync-status .crm-status-message.crm-status-healthy {
    background: #d4edda;
    color: #155724;
    border-color: #c3e6cb;
  }

  .crm-civirag-sync-status .crm-status-message.crm-status-warning {
    background: #fff3cd;
    color: #856404;
    border-color: #ffeaa7;
  }

  .crm-civirag-sync-status .crm-status-message.crm-status-error,
  .crm-civirag-sync-status .crm-status-message.crm-status-disabled {
    background: #f8d7da;
    color: #721c24;
    border-color: #f5c6cb;
  }

  .crm-civirag-sync-status .crm-recommendations {
    background: #e2f3ff;
    border: 1px solid #bee5eb;
    border-radius: 4px;
    padding: 15px;
    margin-top: 15px;
  }

  .crm-civirag-sync-status .crm-recommendations h4 {
    margin-top: 0;
    color: #0c5460;
  }

  .crm-civirag-sync-status .crm-recommendations ul {
    margin-bottom: 0;
    padding-left: 20px;
  }

  .crm-civirag-sync-status .crm-recommendations li {
    margin-bottom: 5px;
  }

  .crm-civirag-sync-status .crm-accordion-header-warning {
    background: #fff3cd;
    color: #856404;
    border-color: #ffeaa7;
  }

  .crm-civirag-sync-status .crm-activity-count,
  .crm-civirag-sync-status .crm-failed-count {
    font-size: 0.9em;
    font-weight: normal;
    color: #666;
  }

  .crm-civirag-sync-status .crm-activity-completed {
    background: #f8fff8;
  }

  .crm-civirag-sync-status .crm-activity-processing {
    background: #fff8e1;
  }

  .crm-civirag-sync-status .crm-activity-pending {
    background: #f5f5f5;
  }

  .crm-civirag-sync-status .crm-operation-create {
    color: #28a745;
    font-weight: bold;
  }

  .crm-civirag-sync-status .crm-operation-edit {
    color: #ffc107;
    font-weight: bold;
  }

  .crm-civirag-sync-status .crm-operation-delete {
    color: #dc3545;
    font-weight: bold;
  }

  .crm-civirag-sync-status .button-danger {
    background: #dc3545;
    border-color: #dc3545;
    color: white;
  }

  .crm-civirag-sync-status .button-danger:hover {
    background: #c82333;
    border-color: #bd2130;
    color: white;
  }

  .crm-civirag-sync-status .crm-info-panel {
    width: 100%;
    border-collapse: collapse;
  }

  .crm-civirag-sync-status .crm-info-panel td {
    padding: 8px;
    border-bottom: 1px solid #dee2e6;
  }

  .crm-civirag-sync-status .crm-info-panel td.label {
    font-weight: bold;
    width: 200px;
    background: #f8f9fa;
  }

  .crm-civirag-sync-status .display {
    width: 100%;
    border-collapse: collapse;
    margin-top: 10px;
  }

  .crm-civirag-sync-status .display th,
  .crm-civirag-sync-status .display td {
    padding: 8px;
    text-align: left;
    border-bottom: 1px solid #dee2e6;
  }

  .crm-civirag-sync-status .display th {
    background: #f8f9fa;
    font-weight: bold;
  }

  .crm-civirag-sync-status .display tbody tr:hover {
    background: #f8f9fa;
  }

  .crm-civirag-sync-status code {
    background: #f8f9fa;
    padding: 2px 4px;
    border-radius: 3px;
    font-family: 'Courier New', monospace;
    font-size: 0.9em;
  }
  {/literal}
</style>
