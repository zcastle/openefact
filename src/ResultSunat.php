<?php
namespace Ob;

use Ob\Result;

class ResultSunat extends Result {

  private $data = "";
  //
  private $ticket = 0;
  private $code = 0;
  private $cdrZip;
  private $cdrResponse;

  public function setData($data){
    $this->data = $data;
  }

  public function getData(){
    return $this->data;
  }

  public function setTicket($ticket){
    $this->ticket = $ticket;
  }

  public function getTicket(){
    return $this->ticket;
  }

  public function setCode($code){
    $this->code = $code;
  }

  public function getCode(){
    return $this->code;
  }

  public function getCdrZip(){
    return $this->cdrZip;
  }

  public function setCdrZip($cdrZip){
    $this->cdrZip = $cdrZip;
  }

  public function getCdrResponse(){
    return $this->cdrResponse;
  }

  public function setCdrResponse($cdrResponse){
    $this->cdrResponse = $cdrResponse;
  }

}

?>
