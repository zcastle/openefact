<?php

namespace Ob;

use Ob\Xml\Sign\Sunat\SignedXml;
use Ob\Pdf\PdfBuilder;

use Ob\Model\DocumentInterface;

abstract class SeeBase {

  protected $isProduccion = false;
  protected $certificado = null;
  protected $usuarioSol = null;
  protected $claveSol = null;
  //
  protected $document = null;
  protected $xmlContent = "";
  //
  protected $rutaTrabajo = "";
  //
  const RUTA_XML = "/xml/";
  const RUTA_CDR = "/cdr/";
  const RUTA_PDF = "/pdf/";
  const RUTA_TMP = "/tmp/";
  protected $ruta = array();
  //

  public function setCertificado($certificado){
    $this->certificado = $certificado;
  }

  public function setUsuarioSunat($usuarioSol, $claveSol){
    $this->usuarioSol = $usuarioSol;
    $this->claveSol = $claveSol;
  }

  public function setProduccion($isProduccion){
    $this->isProduccion = $isProduccion;
  }

  public function getXmlContent(){
    return $this->xmlContent;
  }

  protected function prepararRutaTrabajo(){
    if(empty($this->rutaTrabajo)){
      return new Result(false, "No ha especificado la ruta de trabajo, no se puede continuar");
    }

    $isNew = false;
    if(!file_exists($this->rutaTrabajo)){
      mkdir($this->rutaTrabajo, 0777, true);
      $isNew = true;
    }

    if(is_dir($this->rutaTrabajo)){
      if($isNew){
        mkdir($this->rutaTrabajo . self::RUTA_XML);
        mkdir($this->rutaTrabajo . self::RUTA_CDR);
        mkdir($this->rutaTrabajo . self::RUTA_PDF);
        mkdir($this->rutaTrabajo . self::RUTA_TMP);
      }else{
        if(!file_exists($this->rutaTrabajo . self::RUTA_XML)){
          mkdir($this->rutaTrabajo . self::RUTA_XML);
        }
        if(!file_exists($this->rutaTrabajo . self::RUTA_CDR)){
          mkdir($this->rutaTrabajo . self::RUTA_CDR);
        }
        if(!file_exists($this->rutaTrabajo . self::RUTA_PDF)){
          mkdir($this->rutaTrabajo . self::RUTA_PDF);
        }
        if(!file_exists($this->rutaTrabajo . self::RUTA_TMP)){
          mkdir($this->rutaTrabajo . self::RUTA_TMP);
        }
      }
      $this->ruta = array(
        self::RUTA_XML => $this->rutaTrabajo . self::RUTA_XML,
        self::RUTA_CDR => $this->rutaTrabajo . self::RUTA_CDR,
        self::RUTA_PDF => $this->rutaTrabajo . self::RUTA_PDF,
        self::RUTA_TMP => $this->rutaTrabajo . self::RUTA_TMP
      );
      return new Result(true);
    }else{
      return new Result(false, "La ruta no es un directorio, no se puede continuar");
    }
  }

  public function setRutaTrabajo($rutaTrabajo){
    $this->rutaTrabajo = $rutaTrabajo;
  }

  protected function guardarXml(){
    $file = $this->ruta[self::RUTA_XML] . $this->document->getName() . '.xml';
    file_put_contents($file, $this->xmlContent);
  }

  protected function firmar($xml){
    $signer = new SignedXml();
    $signer->setCertificate($this->certificado);
    return $signer->signXml($xml);
  }

  protected function guardarTmp($content){
    //var_dump($content);
    $file = $this->ruta[self::RUTA_TMP] . 'tmp-' . $this->document->getName() . '.xml';
    file_put_contents($file, $content);
  }

  protected function guardarPdf(DocumentInterface $document, $parameters = []){
    $builder = new PdfBuilder();
    $pdf = $builder->build($document, $parameters);

    $file = $this->ruta[self::RUTA_PDF] . $document->getName() . '.pdf';
    file_put_contents($file, $pdf);

  }

}
