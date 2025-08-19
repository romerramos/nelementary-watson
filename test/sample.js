// Sample JavaScript file for testing
import * as m from '$lib/paraglide/messages';

// Simple translation calls
const title = m.hello_world();
const greeting = m.welcome_message();
const error = m.error_occurred();

// With parameters
const paramMessage = m.user_greeting({ name: "John" });
const count = m.item_count({ count: 5 });

// Inline usage
console.log(m.debug_message());
element.textContent = m.page_title();

// Multiple on same line
const msg1 = m.first_message(), msg2 = m.second_message();

// Nested in object
const config = {
  title: m.app_title(),
  description: m.app_description()
};

export { title, greeting };