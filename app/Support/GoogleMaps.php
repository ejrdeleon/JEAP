<?php

namespace App\Support;

class GoogleMaps
{
    public static function browserKey(): ?string
    {
        $key = trim((string) config('services.google.maps_browser_key'));
        if ($key === '' || preg_match('/your-google|placeholder|changeme|example/i', $key) === 1) {
            return null;
        }

        return $key;
    }
}
