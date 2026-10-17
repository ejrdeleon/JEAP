<?php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class EmailVerificationCodeNotification extends Notification
{
    use Queueable;

    public function __construct(public readonly string $code) {}

    public function via(object $notifiable): array
    {
        return ['mail'];
    }

    public function toMail(object $notifiable): MailMessage
    {
        return (new MailMessage)
            ->subject('Verify your JEAP account')
            ->greeting('Verify your email address')
            ->line('Enter this 6-digit code to finish creating your JEAP account:')
            ->line($this->code)
            ->line('This code expires in 5 minutes. If you did not create this account, you can ignore this email.');
    }
}
