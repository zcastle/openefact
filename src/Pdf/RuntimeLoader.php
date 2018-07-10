<?php

namespace Ob\Pdf;

class RuntimeLoader implements \Twig_RuntimeLoaderInterface{

    public function load($class){
        return new $class();
    }
}
