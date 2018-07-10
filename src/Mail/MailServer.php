<?php

namespace Greenter\Mail;

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

use Ob\Mail\Notification;
use Ob\Mail\MailSender;

use Ob\Report\HtmlReport;
use Ob\Model\DocumentInterface;

class MailServer {

	const DEBUG = true;
	const SUBJECT = 'Documento electrónico emitido por {}';

	protected $mail;

    public function __construct($config = [], $debug = true) {
    	$this->mail = new PHPMailer($debug);
    	$this->mail->isHTML(true);
        $this->mail->CharSet = 'UTF-8';

    	if(isset($config['SMTPDebug'])){
	    	$this->mail->SMTPDebug = $config['SMTPDebug'];
	    }

	    if(isset($config['isSMTP'])){
	    	if(is_bool($config['isSMTP']) && $config['isSMTP']){
		    	$this->mail->isSMTP();
		    }
	    }

	    if(isset($config['Host'])){
	    	$this->mail->Host = $config['Host'];
	    }

	    if(isset($config['SMTPAuth'])){
	    	if(is_bool($config['SMTPAuth'])){
		    	$this->mail->SMTPAuth = $config['SMTPAuth'];
		    }
	    }

	    if(isset($config['Username']) && isset($config['Password'])){
	    	$this->mail->Username = $config['Username'];
	    	$this->mail->Password = $config['Password'];
	    }

	    if(isset($config['SMTPSecure'])){
	    	$this->mail->SMTPSecure = $config['SMTPSecure'];
	    }

	    if(isset($config['Port'])){
	    	$this->mail->Port = $config['Port'];
	    }

    }

    public function setSender(MailEmail $sender){
    	$this->mail->setFrom($sender->getEmail(), $sender->getName());
    }

    public function setReceipt(MailEmail $receipt){
    	$this->mail->addAddress($receipt->getEmail(), $receipt->getName());
    }

    private function setBody(DocumentInterface $document, $options = []){
        $content = $this->getTemplate($document, $options);
        $this->mail->Body = $content;
        $this->mail->Subject = str_replace('{}', $document->getCompany()->getRazonSocial(), MailServer::SUBJECT);
    }

    private function setAttachment($files){
        foreach ($files as $file) {
    	   $this->mail->AddStringAttachment($file->getContent(), $file->getName(), 'base64', $file->getType());
        }
    }

    public function send(Notification $notification, $options = []){
    	$response = array('success' => true, 'error' => false, 'code' => 0, 'message' => '');

        $this->setBody($notification->getDocument(), $options);
        $this->setAttachment($notification->getFiles());

		if (!$this->mail->send()) {
            $response['error'] = true;
            $response['message'] = $this->mail->ErrorInfo;
        } else {
            $response['message'] = 'Correo enviado';
        }

		return $response;
    }

    private function getTemplate(DocumentInterface $document, $options = []){
        $html = new HtmlReport(__DIR__ . '/Templates', [
            //'cache' => __DIR__ . '/../cache',
            'strict_variables' => true
        ]);
        $html->setTemplate('mail.html.twig');
        return $html->render($document, $options);
    }
}
