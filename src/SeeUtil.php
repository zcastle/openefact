<?php
namespace Ob;

use Ob\Sign\Certificate\X509Certificate;
use Ob\Sign\Certificate\X509ContentType;

class SeeUtil {

  public function __construct(){}

    public function convert2Pem($pfx, $password){
      $certificate = new X509Certificate($pfx, $password);
      $pem = $certificate->export(X509ContentType::PEM);

      file_put_contents('certificate.pem', $pem);
    }

    public function convert2Pem($pfx, $password){
      $certificate = new X509Certificate($pfx, $password);
      $cer = $certificate->export(X509ContentType::CER);

      file_put_contents('certificate.cer', $cer);
    }

}

?>
