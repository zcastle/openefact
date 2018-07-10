<?php
namespace Ob;

class Error {

  private $code;
  private $message;

  public function __construct($code = 0, $message = ""){
    $this->code = $code;
    $this->message = $message;
  }

  public function setCode($code){
    $this->code = $code;
  }

  public function getCode(){
    return $this->code;
  }

  public function setMessage($message){
    $this->message = $message;
  }

  public function getMessage(){
    return $this->message;
  }

}

?>
