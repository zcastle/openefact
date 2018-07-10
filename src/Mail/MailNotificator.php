<?php

namespace Ob\Mail;

use Ob\Mail\Notification;

use Ob\Mail\MailServer;
use Ob\Mail\MailSender;

class MailNotificator {

    private $mailServer;

    public function __construct(MailServer $mailServer){
        $this->mailServer = $mailServer;
    }

    public function notify(Notification $notification, $options = []){
        return $this->mailServer->send($notification, $options);
    }

}
