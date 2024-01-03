Rebol [
	Title:  "Simple server for testing WebSocket connection"
	File:   %server-test.r3
	Date:    02-Jul-2020
	Author: "Oldes"
	Version: 0.6.0
]

import httpd

system/options/log/httpd: 4 ; for verbose output
system/options/quiet: false

http-server/config/actor 8081 [
	;- Main server configuration                                                                 
	;keep-alive: [30 100] ;= [timeout max-requests] or FALSE to turn it off
] [
	;- Server's actor functions                                                                  
	On-Header: func [ctx [object!] /local path key][
		path: ctx/inp/target/file
		;- serve valid content...
		switch path [
			%/echo [
				;@@ Consider checking the ctx/out/header/Origin value
				;@@ before accepting websocket connection upgrade!   
				system/schemes/httpd/actor/WS-handshake ctx
			]
		]
	]
	;-- WebSocket related actions                                                                
	On-Read-Websocket: func[ctx final? opcode][
		sys/log/info 'HTTPD ["WS opcode:" opcode "final frame:" final?]
		either opcode = 1 [
			ctx/out/content: to string! ctx/inp/content
			sys/log/info 'HTTPD mold ctx/out/content
		][
			? ctx/inp/content
		]
	]
	On-Close-Websocket: func[ctx code /local reason][
		reason: any [
			select [
				1000 "the purpose for which the connection was established has been fulfilled."
				1001 "a client navigated away from a page."
				1002 "a protocol error."
				1003 "it has received a type of data it cannot accept."
				1007 "it has received data within a message that was not consistent with the type of the message."
				1008 "it has received a message that violates its policy."
				1009 "it has received a message that is too big for it to process."
				1010 "it has expected the server to negotiate one or more extension, but the server didn't return them in the response message of the WebSocket handshake."
				1011 "it encountered an unexpected condition that prevented it from fulfilling the request."
			] code
			ajoin ["an unknown reason (" code ")"]
		]
		sys/log/info 'HTTPD ["WS connection is closing because" reason]
		unless empty? reason: ctx/inp/content [
			;; optional client's reason
			sys/log/info 'HTTPD ["Client's reason:" as-red to string! reason]
		]
	]
]

