<?php

namespace Ob\Mail;

use Ob\Model\DocumentInterface;

class Notification {

    private $files;
    private $document;

    public function getFiles(){
      return $this->files;
    }

    public function setFiles($files){
        $this->files = $files;
    }

    public function getDocument(){
        return $this->document;
    }

    public function setDocument($document){
        $this->document = $document;
    }
}
