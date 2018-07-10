<?php

use PHPUnit\Framework\TestCase;

use Ob\Model\Company\Company;
use Ob\Model\Company\Address;
use Ob\Model\Client\Client;
use Ob\Model\Sale\Document;
use Ob\Model\Sale\Invoice;
use Ob\Model\Sale\Detraction;
use Ob\Model\Sale\SaleDetail;
use Ob\Model\Sale\Legend;
use Ob\Model\Sale\Note;
use Ob\Model\Voided\Voided;
use Ob\Model\Voided\VoidedDetail;

use Ob\See;
use Ob\SeeUtil;

final class FacturaTest extends TestCase {

    private function getCia(){
      $direccion = new Address();
      $direccion->setUbigueo('150136')
          ->setDepartamento('LIMA')
          ->setProvincia('LIMA')
          ->setDistrito('SAN MIGUEL')
          ->setUrbanizacion('NONE')
          ->setDireccion('CAL.ARCA PARRO NRO. 279 URB. PANDO (PISO 2/ALT CDRA 1 Y 2 AV DINTHILAC)');

      $cia = new Company();
      $cia->setRuc('20514469335')
          ->setRazonSocial('CORPORACION WINWARE S.A.C.')
          ->setNombreComercial('WINCORP')
          ->setAddress($direccion);

      return $cia;
    }

    public function test01(){
      echo "\n";

      $client = new Client();
  		$client->setTipoDoc("6"); //update
  		$client->setNumDoc("00000000000");
  		$client->setRznSocial("CLIENTE SA");
  		$client->setAddress("DIRECCION CLIENTE SA");

      $invoice = new Invoice();
      $invoice->setCompany($this->getCia());
      $invoice->setFechaEmision(new DateTime());
      $invoice->setTipoDoc("01"); // 01 factura
  		$invoice->setSerie("F001");
  		$invoice->setCorrelativo("1");
  		$invoice->setTipoMoneda("PEN");
      $invoice->setClient($client);
      $esGratis = false;
      if($esGratis){ // GRATUITO
  			$invoice->setMtoOperGravadas(0.00);
  			$invoice->setMtoOperExoneradas(0.00);
  			$invoice->setMtoOperInafectas(0.00);
  			$invoice->setMtoIGV(0.00);
  			$invoice->setMtoImpVenta(0.00);
  			$invoice->setMtoOperGratuitas(1000.00);
  		}else{
        $invoice->setMtoOperGravadas(100.00);
    		$invoice->setMtoOperExoneradas(0.00);
    		$invoice->setMtoOperInafectas(0.00);
    		$invoice->setMtoIGV(18.00);
    		$invoice->setMtoImpVenta(118.00);
      }
          //
      $item = new SaleDetail();
  		$item->setCodProducto('P001');
  		$item->setUnidad("ZZ"); // Unidad servicio
  		$item->setCantidad(2);
  		$item->setDescripcion("Producto de prueba 01");
      if($esGratis){
        $item->setIgv(0);
  			$item->setTipAfeIgv(12); //DONACION
      }else{
        $item->setIgv(18);
    		$item->setTipAfeIgv(10);
      }
      if($esGratis){
        $item->setMtoValorUnitario(500.00);
				$item->setMtoValorVenta(1000.00);
				$item->setMtoPrecioUnitario(0.00);
				$item->setMtoValorGratuito(1000.00);
			}else{
        $item->setMtoValorUnitario(20.00);
        $item->setMtoValorVenta(40.00);
    		$item->setMtoPrecioUnitario(23.60);
      }
      $invoice->setDetails([$item]);
      //
      $legend1 = new Legend();
  		$legend1->setCode('1000');
  		$legend1->setValue("Monto en letras");
      $legend2 = new Legend();
  		$legend2->setCode('3000');
  		$legend2->setValue("0000000000"); // update: clave primaria de la table
      if($esGratis){
  			$legend3 = new Legend();
  			$legend3->setCode('1002');
  			//$legend->setValue('TRANSFERENCIA GRATUITA DE UN BIEN Y/O SERVICIO PRESTADO GRATUITAMENTE');
  			$legend3->setValue('TRANSFERENCIA A TITULO GRATUITO');
  		}
      $invoice->setLegends([$legend1]);

      $detraccion = new Detraction();
      $detraccion->setMount(10.00);
      $detraccion->setPercent(10.00);
      //$detraccion->setValueRef(0);
      $detraccion->setCode("019");
      $invoice->setDetraccion($detraccion);

      $see = new See();
      $see->setCertificado(file_get_contents(__DIR__ . '/certificate.pem'));
      $see->setRutaTrabajo("/var/www/html/see_archivos_new");
      $result = $see->enviar($invoice);
      //
      print_r($result);
      //file_put_contents(__DIR__ . '/' . $invoice->getName() . ".xml", $see->getXmlContent());

      //$util = new SeeUtil();
      //$util->convert2Pem(file_get_contents(__DIR__ . '/ww.pfx'), "q7Cc7cxX3nEheqkF");
    }

    /*public function test02(){
      echo "\n";

      $client = new Client();
  		$client->setTipoDoc("6"); //update
  		$client->setNumDoc("00000000000");
  		$client->setRznSocial("CLIENTE SA");
  		$client->setAddress("DIRECCION CLIENTE SA");

  		$note = new Note();
      $note->setCompany($this->getCia());
      $note->setFechaEmision(new DateTime());
      $note->setTipoDoc("07");
      $note->setSerie("F001");
      $note->setCorrelativo("10");
      $note->setTipoMoneda("PEN");
      $note->setCodMotivo("01"); // Anulacion de la operacion
      $note->setDesMotivo("Anulacion");
  		$note->setTipDocAfectado("01");
      $note->setNumDocfectado("F001-1");
      $note->setClient($client);
      //
      $note->setMtoOperGravadas(40.00);
      $note->setMtoOperExoneradas(0);
      $note->setMtoOperInafectas(0);
      $note->setMtoIGV(7.20);
      $note->setMtoImpVenta(47.20);
  	    // DETALLE
  		$items = [];
  		//foreach ($data->detalle as $row) {
      for ($i=1; $i <= 1; $i++) {
  			$item = new SaleDetail();
  			//$item->setCodProducto('P001');
  			$item->setUnidad("ZZ");
  			$item->setCantidad(2);
  			$item->setDescripcion("DESCRIPCION DE ITEM");
  			$item->setIgv(18);
  			$item->setTipAfeIgv(10);
        $item->setMtoValorUnitario(20.00);
  			$item->setMtoValorVenta(40.00);
  			$item->setMtoPrecioUnitario(23.60);
  			array_push($items, $item);
  		}
  		$note->setDetails($items);
  		//
  		$legend = new Legend();
  		$legend->setCode('1000');
  		$legend->setValue("Monto en letras");
  		//
    	$note->setLegends([$legend]);

      $see = new See();
      $see->setCertificado(file_get_contents(__DIR__ . '/certificate.pem'));
      $see->setRutaTrabajo("/var/www/html/see_archivos_new");
      $result = $see->enviar($note);
      //
      print_r($result);
      //file_put_contents(__DIR__ . '/' . $note->getName() . ".xml", $see->getXmlContent());
    }*/

    /*public function test03(){
      $baja = new VoidedDetail();
      $baja->setTipoDoc("01");
      $baja->setSerie("F001");
      $baja->setCorrelativo(1);
      $baja->setDesMotivoBaja("ERROR");

      $voided = new Voided();
      $voided->setCorrelativo("1");
      $voided->setFecGeneracion(new DateTime());
      $voided->setFecComunicacion(new DateTime());
      $voided->setCompany($this->getCia());
      $voided->setDetails([$baja]);

      $see = new See();
      $see->setCertificado(file_get_contents(__DIR__ . '/certificate.pem'));
      $see->setRutaTrabajo("/var/www/html/see_archivos_new");
      $result = $see->enviar($voided);
      //
      print_r($result);
    }*/
}
