<?php

namespace App\Http\Requests;

use App\Enums\ShipmentStatus;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class LogShipmentCheckpointRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->hasAnyRole(['courier', 'logistics', 'admin', 'super-admin']) === true;
    }

    public function rules(): array
    {
        $delivered = $this->input('status') === ShipmentStatus::Delivered->value;

        return [
            'status' => ['required', 'string', Rule::in(ShipmentStatus::values())],
            'title' => ['nullable', 'string', 'max:255'],
            'location' => ['nullable', 'string', 'max:160'],
            'notes' => ['nullable', 'string', 'max:2000'],
            'scanned_at' => ['nullable', 'date'],
            'courier_id' => ['nullable', 'integer', 'exists:users,id'],
            'recipient_name' => [$delivered ? 'nullable' : 'nullable', 'string', 'max:120'],
            'proof_of_delivery' => [$delivered ? 'required' : 'nullable', 'image', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
        ];
    }

    public function messages(): array
    {
        return [
            'proof_of_delivery.required' => 'Upload a proof-of-delivery photo when marking the parcel delivered.',
        ];
    }
}
