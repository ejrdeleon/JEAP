@extends('layouts.dashboard')
@section('title', 'Store profile')
@section('nav')
    @include('partials.seller-nav', ['active' => 'store'])
@endsection
@section('content')
<div class="seller-page">
    <div class="seller-heading">
        <div><h1>Store profile</h1><p>Shop name, photos, and vacation mode. A store on vacation is hidden from the shop until you turn this off.</p></div>
    </div>
    @if(session('status'))<div class="seller-empty"><strong>{{ session('status') }}</strong></div>@endif
    @if($errors->any())<div class="seller-errors">{{ $errors->first() }}</div>@endif
    <form class="seller-product-form" method="post" action="{{ route('seller.store-profile.update') }}" enctype="multipart/form-data">
        @csrf @method('PUT')
        <div class="s3-field"><label for="store-name">Shop name</label><input id="store-name" name="business_name" value="{{ old('business_name', $profile->business_name) }}" minlength="3" maxlength="30" required></div>
        <div class="s3-field"><label for="store-phone">Shop phone</label><input id="store-phone" name="contact_phone" value="{{ old('contact_phone', $profile->contact_phone) }}" required></div>
        <div class="s3-field"><label for="store-description">About the shop</label><textarea id="store-description" name="description" rows="4" maxlength="500">{{ old('description', $profile->description) }}</textarea></div>
        <div class="s3-field"><label for="store-logo">Logo (JPG or PNG, 5 MB)</label><input id="store-logo" type="file" name="logo" accept=".jpg,.jpeg,.png">@if($profile->logo_path)<label class="register-terms"><input type="checkbox" name="remove_logo" value="1"> Remove current logo</label>@endif</div>
        <div class="s3-field"><label for="store-banner">Banner (JPG or PNG, 5 MB)</label><input id="store-banner" type="file" name="banner" accept=".jpg,.jpeg,.png">@if($profile->banner_path)<label class="register-terms"><input type="checkbox" name="remove_banner" value="1"> Remove current banner</label>@endif</div>
        <label class="register-terms"><input type="checkbox" name="vacation_mode" value="1" @checked(old('vacation_mode', $profile->vacation_mode))> Vacation mode — hide this shop from the catalog</label>
        <div class="seller-form-actions"><button class="seller-primary" type="submit">Save store profile</button></div>
    </form>
</div>
@endsection
