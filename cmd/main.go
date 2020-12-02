package main

import (
	"crypto/tls"
	"crypto/x509"
	"io"
	"io/ioutil"
	"log"
	"net/http"
	"sync"
)

func main() {
	http.HandleFunc("/hello", func(writer http.ResponseWriter, request *http.Request) {
		_, err := io.WriteString(writer, "hello world\n")
		if err != nil {
			http.Error(writer, "failed to write response greeting", http.StatusInternalServerError)
		}
	})

	var wg sync.WaitGroup

	// start HTTP server
	wg.Add(1)
	go func() {
		defer wg.Done()
		err := http.ListenAndServe(":8080", nil)
		if err != nil {
			log.Println(err)
		}
	}()

	// start HTTPS server
	wg.Add(1)
	go func() {
		defer wg.Done()
		cp, err := x509.SystemCertPool()
		if err != nil {
			log.Println("failed to get system certificate pool")
		}
		ca, err := ioutil.ReadFile("/etc/tls/ca.crt")
		if err != nil {
			log.Println("failed to read CA certificate")
		}
		cp.AppendCertsFromPEM(ca)
		err = (&http.Server{
			Addr: ":8443",
			TLSConfig: &tls.Config{
				ClientAuth: tls.RequireAndVerifyClientCert,
				ClientCAs:  cp,
			},
		}).ListenAndServeTLS("/etc/tls/tls.crt", "/etc/tls/tls.key")
		if err != nil {
			log.Println(err)
		}
	}()

	wg.Wait()
	log.Fatalln("both HTTP and HTTPS server are down")
}
