# Apex-action-retrieves-all-MS-entries-from-MS
Invocable Apex action returning an Enhanced Messaging MessagingSession transcript. ConversationEntry is off-platform (not SOQL-queryable), so it delegates to the standard getConvTscpForRecord action via an internal REST callout. In: messagingSessionId. Out: conversationTranscript. Works in Flows and Template-Triggered Prompt Flows.
