<?php
namespace Ob;

use Ob\Error;

class Result {

  private $success;
  private $message;
  private $error = null;
  private $accion = "";

  public function __construct($success = false, $message = ""){
    $this->success = $success;
    $this->message = $message;
  }

  public function setSuccess($success){
    $this->success = $success;
  }

  public function isSuccess(){
    return $this->success;
  }

  public function setMessage($message){
    $this->message = $message;
  }

  public function getMessage(){
    return $this->message;
  }

  public function setError(Error $error){
    $this->error = $error;
  }

  public function getError(){
    return $this->error;
  }

  public function setAccion($accion){
    $this->accion = $accion;
  }

  public function getAccion(){
    return $this->eraccionror;
  }

}

?>
