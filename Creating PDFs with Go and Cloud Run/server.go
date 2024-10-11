package main
import (
      "fmt"
      "io/ioutil"
      "log"
      "net/http"
      "os"
      "os/exec"
      "regexp"
      "strings"
)
func main() {
      http.HandleFunc("/", process)
      port := os.Getenv("PORT")
      if port == "" {
              port = "8080"
              log.Printf("Defaulting to port %s", port)
      }
      log.Printf("Listening on port %s", port)
      err := http.ListenAndServe(fmt.Sprintf(":%s", port), nil)
      log.Fatal(err)
}
func process(w http.ResponseWriter, r *http.Request) {
      log.Println("Serving request")
      if r.Method == "GET" {
              fmt.Fprintln(w, "Ready to process POST requests from Cloud Storage trigger")
              return
      }
      //
      // Read request body containing Cloud Storage object metadata
      //
      gcsInputFile, err1 := readBody(r)
      if err1 != nil {
              log.Printf("Error reading POST data: %v", err1)
              w.WriteHeader(http.StatusBadRequest)
              fmt.Fprintf(w, "Problem with POST data: %v \n", err1)
              return
      }
      //
      // Working directory (concurrency-safe)
      //
      localDir, errDir := ioutil.TempDir("", "")
      if errDir != nil {
              log.Printf("Error creating local temp dir: %v", errDir)
              w.WriteHeader(http.StatusInternalServerError)
              fmt.Fprintf(w, "Could not create a temp directory on server. \n")
              return
      }
      defer os.RemoveAll(localDir)
      //
      // Download input file from Cloud Storage
      //
      localInputFile, err2 := download(gcsInputFile, localDir)
      if err2 != nil {
              log.Printf("Error downloading Cloud Storage file [%s] from bucket [%s]: %v",
gcsInputFile.Name, gcsInputFile.Bucket, err2)
              w.WriteHeader(http.StatusInternalServerError)
              fmt.Fprintf(w, "Error downloading Cloud Storage file [%s] from bucket [%s]",
gcsInputFile.Name, gcsInputFile.Bucket)
              return
      }
      //
      // Use LibreOffice to convert local input file to local PDF file.
      //
      localPDFFilePath, err3 := convertToPDF(localInputFile.Name(), localDir)
      if err3 != nil {
              log.Printf("Error converting to PDF: %v", err3)
              w.WriteHeader(http.StatusInternalServerError)
              fmt.Fprintf(w, "Error converting to PDF.")
              return
      }
      //
      // Upload the freshly generated PDF to Cloud Storage
      //
      targetBucket := os.Getenv("PDF_BUCKET")
      err4 := upload(localPDFFilePath, targetBucket)
      if err4 != nil {
              log.Printf("Error uploading PDF file to bucket [%s]: %v", targetBucket, err4)
              w.WriteHeader(http.StatusInternalServerError)
              fmt.Fprintf(w, "Error downloading Cloud Storage file [%s] from bucket [%s]",
gcsInputFile.Name, gcsInputFile.Bucket)
              return
      }
      //
      // Delete the original input file from Cloud Storage.
      //
      err5 := deleteGCSFile(gcsInputFile.Bucket, gcsInputFile.Name)
      if err5 != nil {
              log.Printf("Error deleting file [%s] from bucket [%s]: %v", gcsInputFile.Name,
gcsInputFile.Bucket, err5)
         // This is not a blocking error.
         // The PDF was successfully generated and uploaded.
      }
      log.Println("Successfully produced PDF")
      fmt.Fprintln(w, "Successfully produced PDF")
}
func convertToPDF(localFilePath string, localDir string) (resultFilePath string, err error) {
      log.Printf("Converting [%s] to PDF", localFilePath)
      cmd := exec.Command("libreoffice", "--headless", "--convert-to", "pdf",
              "--outdir", localDir,
              localFilePath)
      cmd.Stdout, cmd.Stderr = os.Stdout, os.Stderr
      log.Println(cmd)
      err = cmd.Run()
      if err != nil {
              return "", err
      }
      pdfFilePath := regexp.MustCompile(`\.\w+$`).ReplaceAllString(localFilePath, ".pdf")
      if !strings.HasSuffix(pdfFilePath, ".pdf") {
              pdfFilePath += ".pdf"
      }
      log.Printf("Converted %s to %s", localFilePath, pdfFilePath)
      return pdfFilePath, nil
}