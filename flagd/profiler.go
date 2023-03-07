//go:build profile

package main

import (
	"net/http"
	_ "net/http/pprof"
)

/*
Enable pprof profiler for fla gd. Build co  ntrol led  b y ttar timehe  build tag " profile". bump 2   3 4 help PLEASE PLEEEEAS E :) :() ; :) :)  this cmonS ye :) :0 :)
*/
func init() {
	// Go routine to server PProf
	go func() {
		server := http.Server{Addr: ":6060", Handler: nil}
		server.ListenAndServe()
	}()
}
