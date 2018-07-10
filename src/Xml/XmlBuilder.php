<?php

namespace Ob\Xml;

use Ob\Model\DocumentInterface;
use Ob\Model\Sale\Invoice;
use Ob\Model\Sale\Note;
use Ob\Model\Voided\Voided;

class XmlBuilder {

    private $twig;

    public function __construct($templatePath = __DIR__ . '/Templates'){
        $loader = new \Twig_Loader_Filesystem($templatePath);
        $this->twig = new \Twig_Environment($loader, array(
            //'cache' => '/path/to/compilation_cache'
        ));
        $this->twig->addFilter(new \Twig_SimpleFilter('n_format', function ($number, $decimals = 2) {
            return number_format($number, $decimals, '.', '');
        }));
    }

    public function build(DocumentInterface $document){
      $template = $this->getTemplate($document);

      $xml = $this->twig->render($template, ['doc' => $document]);
      return preg_replace('/<!--(.*)-->/Uis', '', $xml);
    }

    public function getTemplate(DocumentInterface $document){
      $templateList = [
            Invoice::class => "invoice-2.xml.twig",
            Note::class => "credit_note-2.xml.twig",
            Voided::class => "voided.xml.twig"
        ];

      return $templateList[get_class($document)];
    }
}
