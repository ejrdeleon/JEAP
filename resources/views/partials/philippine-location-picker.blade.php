@php
    $regionNameField = $regionNameField ?? 'region_name';
    $provinceNameField = $provinceNameField ?? 'province_name';
    $cityNameField = $cityNameField ?? 'city_name';
    $barangayNameField = $barangayNameField ?? 'barangay_name';
    $countryCodeField = $countryCodeField ?? 'country_code';
    $countryNameField = $countryNameField ?? 'country_name';
    $postalCodeField = $postalCodeField ?? 'postal_code';
    $initialCountryCode = $initialCountryCode ?? 'PH';
    $initialCountryName = $initialCountryName ?? 'Philippines';
    $initialPostalCode = $initialPostalCode ?? '';
    $initialRegionName = $initialRegionName ?? '';
    $initialProvinceName = $initialProvinceName ?? '';
    $initialCityName = $initialCityName ?? '';
    $initialBarangayName = $initialBarangayName ?? '';
    $initialRegionCode = $initialRegionCode ?? '';
    $initialProvinceCode = $initialProvinceCode ?? '';
    $initialCityCode = $initialCityCode ?? '';
    $initialBarangayCode = $initialBarangayCode ?? '';
@endphp
<div class="ph-location-picker" data-philippine-location data-endpoint="{{ route('philippines.locations', 'LEVEL') }}"
    data-region-name-field="{{ $regionNameField }}"
    data-province-name-field="{{ $provinceNameField }}"
    data-city-name-field="{{ $cityNameField }}"
    data-barangay-name-field="{{ $barangayNameField }}"
    data-country-code-field="{{ $countryCodeField }}"
    data-country-name-field="{{ $countryNameField }}"
    data-postal-code-field="{{ $postalCodeField }}"
    data-initial-country-code="{{ old($countryCodeField, $initialCountryCode) }}"
    data-initial-country-name="{{ old($countryNameField, $initialCountryName) }}"
    data-initial-postal-code="{{ old($postalCodeField, $initialPostalCode) }}"
    data-initial-region-code="{{ $initialRegionCode }}"
    data-initial-province-code="{{ $initialProvinceCode }}"
    data-initial-city-code="{{ $initialCityCode }}"
    data-initial-barangay-code="{{ $initialBarangayCode }}"
    data-initial-region-name="{{ $initialRegionName }}"
    data-initial-province-name="{{ $initialProvinceName }}"
    data-initial-city-name="{{ $initialCityName }}"
    data-initial-barangay-name="{{ $initialBarangayName }}">
    <div class="delivery-address-fields">
        <label class="delivery-field"><span>Country</span>
            <select name="{{ $countryCodeField }}" data-country-select data-address-entry-field required>
                <option value="{{ old($countryCodeField, $initialCountryCode) }}">{{ old($countryNameField, $initialCountryName) ?: 'Loading countries…' }}</option>
            </select>
        </label>
    </div>
    <p class="ph-location-status" data-location-status role="status" aria-live="polite">Loading official Philippine locations…</p>
    <div class="ph-location-selectors" data-location-selectors hidden>
        <div class="delivery-address-fields">
            <label class="delivery-field"><span>Region</span><select data-location-level="regions" required disabled><option value="">Select a region</option></select></label>
            <label class="delivery-field" data-location-wrapper="province"><span>Province</span><select data-location-level="provinces" disabled><option value="">Select a province</option></select></label>
            <label class="delivery-field"><span>City / municipality</span><select data-location-level="municipalities" required disabled><option value="">Select a city or municipality</option></select></label>
            <label class="delivery-field" data-location-wrapper="barangay"><span>Barangay (optional)</span><select data-location-level="barangays" disabled><option value="">Select a barangay</option></select></label>
            <label class="delivery-field" data-postal-select-wrapper hidden><span>ZIP / postal code suggestions</span><select data-postal-select disabled><option value="">Select a postal code</option></select></label>
        </div>
        <button class="delivery-text-link ph-location-mode-button" type="button" data-location-use-manual>Enter location manually</button>
    </div>
    <div class="ph-location-manual" data-location-manual>
        <div class="delivery-address-fields">
            <label class="delivery-field"><span>Region</span><input name="{{ $regionNameField }}" data-address-entry-field data-location-manual-field="region" value="{{ $initialRegionName }}" maxlength="255"></label>
            <label class="delivery-field"><span>Province (if applicable)</span><input name="{{ $provinceNameField }}" data-address-entry-field data-location-manual-field="province" value="{{ $initialProvinceName }}" maxlength="255"></label>
            <label class="delivery-field"><span>City / municipality</span><input name="{{ $cityNameField }}" data-address-entry-field data-location-manual-field="city" value="{{ $initialCityName }}" maxlength="255" required autocomplete="address-level2"></label>
            <label class="delivery-field"><span>Barangay</span><input name="{{ $barangayNameField }}" data-address-entry-field data-location-manual-field="barangay" value="{{ $initialBarangayName }}" maxlength="255"></label>
        </div>
        <button class="delivery-text-link ph-location-mode-button" type="button" data-location-use-selects hidden>Choose official locations</button>
    </div>
    <label class="delivery-field" data-postal-manual-wrapper><span>ZIP / postal code</span><input name="{{ $postalCodeField }}" data-address-entry-field data-postal-manual value="{{ $initialPostalCode }}" maxlength="16" autocomplete="postal-code"></label>
    <input type="hidden" name="{{ $postalCodeField }}" value="{{ old($postalCodeField, $initialPostalCode) }}" data-postal-value data-address-entry-field disabled>
    <input type="hidden" name="{{ $regionNameField }}" value="{{ $initialRegionName }}" data-location-name="region" data-address-entry-field disabled>
    <input type="hidden" name="{{ $countryNameField }}" value="{{ old($countryNameField, $initialCountryName) }}" data-country-name data-address-entry-field>
    <input type="hidden" name="{{ $provinceNameField }}" value="{{ $initialProvinceName }}" data-location-name="province" data-address-entry-field disabled>
    <input type="hidden" name="{{ $cityNameField }}" value="{{ $initialCityName }}" data-location-name="city" data-address-entry-field disabled>
    <input type="hidden" name="{{ $barangayNameField }}" value="{{ $initialBarangayName }}" data-location-name="barangay" data-address-entry-field disabled>
    <input type="hidden" name="region_code" value="{{ old('region_code', $initialRegionCode) }}" data-location-code="region" data-address-entry-field disabled>
    <input type="hidden" name="province_code" value="{{ old('province_code', $initialProvinceCode) }}" data-location-code="province" data-address-entry-field disabled>
    <input type="hidden" name="city_code" value="{{ old('city_code', $initialCityCode) }}" data-location-code="city" data-address-entry-field disabled>
    <input type="hidden" name="barangay_code" value="{{ old('barangay_code', $initialBarangayCode) }}" data-location-code="barangay" data-address-entry-field disabled>
</div>
