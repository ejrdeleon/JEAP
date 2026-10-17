<?php

namespace App\Http\Controllers;

use Illuminate\Http\Client\ConnectionException;
use Illuminate\Http\Client\RequestException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class PhilippineLocationController extends Controller
{
    private const API_BASE_URL = 'https://classification.psa.gov.ph/psgc';

    private const MIRROR_BASE_URL = 'https://psgc.gitlab.io/api';

    private const COUNTRIES_API_URL = 'https://countriesnow.space/api/v0.1/countries/iso';

    private const POSTAL_API_URL = 'https://psgc.cloud/api/v2/cities-municipalities';

    public function index(Request $request, string $level): JsonResponse
    {
        abort_unless(in_array($level, ['countries', 'regions', 'provinces', 'municipalities', 'barangays', 'postal-codes'], true), 404);

        $filters = match ($level) {
            'countries', 'regions' => [],
            'provinces' => $request->validate([
                'region_code' => ['required', 'string', 'regex:/^\d{1,16}$/'],
                'parent_code' => ['nullable', 'string', 'regex:/^\d{1,9}$/'],
            ]),
            'municipalities' => $request->validate([
                'region_code' => ['required_without:province_code', 'nullable', 'string', 'regex:/^\d{1,16}$/'],
                'province_code' => ['required_without:region_code', 'nullable', 'string', 'regex:/^\d{1,16}$/'],
                'parent_code' => ['nullable', 'string', 'regex:/^\d{1,9}$/'],
            ]),
            'barangays' => $request->validate([
                'city_code' => ['required', 'string', 'regex:/^\d{1,16}$/'],
                'parent_code' => ['nullable', 'string', 'regex:/^\d{1,9}$/'],
            ]),
            'postal-codes' => $request->validate([
                'city_code' => ['required', 'string', 'regex:/^\d{1,16}$/'],
            ]),
        };

        if ($level === 'countries') {
            return $this->countries();
        }

        if ($level === 'postal-codes') {
            return $this->postalCodes($filters['city_code']);
        }

        $token = config('services.psgc.token');
        $version = config('services.psgc.version');
        $provider = is_string($token) && trim($token) !== '' ? 'psa' : 'mirror';
        $cacheKey = 'psgc.v2.'.$provider.'.'.$version.'.'.$level.'.'.md5(json_encode($filters));

        try {
            $result = Cache::remember($cacheKey, now()->addWeek(), function () use ($level, $filters, $version, $token, $provider): array {
                if ($provider === 'psa') {
                    try {
                        return [
                            'source' => 'PSA PSGC',
                            'locations' => $this->fetchPsaLocations($level, $filters, $version, $token),
                        ];
                    } catch (ConnectionException|RequestException|\UnexpectedValueException $exception) {
                        Log::warning('PSA PSGC lookup failed; trying the community mirror.', [
                            'exception' => $exception::class,
                            'status' => $exception instanceof RequestException ? $exception->response->status() : null,
                        ]);
                    }
                }

                return [
                    'source' => 'PSGC community mirror',
                    'locations' => $this->fetchMirrorLocations($level, $filters),
                ];
            });
        } catch (ConnectionException $exception) {
            Log::warning('Unable to connect to the Philippine location API.', ['exception' => $exception::class]);

            return $this->unavailable();
        } catch (RequestException $exception) {
            Log::warning('The Philippine location API returned an unsuccessful response.', [
                'status' => $exception->response->status(),
            ]);

            return $this->unavailable();
        } catch (\UnexpectedValueException $exception) {
            Log::warning('The Philippine location API returned an invalid response.', ['exception' => $exception::class]);

            return $this->unavailable();
        }

        return response()->json($result);
    }

    private function fetchPsaLocations(string $level, array $filters, string $version, string $token): array
    {
        $query = match ($level) {
            'regions' => [],
            'provinces' => ['reg' => substr($filters['region_code'], 0, 2)],
            'municipalities' => $this->municipalityFilters($filters),
            'barangays' => $this->barangayFilters($filters['city_code']),
        };

        $response = Http::acceptJson()
            ->timeout(12)
            ->get(self::API_BASE_URL.'/'.$version.'/'.$this->apiLevel($level), [
                'token' => $token,
                'page_size' => 1000,
                ...$query,
            ]);
        $response->throw();

        $payload = $response->json();
        $records = data_get($payload, 'results.psgc_data')
            ?? data_get($payload, 'results')
            ?? data_get($payload, 'data')
            ?? $payload;

        if (! is_array($records)) {
            throw new \UnexpectedValueException('PSA returned an invalid location response.');
        }

        return $this->normalizeLocations($records, false);
    }

    private function fetchMirrorLocations(string $level, array $filters): array
    {
        $path = match ($level) {
            'regions' => '/regions/',
            'provinces' => '/regions/'.rawurlencode($this->requiredParentCode($filters)).'/provinces/',
            'municipalities' => $this->mirrorMunicipalityPath($filters),
            'barangays' => '/cities-municipalities/'.rawurlencode($this->requiredParentCode($filters)).'/barangays/',
        };

        $response = Http::acceptJson()->timeout(12)->get(self::MIRROR_BASE_URL.$path);
        $response->throw();
        $payload = $response->json();

        if (! is_array($payload)) {
            throw new \UnexpectedValueException('The PSGC mirror returned an invalid location response.');
        }

        return $this->normalizeLocations($payload, true);
    }

    private function countries(): JsonResponse
    {
        try {
            $countries = Cache::remember('countries.iso.all', now()->addMonth(), function (): array {
                $response = Http::acceptJson()->timeout(12)->get(self::COUNTRIES_API_URL);
                $response->throw();
                $records = $response->json('data');

                if (! is_array($records)) {
                    throw new \UnexpectedValueException('The country API returned an invalid response.');
                }

                return collect($records)
                    ->filter(fn ($record) => is_array($record))
                    ->map(fn (array $record): array => [
                        'code' => strtoupper((string) ($record['Iso2'] ?? '')),
                        'name' => trim((string) ($record['name'] ?? '')),
                    ])
                    ->filter(fn (array $record): bool => $record['code'] !== '' && $record['name'] !== '')
                    ->unique('code')
                    ->sortBy('name', SORT_NATURAL | SORT_FLAG_CASE)
                    ->values()
                    ->all();
            });
        } catch (ConnectionException|RequestException|\UnexpectedValueException $exception) {
            Log::warning('Unable to retrieve the country list.', ['exception' => $exception::class]);

            return response()->json([
                'message' => 'Country choices are temporarily unavailable. Please retry.',
            ], 503);
        }

        return response()->json(['locations' => $countries]);
    }

    private function postalCodes(string $cityCode): JsonResponse
    {
        try {
            $postalCodes = Cache::remember('psgc.postal.'.md5($cityCode), now()->addMonth(), function () use ($cityCode): array {
                $response = Http::acceptJson()->timeout(12)->get(self::POSTAL_API_URL.'/'.rawurlencode($cityCode));
                $response->throw();
                $postalCode = trim((string) $response->json('zip_code', ''));

                return $postalCode === '' ? [] : [['code' => $postalCode, 'name' => $postalCode]];
            });
        } catch (ConnectionException|RequestException $exception) {
            Log::warning('Unable to retrieve postal code suggestions.', ['exception' => $exception::class]);

            return response()->json([
                'message' => 'Postal code suggestions are temporarily unavailable. Enter the code manually.',
            ], 503);
        }

        return response()->json(['locations' => $postalCodes]);
    }

    private function municipalityFilters(array $filters): array
    {
        if (! empty($filters['province_code'])) {
            $provinceSegment = substr($filters['province_code'], 2, 3);

            if (trim($provinceSegment, '0') !== '') {
                return ['prv' => (int) $provinceSegment];
            }
        }

        return ['reg' => substr($filters['region_code'], 0, 2)];
    }

    private function barangayFilters(string $cityCode): array
    {
        $provinceSegment = substr($cityCode, 2, 3);
        $municipalitySegment = substr($cityCode, 5, 2);
        $filters = ['mun' => (int) $municipalitySegment];

        if (trim($provinceSegment, '0') !== '') {
            $filters['prv'] = (int) $provinceSegment;
        } else {
            $filters['reg'] = substr($cityCode, 0, 2);
        }

        return $filters;
    }

    private function mirrorMunicipalityPath(array $filters): string
    {
        if (! empty($filters['province_code'])) {
            return '/provinces/'.rawurlencode($this->requiredParentCode($filters)).'/cities-municipalities/';
        }

        return '/regions/'.rawurlencode($this->requiredParentCode($filters)).'/cities-municipalities/';
    }

    private function requiredParentCode(array $filters): string
    {
        $code = $filters['parent_code'] ?? null;
        if (! is_string($code) || ! preg_match('/^\d{1,9}$/', $code)) {
            throw new \UnexpectedValueException('A valid PSGC parent code is required.');
        }

        return $code;
    }

    private function normalizeLocations(array $records, bool $mirror): array
    {
        return collect($records)
            ->filter(fn ($record) => is_array($record))
            ->map(fn (array $record): array => [
                'code' => (string) ($mirror
                    ? ($record['psgc10DigitCode'] ?? $record['code'] ?? '')
                    : ($record['code'] ?? $record['psgc_code'] ?? '')),
                'parent_code' => (string) ($mirror ? ($record['code'] ?? '') : ''),
                'name' => trim((string) ($record['name'] ?? $record['area_name'] ?? '')),
            ])
            ->filter(fn (array $record): bool => $record['code'] !== '' && $record['name'] !== '')
            ->unique('code')
            ->sortBy('name', SORT_NATURAL | SORT_FLAG_CASE)
            ->values()
            ->all();
    }

    private function apiLevel(string $level): string
    {
        return $level === 'municipalities' ? 'cities-municipalities' : $level;
    }

    private function unavailable(): JsonResponse
    {
        return response()->json([
            'message' => 'Official Philippine location lookup is temporarily unavailable. Enter the location manually.',
        ], 503);
    }
}
