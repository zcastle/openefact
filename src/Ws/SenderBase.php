<?php

namespace Ob\Ws;

use Ob\Error;
use Ob\Ws\ErrorCode\XmlErrorCodeProvider;

use \ZipArchive;

class SenderBase {

  protected $client;
  private $codeProvider;

  public function __construct($client = null){
      $this->client = $client;
      $this->codeProvider = new XmlErrorCodeProvider();
  }

  protected function compress($filename, $xml){
    $tmpPath = sys_get_temp_dir() . "/" . time();
    $tmpName = $tmpPath . "/tmp_zipfile.zip";
    mkdir($tmpPath);

    $zip = new ZipArchive();
    $zip->open($tmpName, ZipArchive::CREATE);
    $zip->addFromString($filename, $xml);
    $zip->close();

    $zipContent = file_get_contents($tmpName);

    unlink($tmpName);
    rmdir($tmpPath);

    return $zipContent;
  }

  public function decompress($zipContent){
    $xmlContent = "";

    $tmpPath = sys_get_temp_dir() . "/" . time();
    $tmpName = $tmpPath . "/tmp_zipfile.zip";
    mkdir($tmpPath);

    file_put_contents($tmpName, $zipContent);

    $zip = zip_open($tmpName);
    if($zip){
      while ($zip_entry = zip_read($zip)){
        if (strtolower($this->getFileExtension(zip_entry_name($zip_entry))) == 'xml'){
          if(zip_entry_open($zip, $zip_entry)){
            $xmlContent = zip_entry_read($zip_entry, zip_entry_filesize($zip_entry));
            zip_entry_close($zip_entry);
            break;
          }
        }
      }
    }

    unlink($tmpName);
    rmdir($tmpPath);

    return $xmlContent;
  }

  private function getFileExtension($filename){
      $lastDotPos = strrpos($filename, '.');
      if (!$lastDotPos) {
          return '';
      }

      return substr($filename, $lastDotPos + 1);
  }

  protected function getErrorFromFault(\SoapFault $fault) {
    $err = new Error();
    $err->setCode($fault->faultcode);
    $code = preg_replace('/[^0-9]+/', '', $err->getCode());
    $msg = '';

    if (empty($code)) {
        $code = preg_replace('/[^0-9]+/', '', $fault->faultstring);
    }

    if ($code) {
        $msg = $this->codeProvider->getValue($code);
        $err->setCode($code);
    }

    if (empty($msg)) {
        $msg = isset($fault->detail) ? $fault->detail->message : $fault->faultstring;
    }
    $err->setMessage($msg);

    return $err;
  }
}
