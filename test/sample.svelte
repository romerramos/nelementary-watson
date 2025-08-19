<script>
  import * as m from '$lib/paraglide/messages';
  
  // Translation calls in script
  const pageTitle = m.page_title();
  const welcomeMsg = m.welcome_user();
  const errorText = m.form_error();
  
  // With parameters
  const greeting = m.personal_greeting({ name: "Alice" });
</script>

<h1>{m.header_title()}</h1>
<p>{m.description_text()}</p>

<button on:click={() => alert(m.button_clicked())}>
  {m.click_me()}
</button>

<div class="content">
  {#if error}
    <span class="error">{m.error_message()}</span>
  {/if}
  
  <p>{m.footer_text()}</p>
</div>

<style>
  .error {
    color: red;
  }
</style>