<div class="crm-block crm-content-block">
  <div class="crm-submit-buttons">
    <form method="get" action="{crmURL p='civicrm/rag/search'}">
      <div class="crm-section">
        <div class="label">
          <label for="rag-query">{ts}Search Query{/ts}</label>
        </div>
        <div class="content">
          <input type="text" id="rag-query" name="q" value="{$query}"
                 placeholder="Ask a question about your CiviCRM data..."
                 style="width: 400px;" />
          <input type="submit" value="{ts}Search{/ts}" class="crm-button" />
        </div>
      </div>
    </form>
  </div>

  {if $query}
  <div class="crm-results-block">
    <h3>{ts}Search Results{/ts}</h3>

    {if $results.answer}
    <div class="crm-rag-answer" style="background: #f8f9fa; padding: 15px; margin: 10px 0; border-left: 4px solid #007cba;">
      <h4>{ts}AI Answer{/ts}</h4>
      <p>{$results.answer}</p>
    </div>
    {/if}

    {if $results.sources}
    <div class="crm-rag-sources">
      <h4>{ts}Related Records{/ts}</h4>
      {foreach from=$results.sources item=source}
      <div class="crm-rag-source" style="border: 1px solid #ddd; padding: 10px; margin: 5px 0;">
        <strong>{$source.entity_type} #{$source.entity_id}</strong>
        <p>{$source.content|truncate:200}</p>
        <small>Score: {$source.score|string_format:"%.3f"}</small>
      </div>
      {/foreach}
    </div>
    {/if}
  </div>
  {/if}
</div>

<script>
  {literal}
  CRM.$(function($) {
    // Auto-focus search input
    $('#rag-query').focus();

    // Submit on Enter
    $('#rag-query').keypress(function(e) {
      if (e.which == 13) {
        $(this).closest('form').submit();
      }
    });
  });
  {/literal}
</script>
