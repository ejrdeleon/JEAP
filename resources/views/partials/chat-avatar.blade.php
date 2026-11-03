@php
    $person = $person ?? null;
    $label = $label ?? ($person?->name ?? 'JEAP');
    $url = $person?->avatarUrl();
    $initial = mb_strtoupper(mb_substr(trim((string) $label) !== '' ? (string) $label : 'J', 0, 1));
@endphp
<span class="chat-avatar" aria-hidden="true">
    @if($url)
        <img src="{{ $url }}" alt="">
    @else
        {{ $initial }}
    @endif
</span>
