<form method="post" action="{{ $action }}" class="admin-inline-form admin-access-form">
    @csrf
    @method('PATCH')
    <label class="admin-field">
        <span>Status</span>
        <select name="status" aria-label="New status for {{ $account->name }}">
            <option value="active" @selected($account->status->value === 'active')>Active</option>
            <option value="suspended" @selected($account->status->value === 'suspended')>Suspended</option>
            <option value="deactivated" @selected($account->status->value === 'deactivated')>Deactivated</option>
        </select>
    </label>
    <label class="admin-field admin-access-reason">
        <span>Reason</span>
        <textarea name="reason" rows="2" maxlength="500" placeholder="Required to suspend or deactivate">{{ old('reason', $account->status_reason) }}</textarea>
    </label>
    <button class="admin-button admin-button-small">Save</button>
</form>
