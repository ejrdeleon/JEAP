<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Controllers\PhilippineLocationController;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class LocationController extends Controller
{
    public function regions(): JsonResponse
    {
        return $this->wrap('regions', []);
    }

    public function provinces(string $regionCode): JsonResponse
    {
        if (str_starts_with($regionCode, '13')) {
            return response()->json(['data' => []]);
        }

        return $this->wrap('provinces', [
            'region_code' => $regionCode,
            'parent_code' => $this->parentCode($regionCode),
        ], fn (array $row) => [
            'code' => $row['code'],
            'psgc_10_digit' => $row['code'],
            'name' => $row['name'],
            'region_code' => $regionCode,
        ]);
    }

    public function regionCities(string $regionCode): JsonResponse
    {
        return $this->wrap('municipalities', [
            'region_code' => $regionCode,
            'parent_code' => $this->parentCode($regionCode),
        ], fn (array $row) => $this->locality($row, $regionCode, ''));
    }

    public function provinceCities(string $provinceCode): JsonResponse
    {
        return $this->wrap('municipalities', [
            'province_code' => $provinceCode,
            'parent_code' => $this->parentCode($provinceCode),
        ], fn (array $row) => $this->locality($row, '', $provinceCode));
    }

    public function barangays(string $localityCode): JsonResponse
    {
        return $this->wrap('barangays', [
            'city_code' => $localityCode,
            'parent_code' => $this->parentCode($localityCode),
        ], fn (array $row) => [
            'code' => $row['code'],
            'psgc_10_digit' => $row['code'],
            'name' => $row['name'],
            'city_code' => $localityCode,
        ]);
    }

    public function postalCode(string $localityCode): JsonResponse
    {
        $response = app(PhilippineLocationController::class)->index(
            Request::create('/philippines/locations/postal-codes', 'GET', ['city_code' => $localityCode]),
            'postal-codes'
        );
        $payload = $response->getData(true);
        $code = $payload['locations'][0]['code'] ?? null;

        return response()->json([
            'postal_code' => $code,
            'data' => ['postal_code' => $code],
        ]);
    }

    public function search(Request $request): JsonResponse
    {
        $data = $request->validate(['q' => ['required', 'string', 'min:2', 'max:120']]);

        return response()->json(['data' => [], 'query' => $data['q']]);
    }

    private function wrap(string $level, array $query, ?callable $map = null): JsonResponse
    {
        $response = app(PhilippineLocationController::class)->index(
            Request::create('/philippines/locations/'.$level, 'GET', $query),
            $level
        );
        $payload = $response->getData(true);
        if ($response->getStatusCode() >= 400) {
            return response()->json(['data' => [], 'message' => $payload['message'] ?? 'Location lookup unavailable.'], $response->getStatusCode());
        }

        $rows = collect($payload['locations'] ?? [])->map(function (array $row) use ($map) {
            $base = [
                'code' => (string) ($row['code'] ?? ''),
                'psgc_10_digit' => (string) ($row['code'] ?? ''),
                'name' => (string) ($row['name'] ?? ''),
                'region_name' => (string) ($row['name'] ?? ''),
                'island_group' => '',
            ];

            return $map ? array_merge($base, $map($row)) : $base;
        })->values();

        return response()->json(['data' => $rows]);
    }

    private function locality(array $row, string $regionCode, string $provinceCode): array
    {
        $name = strtolower((string) ($row['name'] ?? ''));

        return [
            'region_code' => $regionCode,
            'province_code' => $provinceCode,
            'is_city' => str_contains($name, 'city'),
            'is_municipality' => ! str_contains($name, 'city'),
        ];
    }

    private function parentCode(string $code): string
    {
        return preg_match('/^\d{1,9}$/', $code) === 1 ? $code : substr($code, 0, 9);
    }
}
