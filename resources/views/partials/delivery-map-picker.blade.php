<section class="delivery-map-picker" data-map-picker
    data-api-key="{{ $mapsKey ?? '' }}"
    data-address-selector="{{ $addressSelector ?? '' }}"
    data-latitude-field="{{ $latitudeField ?? 'latitude' }}"
    data-longitude-field="{{ $longitudeField ?? 'longitude' }}">
    <div class="delivery-map-tools">
        <label class="delivery-map-search">
            <span>Search for an address (optional)</span>
            <input type="search" data-map-search autocomplete="off" placeholder="Search a place in the Philippines" aria-label="Search for a delivery address">
        </label>
        <button class="delivery-location-button" type="button" data-map-geolocate>Use my location</button>
    </div>
    <div class="delivery-map-canvas" data-map-canvas role="application" aria-label="Delivery location map"></div>
    <p class="delivery-map-status" data-map-status role="status" aria-live="polite">
        Enter your address manually, or choose a point on the map.
    </p>
    <p class="delivery-map-coordinates" data-map-coordinates>Location coordinates not set.</p>
</section>
