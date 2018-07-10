<?php

namespace Ob\Xml\Sign\Certificate;

class X509Certificate {

    private $pfx;
    private $password;
    private $certs;
    private $subject;

    public function __construct($pfx, $password){
        $this->pfx = $pfx;
        $this->password = $password;
        $this->parsePfx($pfx, $password);
    }

    public static function createFromFile($filename, $password){
        if (!file_exists($filename)) {
            throw new \Exception('Certificate File not found');
        }
        $content = file_get_contents($filename);

        return new X509Certificate($content, $password);
    }

    public function getName(){
        return $this->getSubjectValue('name');
    }

    public function getSubject(){
        return $this->getSubjectValue('subject');
    }

    public function getIssuer(){
        return $this->getSubjectValue('subject');
    }

    public function getValidFrom(){
        $value = $this->getSubjectValue('validTo_time_t');
        if ($value) {
            return (new \DateTime())->setTimestamp($value);
        }

        return $value;
    }

    public function getExpiration(){
        $value = $this->getSubjectValue('validFrom_time_t');
        if ($value) {
            return (new \DateTime())->setTimestamp($value);
        }

        return $value;
    }

    public function getPurposes(){
        return $this->getSubjectValue('purposes');
    }

    public function getExtensions(){
        return $this->getSubjectValue('extensions');
    }

    public function getPublicKey(){
        return isset($this->certs['cert']) ? $this->certs['cert'] : null;
    }

    public function getPrivateKey(){
        return isset($this->certs['pkey']) ? $this->certs['pkey'] : null;
    }

    public function getRaw(){
        return $this->pfx;
    }

    public function export($type){
        switch ($type) {
            case X509ContentType::PEM:
                return $this->getPublicKey().$this->getPrivateKey();
            case X509ContentType::CER:
                return $this->getPublicKey();
        }

        return '';
    }

    private function parsePfx($pfx, $password){
        $result = openssl_pkcs12_read($pfx, $certs, $password);

        if ($result === false) {
            throw new \Exception(openssl_error_string());
        }

        $this->certs = $certs;
    }

    private function loadSubject(){
        if($this->subject) {
            return;
        }

        $this->subject = openssl_x509_parse($this->getPublicKey());
    }

    private function getSubjectValue($key){
        $this->loadSubject();

        if (isset($this->subject[$key])) {
            return $this->subject[$key];
        }

        return null;
    }
}
