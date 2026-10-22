<?php

namespace App\Http\Requests;

use App\Enums\UserStatus;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateAccountAccessRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $restricted = in_array($this->input('status'), [
            UserStatus::Suspended->value,
            UserStatus::Deactivated->value,
        ], true);

        return [
            'status' => ['required', Rule::in([
                UserStatus::Active->value,
                UserStatus::Suspended->value,
                UserStatus::Deactivated->value,
            ])],
            'reason' => [$restricted ? 'required' : 'nullable', 'string', 'min:8', 'max:500'],
        ];
    }

    public function messages(): array
    {
        return [
            'reason.required' => 'Give the account holder a reason when suspending or deactivating them.',
            'reason.min' => 'The reason must be at least 8 characters.',
        ];
    }

    public function accessStatus(): UserStatus
    {
        return UserStatus::from((string) $this->validated('status'));
    }

    public function accessReason(): ?string
    {
        $reason = trim((string) ($this->validated('reason') ?? ''));

        return $reason !== '' ? $reason : null;
    }
}
