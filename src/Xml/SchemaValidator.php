<?php

namespace Ob\Xml;

class SchemaValidator {

    const VERSION20 = "2.0";
    const VERSION21 = "2.1";

    private $error;
    private $version = '2.1';

    public function setVersion($version){
        $this->version = $version;
    }

    public function getMessage(){
        return $this->error;
    }

    public function validate($value){
        if ($value instanceof \DOMDocument) {
            $doc = $value;
        } else {
            $doc = new \DOMDocument();
            @$doc->loadXML($value);
        }
        $filename = $this->getFilename($doc->documentElement->nodeName);
        if (!file_exists($filename)) {
            $this->error = 'Schema file not found';
            return false;
        }
        $state = libxml_use_internal_errors(true);
        $result = $doc->schemaValidate($filename);
        $this->error = $this->getErrors();
        libxml_use_internal_errors($state);
        return $result;
    }

    private function getErrors(){
        $message = '';
        $errors = libxml_get_errors();
        foreach ($errors as $error) {
            $message .= $this->getError($error).PHP_EOL;
        }
        libxml_clear_errors();
        return $message;
    }

    public function getError($error){
        return $error->code.': '.trim($error->message).' en la linea '.$error->line;
    }

    private function getFilename($rootName){
        $name = $this->getName($rootName);
        return __DIR__ . '/xsd/' . $this->version . '/maindoc/' . $name . '.xsd';
    }

    private function getName($rootName){
        if ($this->version == self::VERSION20) {
            return $rootName == 'DespatchAdvice' ? 'UBL-DespatchAdvice-2.0' : 'UBLPE-' . $rootName . '-1.0';
        }
        return 'UBL-' . $rootName . '-2.1';
    }

}
?>
