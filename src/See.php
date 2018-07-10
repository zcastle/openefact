<?php
namespace Ob;

use Ob\SunatEndpoints;
use Ob\Result;
use Ob\SeeBase;
use Ob\Xml\XmlBuilder;
use Ob\Xml\SchemaValidator;
use Ob\Model\DocumentInterface;
use Ob\Model\Sale\Invoice;
use Ob\Model\Sale\Note;
use Ob\Model\Voided\Voided;

use Ob\Ws\SoapClient;
use Ob\Ws\Sender;

class See extends SeeBase {

  public function __construct(){
    
  }

  public function enviar(DocumentInterface $document) {
    $result = $this->prepararRutaTrabajo();
    if(!$result->isSuccess()){
      return $result;
    }

    $this->document = $document;
    // TEMPLATE
    $builder = new XmlBuilder();
    $xml = $builder->build($document);
    // FIRMAR
    if(is_null($this->certificado)){
      return new Result(false, "No se ha establecido el certificado, use: setCertificado()");
    }else{
      $xml = $this->firmar($xml);
      $this->xmlContent = $xml;
    }
    // VALIDAR SCHEMA UBL 2.1
    if(in_array(get_class($document), [Invoice::class, Note::class])){
      $result = $this->validarSchema($xml);
      $result->setAccion("validarSchema");
      if(!$result->isSuccess()){
        return $result;
      }
    }

    $result = $this->enviarSunat($document, $xml);
    $this->guardarXml();
    if($result->isSuccess()){
      $this->guardarTmp($result->getData());

    }else{

    }
    return $result;
  }

  public function guardarPdf(DocumentInterface $document){
    $this->guardarPdf($document);
  }

  private function enviarSunat($document, $xml){
    $client = new SoapClient();
    if($this->isProduccion){
      $client->setCredentials($this->usuarioSol, $this->claveSol);
    }else{
      $client->setCredentials("00000000000MODDATOS", "moddatos");
    }

    $sender = new Sender($client);
    $sender->setFileName($document->getName());
    $sender->setContent($xml);
    if(in_array(get_class($document), [Invoice::class, Note::class])){
      return $sender->bill();
    }else{
      return $sender->summary();
    }
  }

  private function validarSchema($xml){
    $validator = new SchemaValidator();

    if ($validator->validate($xml)) {
      return new Result(true);
    } else {
      return new Result(false, $validator->getMessage());
    }
  }

  /*private function validarExp($xmlContent){
    $xml = new \DOMDocument();
    $xml->loadXML($xmlContent);

    $xsl = new \DOMDocument();
    //$xsl->load(__DIR__ . '/xsd/validacion/ValidaExprRegFactura.xsl');
    $xsl->load(__DIR__ . '/xsd/validacion/ValidaExprRegFactura_v1.1.0.xsl');

    $proc = new \XSLTProcessor();
    $proc->registerPHPFunctions();
    $proc->importStyleSheet($xsl);

    return new Result(false, $proc->transformToXML($xml));
  }*/

}

?>
