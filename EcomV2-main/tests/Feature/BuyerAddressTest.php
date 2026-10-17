<?php

namespace Tests\Feature;

use App\Enums\UserStatus;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Client\Request as ClientRequest;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class BuyerAddressTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RoleSeeder::class);
    }

    public function test_buyer_can_save_and_edit_an_address_with_coordinates(): void
    {
        $buyer = $this->createBuyer();

        $this->actingAs($buyer)->post(route('buyer.addresses.store'), $this->addressData())
            ->assertRedirect()
            ->assertSessionHas('toast', 'Delivery address saved.');

        $address = $buyer->addresses()->firstOrFail();
        $this->assertSame('14.5995123', $address->latitude);
        $this->assertSame('120.9842222', $address->longitude);
        $this->assertSame('1300000000', $address->region_code);
        $this->assertSame('National Capital Region', $address->region_name);
        $this->assertSame('Ermita', $address->barangay_name);
        $this->assertSame('PH', $address->country_code);
        $this->assertSame('Philippines', $address->country_name);
        $this->assertTrue($address->is_default);

        $this->actingAs($buyer)->put(route('buyer.addresses.update', $address), array_merge(
            $this->addressData(),
            ['street_line' => 'Updated Street', 'latitude' => '-14.5000000', 'longitude' => '-179.5000000']
        ))->assertRedirect();

        $this->assertDatabaseHas('addresses', [
            'id' => $address->id,
            'street_line' => 'Updated Street',
            'latitude' => '-14.5000000',
            'longitude' => '-179.5000000',
        ]);
        $this->actingAs($buyer)->get(route('buyer.addresses'))
            ->assertOk()
            ->assertSee('Updated Street')
            ->assertSee('-14.5000000');

        $this->actingAs($buyer)->delete(route('buyer.addresses.delete', $address))
            ->assertRedirect();
        $this->assertDatabaseMissing('addresses', ['id' => $address->id]);
    }

    public function test_buyer_address_page_renders_location_and_country_selectors(): void
    {
        $buyer = $this->createBuyer();

        $this->actingAs($buyer)->get(route('buyer.addresses'))
        ->assertOk()
        ->assertSee('data-country-select', false)
        ->assertSee('data-location-level="regions"', false)
        ->assertSee('data-location-level="provinces"', false)
        ->assertSee('data-location-level="municipalities"', false)
        ->assertSee('data-location-level="barangays"', false)
        ->assertSee('ZIP / postal code suggestions');
    }

    public function test_address_coordinates_are_validated_as_a_pair_and_within_range(): void
    {
        $buyer = $this->createBuyer();

        $this->actingAs($buyer)->from(route('buyer.addresses'))->post(route('buyer.addresses.store'), array_merge(
            $this->addressData(),
            ['latitude' => '90.0000001', 'longitude' => '181']
        ))->assertRedirect(route('buyer.addresses'))
            ->assertSessionHasErrors(['latitude', 'longitude']);

        $this->actingAs($buyer)->from(route('buyer.addresses'))->post(route('buyer.addresses.store'), array_merge(
            $this->addressData(),
            ['latitude' => '14.5', 'longitude' => '']
        ))->assertRedirect(route('buyer.addresses'))
            ->assertSessionHasErrors('longitude');

        $this->assertDatabaseCount('addresses', 0);
    }

    public function test_buyer_cannot_view_or_modify_another_users_address(): void
    {
        $buyer = $this->createBuyer();
        $otherBuyer = $this->createBuyer();
        $address = $otherBuyer->addresses()->create($this->addressData());

        $this->actingAs($buyer)->put(route('buyer.addresses.update', $address), $this->addressData())
            ->assertNotFound();
        $this->actingAs($buyer)->delete(route('buyer.addresses.delete', $address))
            ->assertNotFound();

        $this->assertDatabaseHas('addresses', ['id' => $address->id, 'street_line' => '1 Example Street']);
    }

    public function test_only_buyers_can_access_their_delivery_address_page(): void
    {
        $seller = User::factory()->create(['status' => UserStatus::Active]);
        $seller->assignRole('seller');

        $this->actingAs($seller)->get(route('buyer.addresses'))->assertForbidden();
    }

    public function test_existing_address_api_accepts_and_validates_pin_coordinates(): void
    {
        $buyer = $this->createBuyer();
        $payload = [
            'label' => 'Home',
            'recipient_name' => 'Test Buyer',
            'phone' => '09170000000',
            'province_name' => 'Metro Manila',
            'city_name' => 'Manila',
            'barangay_name' => 'Barangay 1',
            'street_line' => '1 Example Street',
            'postal_code' => '1000',
            'latitude' => '14.5995123',
            'longitude' => '120.9842222',
        ];

        $this->actingAs($buyer, 'sanctum')->postJson('/api/v1/addresses', $payload)
            ->assertCreated()
            ->assertJsonPath('address.latitude', '14.5995123')
            ->assertJsonPath('address.longitude', '120.9842222');

        $this->actingAs($buyer, 'sanctum')->postJson('/api/v1/addresses', array_merge(
            $payload,
            ['latitude' => '91']
        ))->assertUnprocessable()->assertJsonValidationErrors('latitude');
    }

    public function test_psgc_location_endpoint_proxies_official_results_and_filters(): void
    {
        config([
            'services.psgc.token' => 'test-psa-token',
            'services.psgc.version' => 'Q2_TEST',
        ]);
        Http::fake([
            'classification.psa.gov.ph/psgc/Q2_TEST/regions*' => Http::response([
                'results' => ['psgc_data' => [
                    ['psgc_code' => '1300000000', 'area_name' => 'National Capital Region'],
                ]],
            ]),
            'classification.psa.gov.ph/psgc/Q2_TEST/cities-municipalities*' => Http::response([
                'results' => ['psgc_data' => [
                    ['psgc_code' => '1380600000', 'area_name' => 'City of Manila'],
                ]],
            ]),
        ]);

        $this->getJson(route('philippines.locations', 'regions'))
            ->assertOk()
            ->assertJsonPath('locations.0.code', '1300000000')
            ->assertJsonPath('locations.0.name', 'National Capital Region');
        $this->getJson(route('philippines.locations', 'municipalities').'?region_code=1300000000')
            ->assertOk()
            ->assertJsonPath('locations.0.code', '1380600000');

        Http::assertSent(function (ClientRequest $request): bool {
            parse_str((string) parse_url($request->url(), PHP_URL_QUERY), $query);

            return str_contains($request->url(), '/Q2_TEST/regions')
                && ($query['token'] ?? null) === 'test-psa-token';
        });
        Http::assertSent(function (ClientRequest $request): bool {
            parse_str((string) parse_url($request->url(), PHP_URL_QUERY), $query);

            return str_contains($request->url(), '/Q2_TEST/cities-municipalities')
                && ($query['reg'] ?? null) === '13'
                && ($query['token'] ?? null) === 'test-psa-token';
        });
    }

    public function test_psgc_location_endpoint_uses_public_mirror_when_psa_token_is_not_configured(): void
    {
        config(['services.psgc.token' => null]);
        Cache::forget('psgc.mirror.Q2_2026.regions.'.md5(json_encode([])));
        Http::fake([
            'psgc.gitlab.io/api/regions/' => Http::response([
                ['code' => '130000000', 'psgc10DigitCode' => '1300000000', 'name' => 'National Capital Region'],
            ]),
        ]);

        $this->getJson(route('philippines.locations', 'regions'))
            ->assertOk()
            ->assertJsonPath('source', 'PSGC community mirror')
            ->assertJsonPath('locations.0.code', '1300000000')
            ->assertJsonPath('locations.0.parent_code', '130000000');

        Http::assertSent(fn (ClientRequest $request): bool => $request->url() === 'https://psgc.gitlab.io/api/regions/');
    }

    public function test_country_and_postal_dropdown_apis_return_available_options(): void
    {
        Cache::forget('countries.iso.all');
        Cache::forget('psgc.postal.'.md5('0102801000'));
        Http::fake([
            'countriesnow.space/api/v0.1/countries/iso' => Http::response([
                'error' => false,
                'data' => [['name' => 'Philippines', 'Iso2' => 'PH']],
            ]),
            'psgc.cloud/api/v2/cities-municipalities/0102801000' => Http::response([
                'code' => '0102801000',
                'name' => 'Adams',
                'zip_code' => '2922',
            ]),
        ]);

        $this->getJson(route('philippines.locations', 'countries'))
            ->assertOk()
            ->assertJsonPath('locations.0.code', 'PH')
            ->assertJsonPath('locations.0.name', 'Philippines');
        $this->getJson(route('philippines.locations', 'postal-codes').'?city_code=0102801000')
            ->assertOk()
            ->assertJsonPath('locations.0.code', '2922');
    }

    public function test_public_psgc_mirror_provides_the_full_cascading_location_hierarchy(): void
    {
        config(['services.psgc.token' => null]);
        Cache::forget('psgc.mirror.Q2_2026.provinces.'.md5(json_encode([
            'region_code' => '0100000000',
            'parent_code' => '010000000',
        ])));
        Cache::forget('psgc.mirror.Q2_2026.municipalities.'.md5(json_encode([
            'province_code' => '0102800000',
            'parent_code' => '012800000',
        ])));
        Cache::forget('psgc.mirror.Q2_2026.barangays.'.md5(json_encode([
            'city_code' => '0102801000',
            'parent_code' => '012801000',
        ])));
        Http::fake([
            'psgc.gitlab.io/api/regions/010000000/provinces/' => Http::response([
                ['code' => '012800000', 'psgc10DigitCode' => '0102800000', 'name' => 'Ilocos Norte'],
            ]),
            'psgc.gitlab.io/api/provinces/012800000/cities-municipalities/' => Http::response([
                ['code' => '012801000', 'psgc10DigitCode' => '0102801000', 'name' => 'Adams'],
            ]),
            'psgc.gitlab.io/api/cities-municipalities/012801000/barangays/' => Http::response([
                ['code' => '012801001', 'psgc10DigitCode' => '0102801001', 'name' => 'Adams (Pob.)'],
            ]),
        ]);

        $this->getJson(route('philippines.locations', 'provinces').'?region_code=0100000000&parent_code=010000000')
            ->assertOk()
            ->assertJsonPath('locations.0.code', '0102800000');
        $this->getJson(route('philippines.locations', 'municipalities').'?province_code=0102800000&parent_code=012800000')
            ->assertOk()
            ->assertJsonPath('locations.0.code', '0102801000');
        $this->getJson(route('philippines.locations', 'barangays').'?city_code=0102801000&parent_code=012801000')
            ->assertOk()
            ->assertJsonPath('locations.0.code', '0102801001');
    }

    private function createBuyer(): User
    {
        $buyer = User::factory()->create(['status' => UserStatus::Active]);
        $buyer->assignRole('buyer');

        return $buyer;
    }

    private function addressData(): array
    {
        return [
            'label' => 'Home',
            'recipient_name' => 'Test Buyer',
            'phone' => '09170000000',
            'country_code' => 'PH',
            'country_name' => 'Philippines',
            'street_line' => '1 Example Street',
            'city_name' => 'Manila',
            'province_name' => 'Metro Manila',
            'region_name' => 'National Capital Region',
            'region_code' => '1300000000',
            'province_code' => '',
            'city_code' => '1380600000',
            'barangay_code' => '1380600010',
            'barangay_name' => 'Ermita',
            'postal_code' => '1000',
            'latitude' => '14.5995123',
            'longitude' => '120.9842222',
            'is_default' => '1',
        ];
    }
}
