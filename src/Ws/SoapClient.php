<?php
namespace Ob\Ws;

use Ob\Ws\WSSESecurityHeader;

class SoapClient {

    private $client;

    public function __construct($wsdl = '', $parameters = []){
        if (empty($wsdl)) {
            $wsdl = __DIR__.'/wsdl/billService.wsdl';
        }
        $this->client = new \SoapClient($wsdl, $parameters);
    }

    public function setCredentials($user, $password){
        $this->client->__setSoapHeaders(new WSSESecurityHeader($user, $password));
    }

    public function setService($url){
        $this->client->__setLocation($url);
    }

    public function call($function, $arguments){
        return $this->client->__soapCall($function, $arguments);
    }
}
