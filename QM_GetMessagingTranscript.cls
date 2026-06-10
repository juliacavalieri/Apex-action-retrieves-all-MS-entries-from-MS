/**
 * QM_GetMessagingTranscript
 * ---------------------------------------------------------------------------
 * Action invocable (utilisable en Flow / Template-Triggered Prompt Flow) qui
 * prend une MessagingSession en input et retourne son transcript de conversation.
 *
 * Pourquoi cette classe ?
 *   Les ConversationEntry de l'Enhanced Messaging sont stockées OFF-PLATFORM :
 *   elles ne sont PAS requêtables en SOQL. Salesforce expose l'action standard
 *   "Get Conversation Transcript for Record" (getConvTscpForRecord) qui sait
 *   récupérer ce transcript, mais elle n'est pas appelable via
 *   Invocable.Action.createStandardAction (type non whitelisté en Apex) et
 *   n'accepte pas toujours une MessagingSession en input selon le contexte Flow.
 *
 *   Cette action délègue donc à l'action standard via un callout interne sur
 *   l'API REST "Invocable Actions" de l'org, en acceptant explicitement une
 *   MessagingSession en input.
 *
 * NB : nécessite que les callouts vers le domaine de l'org soient autorisés.
 * UserInfo.getSessionId() doit renvoyer une session valide (contexte synchrone).
 * ---------------------------------------------------------------------------
 */
public with sharing class QM_GetMessagingTranscript {

    private static final String API_VERSION = 'v62.0';

    public class Request {
        @InvocableVariable(label='Messaging Session ID'
            description='ID de la MessagingSession dont on veut le transcript'
            required=true)
        public Id messagingSessionId;
    }

    public class Response {
        @InvocableVariable(label='Conversation Transcript'
            description='Transcript de la conversation (un tour par ligne)')
        public String conversationTranscript;
    }

    @InvocableMethod(
        label='Get Messaging Transcript'
        description='Retourne le transcript d\'une MessagingSession (délègue à l\'action standard Get Conversation Transcript for Record).'
        category='Messaging')
    public static List<Response> getTranscripts(List<Request> requests) {
        List<Response> responses = new List<Response>();
        for (Request req : requests) {
            Response res = new Response();
            res.conversationTranscript = fetchTranscript(req.messagingSessionId);
            responses.add(res);
        }
        return responses;
    }

    /**
     * Appelle l'action standard getConvTscpForRecord via l'API Invocable Actions
     * et renvoie la valeur conversationTranscript.
     */
    private static String fetchTranscript(Id messagingSessionId) {
        if (messagingSessionId == null) {
            return '';
        }

        HttpRequest httpReq = new HttpRequest();
        httpReq.setEndpoint(
            URL.getOrgDomainUrl().toExternalForm()
            + '/services/data/' + API_VERSION
            + '/actions/standard/getConvTscpForRecord'
        );
        httpReq.setMethod('POST');
        httpReq.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
        httpReq.setHeader('Content-Type', 'application/json');
        httpReq.setBody(JSON.serialize(new Map<String, Object>{
            'inputs' => new List<Object>{
                new Map<String, Object>{ 'recordId' => messagingSessionId }
            }
        }));

        HttpResponse res = new Http().send(httpReq);

        if (res.getStatusCode() != 200) {
            throw new CalloutException(
                'getConvTscpForRecord a renvoyé HTTP ' + res.getStatusCode()
                + ' : ' + res.getBody()
            );
        }

        List<Object> results = (List<Object>) JSON.deserializeUntyped(res.getBody());
        if (results == null || results.isEmpty()) {
            return '';
        }

        Map<String, Object> first = (Map<String, Object>) results[0];
        if (first.get('isSuccess') == true) {
            Map<String, Object> outputs = (Map<String, Object>) first.get('outputValues');
            if (outputs != null) {
                Object transcript = outputs.get('conversationTranscript');
                return (transcript == null) ? '' : String.valueOf(transcript);
            }
        }
        return '';
    }
}
