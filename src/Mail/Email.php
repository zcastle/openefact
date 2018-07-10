<?php

namespace Ob\Mail;

class Email {

	private $address;
	private $name;

  public function __construct($address, $name) {
  	$this->address = $address;
  	$this->name = $name;
  }

  public function setAddress($address){
  	$this->address = $address;
  }

  public function getAddress(){
  	return $this->address;
  }

  public function setName($name){
  	$this->name = $name;
  }

  public function getName(){
  	return $this->name;
  }
}
