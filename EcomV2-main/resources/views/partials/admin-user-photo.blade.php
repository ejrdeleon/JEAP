<div class="admin-user-cell">
    <div class="admin-user-photo" title="{{ $user->avatarUrl() ? 'Open profile photo' : 'No profile photo on file' }}">
        <span aria-hidden="true">{{ $user->initials() }}</span>
        @if ($user->avatarUrl())
            <a href="{{ $user->avatarUrl() }}" target="_blank" rel="noopener">
                <img src="{{ $user->avatarUrl() }}" alt="Profile photo of {{ $user->name }}" onerror="this.parentElement.remove()">
            </a>
        @endif
    </div>
    <div>
        <strong>{{ $user->name }}</strong>
        <small>{{ $user->email }}</small>
        @if ($user->status_reason)
            <small class="admin-status-reason">{{ $user->status->label() }}: {{ $user->status_reason }}</small>
        @endif
        @if ($user->statusChangedBy)
            <small>Last changed by {{ $user->statusChangedBy->name }}@if($user->status_changed_at) · {{ $user->status_changed_at->format('M j, Y') }}@endif</small>
        @endif
    </div>
</div>
