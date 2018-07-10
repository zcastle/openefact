<?php

namespace Ob\Pdf;

class Extension extends \Twig_Extension{

    public function getFilters(){
        return [
            new \Twig_SimpleFilter('catalog', ['Ob\Pdf\Filter\DocumentFilter', 'getValueCatalog']),
            new \Twig_SimpleFilter('image_b64', ['Ob\Pdf\Filter\ImageFilter', 'toBase64']),
            new \Twig_SimpleFilter('n_format', ['Ob\Pdf\Filter\FormatFilter', 'number']),
        ];
    }

    public function getFunctions(){
        return [
            new \Twig_SimpleFunction('legend', ['Ob\Pdf\Filter\ResolveFilter', 'getValueLegend']),
            new \Twig_SimpleFunction('qrCode', ['Ob\Pdf\Filter\ResolveFilter', 'getQr']),
        ];
    }
}
