/**
 * Ruby-Mongrel2 Websocket Demo
 * $Id$
 *
 * Author:
 * - Michael Granger <ged@FaerieMUD.org>
 *
 */

var ws = null;

function writeToLog( msg ) {
	$('#log').append( "<li>" + msg + "</li>\n");
}

function writeErrorLog( msg ) {
	$('#log').append( "<li class=\"error\">" + msg + "</li>\n");
}

function onOpen( e ) {
	console.debug( "WebSocket open." );
	writeToLog( "Connected." );

	$('form').addClass( 'socket-connected' );
	$('#connect').unbind( 'click' ).attr( 'disabled', 'disabled' );
	$('#disconnect').click( doDisconnect ).removeAttr('disabled');
	$('#echo-body').removeAttr('disabled');
	$('#send').click( doSend ).removeAttr('disabled');
}

function onClose( e ) {
	console.debug( "WebSocket closed." );
	writeToLog( "Disconnected." );

	$('form').removeClass( 'socket-connected' );
	$('#connect').click( doConnect ).removeAttr('disabled');
	$('#disconnect,#echo-body,#send').unbind( 'click' ).attr( 'disabled', 'disabled' );
}

function onMessage( e ) {
	console.debug( "WebSocket message: %s.", e.data );
	writeToLog( "Response: <code>" + e.data + "</code>" );
}

function onError( e ) {
	console.error( "WebSocket error: %o", e );
	writeErrorLog( "WebSocket Error: " + e.data )
}

function doConnect( e ) {
	console.debug( "Connecting WebSocket." );
	writeToLog( "Connecting." );
	var ws_uri = $('meta[name=socket-uri]').attr( 'content' );
	ws_uri = 'ws://' + window.location.host + ws_uri;

	console.debug( "  Socket URI is: %s", ws_uri );

	ws = new WebSocket( ws_uri, 'echo' );

	ws.onopen    = onOpen;
	ws.onclose   = onClose;
	ws.onmessage = onMessage;
	ws.onerror   = onError;
}

function doDisconnect( e ) {
	console.debug( "Closing WebSocket." );
	writeToLog( "Disconnecting." );
	ws.close();
}

function doSend( e ) {
	e.preventDefault();
	e.stopPropagation();

	var data = $('#echo-body').val();
	$('#echo-body').val('');

	console.debug( "Sending message: %s.", data );
	writeToLog( "Sent: <code>" + data + "</code>." );

	ws.send( data );
}

$(document).ready( function() {
	log = $('#log');

	if (window.MozWebSocket) {
        console.debug( 'Using MozWebSocket' );
        window.WebSocket = window.MozWebSocket;
    } else if (!window.WebSocket) {
        console.error( "This browser doesn't support WebSocket. ;_;" );
        return;
    }

	// Check for recent implementations of the WebSocket API
	if ( typeof WebSocket.CONNECTING == 'undefined' ) {
		console.error( "WebSocket implementation is too old." );
		writeErrorLog( "WebSocket implementation too old. Sorry, you'll need a newer browser." );
		return;
	}

	$('#connect').click( doConnect );
	$('#disconnect,#echo-body,#send').attr( 'disabled', 'disabled' );

	writeToLog( "Ready." );
});

