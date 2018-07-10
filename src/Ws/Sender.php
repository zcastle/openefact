<?php

namespace Ob\Ws;

use Ob\ResultSunat;
use Ob\Error;

use Ob\Ws\SenderBase;

class Sender extends SenderBase {

  private $file;
  private $content;

  public function setFileName($fileName){
    $this->fileName = $fileName;
  }

  public function setContent($content){
    $this->content = $content;
  }

  public function bill() {
    if (is_null($this->client)) {
        return new ResultSunat(false, "No se ha cargado el cliente SOAP");
    }
    $result = new ResultSunat();
    $result->setAccion("sendBill");

    try {
        $zipContent = $this->compress($this->fileName . '.xml', $this->content);
        $params = ['fileName' => $this->fileName . '.zip', 'contentFile' => $zipContent];

        $response = $this->client->call('sendBill', ['parameters' => $params]);
        if(is_object($response)){
          if(isset($response->applicationResponse)){
            //$result->setData($response->applicationResponse);
            $result->setData($this->decompress($response->applicationResponse));
          }
        }
        $result->setSuccess(true);
    } catch (\SoapFault $e) {
        $result->setError($this->getErrorFromFault($e));
    }

    return $result;
  }

  public function summary() {
    if (is_null($this->client)) {
        return new ResultSunat(false, "No se ha cargado el cliente SOAP");
    }
    $result = new ResultSunat();
    $result->setAccion("sendSummary");

    try {
        $zipContent = $this->compress($this->fileName . '.xml', $this->content);
        $params = ['fileName' => $this->fileName . '.zip', 'contentFile' => $zipContent];

        $response = $this->client->call('sendSummary', ['parameters' => $params]);
        $result->setTicket($response->ticket);
        $result->setSuccess(true);
    } catch (\SoapFault $e) {
        $result->setError($this->getErrorFromFault($e));
    }

    return $result;
  }

  public function getStatus($ticket){
    if (is_null($this->client)) {
        return new ResultSunat(false, "No se ha cargado el cliente SOAP");
    }
    $result = new ResultSunat();
    $result->setAccion("getStatus");

    try {
        $params = ['ticket' => $ticket];

        $response = $this->client->call('getStatus', ['parameters' => $params]);
        $status = $response->status; //StatusResponse

        $code = $status->statusCode;
        $result->setCode($code);
        $result->setSuccess(true);

        if ($code == 0 || $code == 99) {
          $cdrZip = $status->content;
          $result->setCdrZip($cdrZip);
          $result->setCdrResponse($this->decompress($cdrZip));
        }
    } catch (\SoapFault $e) {
        $result->setError($this->getErrorFromFault($e));
    }

    return $result;
  }

  public function getCdrStatus($ruc, $tipo, $serie, $numero){
    if (is_null($this->client)) {
        return new ResultSunat(false, "No se ha cargado el cliente SOAP");
    }
    $result = new ResultSunat();
    $result->setAccion("getCdrStatus");

    try {
      $params = ['rucComprobante' => $ruc, 'tipoComprobante' => $tipo, 'serieComprobante' => $serie, 'numeroComprobante' => $numero];
      $response = $this->client->call('getStatusCdr', ['parameters' => $params]);
      $statusCdr = $response->statusCdr;

      $result->setCode($statusCdr->statusCode);
      $result->setMessage($statusCdr->statusMessage);
      $result->setCdrZip($statusCdr->content);
      $result->setSuccess(true);

      //if ($statusCdr->content) {
      /*if ($statusCdr->statusCode == "0004") {
        $result->setCdrZip($statusCdr->content);
        $result->setCdrResponse($this->extractResponse($statusCdr->content));
      }*/
    } catch (\SoapFault $e) {
      $result->setError($this->getErrorFromFault($e));
    }

    return $result;
  }
}
