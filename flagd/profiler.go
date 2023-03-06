//go:build profile

package main

import (
	"net/http"
	_ "net/http/pprof"
)

/*
Enable pprof profiler for flagd. Build controlled by the build tag "profile". bump 2 3 4 help PLEASE PLEEEEASE :) :() ; :) :) this cmonS ye :) :0
*/
func init() {
	// Go routine to server PProf
	go func() {
		server := http.Server{Addr: ":6060", Handler: nil}
		server.ListenAndServe()
	}()
}
