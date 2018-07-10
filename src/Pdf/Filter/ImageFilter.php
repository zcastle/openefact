<?php

namespace Ob\Pdf\Filter;

class ImageFilter {

    const IMAGE_EMBED_PART = 'data:image/png;base64,';

    public function toBase64($image){
        $content = base64_encode($image);

        return self::IMAGE_EMBED_PART.$content;
    }
}
