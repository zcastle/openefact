<?PHP

namespace Ob\Pdf;

use Ob\Model\DocumentInterface;
use Ob\Model\Sale\Invoice;
use Ob\Model\Sale\Note;
use Ob\Model\Voided\Voided;

use Ob\Pdf\RuntimeLoader;
use Ob\Pdf\Extension;

use mikehaertl\wkhtmlto\Pdf;

class PdfBuilder {

    private $twig;

    public function __construct($templatePath = __DIR__ . '/Templates'){
        $loader = new \Twig_Loader_Filesystem($templatePath);
        $this->twig = new \Twig_Environment($loader, array(
            //'cache' => '/path/to/compilation_cache'
        ));
        $this->twig->addRuntimeLoader(new RuntimeLoader());
        $this->twig->addExtension(new Extension());
    }

    public function build(DocumentInterface $document, $parameters = []){
      $template = $this->getTemplate($document);

      $html = $this->twig->render($template, [
        'doc' => $document,
        'params' => $parameters,
      ]);

      $pdfRender = $this->getPdfRender();
      $pdfRender->addPage($html);
      return $pdfRender->toString();
      //return $html;
    }

    public function getTemplate(DocumentInterface $document){
      $templateList = [
            Invoice::class => "invoice.html.twig",
            Note::class => "invoice.html.twig"
        ];

      return $templateList[get_class($document)];
    }

    private function getPdfRender(){
      $pdfRender = new Pdf([
        'no-outline',
        'viewport-size' => '1280x1024',
        'page-width' => '21cm',
        'page-height' => '29.7cm'
      ]);
      $binPath = __DIR__ . '/../../vendor/bin/wkhtmltopdf';
      if ($this->isWindows()) {
        $binPath .= '.exe';
      }
      $pdfRender->binary = $binPath;

      return $pdfRender;
    }

    private function isWindows(){
      return strtoupper(substr(PHP_OS, 0, 3)) === 'WIN';
    }
}
