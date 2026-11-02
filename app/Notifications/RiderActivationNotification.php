<?php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class RiderActivationNotification extends Notification
{
    use Queueable;

    public function __construct(public readonly string $activationUrl) {}

    public function via(object $notifiable): array
    {
        return ['mail'];
    }

    public function toMail(object $notifiable): MailMessage
    {
        return (new MailMessage)
            ->subject('Activate your '.config('jeap.courier_name').' rider account')
            ->greeting('Welcome to '.config('jeap.courier_name'))
            ->line('An approved logistics company created a '.config('jeap.courier_name').' rider account for you.')
            ->line('Set a password to activate your account. This link expires in 24 hours and can only be used once.')
            ->action('Activate rider account', $this->activationUrl);
    }
}
