Rebol [
	title: "Rebol/WebSocket CI test"
]

print ["Running test on Rebol build:" mold to-block system/build]
if exists? %websocket.reb [
	;; make sure that we load a fresh extension
	try [system/modules/websocket: none]
	import %websocket.reb
]

ws-decode: :codecs/ws/decode
probe ws-decode codecs/ws/encode #(a: 1 b: ["a" "b"])

print-horizontal-line
print as-green "Launching the server..."
pid: call reduce [to-local-file system/options/boot  %server-test.r3]
wait 0:0:1


unless all [
	port? try/with [port: open ws://localhost:8081/echo] :print

	port/awake: func [event /local port extra parent spec temp] [
		port: event/port
		sys/log/debug 'WS ["== WS-event:" as-red event/type]

		switch event/type [
			read  [
				sys/log/debug 'WS ["== raw-data:" as-blue port/data]
				sys/log/debug 'WS ["== decoded: " as-green mold ws-decode port/data]
			]
		]
		true
	]

	port? wait port
	port? try/with [write port 'ping] :print
	port? try/with [write port "Hello"] :print
	port? wait port
	print "read.."
	port? try/with [read port] :print
	port? wait [port 10]
	port? try/with [write port 'close] :print
	port? wait [port 10]
][
	print as-purple "WebSocket test failed!"
]
wait 0.1
print-horizontal-line
print as-green "Stopping the server..."
access-os/set 'pid :pid
wait 0:0:1