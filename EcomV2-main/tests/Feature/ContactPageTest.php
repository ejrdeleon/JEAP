<?php

namespace Tests\Feature;

use App\Models\ContactMessage;
use App\Models\User;
use Database\Seeders\CatalogSeeder;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ContactPageTest extends TestCase
{
    use RefreshDatabase;

    public function test_contact_page_uses_available_support_routes_and_real_hotline(): void
    {
        $this->seed(RoleSeeder::class);
        $this->seed(CatalogSeeder::class);
        $hotline = config('jeap.hotline');
        $telephone = preg_replace('/\D+/', '', $hotline);

        $this->get(route('contact'))
            ->assertOk()
            ->assertSee('Talk to JEAP.')
            ->assertSee($hotline)
            ->assertSee('tel:'.$telephone, false)
            ->assertSee(route('shipping.track'))
            ->assertSee(route('login'))
            ->assertSee(route('contact.submit'))
            ->assertSee('Which payment method can I use?')
            ->assertDontSee('hello@jeap.test')
            ->assertDontSee('data-sent');
    }

    public function test_contact_submission_is_validated_and_persisted_for_the_private_admin_inbox(): void
    {
        $this->seed(RoleSeeder::class);
        $this->seed(CatalogSeeder::class);

        $this->post(route('contact.submit'), [
            'full_name' => 'Maya Santos',
            'email' => 'maya@example.com',
            'category' => 'delivery',
            'order_number' => 'JEP12345',
            'message' => 'Please help me check the latest shipment update.',
            'website' => '',
        ])->assertRedirect(route('contact'));

        $this->assertDatabaseHas('contact_messages', [
            'full_name' => 'Maya Santos',
            'email' => 'maya@example.com',
            'category' => 'delivery',
            'order_number' => 'JEP12345',
        ]);

        $this->get(route('admin.contact-messages'))->assertRedirect(route('login'));

        $admin = User::factory()->create();
        $admin->assignRole('admin');
        $this->actingAs($admin)->get(route('admin.contact-messages'))
            ->assertOk()
            ->assertSee('Maya Santos')
            ->assertSee('Please help me check the latest shipment update.');
    }

    public function test_contact_form_rejects_invalid_fields_and_rate_limits_submissions(): void
    {
        $this->seed(RoleSeeder::class);
        $this->seed(CatalogSeeder::class);

        $this->from(route('contact'))->post(route('contact.submit'), [
            'full_name' => 'A',
            'email' => 'invalid-email',
            'category' => 'unknown',
            'message' => 'short',
            'website' => '',
        ])->assertRedirect(route('contact'))
            ->assertSessionHasErrors(['full_name', 'email', 'category', 'message']);

        $payload = [
            'full_name' => 'Maya Santos',
            'email' => 'maya@example.com',
            'category' => 'general',
            'message' => 'I have a question about the JEAP marketplace.',
            'website' => '',
        ];

        for ($attempt = 0; $attempt < 4; $attempt++) {
            $this->post(route('contact.submit'), $payload)->assertRedirect(route('contact'));
        }

        $this->post(route('contact.submit'), $payload)->assertTooManyRequests();
        $this->assertSame(4, ContactMessage::query()->count());
    }
}
