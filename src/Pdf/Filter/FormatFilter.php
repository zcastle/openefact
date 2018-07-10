<?php

namespace Ob\Pdf\Filter;

class FormatFilter {

    public function number($number, $decimals = 2){
        return number_format($number, $decimals, '.', '');
    }
}
