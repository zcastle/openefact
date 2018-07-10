<?php

namespace Ob\Ws\ErrorCode;

class XmlErrorCodeProvider {

  private $xmlErrorFile;

  public function __construct(){
    $this->xmlErrorFile = __DIR__ . '/ErrorCode.xml';
  }

  public function getAll(){
    $xpath = $this->getXpath();
    $nodes = $xpath->query('/errors/error');

    $items = [];
    foreach ($nodes as $node) {
      $key = $node->getAttribute('code');
      $items[$key] = $node->nodeValue;
    }

    return $items;
  }

  public function getValue($code){
    $xpath = $this->getXpath();
    $nodes = $xpath->query("/errors/error[@code='$code']");

    if ($nodes->length !== 1) {
      return '';
    }

    return $nodes[0]->nodeValue;
  }

  private function getXpath(){
    $doc = new \DOMDocument();
    $doc->load($this->xmlErrorFile);
    $xpath = new \DOMXPath($doc);

    return $xpath;
  }
}
