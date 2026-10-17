@props([
    'formClass' => '',
    'buttonClass' => '',
    'style' => '',
])

<form method="POST" action="/logout" class="{{ $formClass }}">
    @csrf
    <button type="submit" class="{{ $buttonClass }}" @if ($style !== '') style="{{ $style }}" @endif>{{ $slot->isEmpty() ? 'Log out' : $slot }}</button>
</form>
