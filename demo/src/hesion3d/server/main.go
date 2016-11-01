package main

import (
	"flag"
	"fmt"
	"io"
	"net/http"
)

func main() {
	var serverIP string
	flag.StringVar(&serverIP, "server_ip", "127.0.0.1", "Ip address of the server.")
	var port int
	flag.IntVar(&port, "port", 80, "Port to listen.")
	flag.Parse()
	http.HandleFunc("/hello", func(w http.ResponseWriter, req *http.Request) {
		io.WriteString(w, "Hello slimage\n")
	})
	http.ListenAndServe(fmt.Sprintf("%s:%d", serverIP, port), nil)
}
