<?php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class RegistrationDecisionNotification extends Notification
{
    use Queueable;

    public function __construct(public readonly string $decision, public readonly ?string $reason = null) {}

    public function via(object $notifiable): array
    {
        return ['mail'];
    }

    public function toMail(object $notifiable): MailMessage
    {
        $message = (new MailMessage)
            ->subject($this->decision === 'approved' ? 'Your JEAP application was approved' : 'Update on your JEAP application')
            ->greeting('Hello '.$notifiable->first_name);

        if ($this->decision === 'approved') {
            return $message->line('Your JEAP seller or logistics application has been approved. You can now sign in to your account.');
        }

        $message->line('Your JEAP application was not approved. You can correct the information and submit it again.');
        if ($this->reason) {
            $message->line('Review notes: '.$this->reason);
        }

        return $message;
    }
}
